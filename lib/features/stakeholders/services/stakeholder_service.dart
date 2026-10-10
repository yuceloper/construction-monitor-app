import 'dart:convert';
import 'dart:io';

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/stakeholder_summary.dart';

class StakeholderService {
  Future<List<StakeholderSummary>> getStakeholders() async {
    final token = _token();
    final siteId = _siteId();
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('${ApiConfig.baseUrl}/sites/$siteId/stakeholders'));
      _auth(request, token);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true || data is! List) {
          throw const StakeholderException('Paydaşlar alınamadı.');
        }
        return data
            .whereType<Map>()
            .map((item) => StakeholderSummary.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id > 0)
            .toList();
      }
      _throwForResponse(response.statusCode, body, 'Paydaşlar alınamadı.');
    } on SocketException {
      throw const StakeholderException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const StakeholderException('Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.');
    } finally {
      client.close(force: true);
    }
  }

  Future<StakeholderSummary> save({
    int? id,
    required String companyName,
    required String detail,
    required String contactPerson,
    required String phoneNumber,
  }) async {
    final token = _token();
    final siteId = _siteId();
    final client = HttpClient();
    try {
      final uri = id == null
          ? Uri.parse('${ApiConfig.baseUrl}/sites/$siteId/stakeholders')
          : Uri.parse('${ApiConfig.baseUrl}/stakeholders/$id');
      final request = id == null ? await client.postUrl(uri) : await client.putUrl(uri);
      _auth(request, token, json: true);
      request.write(jsonEncode({
        'companyName': companyName,
        'detail': detail,
        'contactPerson': contactPerson,
        'phoneNumber': phoneNumber,
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true || data is! Map) {
          throw const StakeholderException('Paydaş kaydedilemedi.');
        }
        return StakeholderSummary.fromJson(Map<String, dynamic>.from(data));
      }
      _throwForResponse(response.statusCode, body, 'Paydaş kaydedilemedi.');
    } on SocketException {
      throw const StakeholderException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const StakeholderException('Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> delete(int id) async {
    final token = _token();
    final client = HttpClient();
    try {
      final request = await client.deleteUrl(Uri.parse('${ApiConfig.baseUrl}/stakeholders/$id'));
      _auth(request, token);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      _throwForResponse(response.statusCode, body, 'Paydaş silinemedi.');
    } finally {
      client.close(force: true);
    }
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const StakeholderException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return token;
  }

  int _siteId() {
    final siteId = SessionManager.instance.selectedSiteId;
    if (siteId == null || siteId <= 0) {
      throw const StakeholderException('Şantiye seçimi bulunamadı.');
    }
    return siteId;
  }

  void _auth(HttpClientRequest request, String token, {bool json = false}) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (json) request.headers.contentType = ContentType.json;
  }

  Never _throwForResponse(int statusCode, String body, String fallback) {
    if (statusCode == 401) {
      throw const StakeholderException('Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.');
    }
    if (statusCode == 403) {
      throw const StakeholderException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
    String? message;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['message']?.toString();
        message ??= decoded['detail']?.toString();
      }
    } catch (_) {}
    throw StakeholderException(
      message != null && message.trim().isNotEmpty ? message.trim() : '$fallback Lütfen daha sonra tekrar deneyiniz.',
    );
  }
}

class StakeholderException implements Exception {
  final String message;
  const StakeholderException(this.message);

  @override
  String toString() => message;
}
