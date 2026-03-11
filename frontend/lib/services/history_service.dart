import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sample_app_1/objectbox/objectbox_store.dart';
import '../models/scan_result.dart';
import '../objectbox/models/history_entity.dart';

class HistoryService {
  static final List<ScanResult> _history = [];

  static List<ScanResult> get history => List.unmodifiable(_history);

  static Future<void> init() async {
    _history.clear();
    await ObjectBoxStore.ensureInitialized();
    final box = ObjectBoxStore.instance.historyBox;
    final entities = box.getAll().reversed.toList(); // Newest first
    for (var entity in entities) {
      try {
        _history.add(entity.toScanResult());
      } catch (e) {
        debugPrint('Error parsing history entity: ');
      }
    }
  }

  static Future<void> addResult(ScanResult result) async {
    if (!kIsWeb && result.imagePath.isNotEmpty && !result.imagePath.startsWith('http') && !result.imagePath.startsWith('assets')) {
      try {
        // Copy temporary camera image to permanent app docs dir
        final docDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(result.imagePath);
        final historyDir = Directory(p.join(docDir.path, 'history_images'));
        if (!await historyDir.exists()) {
          await historyDir.create(recursive: true);
        }
        final savedImage = await File(result.imagePath).copy(p.join(historyDir.path, fileName));
        // Update result object with permanent path BEFORE saving
        result = ScanResult(
          id: result.id,
          cropName: result.cropName,
          diseaseName: result.diseaseName,
          confidence: result.confidence,
          imagePath: savedImage.path,
          hasDisease: result.hasDisease,
          date: result.date,
          severity: result.severity,
          fullLabel: result.fullLabel,
          qualityWarnings: result.qualityWarnings,
          heatmapPng: result.heatmapPng,
          rating: result.rating,
        );
      } catch (e) {
        debugPrint('Error saving history image: ');
      }
    }

    _history.insert(0, result);
    final entity = HistoryEntity(jsonPayload: jsonEncode(result.toJson()));
    ObjectBoxStore.instance.historyBox.put(entity);
  }


  static Future<void> updateResult(ScanResult updatedResult) async {
    final index = _history.indexWhere((r) => r.id == updatedResult.id);
    if (index >= 0) {
      _history[index] = updatedResult;
      final box = ObjectBoxStore.instance.historyBox;
      final entities = box.getAll();
      for (var e in entities) {
        if (e.toScanResult().id == updatedResult.id) {
          e.jsonPayload = jsonEncode(updatedResult.toJson());
          box.put(e);
          break;
        }
      }
    }
  }

  static void removeResult(int index) {
    if (index >= 0 && index < _history.length) {
      final res = _history[index];
      // Find and delete from objectbox
      final box = ObjectBoxStore.instance.historyBox;
      final entities = box.getAll();
      for (var e in entities) {
        if (e.toScanResult().id == res.id) {
          box.remove(e.id);
          break;
        }
      }
      
      // Delete image file if it's local
      if (!kIsWeb && res.imagePath.isNotEmpty && !res.imagePath.startsWith('http') && !res.imagePath.startsWith('assets')) {
        try {
          final file = File(res.imagePath);
          if (file.existsSync()) file.deleteSync();
        } catch (e) {
          debugPrint('Error deleting history image file: ');
        }
      }
      _history.removeAt(index);
    }
  }

  static void clear() {
    _history.clear();
    ObjectBoxStore.instance.historyBox.removeAll();
  }

  static Future<void> fetchHistory() async {
    // In local-first offline mode, fallback entirely to local objectbox.
    await init();
  }
}