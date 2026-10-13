import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/safety_document_summary.dart';

/// ISG dokuman servisi.
///
/// dart:io'daki HttpClient tarayicida calismadigi icin istekler http
/// paketiyle yapiliyor. Govde utf8.decode(bodyBytes) ile okunuyor: sunucu
/// Content-Type'ta charset bildirmiyor, http paketi boyle durumda latin1
/// varsayiyor.
class SafetyDocumentService {
  Future<List<SafetyDocumentSummary>> getDocuments() async {
    final token = _token();
    final siteId = _siteId();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/sites/$siteId/safety-documents'),
        headers: _headers(token),
      );
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> ||
            decoded['success'] != true ||
            data is! List) {
          throw const SafetyDocumentException('İSG dokümanları alınamadı.');
        }
        return data
            .whereType<Map>()
            .map(
              (item) => SafetyDocumentSummary.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((item) => item.id > 0)
            .toList();
      }
      _throwForResponse(response.statusCode, body);
    } on http.ClientException {
      throw const DailySafetyConnectionException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  Future<SafetyDocumentSummary?> getLatest(String type) async {
    final token = _token();
    final siteId = _siteId();
    try {
      final uri =
          Uri.parse(
            '${ApiConfig.baseUrl}/sites/$siteId/safety-documents/latest',
          ).replace(queryParameters: {'type': type});
      final response = await http.get(uri, headers: _headers(token));
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
          throw const SafetyDocumentException('İSG dokümanı alınamadı.');
        }
        if (data == null) return null;
        if (data is! Map) {
          throw const SafetyDocumentException('Geçersiz İSG doküman yanıtı.');
        }
        return SafetyDocumentSummary.fromJson(Map<String, dynamic>.from(data));
      }
      _throwForResponse(response.statusCode, body);
    } on http.ClientException {
      throw const DailySafetyConnectionException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  Future<Uint8List> getPdfBytes(int documentId) async {
    final token = _token();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/safety-documents/$documentId/file'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      _throwForResponse(
        response.statusCode,
        utf8.decode(response.bodyBytes),
      );
    } on http.ClientException {
      throw const DailySafetyConnectionException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const SafetyDocumentException(
        'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
      );
    }
    return token;
  }

  int _siteId() {
    final siteId = SessionManager.instance.selectedSiteId;
    if (siteId == null || siteId <= 0) {
      throw const SafetyDocumentException('Şantiye seçimi bulunamadı.');
    }
    return siteId;
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  Never _throwForResponse(int statusCode, String body) {
    if (statusCode == 401) {
      throw const SafetyDocumentException(
        'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
      );
    }
    if (statusCode == 403) {
      throw const SafetyDocumentException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
    String? message;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['message']?.toString();
      }
    } catch (_) {
      // Sunucu okunabilir bir mesaj dondurmediyse asagidaki metin kullanilir.
    }
    throw SafetyDocumentException(
      message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'İSG dokümanı alınamadı.',
    );
  }
}

class SafetyDocumentException implements Exception {
  final String message;

  const SafetyDocumentException(this.message);

  @override
  String toString() => message;
}

class DailySafetyConnectionException extends SafetyDocumentException {
  const DailySafetyConnectionException(super.message);
}
