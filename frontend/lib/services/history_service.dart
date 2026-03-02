import 'dart:convert';
import 'package:flutter/foundation.dart'; // FIX: needed for debugPrint
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/scan_result.dart';
import 'objectbox_service.dart';
import 'package:objectbox/objectbox.dart';
import '../objectbox.g.dart';

class HistoryService {
  static Box<ScanResult> get _box => ObjectBoxService.store.box<ScanResult>();

  static List<ScanResult> get history {
    // Return sorted by date descending
    final query = _box.query().order(ScanResult_.date, flags: Order.descending).build();
    final results = query.find();
    query.close();
    return results;
  }

  static void addResult(ScanResult result) {
    _box.put(result);
  }

  static void removeResult(int index) {
    var items = history;
    if (index >= 0 && index < items.length) {
      _box.remove(items[index].obxId);
    }
  }

  static void clear() {
    _box.removeAll();
  }

  /// Fetch history from backend API
  static Future<void> fetchHistory() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.apiUrl}/scans/history?limit=50'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Convert to objects
        final newResults = data.map((json) => ScanResult.fromJson(json)).toList();
        
        // Put all to box
        _box.putMany(newResults);
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
