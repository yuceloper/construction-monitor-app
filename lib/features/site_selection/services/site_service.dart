import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/site_member_summary.dart';
import '../models/site_summary.dart';

class SiteService {
  Future<List<SiteSummary>> getSites() async {
    final token = _token();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/sites'),
        headers: _headers(token),
      );

      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
          throw const SiteException('Şantiyeler alınamadı.');
        }
        final data = decoded['data'];
        if (data is! List) {
          throw const SiteException('Sunucu şantiye listesi döndürmedi.');
        }
        return data
            .whereType<Map>()
            .map((item) => SiteSummary.fromJson(Map<String, dynamic>.from(item)))
            .where((site) => site.id > 0 && site.name.isNotEmpty)
            .toList();
      }

      _throwForStatus(response.statusCode, 'Şantiyeler alınamadı.');
    } on http.ClientException {
      throw const SiteException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const SiteException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
  }

  Future<List<SiteMemberSummary>> getMembers(int siteId) async {
    final token = _token();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/sites/$siteId/members'),
        headers: _headers(token),
      );

      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> ||
            decoded['success'] != true ||
            data is! List) {
          throw const SiteException('Şantiye kullanıcıları alınamadı.');
        }
        return data
            .whereType<Map>()
            .map((item) => SiteMemberSummary.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id > 0)
            .toList();
      }

      _throwForStatus(response.statusCode, 'Şantiye kullanıcıları alınamadı.');
    } on http.ClientException {
      throw const SiteException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const SiteException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const SiteException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return token;
  }

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Never _throwForStatus(int statusCode, String fallback) {
    if (statusCode == 401) {
      throw const SiteException('Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.');
    }
    if (statusCode == 403) {
      throw const SiteException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
    throw SiteException('$fallback Lütfen daha sonra tekrar deneyiniz.');
  }
}

class SiteException implements Exception {
  final String message;
  const SiteException(this.message);

  @override
  String toString() => message;
}
