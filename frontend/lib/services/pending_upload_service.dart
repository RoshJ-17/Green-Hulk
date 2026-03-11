import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';

class PendingUploadService {
  static final List<PendingUpload> _pendingUploads = [];

  static List<PendingUpload> get pendingUploads =>
      List.unmodifiable(_pendingUploads);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('pending_uploads');
    if (data != null) {
      try {
        final List<dynamic> decoded = json.decode(data);
        _pendingUploads.clear();
        for (var item in decoded) {
          _pendingUploads.add(PendingUpload.fromJson(item as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('Error loading pending uploads: ');
      }
    }
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(_pendingUploads.map((e) => e.toJson()).toList());
    await prefs.setString('pending_uploads', data);
  }

  static Future<void> addPendingUpload({
    required String imagePath,
    required String cropName,
    bool heatmap = false,
  }) async {
    _pendingUploads.add(
      PendingUpload(
        imagePath: imagePath,
        cropName: cropName,
        heatmap: heatmap,
        timestamp: DateTime.now(),
      ),
    );
    await _save();
  }

  static Future<void> removeUpload(PendingUpload upload) async {
    _pendingUploads.remove(upload);
    await _save();
  }

  static Future<void> clear() async {
    _pendingUploads.clear();
    await _save();
  }

  static Future<void> syncPendingUploads() async {
    if (ConnectivityService.isOffline) return;
    if (_pendingUploads.isEmpty) return;

    debugPrint('Auto-Sync: Syncing \ pending items to backend...');
    
    // Simulate sync
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real scenario, loop through _pendingUploads and upload to API
    await clear();
    debugPrint('Auto-Sync complete');
  }
}

class PendingUpload {
  final String imagePath;
  final String cropName;
  final bool heatmap;
  final DateTime timestamp;

  PendingUpload({
    required this.imagePath,
    required this.cropName,
    this.heatmap = false,
    required this.timestamp,
  });

  factory PendingUpload.fromJson(Map<String, dynamic> json) {
    return PendingUpload(
      imagePath: json['imagePath'],
      cropName: json['cropName'],
      heatmap: json['heatmap'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'cropName': cropName,
      'heatmap': heatmap,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
