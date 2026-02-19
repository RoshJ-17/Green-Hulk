import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/models/scan_result.dart';
import 'package:sample_app_1/services/history_service.dart';

void main() {
  group('HistoryService Unit Tests', () {

    setUp(() {
      HistoryService.clear();
    });

    test('addResult adds item to history', () {
      final result = ScanResult(
        cropName: 'Tomato',
        diseaseName: 'Blight',
        confidence: 0.8,
        imagePath: 'img.jpg',
        hasDisease: true,
      );

      HistoryService.addResult(result);

      expect(HistoryService.history.length, 1);
      expect(HistoryService.history.first, result);
    });

    test('addResult inserts at top (index 0)', () {
      final result1 = ScanResult(
        cropName: 'Rice',
        diseaseName: 'Healthy',
        confidence: 0.9,
        imagePath: 'r.jpg',
        hasDisease: false,
      );

      final result2 = ScanResult(
        cropName: 'Wheat',
        diseaseName: 'Rust',
        confidence: 0.7,
        imagePath: 'w.jpg',
        hasDisease: true,
      );

      HistoryService.addResult(result1);
      HistoryService.addResult(result2);

      expect(HistoryService.history.first, result2);
    });

    test('removeResult removes correct item', () {
      final result = ScanResult(
        cropName: 'Corn',
        diseaseName: 'Leaf Spot',
        confidence: 0.6,
        imagePath: 'c.jpg',
        hasDisease: true,
      );

      HistoryService.addResult(result);
      HistoryService.removeResult(0);

      expect(HistoryService.history.isEmpty, true);
    });

    test('removeResult does nothing for invalid index', () {
      HistoryService.removeResult(5);
      expect(HistoryService.history.length, 0);
    });

    test('clear removes all history', () {
      final result = ScanResult(
        cropName: 'Cotton',
        diseaseName: 'Healthy',
        confidence: 0.95,
        imagePath: 'cot.jpg',
        hasDisease: false,
      );

      HistoryService.addResult(result);
      HistoryService.clear();

      expect(HistoryService.history.isEmpty, true);
    });

  });
}
