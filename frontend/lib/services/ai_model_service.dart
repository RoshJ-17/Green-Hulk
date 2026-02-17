import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart'; // Provides XFile
import 'package:http_parser/http_parser.dart';
import '../models/scan_result.dart';

/// AI Model Service (Backend API Version)
/// Sends image to backend for analysis instead of running local TFLite
class AIModelService {
  // CONFIG: Replace with your computer's IP address (not localhost for Android/iOS)
  // For Android Emulator, use 10.0.2.2
  // For Physical Device, use your machine's LAN IP (e.g., 192.168.1.x)
  static const String _baseUrl = 'http://192.168.1.100:3000/api'; 

  /// No initialization needed for API service
  static Future<bool> initialize() async {
    return true;
  }

  /// Check if model is loaded (Always true for API)
  static bool get isModelLoaded => true;

  /// Send a photo to the backend AI model and get diagnosis result
  /// 
  /// [imagePath] - Path to the image file
  /// [cropName] - Name of the crop being scanned
  /// 
  /// Returns a [ScanResult] with the diagnosis
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

      // Add file
      // imagePath is a string here, but we can treat it as XFile path or File path
      // XFile from camera usually gives a path.
      
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imagePath,
        contentType: MediaType('image', 'jpeg'), // Assume JPEG/PNG
      );
      
      request.files.add(multipartFile);

      // Send request
      debugPrint('AI Model (API): Sending request to $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Parse response
        final diseaseName = data['disease'] as String? ?? 'Unknown';
        final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
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

  /// Get confidence level as display string
  static String getConfidenceDisplay(double confidence) {
    final percentage = (confidence * 100).toStringAsFixed(0);
    return '$percentage% Certain';
  }

  /// Get disease name for display
  static String getDiseaseDisplayName(ScanResult result) {
    return result.diseaseName;
  }

  /// Dispose and cleanup (Nothing to verify)
  static void dispose() {}
}
