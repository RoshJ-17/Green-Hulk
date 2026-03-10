import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );
  /// On Android the loopback 127.0.0.1 points to the device itself.
  /// The Android emulator routes 10.0.2.2 to the host machine (your PC).
  static String get _localFallbackUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://127.0.0.1:3000';
  }

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
