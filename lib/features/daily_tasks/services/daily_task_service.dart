import 'dart:convert';
import 'dart:io';

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/daily_task_summary.dart';

class DailyTaskService {
  Future<List<DailyTaskSummary>> getTasks({required bool includeCompleted}) async {
    final token = SessionManager.instance.accessToken;
    final siteId = SessionManager.instance.selectedSiteId;

    if (token == null || token.isEmpty) {
      throw const DailyTaskException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    if (siteId == null || siteId <= 0) {
      throw const DailyTaskException('Şantiye seçimi bulunamadı.');
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/tasks/site/$siteId').replace(
        queryParameters: {'includeCompleted': includeCompleted.toString()},
      );
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> || decoded['success'] != true || data is! List) {
          throw const DailyTaskException('Günlük işler alınamadı.');
        }

        return data
            .whereType<Map>()
            .map((item) => DailyTaskSummary.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id > 0)
            .toList();
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const DailyTaskException('Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.');
      }
      throw DailyTaskException('Günlük işler alınamadı. Sunucu hatası: ${response.statusCode}');
    } on SocketException {
      throw DailyTaskException('Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).');
    } on FormatException {
      throw const DailyTaskException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }
}

class DailyTaskException implements Exception {
  final String message;
  const DailyTaskException(this.message);

  @override
  String toString() => message;
}
