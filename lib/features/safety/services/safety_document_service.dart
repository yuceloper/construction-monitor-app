import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/safety_document_summary.dart';

class SafetyDocumentService {
  Future<SafetyDocumentSummary?> getLatest(String type) async {
    final token = _token();
    final siteId = _siteId();
    final client = HttpClient();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/sites/$siteId/safety-documents/latest')
          .replace(queryParameters: {'type': type});
      final request = await client.getUrl(uri);
      _auth(request, token);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
          throw const SafetyDocumentException('İSG dokümanı alınamadı.');
        }
        if (data == null) return null;
        if (data is! Map) throw const SafetyDocumentException('Geçersiz İSG doküman yanıtı.');
        return SafetyDocumentSummary.fromJson(Map<String, dynamic>.from(data));
      }
      _throwForResponse(response.statusCode, body);
    } on SocketException {
      throw DailySafetyConnectionException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } finally {
      client.close(force: true);
    }
  }

  Future<Uint8List> getPdfBytes(int documentId) async {
    final token = _token();
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('${ApiConfig.baseUrl}/safety-documents/$documentId/file'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/pdf');
      final response = await request.close();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
        }
        return Uint8List.fromList(bytes);
      }
      final body = await response.transform(utf8.decoder).join();
      _throwForResponse(response.statusCode, body);
    } on SocketException {
      throw DailySafetyConnectionException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } finally {
      client.close(force: true);
    }
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const SafetyDocumentException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
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

  void _auth(HttpClientRequest request, String token) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
  }

  Never _throwForResponse(int statusCode, String body) {
    if (statusCode == 401 || statusCode == 403) {
      throw const SafetyDocumentException('Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.');
    }
    String? message;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) message = decoded['message']?.toString();
    } catch (_) {}
    throw SafetyDocumentException(message?.trim().isNotEmpty == true ? message!.trim() : 'İSG dokümanı alınamadı.');
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
