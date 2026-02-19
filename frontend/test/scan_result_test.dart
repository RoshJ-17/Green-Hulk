import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/models/scan_result.dart';

void main() {
  group('ScanResult Model Tests', () {

    test('should initialize with required values', () {
      final result = ScanResult(
        cropName: 'Tomato',
        diseaseName: 'Early Blight',
        confidence: 0.85,
        imagePath: 'image.jpg',
        hasDisease: true,
      );

      expect(result.cropName, 'Tomato');
      expect(result.diseaseName, 'Early Blight');
      expect(result.confidence, 0.85);
      expect(result.hasDisease, true);
      expect(result.imagePath, 'image.jpg');
    });

    test('should auto generate id and date', () {
      final result = ScanResult(
        cropName: 'Rice',
        diseaseName: 'Healthy',
        confidence: 0.99,
        imagePath: 'rice.jpg',
        hasDisease: false,
      );

      expect(result.id, isNotNull);
      expect(result.date, isNotNull);
    });

  });
}
