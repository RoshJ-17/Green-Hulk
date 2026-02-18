import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/scan_result.dart';
import 'auth_service.dart';

class AIModelService {
  static bool _isModelLoaded = false;
  
  // Use 10.0.2.2 for Android emulator to access host localhost
  // Use localhost for iOS simulator
  // Use your machine's IP for physical devices
  static const String _baseUrl = 'http://10.0.2.2:3000/api'; 

  static Future<bool> initialize() async {
    try {
      // Check backend health
      final uri = Uri.parse('$_baseUrl/health'); // Assuming a health endpoint exists or we just proceed
      // For now, we'll just check if we can reach the diagnosis endpoint or just assume it's ready
      // Realistically, backend should be running. 
      _isModelLoaded = true;
      debugPrint('AI Model Service: Initialized');
      return true;
    } catch (e) {
      debugPrint('AI Model init error: $e');
      return false;
    }
  }

  static bool get isModelLoaded => _isModelLoaded;

  static Future<ScanResult> analyzeImage({
    required String imagePath,
    required String cropName,
  }) async {
    debugPrint('AI Model (API): Analyzing image for $cropName');
    
    try {
      final uri = Uri.parse('$_baseUrl/diagnose');
      final request = http.MultipartRequest('POST', uri);

      // Add fields
      request.fields['selectedCrop'] = cropName;
      if (AuthService.userId != null) {
        request.fields['userId'] = AuthService.userId!;
      }

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      );
      
      request.files.add(multipartFile);

      // Send request
      debugPrint('AI Model (API): Sending request to $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Response format from backend:
        // {
        //   "type": "success",
        //   "disease": "Tomato___Late_blight",
        //   "confidence": 0.92,
        //   "severity": "high",
        //   "cropType": "Tomato",
        //   ...
        // }

        if (data['type'] == 'error') {
           throw Exception(data['message'] ?? 'Unknown backend error');
        }
        
        final diseaseName = data['disease'] as String? ?? 'Unknown';
        final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
        // Check if healthy
        final hasDisease = !diseaseName.toLowerCase().contains('healthy');
        
        debugPrint('AI Model (API): Success - $diseaseName ($confidence)');

        return ScanResult(
          cropName: cropName,
          diseaseName: diseaseName,
          confidence: confidence,
          imagePath: imagePath,
          hasDisease: hasDisease,
        );
      } else {
        debugPrint('AI Model (API): Error ${response.statusCode} - ${response.body}');
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('AI Model (API): Exception - $e');
      rethrow;
    }
  }
  
  static String getConfidenceDisplay(double confidence) {
    final percentage = (confidence * 100).toStringAsFixed(0);
    return '$percentage% Certain';
  }

  static String getDiseaseDisplayName(ScanResult result) {
    if (!result.hasDisease) {
      return 'Healthy - No Disease Detected';
    }
    // Clean up string like "Tomato___Late_blight" -> "Late Blight"
    // But backend might send cleaner names. For now, basic logic:
    String name = result.diseaseName;
    if (name.contains('___')) {
      name = name.split('___')[1].replaceAll('_', ' ');
    }
    return name;
  }

  static void dispose() {
    _isModelLoaded = false;
  }
}
