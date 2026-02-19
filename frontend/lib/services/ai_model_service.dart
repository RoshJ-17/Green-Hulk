import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cross_file/cross_file.dart';
import '../models/scan_result.dart';

import '../config/api_config.dart';

/// AI Model Service (Backend API Version)
/// Sends image to backend for analysis instead of running local TFLite
class AIModelService {
  static const String _baseUrl = ApiConfig.apiUrl;

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

      // Add file - use bytes for web compatibility
      final bytes = await XFile(imagePath).readAsBytes();

      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      // Send request
      debugPrint('AI Model (API): Sending request to $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Parse response type
        final type = data['type'] as String? ?? 'success';

        if (type != 'success') {
          final message = data['message'] as String? ?? 'Analysis failed';
          debugPrint('AI Model (API): Non-success type: $type - $message');
          throw Exception(message);
        }

        // Parse full response
        final diseaseName = data['disease'] as String? ?? 'Unknown';
        final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
        final hasDisease = !diseaseName.toLowerCase().contains('healthy');
        final severity = data['severity'] as String?;
        final fullLabel = data['fullLabel'] as String?;
        final qualityWarnings = data['message'] as String?;

        debugPrint(
          'AI Model (API): Success - $diseaseName ($confidence) severity=$severity',
        );

        return ScanResult(
          cropName: cropName,
          diseaseName: diseaseName,
          confidence: confidence,
          imagePath: imagePath,
          hasDisease: hasDisease,
          severity: severity,
          fullLabel: fullLabel,
          qualityWarnings: qualityWarnings,
        );
      } else {
        debugPrint(
          'AI Model (API): Error ${response.statusCode} - ${response.body}',
        );
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
