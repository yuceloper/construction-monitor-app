import 'dart:convert';
import 'dart:io';

import '../../../core/constants/api_config.dart';
import '../models/auth_response.dart';

class AuthService {
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      );

      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody);

        if (decoded is! Map<String, dynamic>) {
          throw const AuthException('Sunucudan geçersiz bir yanıt geldi.');
        }

        if (decoded['success'] != true) {
          final message = decoded['message']?.toString().trim();
          throw AuthException(
            message != null && message.isNotEmpty
                ? message
                : 'Giriş başarısız.',
          );
        }

        final data = decoded['data'];
        if (data is! Map<String, dynamic>) {
          throw const AuthException(
            'Sunucu kullanıcı bilgilerini döndürmedi.',
          );
        }

        final authResponse = AuthResponse.fromJson(data);

        if (authResponse.accessToken.isEmpty) {
          throw const AuthException('Sunucu access token döndürmedi.');
        }

        return authResponse;
      }

      throw AuthException(_readErrorMessage(responseBody, response.statusCode));
    } on SocketException {
      throw AuthException(
        'Backend sunucusuna ulaşılamadı (${ApiConfig.baseUrl}).',
      );
    } on FormatException {
      throw const AuthException('Sunucudan geçersiz bir yanıt geldi.');
    } finally {
      client.close(force: true);
    }
  }

  String _readErrorMessage(String body, int statusCode) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        for (final key in ['message', 'error', 'detail']) {
          final value = json[key];
          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
        }
      }
    } catch (_) {
      // Fall back to a status-based message below.
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'Kullanıcı adı veya parola hatalı.';
    }

    if (statusCode == 400) {
      return 'Giriş bilgileri geçersiz.';
    }

    return 'Giriş yapılamadı. Sunucu hatası: $statusCode';
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
