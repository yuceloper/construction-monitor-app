import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }

    // Web debug runs from Flutter's temporary dev-server port. In that mode a
    // relative /api/v1 URL would hit the Flutter dev server instead of Spring
    // Boot, so default to the local backend. Release web builds keep the API
    // same-origin and rely on nginx/reverse-proxy routing /api/v1 to backend.
    if (kIsWeb) {
      return kDebugMode ? 'http://localhost:8080/api/v1' : '/api/v1';
    }

    // Android emulator reaches the host machine through 10.0.2.2.
    // iOS Simulator can reach the host through localhost.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }

    return 'http://localhost:8080/api/v1';
  }
}
