import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Treatment API Service
/// Fetches treatment data from the backend treatments API
class TreatmentApiService {
  // Same base URL as AIModelService
  static String get _baseUrl => '${ApiConfig.apiUrl}/treatments';

  /// Fetch treatments for a specific disease key (e.g., "Tomato___Early_blight")
  static Future<Map<String, dynamic>?> getTreatments(String diseaseKey) async {
    try {
      // URL-encode the key so that special characters (spaces, parentheses)
      // in keys like "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot"
      // are transmitted correctly.
      final encodedKey = Uri.encodeComponent(diseaseKey);
      final uri = Uri.parse('$_baseUrl/$encodedKey');
      debugPrint('TreatmentAPI: Fetching treatments from $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('TreatmentAPI: Got treatments for $diseaseKey');
        return data;
      } else {
        debugPrint('TreatmentAPI: Error ${response.statusCode} for $diseaseKey');
        return null;
      }
    } catch (e) {
      debugPrint('TreatmentAPI: Exception - $e');
      return null;
    }
  }

  /// Fetch only organic treatments for a disease
  static Future<List<dynamic>> getOrganicTreatments(String diseaseKey) async {
    try {
      final encodedKey = Uri.encodeComponent(diseaseKey);
      final uri = Uri.parse('$_baseUrl/$encodedKey/organic');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['treatments'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('TreatmentAPI: Exception - $e');
      return [];
    }
  }

  /// Fetch chemical treatments for a disease
  static Future<List<dynamic>> getChemicalTreatments(String diseaseKey) async {
    try {
      final encodedKey = Uri.encodeComponent(diseaseKey);
      final uri = Uri.parse('$_baseUrl/$encodedKey/chemical');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['treatments'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('TreatmentAPI: Exception - $e');
      return [];
    }
  }

  /// Fetch home remedies for a disease
  static Future<List<dynamic>> getHomeRemedies(String diseaseKey) async {
    try {
      final encodedKey = Uri.encodeComponent(diseaseKey);
      final uri = Uri.parse('$_baseUrl/$encodedKey/home-remedies');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('TreatmentAPI: Exception - $e');
      return [];
    }
  }
}
