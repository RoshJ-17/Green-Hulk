import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cross_file/cross_file.dart';
import 'package:image/image.dart' as img;
import '../models/scan_result.dart';
import '../config/api_config.dart';

/// AI Model Service
///
/// Sends the captured leaf image to the backend for TFLite diagnosis.
///
/// Key improvements:
///   • Resizes image to ≤ 800 px longest side before upload  → < 1 s round-trip
///   • Applies adaptive gamma correction for dark images (client-side preview;
///     backend also applies its own correction independently)
///   • Supports heatmap=true query param to request Grad-CAM overlay
///   • Parses severity as "Early Stage" | "Medium" | "Severe"
class AIModelService {
  static const String _baseUrl = ApiConfig.apiUrl;

  /// No initialization needed for API service
  static Future<bool> initialize() async {
    return true;
  }

  /// Check if model is loaded (Always true for API)
  static bool get isModelLoaded => true;

  // ─── Public API ──────────────────────────────────────────────────────────

  static Future<ScanResult> analyzeImage({
    required String imagePath,
    required String cropName,
    bool withHeatmap = false,
  }) async {
    debugPrint('AIModelService: analysing "$cropName"  heatmap=$withHeatmap');

    // Optimise image on a background isolate
    final Uint8List bytes = await compute(_optimiseInBackground, imagePath);

    final url = Uri.parse(
      '$_baseUrl/diagnose${withHeatmap ? '?heatmap=true' : ''}',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['selectedCrop'] = cropName
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'leaf.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

    debugPrint('AIModelService: uploading ${bytes.length} bytes → $url');

    final streamed  = await request.send();
    final response  = await http.Response.fromStream(streamed);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseResponse(
        json.decode(response.body) as Map<String, dynamic>,
        cropName,
        imagePath,
      );
    }
    throw Exception('API ${response.statusCode}: ${response.body}');
  }

  // ─── Image optimisation (runs in background isolate) ─────────────────────

  static Future<Uint8List> _optimiseInBackground(String path) async {
    final raw = await XFile(path).readAsBytes();
    img.Image? image = img.decodeImage(raw);
    if (image == null) return raw;

    // 1. Resize: longest side ≤ 800 px
    const maxDim = 800;
    if (image.width > maxDim || image.height > maxDim) {
      image = image.width >= image.height
          ? img.copyResize(image, width: maxDim,
              interpolation: img.Interpolation.cubic)
          : img.copyResize(image, height: maxDim,
              interpolation: img.Interpolation.cubic);
    }

    // 2. Brightness boost for dark images
    image = _adaptiveBrightness(image);

    return Uint8List.fromList(img.encodeJpg(image, quality: 85));
  }

  /// Adaptive gamma correction.
  ///
  ///   avg < 80   → gamma 0.55 (strong boost)
  ///   avg < 120  → gamma 0.75 (moderate boost)
  ///   otherwise  → no change
  static img.Image _adaptiveBrightness(img.Image src) {
    double sum = 0;
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        sum += 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      }
    }
    final avg = sum / (src.width * src.height);

    final double gamma;
    if      (avg < 80)  gamma = 0.55;
    else if (avg < 120) gamma = 0.75;
    else return src;

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        final r = (255 * math.pow(p.r / 255.0, gamma)).round().clamp(0, 255);
        final g = (255 * math.pow(p.g / 255.0, gamma)).round().clamp(0, 255);
        final b = (255 * math.pow(p.b / 255.0, gamma)).round().clamp(0, 255);
        src.setPixelRgb(x, y, r, g, b);
      }
    }
    return src;
  }

  // ─── Response parsing ────────────────────────────────────────────────────

static ScanResult _parseResponse(Map<String, dynamic> data, String cropName, String imagePath) {
  final type = data['type'] as String? ?? 'error';
  
  switch (type) {
    case 'success':
      return ScanResult(
        cropName:    cropName,
        diseaseName: data['disease'] as String? ?? 'Unknown',
        confidence:  (data['confidence'] as num?)?.toDouble() ?? 0.0,
        imagePath:   imagePath,
        hasDisease:  !(data['disease'] as String? ?? '').toLowerCase().contains('healthy'),
        severity:    data['severity'] as String?,
        fullLabel:   data['fullLabel'] as String?,
      );
    case 'wrongCrop':
      throw Exception('Wrong crop detected: ${data['detectedCrop']}. You selected ${data['selectedCrop']}.');
    case 'lowConfidence':
      throw Exception('Image not clear enough (${((data['confidence'] as num?)?.toDouble() ?? 0) * 100 ~/ 1}% confidence). Try better lighting.');
    case 'outOfDistribution':
      throw Exception('Could not identify this as a known plant disease. Make sure to scan a single leaf close-up.');
    case 'poorQuality':
      throw Exception('Image quality too poor: ${data['message']}');
    default:
      throw Exception(data['message'] as String? ?? 'Analysis failed');
  }
}

  // ─── Display helpers ─────────────────────────────────────────────────────

  static String getConfidenceDisplay(double confidence) =>
      '${(confidence * 100).toStringAsFixed(0)}% Certain';

  static String getDiseaseDisplayName(ScanResult result) => result.diseaseName;

  static void dispose() {}
}
