import 'dart:convert';
import 'dart:io';

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/site_member_summary.dart';
import '../models/site_summary.dart';

class SiteService {
  Future<List<SiteSummary>> getSites() async {
    final token = _token();
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('${ApiConfig.baseUrl}/sites'));
      _auth(request, token);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
          throw const SiteException('Şantiyeler alınamadı.');
        }
        final data = decoded['data'];
        if (data is! List) throw const SiteException('Sunucu şantiye listesi döndürmedi.');
        return data
            .whereType<Map>()
            .map((item) => SiteSummary.fromJson(Map<String, dynamic>.from(item)))
            .where((site) => site.id > 0 && site.name.isNotEmpty)
            .toList();
      }
      _throwForStatus(response.statusCode, 'Şantiyeler alınamadı.');
    } on SocketException {
      throw SiteException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const SiteException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<SiteMemberSummary>> getMembers(int siteId) async {
    final token = _token();
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('${ApiConfig.baseUrl}/sites/$siteId/members'));
      _auth(request, token);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true || data is! List) {
          throw const SiteException('Şantiye kullanıcıları alınamadı.');
        }
        return data
            .whereType<Map>()
            .map((item) => SiteMemberSummary.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id > 0)
            .toList();
      }
      _throwForStatus(response.statusCode, 'Şantiye kullanıcıları alınamadı.');
    } on SocketException {
      throw SiteException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const SiteException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const SiteException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return token;
  }

  void _auth(HttpClientRequest request, String token) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
  }

  Never _throwForStatus(int statusCode, String fallback) {
    if (statusCode == 401 || statusCode == 403) {
      throw const SiteException('Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.');
    }
    throw SiteException('$fallback Sunucu hatası: $statusCode');
  }
}

class SiteException implements Exception {
  final String message;
  const SiteException(this.message);

  @override
  String toString() => message;
}
