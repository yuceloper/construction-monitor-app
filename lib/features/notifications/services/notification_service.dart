import 'dart:convert';
import 'dart:io';

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/notification_item.dart';

class NotificationService {
  Future<List<NotificationItem>> getNotifications() async {
    final token = _token();
    final client = HttpClient();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/notifications').replace(
        queryParameters: {'page': '0', 'size': '100'},
      );
      final request = await client.getUrl(uri);
      _auth(request, token);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
          throw const NotificationException('Bildirimler alınamadı.');
        }
        final data = decoded['data'];
        final content = data is Map<String, dynamic> ? data['content'] : null;
        if (content is! List) return const [];
        return content
            .whereType<Map>()
            .map((item) => NotificationItem.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id > 0)
            .toList();
      }
      _throwForResponse(response.statusCode, body, 'Bildirimler alınamadı.');
    } on SocketException {
      throw NotificationException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const NotificationException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> markAsRead(int id) async {
    await _patch('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _patch('/notifications/read-all');
  }

  Future<void> _patch(String path) async {
    final token = _token();
    final client = HttpClient();
    try {
      final request = await client.patchUrl(Uri.parse('${ApiConfig.baseUrl}$path'));
      _auth(request, token);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      _throwForResponse(response.statusCode, body, 'Bildirim güncellenemedi.');
    } on SocketException {
      throw NotificationException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } finally {
      client.close(force: true);
    }
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const NotificationException('Oturum bilgisi bulunamadı.');
    }
    return token;
  }

  void _auth(HttpClientRequest request, String token) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
  }

  Never _throwForResponse(int statusCode, String body, String fallback) {
    String message = fallback;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final candidate = decoded['message'] ?? decoded['error'];
        if (candidate is String && candidate.trim().isNotEmpty) message = candidate.trim();
      }
    } catch (_) {}
    throw NotificationException('$message ($statusCode)');
  }
}

class NotificationException implements Exception {
  final String message;
  const NotificationException(this.message);

  @override
  String toString() => message;
}
