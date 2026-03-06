class ApiConfig {
  // Environment-aware base URL:
  // Production (Railway): BACKEND_URL is injected at Flutter build time via --dart-define
  // Local development fallback: http://127.0.0.1:3000
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  static const String apiUrl = '$baseUrl/api';
  static const String authUrl = '$baseUrl/auth';
}
