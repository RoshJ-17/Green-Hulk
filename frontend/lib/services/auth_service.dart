import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  /// Register a new user
  static Future<Map<String, dynamic>?> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.authUrl}/register');
      debugPrint('AuthService: Registering at $uri');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      );

      debugPrint('AuthService: Register response ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await _saveToken(data['accessToken']);
        return data; // { accessToken: ... }
      } else {
        debugPrint('AuthService: Register failed - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('AuthService: Register exception - $e');
      return null;
    }
  }

  /// Login existing user
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.authUrl}/login');
      debugPrint('AuthService: Logging in at $uri');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        await _saveToken(data['accessToken']);
        return data;
      } else {
        debugPrint('AuthService: Login failed - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('AuthService: Login exception - $e');
      return null;
    }
  }

  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Check if user is logged in and token is valid
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }

  /// Save token to local storage
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
}
