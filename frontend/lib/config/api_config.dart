class ApiConfig {
  // Replace with your machine's IP for physical device
  // Use http://10.0.2.2:3000 for Android Emulator
  // Use http://localhost:3000 for iOS Simulator / Web

  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  // static const String baseUrl = 'http://10.0.2.2:3000'; 
  // static const String baseUrl = 'http://127.0.0.1:3000';

  // Automatically switch running on Android Emulator vs others
  static const String baseUrl = 'http://10.0.2.2:3000'; 

  static const String apiUrl = '$baseUrl/api';
  static const String authUrl = '$baseUrl/auth';
}
