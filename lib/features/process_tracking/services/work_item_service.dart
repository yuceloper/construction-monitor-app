import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/work_item_detail.dart';
import '../models/work_item_summary.dart';

class WorkItemService {
  Future<List<WorkItemSummary>> getByProject(int projectId) async {
    final token = _token();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/work-items/project/$projectId'),
        headers: _headers(token),
      );
      final body = response.body;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
          throw const WorkItemException('Alt işler alınamadı.');
        }
        final data = decoded['data'];
        if (data is! List) throw const WorkItemException('Sunucu alt iş listesi döndürmedi.');
        final items = data.whereType<Map>()
            .map((item) => WorkItemSummary.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id > 0 && item.progressBlockId > 0 && item.title.isNotEmpty)
            .toList();
        items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        return items;
      }
      _throwForResponse(response.statusCode, body, 'Alt işler alınamadı.');
    } on http.ClientException {
      throw const WorkItemException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const WorkItemException('Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.');
    }
  }

  Future<WorkItemDetail> getDetail(int id) async {
    final token = _token();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/work-items/$id/detail'),
        headers: _headers(token),
      );
      final body = response.body;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true || data is! Map) {
          throw const WorkItemException('İş detayı alınamadı.');
        }
        return WorkItemDetail.fromJson(Map<String, dynamic>.from(data));
      }
      _throwForResponse(response.statusCode, body, 'İş detayı alınamadı.');
    } on http.ClientException {
      throw const WorkItemException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const WorkItemException('Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.');
    }
  }

  Future<WorkItemWarning> addWarning(int id, String text) async {
    final token = _token();
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/work-items/$id/warnings'),
        headers: _headers(token, json: true),
        body: jsonEncode({'text': text}),
      );
      final body = response.body;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true || data is! Map) {
          throw const WorkItemException('Uyarı eklenemedi.');
        }
        return WorkItemWarning.fromJson(Map<String, dynamic>.from(data));
      }
      _throwForResponse(response.statusCode, body, 'Uyarı eklenemedi.');
    } on http.ClientException {
      throw const WorkItemException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const WorkItemException('Uyarı eklenemedi.');
    }
  }

  Future<void> uploadWarningAudio(int id, int warningId, String filePath) async {
    final token = _token();
    try {
      final file = XFile(filePath);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw const WorkItemException('Ses kaydı okunamadı.');
      if (bytes.length > 20 * 1024 * 1024) {
        throw const WorkItemException('Sesli not 20 MB sınırını aşıyor.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/work-items/$id/warnings/$warningId/audio'),
      )..headers.addAll(_headers(token));
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name.isEmpty ? 'uyari.m4a' : file.name,
        ),
      );
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _throwForResponse(response.statusCode, response.body, 'Sesli not yüklenemedi.');
      }
    } on http.ClientException {
      throw const WorkItemException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  Future<String> downloadWarningAudio(int id, int warningId) async {
    final token = _token();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/work-items/$id/warnings/$warningId/audio'),
        headers: _headers(token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _throwForResponse(response.statusCode, response.body, 'Sesli not alınamadı.');
      }
      if (response.bodyBytes.isEmpty) {
        throw const WorkItemException('Sesli not dosyası boş geldi.');
      }
      final contentType = response.headers['content-type'] ?? 'audio/mp4';
      return 'data:$contentType;base64,${base64Encode(response.bodyBytes)}';
    } on http.ClientException {
      throw const WorkItemException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  Future<void> updateWarning(int id, int warningId, String text) async {
    final token = _token();
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/work-items/$id/warnings/$warningId'),
        headers: _headers(token, json: true),
        body: jsonEncode({'text': text}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _throwForResponse(response.statusCode, response.body, 'Uyarı güncellenemedi.');
      }
    } on http.ClientException {
      throw const WorkItemException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  Future<void> deleteWarning(int id, int warningId) async {
    final token = _token();
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/work-items/$id/warnings/$warningId'),
        headers: _headers(token),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _throwForResponse(response.statusCode, response.body, 'Uyarı silinemedi.');
      }
    } on http.ClientException {
      throw const WorkItemException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  Future<WorkItemSummary> updateStatus(int id, {required bool completed}) async {
    final token = _token();
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/work-items/$id/status'),
        headers: _headers(token, json: true),
        body: jsonEncode({'status': completed ? 'COMPLETED' : 'WAITING'}),
      );
      final body = response.body;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true || data is! Map) {
          throw const WorkItemException('Alt iş güncellenemedi.');
        }
        return WorkItemSummary.fromJson(Map<String, dynamic>.from(data));
      }
      _throwForResponse(response.statusCode, body, 'Alt iş güncellenemedi.');
    } on http.ClientException {
      throw const WorkItemException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const WorkItemException('Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.');
    }
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const WorkItemException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return token;
  }

  Map<String, String> _headers(String token, {bool json = false}) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
      };

  Never _throwForResponse(int statusCode, String body, String fallback) {
    if (statusCode == 401) {
      throw const WorkItemException('Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.');
    }
    if (statusCode == 403) {
      throw const WorkItemException(
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
    } catch (_) {}

    throw WorkItemException(
      message != null && message.trim().isNotEmpty
          ? message.trim()
          : '$fallback Lütfen daha sonra tekrar deneyiniz.',
    );
  }
}

class WorkItemException implements Exception {
  final String message;
  const WorkItemException(this.message);
  @override
  String toString() => message;
}
