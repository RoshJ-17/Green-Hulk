import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/services/ai_model_service.dart';
import 'package:sample_app_1/models/scan_result.dart';

void main() {
  group('AIModelService Unit Tests', () {

    test('getConfidenceDisplay formats percentage correctly', () {
      final result = AIModelService.getConfidenceDisplay(0.876);
      expect(result, '88% Certain');
    });

    test('getConfidenceDisplay rounds correctly', () {
      final result = AIModelService.getConfidenceDisplay(0.234);
      expect(result, '23% Certain');
    });

    test('getDiseaseDisplayName returns disease name correctly', () {
      final scan = ScanResult(
        cropName: 'Wheat',
        diseaseName: 'Rust',
        confidence: 0.91,
        imagePath: 'img.jpg',
        hasDisease: true,
      );

      final name = AIModelService.getDiseaseDisplayName(scan);
      expect(name, 'Rust');
    });

  });
}
