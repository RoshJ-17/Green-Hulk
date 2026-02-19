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

  /// Placeholder for fetching history from backend/local storage
  static Future<void> fetchHistory() async {
    // In a real app, this would fetch from a local database or API
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
