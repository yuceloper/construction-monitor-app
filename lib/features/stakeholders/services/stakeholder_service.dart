import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/stakeholder_summary.dart';

/// Paydas servisi.
///
/// dart:io'daki HttpClient tarayicida calismadigi icin istekler http
/// paketiyle yapiliyor; diger servislerle ayni kalip. Govde
/// utf8.decode(bodyBytes) ile okunuyor: sunucu Content-Type'ta charset
/// bildirmiyor, http paketi boyle durumda latin1 varsayiyor.
class StakeholderService {
  Future<List<StakeholderSummary>> getStakeholders() async {
    final token = _token();
    final siteId = _siteId();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/sites/$siteId/stakeholders'),
        headers: _headers(token),
      );
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> ||
            decoded['success'] != true ||
            data is! List) {
          throw const StakeholderException('Paydaşlar alınamadı.');
        }
        return data
            .whereType<Map>()
            .map(
              (item) =>
                  StakeholderSummary.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.id > 0)
            .toList();
      }
      _throwForResponse(response.statusCode, body, 'Paydaşlar alınamadı.');
    } on http.ClientException {
      throw const StakeholderException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const StakeholderException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
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
    try {
      final uri = id == null
          ? Uri.parse('${ApiConfig.baseUrl}/sites/$siteId/stakeholders')
          : Uri.parse('${ApiConfig.baseUrl}/stakeholders/$id');
      final govde = jsonEncode({
        'companyName': companyName,
        'detail': detail,
        'contactPerson': contactPerson,
        'phoneNumber': phoneNumber,
      });
      final response = id == null
          ? await http.post(
              uri,
              headers: _headers(token, json: true),
              body: govde,
            )
          : await http.put(
              uri,
              headers: _headers(token, json: true),
              body: govde,
            );
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> ||
            decoded['success'] != true ||
            data is! Map) {
          throw const StakeholderException('Paydaş kaydedilemedi.');
        }
        return StakeholderSummary.fromJson(Map<String, dynamic>.from(data));
      }
      _throwForResponse(response.statusCode, body, 'Paydaş kaydedilemedi.');
    } on http.ClientException {
      throw const StakeholderException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const StakeholderException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
  }

  Future<void> delete(int id) async {
    final token = _token();
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/stakeholders/$id'),
        headers: _headers(token),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      _throwForResponse(
        response.statusCode,
        utf8.decode(response.bodyBytes),
        'Paydaş silinemedi.',
      );
    } on http.ClientException {
      throw const StakeholderException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const StakeholderException(
        'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
      );
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

  Map<String, String> _headers(String token, {bool json = false}) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json; charset=utf-8',
  };

  Never _throwForResponse(int statusCode, String body, String fallback) {
    if (statusCode == 401) {
      throw const StakeholderException(
        'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
      );
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
    } catch (_) {
      // Sunucu okunabilir bir mesaj dondurmediyse asagidaki metin kullanilir.
    }
    throw StakeholderException(
      message != null && message.trim().isNotEmpty
          ? message.trim()
          : '$fallback Lütfen daha sonra tekrar deneyiniz.',
    );
  }
}

class StakeholderException implements Exception {
  final String message;

  const StakeholderException(this.message);

  @override
  String toString() => message;
}
