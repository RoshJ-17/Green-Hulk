import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/scan_result.dart';

class HistoryService {
  static final List<ScanResult> _history = [];

  static List<ScanResult> get history => List.unmodifiable(_history);

  static void addResult(ScanResult result) {
    _history.insert(0, result); // Add to top
  }

  static void removeResult(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
    }
  }

  static void clear() {
    _history.clear();
  }

  /// Fetch history from backend API
  static Future<void> fetchHistory() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.apiUrl}/scans/history?limit=50'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _history.clear();
        _history.addAll(data.map((json) => ScanResult.fromJson(json)).toList());
      }
    } catch (e) {
      print('Error fetching history: $e');
      // Keep existing history on error or handle as needed
    }
  }
}
