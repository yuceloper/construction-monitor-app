import 'dart:convert';
import 'dart:io';

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/progress_stage.dart';

class ProgressService {
  Future<List<ProgressStage>> getStagesByProject(int projectId) async {
    final token = SessionManager.instance.accessToken;

    if (token == null || token.isEmpty) {
      throw const ProgressException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }

    final client = HttpClient();

    try {
      final request = await client.getUrl(
        Uri.parse('${ApiConfig.baseUrl}/progress/project/$projectId'),
      );

      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody);

        if (decoded is! Map<String, dynamic>) {
          throw const ProgressException('Sunucudan geçersiz süreç yanıtı geldi.');
        }

        if (decoded['success'] != true) {
          throw ProgressException(
            decoded['message']?.toString() ?? 'Süreç aşamaları alınamadı.',
          );
        }

        final data = decoded['data'];
        if (data is! List) {
          throw const ProgressException('Sunucu süreç listesi döndürmedi.');
        }

        final stages = data
            .whereType<Map>()
            .map((item) => ProgressStage.fromJson(Map<String, dynamic>.from(item)))
            .where((stage) => stage.id > 0 && stage.name.isNotEmpty)
            .toList();

        stages.sort((a, b) => a.blockNumber.compareTo(b.blockNumber));
        return stages;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const ProgressException(
          'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
        );
      }

      throw ProgressException('Süreç aşamaları alınamadı. Sunucu hatası: ${response.statusCode}');
    } on SocketException {
      throw ProgressException(
        'Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).',
      );
    } on FormatException {
      throw const ProgressException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }
}

class ProgressException implements Exception {
  final String message;

  const ProgressException(this.message);

  @override
  String toString() => message;
}
