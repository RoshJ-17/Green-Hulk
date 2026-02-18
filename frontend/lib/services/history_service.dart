import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/scan_result.dart';
import 'auth_service.dart';

class HistoryService {
  // Use 10.0.2.2 for Android emulator, localhost for iOS/Web
  static const String _baseUrl = 'http://10.0.2.2:3000/api/history';
  
  static List<ScanResult> _history = [];
  static List<ScanResult> get history => List.unmodifiable(_history);

  /// Fetch history from backend
  static Future<void> fetchHistory() async {
    final userId = AuthService.userId;
    if (userId == null) {
      _history = [];
      return;
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl?userId=$userId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _history = data.map((json) => _mapBackendToScanResult(json)).toList();
      } else {
        debugPrint('Failed to fetch history: ${response.body}');
      }
    } catch (e) {
      debugPrint('History fetch error: $e');
    }
  }

  /// Add result (Optimistic update + Refetch recommendation)
  static void addResult(ScanResult result) {
    _history.insert(0, result);
    // In a real app, we might want to re-fetch to get the ID/timestamp from server
  }

  static void removeResult(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      // TODO: Call API to delete
    }
  }

  static void clear() {
    _history.clear();
  }

  static ScanResult _mapBackendToScanResult(Map<String, dynamic> json) {
    // Map backend ScanRecord entity to frontend ScanResult
    // Backend: id, timestamp, cropType, imagePath, diseaseName, fullLabel, confidence, severity...
    return ScanResult(
      cropName: json['cropType'] ?? 'Unknown',
      diseaseName: json['diseaseName'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      imagePath: json['imagePath'] ?? '', // Note: This might be a server path, not local. 
      // For now, if it's a server path, we might need a full URL. 
      // Assuming for this MVP we might see issues if image is not local.
      hasDisease: json['diseaseName'] != 'Healthy',
      date: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }
}
