import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Treatment API Service (Offline First via SharedPreferences)
class TreatmentApiService {
  // Same base URL as AIModelService
  static String get _baseUrl => '${ApiConfig.apiUrl}/treatments';

  /// Fetch treatments for a specific disease key (e.g., "Tomato___Early_blight")
  static Future<Map<String, dynamic>?> getTreatments(String diseaseKey) async { 
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'treatment_cache_$diseaseKey';
    
    try {
      final encodedKey = Uri.encodeComponent(diseaseKey);
      final uri = Uri.parse('$_baseUrl/$encodedKey');

      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;        
        // Cache the result
        await prefs.setString(cacheKey, response.body);
        return data;
      }
    } catch (e) {
      debugPrint('TreatmentAPI Network Error: $e');
    }
    
    // Fallback to cache offline
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      return json.decode(cached) as Map<String, dynamic>;
    }
    return null;
  }

  /// Fetch only organic treatments for a disease
  static Future<List<dynamic>> getOrganicTreatments(String diseaseKey) async {  
    final data = await getTreatments(diseaseKey);
    return data?['organic'] as List<dynamic>? ?? [];
  }

  /// Fetch chemical treatments for a disease
  static Future<List<dynamic>> getChemicalTreatments(String diseaseKey) async { 
    final data = await getTreatments(diseaseKey);
    return data?['chemical'] as List<dynamic>? ?? [];
  }

  /// Fetch home remedies for a disease
  static Future<List<dynamic>> getHomeRemedies(String diseaseKey) async {       
    final data = await getTreatments(diseaseKey);
    return data?['home_remedies'] as List<dynamic>? ?? [];
  }
}
