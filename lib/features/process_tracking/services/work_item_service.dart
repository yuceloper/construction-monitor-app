import 'dart:convert';
import 'dart:io';

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/work_item_detail.dart';
import '../models/work_item_summary.dart';

class WorkItemService {
  Future<List<WorkItemSummary>> getByProject(int projectId) async {
    final token = _token();
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('${ApiConfig.baseUrl}/work-items/project/$projectId'));
      _auth(request, token);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
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
      _throwForStatus(response.statusCode, 'Alt işler alınamadı.');
    } on SocketException {
      throw WorkItemException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const WorkItemException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  Future<WorkItemDetail> getDetail(int id) async {
    final token = _token();
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('${ApiConfig.baseUrl}/work-items/$id/detail'));
      _auth(request, token);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true || data is! Map) {
          throw const WorkItemException('İş detayı alınamadı.');
        }
        return WorkItemDetail.fromJson(Map<String, dynamic>.from(data));
      }
      _throwForStatus(response.statusCode, 'İş detayı alınamadı.');
    } on SocketException {
      throw WorkItemException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const WorkItemException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> addWarning(int id, String text) async {
    final token = _token();
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('${ApiConfig.baseUrl}/work-items/$id/warnings'));
      _auth(request, token, json: true);
      request.write(jsonEncode({'text': text, 'critical': true}));
      final response = await request.close();
      await response.drain();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _throwForStatus(response.statusCode, 'Uyarı eklenemedi.');
      }
    } on SocketException {
      throw WorkItemException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } finally {
      client.close(force: true);
    }
  }

  Future<WorkItemSummary> updateStatus(int id, {required bool completed}) async {
    final token = _token();
    final client = HttpClient();
    try {
      final request = await client.putUrl(Uri.parse('${ApiConfig.baseUrl}/work-items/$id/status'));
      _auth(request, token, json: true);
      request.write(jsonEncode({'status': completed ? 'COMPLETED' : 'WAITING'}));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true || data is! Map) {
          throw const WorkItemException('Alt iş güncellenemedi.');
        }
        return WorkItemSummary.fromJson(Map<String, dynamic>.from(data));
      }
      _throwForStatus(response.statusCode, 'Alt iş güncellenemedi.');
    } on SocketException {
      throw WorkItemException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const WorkItemException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const WorkItemException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return token;
  }

  void _auth(HttpClientRequest request, String token, {bool json = false}) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (json) request.headers.contentType = ContentType.json;
  }

  Never _throwForStatus(int statusCode, String message) {
    if (statusCode == 401 || statusCode == 403) {
      throw const WorkItemException('Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.');
    }
    throw WorkItemException('$message Sunucu hatası: $statusCode');
  }
}

class WorkItemException implements Exception {
  final String message;
  const WorkItemException(this.message);
  @override
  String toString() => message;
}
