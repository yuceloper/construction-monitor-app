import 'dart:convert';
import 'dart:io';

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/project_summary.dart';

class ProjectService {
  Future<List<ProjectSummary>> getProjects() async {
    final token = SessionManager.instance.accessToken;

    if (token == null || token.isEmpty) {
      throw const ProjectException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }

    final client = HttpClient();

    try {
      final request = await client.getUrl(
        Uri.parse('${ApiConfig.baseUrl}/projects'),
      );

      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.accept.add(ContentType.json.mimeType);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody);

        if (decoded is! Map<String, dynamic>) {
          throw const ProjectException('Sunucudan geçersiz proje yanıtı geldi.');
        }

        if (decoded['success'] != true) {
          throw ProjectException(
            decoded['message']?.toString() ?? 'Projeler alınamadı.',
          );
        }

        final data = decoded['data'];
        if (data is! List) {
          throw const ProjectException('Sunucu proje listesi döndürmedi.');
        }

        return data
            .whereType<Map>()
            .map(
              (item) => ProjectSummary.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((project) => project.id > 0 && project.name.isNotEmpty)
            .toList();
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const ProjectException(
          'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
        );
      }

      throw ProjectException(
        _readErrorMessage(responseBody, response.statusCode),
      );
    } on SocketException {
      throw ProjectException(
        'Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).',
      );
    } on FormatException {
      throw const ProjectException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  String _readErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Status based message below.
    }

    return 'Projeler alınamadı. Sunucu hatası: $statusCode';
  }
}

class ProjectException implements Exception {
  final String message;

  const ProjectException(this.message);

  @override
  String toString() => message;
}
