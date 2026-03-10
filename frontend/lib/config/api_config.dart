import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );
  static const String _localFallbackUrl = 'http://192.168.106.183:3000';

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      final currentUri = Uri.base;
      final isLoopbackHost = currentUri.host == 'localhost' ||
          currentUri.host == '127.0.0.1';

      if (isLoopbackHost) {
        return '${currentUri.scheme}://${currentUri.host}:3000';
      }

      return currentUri.origin;
    }

    return _localFallbackUrl;
  }

  static String get apiUrl => '$baseUrl/api';
  static String get authUrl => '$baseUrl/auth';
}
