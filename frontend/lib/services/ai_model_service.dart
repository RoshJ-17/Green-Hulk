import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/scan_result.dart';

class WrongCropException implements Exception {
  final String predictedSpecies;
  final String selectedCrop;
  WrongCropException(this.predictedSpecies, this.selectedCrop);
  @override
  String toString() =>
      'This looks like an $predictedSpecies leaf. Please scan an $selectedCrop leaf.';
}

/// AI Model Service (Local TFLite Inference)
class AIModelService {
  static Interpreter? _interpreter;
  static List<String> _labels = [];

  static Future<bool> initialize() async {
    if (isModelLoaded) return true;
    try {
      _interpreter = await Interpreter.fromAsset('assets/model/model.tflite');
      
      final labelsJson = await rootBundle.loadString('assets/model/class_indices.json');
      final Map<String, dynamic> labelMap = json.decode(labelsJson);
      _labels = List.generate(labelMap.length, (index) => '');
      labelMap.forEach((key, value) {
        _labels[value as int] = key;
      });
      debugPrint('AIModelService: Loaded ${_labels.length} labels and TFLite model.');
      return true;
    } catch (e) {
      debugPrint('AIModelService: Error loading model: $e');
      return false;
    }
  }

  static bool get isModelLoaded => _interpreter != null && _labels.isNotEmpty;

  static Future<ScanResult> analyzeImage({
    required String imagePath,
    required String cropName,
    List<String>? selectedCrops,
    bool withHeatmap = false,
  }) async {
    debugPrint('AIModelService: analysing "$cropName" locally');
    if (!isModelLoaded) {
      await initialize();
    }
    if (!isModelLoaded) {
      throw Exception('Model failed to load');
    }
    
    final payload = await compute(_preprocessAndValidate, imagePath);
    if (payload == null) {
      throw Exception("Could not process image");
    }

    // Gate 1: reject non-leaf images before running inference
    if (!(payload['hasPlant'] as bool)) {
      throw Exception(
        'No plant leaf detected. Point the camera directly at a leaf in good lighting.',
      );
    }

    final tensor = payload['tensor'] as List<List<List<List<double>>>>;
    final output = List.generate(1, (i) => List.filled(_labels.length, 0.0));
    _interpreter!.run(tensor, output);

    final probs = output[0];
    double top1 = -1.0, top2 = -1.0;
    int top1Idx = -1;
    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > top1) {
        top2 = top1;
        top1 = probs[i];
        top1Idx = i;
      } else if (probs[i] > top2) {
        top2 = probs[i];
      }
    }

    // Gate 2: low overall confidence  
    final bool hasSelectedCrops = selectedCrops != null && selectedCrops.isNotEmpty;
    if (top1 < (hasSelectedCrops ? 0.70 : 0.55)) {
      throw Exception(
        'Could not identify the plant clearly (${(top1 * 100).toInt()}% confidence). '
        'Ensure the leaf fills the frame in good lighting.',
      );
    }

    // Gate 3: model is ambiguous between two classes — likely not a real leaf
    if ((top1 - top2) < (hasSelectedCrops ? 0.20 : 0.12) && top1 < 0.75) {
      throw Exception(
        'Result unclear (${(top1 * 100).toInt()}% vs ${(top2 * 100).toInt()}%). '
        'Please retake the photo with the leaf clearly centred.',
      );
    }

    final fullLabel = _labels[top1Idx];
    final maxProb   = top1;

    // Check wrong plant / leaf
    final predictedSpeciesMatch = fullLabel.split('___').first;
    // Format to normal text, e.g. "Cherry_(including_sour)" -> "Cherry including sour"
    final predictedSpecies = predictedSpeciesMatch.replaceAll('_(', ' ').replaceAll('_', ' ').replaceAll(')', '').trim();
    final actualCrop = cropName == 'any' ? predictedSpecies : cropName;
    
    // simple compare for matching species
    // Crop validation: single-crop mode (cropName) or multi-crop mode (selectedCrops)
    if (cropName != 'any') {
      final selectedFormatted = cropName.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final predictedFormatted = predictedSpeciesMatch.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (!predictedFormatted.contains(selectedFormatted) && !selectedFormatted.contains(predictedFormatted)) {
        throw WrongCropException(predictedSpecies, cropName);
      }
    } else if (hasSelectedCrops) {
      final predictedFormatted = predictedSpeciesMatch.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final matchesAny = selectedCrops.any((crop) {
        final cropFormatted = crop.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        return cropFormatted == predictedFormatted ||
               cropFormatted.contains(predictedFormatted) ||
               predictedFormatted.contains(cropFormatted);
      });
      if (!matchesAny) {
        throw WrongCropException(predictedSpecies, selectedCrops.join(' / '));
      }
    }

    // Convert disease name
    final diseasePart = fullLabel.split('___').last.replaceAll('_', ' ');
    final hasDisease = !diseasePart.toLowerCase().contains('healthy');
    
    return ScanResult(
      cropName:    actualCrop,
      diseaseName: hasDisease ? diseasePart : 'Healthy',
      confidence:  maxProb,
      imagePath:   imagePath,
      hasDisease:  hasDisease,
      severity:    hasDisease ? "Medium" : null,
      fullLabel:   fullLabel,
    );
  }

  // Returns preprocessed 224×224 tensor AND a leaf-presence flag.
  // Runs in a background isolate via compute().
  static Future<Map<String, dynamic>?> _preprocessAndValidate(String path) async {
    final raw = await XFile(path).readAsBytes();
    img.Image? image = img.decodeImage(raw);
    if (image == null) return null;

    // 1. Resize to 224×224
    image = img.copyResize(image, width: 224, height: 224, interpolation: img.Interpolation.cubic);

    // 2. Check for plant-like colours BEFORE brightness adjustment
    final hasPlant = _hasPlantLikeColors(image);

    // 3. Brightness boost for dark images
    image = _adaptiveBrightness(image);

    // 4. Normalize into [1, 224, 224, 3] Float32 list  ([0, 1] range)
    var input = List.generate(1, (i) => 
                   List.generate(224, (j) => 
                     List.generate(224, (k) => 
                       List.generate(3, (l) => 0.0))));

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final p = image.getPixel(x, y);
        input[0][y][x][0] = p.r / 255.0;
        input[0][y][x][1] = p.g / 255.0;
        input[0][y][x][2] = p.b / 255.0;
      }
    }
    return {'tensor': input, 'hasPlant': hasPlant};
  }

  /// Returns true when enough pixels have natural leaf/plant tones.
  /// Accepts: fresh green, dark green, yellowed/chlorotic, brown/tan diseased.
  /// Rejects: skin tones, clear sky, walls, metal surfaces.
  static bool _hasPlantLikeColors(img.Image image) {
    int plantPixels = 0;
    final total = image.width * image.height;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();

        // Fresh green leaf
        if (g > 80 && g > r * 0.85 && g > b * 0.85) {
          plantPixels++;
          continue;
        }
        // Dark / olive green leaf
        if (g > 50 && g > r * 0.7 && g > b * 0.8 && r < 140) {
          plantPixels++;
          continue;
        }
        // Yellowed / chlorotic leaf (yellow-green)
        if (r > 120 && g > 100 && b < 120 && g >= r * 0.6) {
          plantPixels++;
          continue;
        }
        // Brown / tan diseased leaf: r dominant but meaningful g, very low b
        if (r > 90 && g > 50 && g >= r * 0.45 && g <= r * 0.88 && b < 100) {
          plantPixels++;
          continue;
        }
      }
    }
    // Require at least 15% of pixels to be plant-like
    return (plantPixels / total) > 0.15;
  }


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

  static String getConfidenceDisplay(double confidence) =>
      '${(confidence * 100).toStringAsFixed(0)}% Certain';

  static String getDiseaseDisplayName(ScanResult result) => result.diseaseName;

  static void dispose() {
    _interpreter?.close();
  }
}
