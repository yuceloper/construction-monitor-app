import 'dart:io';

class ApiConfig {
  ApiConfig._();

  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }

    // Android emulator reaches the host machine through 10.0.2.2.
    // iOS Simulator can reach the host through localhost.
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }

    return 'http://localhost:8080/api/v1';
  }
}
