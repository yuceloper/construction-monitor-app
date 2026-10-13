import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/daily_task_summary.dart';

/// Gunluk is servisi.
///
/// dart:io'daki HttpClient tarayicida calismadigi icin istekler http
/// paketiyle yapiliyor. Coklu dosya gonderimi de elle yazilan multipart
/// govdesi yerine http.MultipartRequest ile: ayni kod hem telefonda hem
/// tarayicida calisiyor.
///
/// Govde utf8.decode(bodyBytes) ile okunuyor: sunucu Content-Type'ta
/// charset bildirmiyor, http paketi boyle durumda latin1 varsayiyor.
class DailyTaskService {
  Future<List<DailyTaskSummary>> getTasks({
    required bool includeCompleted,
  }) async {
    final token = _token();
    final siteId = _siteId();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/tasks/site/$siteId').replace(
        queryParameters: {'includeCompleted': includeCompleted.toString()},
      );
      final response = await http.get(uri, headers: _headers(token));
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> ||
            decoded['success'] != true ||
            data is! List) {
          throw const DailyTaskException('Günlük işler alınamadı.');
        }
        return data
            .whereType<Map>()
            .map(
              (item) =>
                  DailyTaskSummary.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.id > 0)
            .toList();
      }
      _throwForResponse(response.statusCode, body, 'Günlük işler alınamadı.');
    } on http.ClientException {
      throw const DailyTaskException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const DailyTaskException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
  }

  Future<DailyTaskSummary> getTask(int taskId) async {
    final token = _token();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tasks/$taskId/daily'),
        headers: _headers(token),
      );
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _taskFromApi(body, 'Günlük iş detayı alınamadı.');
      }
      _throwForResponse(
        response.statusCode,
        body,
        'Günlük iş detayı alınamadı.',
      );
    } on http.ClientException {
      throw const DailyTaskException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const DailyTaskException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
  }

  Future<DailyTaskSummary> createTask({
    required int projectId,
    required String priority,
    required int assignedToId,
    required String note,
  }) async {
    final token = _token();
    final siteId = _siteId();
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tasks/site/$siteId'),
        headers: _headers(token, json: true),
        body: jsonEncode({
          'projectId': projectId,
          'priority': priority,
          'assignedToId': assignedToId,
          'note': note,
        }),
      );
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _taskFromApi(body, 'Günlük iş oluşturulamadı.');
      }
      _throwForResponse(response.statusCode, body, 'Günlük iş oluşturulamadı.');
    } on http.ClientException {
      throw const DailyTaskException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const DailyTaskException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
  }

  Future<DailyTaskSummary> updateTask({
    required int taskId,
    required String status,
    required String note,
  }) async {
    final token = _token();
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/tasks/$taskId/daily'),
        headers: _headers(token, json: true),
        body: jsonEncode({'status': status, 'note': note}),
      );
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _taskFromApi(body, 'Günlük iş güncellenemedi.');
      }
      _throwForResponse(response.statusCode, body, 'Günlük iş güncellenemedi.');
    } on http.ClientException {
      throw const DailyTaskException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const DailyTaskException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
  }

  Future<DailyTaskSummary> uploadPhotos(int taskId, List<XFile> photos) async {
    if (photos.isEmpty) return getTask(taskId);
    final token = _token();
    try {
      final istek = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/tasks/$taskId/photos'),
      )..headers.addAll(_headers(token));

      for (final photo in photos) {
        final bytes = await photo.readAsBytes();
        if (bytes.length > 10 * 1024 * 1024) {
          throw DailyTaskException('${photo.name} 10 MB sınırını aşıyor.');
        }
        istek.files.add(
          http.MultipartFile.fromBytes(
            'files',
            bytes,
            filename: _safeFileName(photo.name),
            contentType: _mediaType(_contentType(photo.name)),
          ),
        );
      }

      final response = await http.Response.fromStream(await istek.send());
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _taskFromApi(body, 'Fotoğraflar yüklenemedi.');
      }
      _throwForResponse(response.statusCode, body, 'Fotoğraflar yüklenemedi.');
    } on http.ClientException {
      throw const DailyTaskException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  Future<DailyTaskSummary> uploadAudioNote(int taskId, String filePath) async {
    final token = _token();
    try {
      // XFile hem telefondaki dosya yolunu hem tarayicidaki blob adresini
      // okuyabiliyor; dart:io File ikincisinde calismiyordu.
      final bytes = await XFile(filePath).readAsBytes();
      if (bytes.isEmpty) {
        throw const DailyTaskException('Ses kaydı okunamadı.');
      }
      if (bytes.length > 20 * 1024 * 1024) {
        throw const DailyTaskException('Sesli not 20 MB sınırını aşıyor.');
      }
      final fileName = filePath.split(RegExp(r'[\\/]')).last;

      final istek = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/tasks/$taskId/audio-note'),
      )..headers.addAll(_headers(token));
      istek.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: _safeFileName(fileName.isEmpty ? 'ses.m4a' : fileName),
        ),
      );

      final response = await http.Response.fromStream(await istek.send());
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _taskFromApi(body, 'Sesli not yüklenemedi.');
      }
      _throwForResponse(response.statusCode, body, 'Sesli not yüklenemedi.');
    } on http.ClientException {
      throw const DailyTaskException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  /// Sesli notu indirip oynatilabilir bir kaynak dondurur.
  ///
  /// Tarayicida dosya sistemi yok; bytes dogrudan bir data adresine
  /// cevriliyor ve oynatici onu URL gibi kullaniyor.
  Future<String> downloadAudioNote(int audioId) async {
    final token = _token();
    try {
      final response = await http.get(
        Uri.parse(audioUrl(audioId)),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _throwForResponse(
          response.statusCode,
          utf8.decode(response.bodyBytes),
          'Sesli not indirilemedi.',
        );
      }
      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        throw const DailyTaskException('Sesli not dosyası boş geldi.');
      }
      return 'data:audio/mp4;base64,${base64Encode(bytes)}';
    } on http.ClientException {
      throw const DailyTaskException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  String photoUrl(int photoId) => '${ApiConfig.baseUrl}/tasks/photos/$photoId';

  String audioUrl(int audioId) => '${ApiConfig.baseUrl}/tasks/audio/$audioId';

  Map<String, String> photoHeaders() => {'Authorization': 'Bearer ${_token()}'};

  DailyTaskSummary _taskFromApi(String body, String fallback) {
    final decoded = jsonDecode(body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (decoded is! Map<String, dynamic> ||
        decoded['success'] != true ||
        data is! Map) {
      throw DailyTaskException(fallback);
    }
    return DailyTaskSummary.fromJson(Map<String, dynamic>.from(data));
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const DailyTaskException(
        'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
      );
    }
    return token;
  }

  int _siteId() {
    final siteId = SessionManager.instance.selectedSiteId;
    if (siteId == null || siteId <= 0) {
      throw const DailyTaskException('Şantiye seçimi bulunamadı.');
    }
    return siteId;
  }

  Map<String, String> _headers(String token, {bool json = false}) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json; charset=utf-8',
  };

  String _safeFileName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  /// "image/png" gibi bir metni MultipartFile'in bekledigi tipe cevirir.
  MediaType? _mediaType(String tip) {
    final parcalar = tip.split('/');
    if (parcalar.length != 2) return null;
    return MediaType(parcalar.first, parcalar.last);
  }

  Never _throwForResponse(int statusCode, String body, String fallback) {
    if (statusCode == 401) {
      throw const DailyTaskException(
        'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
      );
    }
    // 403 oturumun degil, sunucunun yetki cevabi: kullaniciya tekrar giris
    // yaptirmak yerine gecici bir aksaklik oldugunu soylemek dogru olan.
    if (statusCode == 403) {
      throw const DailyTaskException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
    String? message;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['message']?.toString();
        message ??= decoded['detail']?.toString();
        message ??= decoded['error']?.toString();
      }
    } catch (_) {
      // Sunucu okunabilir bir mesaj dondurmediyse asagidaki metin kullanilir.
    }
    throw DailyTaskException(
      message != null && message.trim().isNotEmpty
          ? message.trim()
          : '$fallback Lütfen daha sonra tekrar deneyiniz.',
    );
  }
}

class DailyTaskException implements Exception {
  final String message;

  const DailyTaskException(this.message);

  @override
  String toString() => message;
}
