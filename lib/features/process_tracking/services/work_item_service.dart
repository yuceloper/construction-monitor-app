import 'dart:convert';
import 'dart:io';

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/work_item_summary.dart';

class WorkItemService {
  Future<List<WorkItemSummary>> getByProject(int projectId) async {
    final token = SessionManager.instance.accessToken;

    if (token == null || token.isEmpty) {
      throw const WorkItemException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }

    final client = HttpClient();

    try {
      final request = await client.getUrl(
        Uri.parse('${ApiConfig.baseUrl}/work-items/project/$projectId'),
      );

      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody);
        if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
          throw WorkItemException(
            decoded is Map<String, dynamic>
                ? decoded['message']?.toString() ?? 'Alt işler alınamadı.'
                : 'Sunucudan geçersiz alt iş yanıtı geldi.',
          );
        }

        final data = decoded['data'];
        if (data is! List) {
          throw const WorkItemException('Sunucu alt iş listesi döndürmedi.');
        }

        final items = data
            .whereType<Map>()
            .map((item) => WorkItemSummary.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id > 0 && item.progressBlockId > 0 && item.title.isNotEmpty)
            .toList();

        items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        return items;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const WorkItemException(
          'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
        );
      }

      throw WorkItemException('Alt işler alınamadı. Sunucu hatası: ${response.statusCode}');
    } on SocketException {
      throw WorkItemException(
        'Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).',
      );
    } on FormatException {
      throw const WorkItemException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }
}

class WorkItemException implements Exception {
  final String message;

  const WorkItemException(this.message);

  @override
  String toString() => message;
}
