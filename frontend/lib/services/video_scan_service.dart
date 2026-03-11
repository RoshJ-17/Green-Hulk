// lib/services/video_scan_service.dart
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';
import 'ai_model_service.dart';

/// Records 3 rapid still captures over ~3 seconds, runs AI on each,
/// and returns the consensus (majority-vote) result.
class VideoScanService {
  /// Takes 3 photos ~1.2s apart, runs AI on each, majority-vote result.
  static Future<ScanResult> rapidCaptureAndAnalyze({
    required CameraController controller,
    required String cropName,
    bool withHeatmap = false,
    void Function(String status)? onStatus,
  }) async {
    final List<XFile> captures = [];

    for (int i = 0; i < 3; i++) {
      onStatus?.call('Capturing frame ${i + 1}/3\u2026');
      final xFile = await controller.takePicture();
      captures.add(xFile);
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 1200));
      }
    }

    onStatus?.call('Analysing frames\u2026');

    final List<ScanResult> results = [];
    WrongCropException? lastWrongCropException;
    for (int i = 0; i < captures.length; i++) {
      onStatus?.call('AI analysis ${i + 1}/3\u2026');
      try {
        final result = await AIModelService.analyzeImage(
          imagePath: captures[i].path,
          cropName: cropName,
          withHeatmap: withHeatmap && i == 0,
        );
        results.add(result);
      } on WrongCropException catch (e) {
        lastWrongCropException = e;
      } catch (e) {
        debugPrint('VideoScan: frame $i failed: $e');
      }
    }

    if (results.isEmpty) {
      if (lastWrongCropException != null) {
        throw lastWrongCropException;
      }
      throw Exception(
          'All frames failed analysis. Try again with better lighting.');
    }
    return _majorityVote(results);
  }
  static ScanResult _majorityVote(List<ScanResult> results) {
    final Map<String, List<ScanResult>> grouped = {};
    for (final r in results) {
      grouped.putIfAbsent(r.diseaseName, () => []).add(r);
    }

    String? bestDisease;
    int bestCount = 0;
    double bestConfidence = 0;

    for (final entry in grouped.entries) {
      final count = entry.value.length;
      final maxConf = entry.value
          .map((r) => r.confidence)
          .reduce((a, b) => a > b ? a : b);

      if (count > bestCount ||
          (count == bestCount && maxConf > bestConfidence)) {
        bestDisease = entry.key;
        bestCount = count;
        bestConfidence = maxConf;
      }
    }

    final winners = grouped[bestDisease]!;
    winners.sort((a, b) => b.confidence.compareTo(a.confidence));

    final best = winners.first;
    return ScanResult(
      cropName: best.cropName,
      diseaseName: best.diseaseName,
      confidence: best.confidence,
      imagePath: best.imagePath,
      hasDisease: best.hasDisease,
      severity: best.severity,
      fullLabel: best.fullLabel,
      heatmapPng: best.heatmapPng,
    );
  }
}
