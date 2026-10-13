import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/notification_item.dart';

class NotificationUnreadCount {
  NotificationUnreadCount._();

  static final ValueNotifier<int> value = ValueNotifier<int>(0);

  static void set(int count) {
    value.value = count < 0 ? 0 : count;
  }

  static void decrement() {
    if (value.value > 0) value.value -= 1;
  }

  static void clear() => value.value = 0;
}

/// Bildirim servisi.
///
/// dart:io'daki HttpClient tarayicida calismadigi icin istekler http
/// paketiyle yapiliyor. Govde utf8.decode(bodyBytes) ile okunuyor: sunucu
/// Content-Type'ta charset bildirmiyor, http paketi boyle durumda latin1
/// varsayiyor.
class NotificationService {
  Future<List<NotificationItem>> getNotifications() async {
    final token = _token();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/notifications').replace(
        queryParameters: {'page': '0', 'size': '100'},
      );
      final response = await http.get(uri, headers: _headers(token));
      final body = utf8.decode(response.bodyBytes);
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
            .map(
              (item) =>
                  NotificationItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.id > 0)
            .toList();
      }
      _throwForResponse(response.statusCode, body, 'Bildirimler alınamadı.');
    } on http.ClientException {
      throw const NotificationException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const NotificationException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
  }

  Future<int> getUnreadCount() async {
    final token = _token();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications/unread-count'),
        headers: _headers(token),
      );
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
          throw const NotificationException('Bildirim sayısı alınamadı.');
        }
        final data = decoded['data'];
        final rawCount = data is Map<String, dynamic> ? data['count'] : null;
        final count = rawCount is num
            ? rawCount.toInt()
            : int.tryParse('$rawCount') ?? 0;
        NotificationUnreadCount.set(count);
        return count;
      }
      _throwForResponse(response.statusCode, body, 'Bildirim sayısı alınamadı.');
    } on http.ClientException {
      throw const NotificationException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const NotificationException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
  }

  Future<void> markAsRead(int id) async {
    await _patch('/notifications/$id/read');
    NotificationUnreadCount.decrement();
  }

  Future<void> markAllAsRead() async {
    await _patch('/notifications/read-all');
    NotificationUnreadCount.clear();
  }

  Future<void> _patch(String path) async {
    final token = _token();
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: _headers(token),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      _throwForResponse(
        response.statusCode,
        utf8.decode(response.bodyBytes),
        'Bildirim güncellenemedi.',
      );
    } on http.ClientException {
      throw const NotificationException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const NotificationException('Oturum bilgisi bulunamadı.');
    }
    return token;
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  Never _throwForResponse(int statusCode, String body, String fallback) {
    String message = fallback;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final candidate = decoded['message'] ?? decoded['error'];
        if (candidate is String && candidate.trim().isNotEmpty) {
          message = candidate.trim();
        }
      }
    } catch (_) {
      // Sunucu okunabilir bir mesaj dondurmediyse yukaridaki metin kalir.
    }
    // Durum kodu kullaniciya gosterilmiyor; diger servislerle ayni.
    throw NotificationException(message);
  }
}

class NotificationException implements Exception {
  final String message;

  const NotificationException(this.message);

  @override
  String toString() => message;
}
