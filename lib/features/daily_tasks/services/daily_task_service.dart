import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/daily_task_summary.dart';

class DailyTaskService {
  Future<List<DailyTaskSummary>> getTasks({required bool includeCompleted}) async {
    final token = _token();
    final siteId = _siteId();

    final client = HttpClient();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/tasks/site/$siteId').replace(
        queryParameters: {'includeCompleted': includeCompleted.toString()},
      );
      final request = await client.getUrl(uri);
      _auth(request, token);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true || data is! List) {
          throw const DailyTaskException('Günlük işler alınamadı.');
        }

        return data
            .whereType<Map>()
            .map((item) => DailyTaskSummary.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id > 0)
            .toList();
      }
      _throwForResponse(response.statusCode, body, 'Günlük işler alınamadı.');
    } on SocketException {
      throw DailyTaskException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const DailyTaskException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  Future<DailyTaskSummary> getTask(int taskId) async {
    final token = _token();
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('${ApiConfig.baseUrl}/tasks/$taskId/daily'));
      _auth(request, token);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _taskFromApi(body, 'Günlük iş detayı alınamadı.');
      }
      _throwForResponse(response.statusCode, body, 'Günlük iş detayı alınamadı.');
    } on SocketException {
      throw DailyTaskException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const DailyTaskException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
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
    final client = HttpClient();

    try {
      final request = await client.postUrl(Uri.parse('${ApiConfig.baseUrl}/tasks/site/$siteId'));
      _auth(request, token, json: true);
      request.write(jsonEncode({
        'projectId': projectId,
        'priority': priority,
        'assignedToId': assignedToId,
        'note': note,
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _taskFromApi(body, 'Günlük iş oluşturulamadı.');
      }
      _throwForResponse(response.statusCode, body, 'Günlük iş oluşturulamadı.');
    } on SocketException {
      throw DailyTaskException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const DailyTaskException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  Future<DailyTaskSummary> updateTask({
    required int taskId,
    required String status,
    required String note,
  }) async {
    final token = _token();
    final client = HttpClient();
    try {
      final request = await client.putUrl(Uri.parse('${ApiConfig.baseUrl}/tasks/$taskId/daily'));
      _auth(request, token, json: true);
      request.write(jsonEncode({'status': status, 'note': note}));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _taskFromApi(body, 'Günlük iş güncellenemedi.');
      }
      _throwForResponse(response.statusCode, body, 'Günlük iş güncellenemedi.');
    } on SocketException {
      throw DailyTaskException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const DailyTaskException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  Future<DailyTaskSummary> uploadPhotos(int taskId, List<XFile> photos) async {
    if (photos.isEmpty) {
      return getTask(taskId);
    }
    if (photos.length > 10) {
      throw const DailyTaskException('En fazla 10 fotoğraf ekleyebilirsiniz.');
    }

    final token = _token();
    final client = HttpClient();
    final boundary = '----construction-monitor-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

    try {
      final request = await client.postUrl(Uri.parse('${ApiConfig.baseUrl}/tasks/$taskId/photos'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');

      for (final photo in photos) {
        final bytes = await photo.readAsBytes();
        if (bytes.length > 10 * 1024 * 1024) {
          throw DailyTaskException('${photo.name} 10 MB sınırını aşıyor.');
        }
        request.add(utf8.encode('--$boundary\r\n'));
        request.add(utf8.encode(
          'Content-Disposition: form-data; name="files"; filename="${_safeFileName(photo.name)}"\r\n',
        ));
        request.add(utf8.encode('Content-Type: ${_contentType(photo.name)}\r\n\r\n'));
        request.add(bytes);
        request.add(utf8.encode('\r\n'));
      }
      request.add(utf8.encode('--$boundary--\r\n'));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _taskFromApi(body, 'Fotoğraflar yüklendi ancak görev bilgisi alınamadı.');
      }
      _throwForResponse(response.statusCode, body, 'Fotoğraflar yüklenemedi.');
    } on SocketException {
      throw DailyTaskException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const DailyTaskException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  String photoUrl(int photoId) => '${ApiConfig.baseUrl}/tasks/photos/$photoId';

  Map<String, String> photoHeaders() => {
        HttpHeaders.authorizationHeader: 'Bearer ${_token()}',
      };

  DailyTaskSummary _taskFromApi(String body, String fallback) {
    final decoded = jsonDecode(body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (decoded is! Map<String, dynamic> || decoded['success'] != true || data is! Map) {
      throw DailyTaskException(fallback);
    }
    return DailyTaskSummary.fromJson(Map<String, dynamic>.from(data));
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const DailyTaskException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
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

  void _auth(HttpClientRequest request, String token, {bool json = false}) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (json) request.headers.contentType = ContentType.json;
  }

  String _safeFileName(String name) => name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  Never _throwForResponse(int statusCode, String body, String fallback) {
    if (statusCode == 401 || statusCode == 403) {
      throw const DailyTaskException('Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.');
    }

    String? message;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['message']?.toString();
        message ??= decoded['detail']?.toString();
        message ??= decoded['error']?.toString();
      }
    } catch (_) {}

    throw DailyTaskException(
      message != null && message.trim().isNotEmpty
          ? message.trim()
          : '$fallback Sunucu hatası: $statusCode',
    );
  }
}

class DailyTaskException implements Exception {
  final String message;
  const DailyTaskException(this.message);

  @override
  String toString() => message;
}
