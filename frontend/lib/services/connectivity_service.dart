import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity Service
/// Tracks internet connection status
/// Used to show "No Internet - Local Scan" badge
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static bool _isOnline = true;
  static StreamSubscription<ConnectivityResult>? _subscription;

  /// Listeners for connectivity changes
  static final List<Function(bool)> _listeners = [];

  /// Current connectivity status
  static bool get isOnline => _isOnline;
  static bool get isOffline => !_isOnline;

  /// Initialize and start monitoring connectivity
  static Future<void> initialize() async {
    try {
      // Check initial status
      final result = await _connectivity.checkConnectivity();
      _updateStatus(result);

      // Listen for changes
      _subscription = _connectivity.onConnectivityChanged.listen((result) {
        _updateStatus(result);
      });
    } catch (e) {
      debugPrint('Connectivity init error: $e');
      _isOnline = true; // Assume online if check fails
    }
  }

  /// Update connectivity status
  static void _updateStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    
    // Check if connection is available
    _isOnline = result != ConnectivityResult.none;

    // Notify listeners if status changed
    if (wasOnline != _isOnline) {
      for (final listener in _listeners) {
        listener(_isOnline);
      }
    }

    debugPrint('Connectivity: ${_isOnline ? "Online" : "Offline"}');
  }

  /// Add listener for connectivity changes
  static void addListener(Function(bool) listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  static void removeListener(Function(bool) listener) {
    _listeners.remove(listener);
  }

  /// Check connectivity once (manual check)
  static Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateStatus(result);
      return _isOnline;
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      return true; // Assume online if check fails
    }
  }

  /// Dispose (cleanup)
  static void dispose() {
    _subscription?.cancel();
    _listeners.clear();
  }
}
