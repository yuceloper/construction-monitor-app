import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }

    // Flutter Web production builds are normally served from the same host as
    // the API reverse proxy, so keep the default origin-relative. Local web
    // development can still override this with --dart-define=API_BASE_URL=...
    if (kIsWeb) {
      return '/api/v1';
    }

    // Android emulator reaches the host machine through 10.0.2.2.
    // iOS Simulator can reach the host through localhost.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }

    return 'http://localhost:8080/api/v1';
  }
}
