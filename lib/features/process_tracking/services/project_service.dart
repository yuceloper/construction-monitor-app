import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/project_summary.dart';

class ProjectService {
  Future<List<ProjectSummary>> getProjects() async {
    final token = SessionManager.instance.accessToken;
    final siteId = SessionManager.instance.selectedSiteId;

    if (token == null || token.isEmpty) {
      throw const ProjectException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    if (siteId == null || siteId <= 0) {
      throw const ProjectException('Şantiye seçimi bulunamadı. Lütfen şantiye seçin.');
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/projects').replace(
        queryParameters: {'siteId': '$siteId'},
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      final responseBody = response.body;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody);

        if (decoded is! Map<String, dynamic>) {
          throw const ProjectException('Sunucudan geçersiz proje yanıtı geldi.');
        }

        if (decoded['success'] != true) {
          throw ProjectException(decoded['message']?.toString() ?? 'Projeler alınamadı.');
        }

        final data = decoded['data'];
        if (data is! List) {
          throw const ProjectException('Sunucu proje listesi döndürmedi.');
        }

        return data
            .whereType<Map>()
            .map((item) => ProjectSummary.fromJson(Map<String, dynamic>.from(item)))
            .where((project) => project.id > 0 && project.name.isNotEmpty)
            .toList();
      }

      if (response.statusCode == 401) {
        throw const ProjectException('Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.');
      }
      if (response.statusCode == 403) {
        throw const ProjectException(
          'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
        );
      }

      throw ProjectException(_readErrorMessage(responseBody, response.statusCode));
    } on http.ClientException {
      throw const ProjectException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const ProjectException('Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.');
    }
  }

  String _readErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {}
    return 'Projeler alınamadı. Lütfen daha sonra tekrar deneyiniz.';
  }
}

class ProjectException implements Exception {
  final String message;
  const ProjectException(this.message);

  @override
  String toString() => message;
}
