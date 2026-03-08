// lib/services/app_state.dart
//
// Centralized state holder for:
//   • Currently selected language (locale)
//   • Login session status
//   • Dashboard scan statistics (total / diseased)
//
// Backed by SharedPreferences so preferences survive app restarts.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_service.dart';
import 'localization_service.dart';

class AppState extends ChangeNotifier {
  // ── Language ──────────────────────────────────────────────────────────────
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  // ── Session ───────────────────────────────────────────────────────────────
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // ── Stats ─────────────────────────────────────────────────────────────────
  int _totalScans    = 0;
  int _diseasedScans = 0;
  int get totalScans    => _totalScans;
  int get diseasedScans => _diseasedScans;

  // ── Selected Crops ────────────────────────────────────────────────────────
  List<String> _selectedCrops = [];
  static const int maxCrops = 6;
  List<String> get selectedCrops => List.unmodifiable(_selectedCrops);
  bool get hasCrops => _selectedCrops.isNotEmpty;
  bool get canAddMoreCrops => _selectedCrops.length < maxCrops;
  bool isCropSelected(String crop) => _selectedCrops.contains(crop);

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _langKey          = 'app_language';
  static const _firstLaunchKey   = 'has_selected_language';
  static const _cropsKey         = 'selected_crops';

  // ═════════════════════════════════════════════════════════════════════════
  // Initialization — call once at startup (in main.dart)
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Restore saved language (default: English)
    final savedLang = prefs.getString(_langKey) ?? 'en';
    _locale = Locale(savedLang);

    // Restore login flag
    _isLoggedIn = (prefs.getString('auth_token') != null);

    // Restore selected crops
    _selectedCrops = prefs.getStringList(_cropsKey) ?? [];

    // Refresh scan stats from history
    await refreshStats();

    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Language
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> changeLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, languageCode);
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // First-launch flag
  // ═════════════════════════════════════════════════════════════════════════

  /// Returns true if the user has never selected a language before.
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_firstLaunchKey) ?? false);
  }

  /// Call this after the user confirms language selection for the first time.
  static Future<void> markLanguageSelected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Session
  // ═════════════════════════════════════════════════════════════════════════

  void setLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Crops
  // ═════════════════════════════════════════════════════════════════════════

  /// Toggle a crop selection. Returns false (and does NOT add) if already at maxCrops.
  Future<bool> toggleCrop(String crop) async {
    if (_selectedCrops.contains(crop)) {
      _selectedCrops.remove(crop);
    } else {
      if (_selectedCrops.length >= maxCrops) return false;
      _selectedCrops.add(crop);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cropsKey, _selectedCrops);
    notifyListeners();
    return true;
  }

  /// Remove all selected crops and persist.
  Future<void> clearCrops() async {
    _selectedCrops.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cropsKey);
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Localization shortcut
  // ═════════════════════════════════════════════════════════════════════════

  /// Translate [key] using the current locale.
  String tr(String key) => L10nService.tr(key, _locale.languageCode);

  // ═════════════════════════════════════════════════════════════════════════
  // Stats
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> refreshStats() async {
    // Ensure history is loaded
    await HistoryService.fetchHistory();
    final history = HistoryService.history;

    _totalScans    = history.length;
    _diseasedScans = history.where((r) => r.hasDisease).length;
    notifyListeners();
  }
}
