import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/scan_result.dart';

class HistoryService {
  static final List<ScanResult> _history = [];

  /// Returns an unmodifiable view of the current history list.
  static List<ScanResult> get history => List.unmodifiable(_history);

  /// Adds a new scan result to the top of the history list.
  static void addResult(ScanResult result) {
    _history.insert(0, result); // Add to top
  }

  /// Removes a scan result at the specified [index].
  static void removeResult(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
    }
  }

  /// Clears all entries from the local history list.
  static void clear() {
    _history.clear();
  }

  /// Fetch history from backend API
  static Future<void> fetchHistory() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return; // Fail fast in tests to avoid hanging
    }
    try {
      final response = await http.get(Uri.parse('${ApiConfig.apiUrl}/scans/history?limit=50'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _history.clear();
        _history.addAll(data.map((json) => ScanResult.fromJson(json)).toList());
      }
    } catch (e) {
      // FIX (avoid_print): replaced print() with debugPrint() — print() must
      // not be used in production code as it always outputs to the console.
      // debugPrint() is stripped in release builds automatically.
      debugPrint('Error fetching history: $e');
      // Keep existing history on error or handle as needed
    }
  }
}
