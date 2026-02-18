class ApiConfig {
  // Replace with your machine's IP for physical device
  // Use http://10.0.2.2:3000 for Android Emulator
  // Use http://localhost:3000 for iOS Simulator / Web

  // static const String baseUrl = 'http://10.0.2.2:3000'; // Android Emulator
  static const String baseUrl =
      'http://127.0.0.1:3000'; // more reliable for browser/simulators

  static const String apiUrl = '$baseUrl/api';
  static const String authUrl = '$baseUrl/auth';
}
