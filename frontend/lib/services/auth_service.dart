import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Use 10.0.2.2 for Android emulator, localhost for iOS/Web
  static const String _baseUrl = 'http://10.0.2.2:3000/auth';
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';

  static String? _token;
  static String? _userId;
  static String? _userName;

  static bool get isLoggedIn => _token != null;
  static String? get userId => _userId;
  static String? get userName => _userName;
  static String? get token => _token;

  /// Initialize: Try to restore session from storage
  static Future<bool> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userId = prefs.getString(_userIdKey);
    _userName = prefs.getString(_userNameKey);
    
    return isLoggedIn;
  }

  /// Login
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveSession(data['token'], data['user']);
        return true;
      } else {
        debugPrint('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  /// Register
  static Future<bool> register(String fullName, String email, String password, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveSession(data['token'], data['user']);
        return true;
      } else {
        debugPrint('Registration failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _token = null;
    _userId = null;
    _userName = null;
  }

  /// Guest Login (Optional - just clears prior session but allows access)
  static Future<void> loginAsGuest() async {
    await logout();
    // In a real app, maybe set a "isGuest" flag
  }

  static Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _userId = user['id'];
    _userName = user['fullName'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_userIdKey, _userId!);
    await prefs.setString(_userNameKey, _userName!);
  }
}
