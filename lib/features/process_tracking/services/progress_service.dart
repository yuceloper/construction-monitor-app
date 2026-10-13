import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../models/progress_stage.dart';

class ProgressService {
  Future<List<ProgressStage>> getStagesByProject(int projectId) async {
    final decoded = await _get('/progress/project/$projectId');
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

  Future<double> getOverallProgress(int projectId) async {
    final decoded = await _get('/progress/project/$projectId/overall');
    final raw = decoded['data'];

    if (raw is num) return raw.toDouble().clamp(0.0, 100.0);

    final parsed = double.tryParse(raw?.toString() ?? '');
    if (parsed == null) {
      throw const ProgressException('Sunucu genel ilerleme değerini döndürmedi.');
    }

    return parsed.clamp(0.0, 100.0);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final token = SessionManager.instance.accessToken;

    if (token == null || token.isEmpty) {
      throw const ProgressException('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      final responseBody = response.body;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody);

        if (decoded is! Map<String, dynamic>) {
          throw const ProgressException('Sunucudan geçersiz süreç yanıtı geldi.');
        }

        if (decoded['success'] != true) {
          throw ProgressException(
            decoded['message']?.toString() ?? 'Süreç bilgileri alınamadı.',
          );
        }

        return decoded;
      }

      if (response.statusCode == 401) {
        throw const ProgressException(
          'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
        );
      }
      if (response.statusCode == 403) {
        throw const ProgressException(
          'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
        );
      }

      throw const ProgressException(
        'Süreç bilgileri alınamadı. Lütfen daha sonra tekrar deneyiniz.',
      );
    } on http.ClientException {
      throw ProgressException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const ProgressException('Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.');
    }
  }
}

class ProgressException implements Exception {
  final String message;

  const ProgressException(this.message);

  @override
  String toString() => message;
}
