// lib/services/auth_service.dart
//
// Handles registration (with phone-OTP flow), login, and logout.
// OTP endpoints: POST /auth/send-otp  { phone }
//                POST /auth/verify-otp { phone, otp }
//
// If the backend does not yet implement OTP endpoints, the sendOtp() method
// falls back to a development mock (accepts any 6-digit code).

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey  = 'user_data';

  // ── OTP ─────────────────────────────────────────────────────────────────

  /// Request an OTP to be sent to [phone].
  /// Returns the OTP string on success (shown on screen for demo),
  /// or null on failure.
  static Future<String?> sendOtp(String phone) async {
    try {
      final uri = Uri.parse('${ApiConfig.authUrl}/send-otp');
      debugPrint('AuthService: Sending OTP to $phone via $uri');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'phone': phone}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final otp = data['otp'] as String?;
        debugPrint('AuthService: OTP sent successfully. OTP=$otp');
        return otp ?? 'sent'; // 'sent' = SMS delivered, no code in response
      }

      debugPrint('AuthService: sendOtp failed with status ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('AuthService: sendOtp error — $e');
      return null;
    }
  }

  /// Verify [otp] for [phone].
  /// Returns user data map on success, null on failure.
  static Future<Map<String, dynamic>?> verifyOtp(
    String phone,
    String otp,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.authUrl}/verify-otp');
      debugPrint('AuthService: Verifying OTP for $phone');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'phone': phone, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['accessToken'] != null) {
          await _saveToken(data['accessToken']);
        }
        return data;
      }

      debugPrint('AuthService: verifyOtp failed with status ${response.statusCode} — ${response.body}');
      return null;
    } catch (e) {
      debugPrint('AuthService: verifyOtp error — $e');
      return null;
    }
  }

  // ── Registration ─────────────────────────────────────────────────────────

  /// Register a new user: phone + OTP the backend already verified (via /auth/register).
  static Future<Map<String, dynamic>?> registerWithPhone({
    required String fullName,
    required String phone,
    required String otp,
    String? email,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.authUrl}/register');
      debugPrint('AuthService: Registering at $uri');

      final body = <String, dynamic>{
        'fullName': fullName,
        'phone':    phone,
        'otp':      otp,
      };
      if (email != null && email.isNotEmpty) body['email'] = email;

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      debugPrint('AuthService: Register response ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['accessToken'] != null) await _saveToken(data['accessToken']);
        return data;
      }
      debugPrint('AuthService: Register failed — ${response.body}');
      return null;
    } catch (e) {
      debugPrint('AuthService: Register exception — $e');
      return null;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Login with phone number only (no OTP required for login).
  static Future<Map<String, dynamic>?> loginWithPhone({
    required String phone,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.authUrl}/login');
      debugPrint('AuthService: Logging in at $uri');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'phone': phone}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['accessToken'] != null) await _saveToken(data['accessToken']);
        return data;
      }
      debugPrint('AuthService: Login failed — ${response.body}');
      return null;
    } catch (e) {
      debugPrint('AuthService: Login exception — $e');
      return null;
    }
  }

  // ── Session ───────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;
    try {
      // Some environments may return opaque (non-JWT) access tokens.
      // In that case keep the session alive if a token is present.
      final isLikelyJwt = token.split('.').length == 3;
      if (!isLikelyJwt) return true;
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return true;
    }
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
}
