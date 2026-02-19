import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

/// Voice Search Service
/// Recognizes crop names from the supported crop list
/// Provides vibration feedback when a keyword is detected
class VoiceSearchService {
  static final SpeechToText _speech = SpeechToText();
  static bool _isInitialized = false;
  static bool _isListening = false;
  static String? _lastDetectedKeyword;

  /// Crop keywords to recognize (must match the crops list in crop_selection_screen.dart)
  static const List<String> keywords = [
    'corn', 'maize', // Corn aliases
    'tomato', 'tomatoes',
    'apple', 'apples',
    'blueberry', 'blueberries', 'blue berry', 'blue berries',
    'cherry', 'cherries',
    'grape', 'grapes',
    'orange', 'oranges',
    'peach', 'peaches',
    'pepper',
    'peppers',
    'bell pepper',
    'bell peppers',
    'chilli',
    'chilly',
    'chili',
    'capsicum',
    'potato', 'potatoes',
    'raspberry', 'raspberries', 'rasp berry', 'rasp berries',
    'soybean', 'soybeans', 'soy', 'soy bean', 'soy beans',
    'squash',
    'strawberry', 'strawberries', 'straw berry', 'straw berries',
  ];

  /// Map aliases back to canonical crop names (used by crop selection screen)
  static const Map<String, String> aliasMap = {
    // Plurals & Variations
    'apples': 'apple',
    'tomatoes': 'tomato',
    'blueberries': 'blueberry',
    'blue berry': 'blueberry',
    'blue berries': 'blueberry',
    'cherries': 'cherry',
    'grapes': 'grape',
    'oranges': 'orange',
    'peaches': 'peach',
    'peppers': 'pepper',
    'bell pepper': 'pepper',
    'bell peppers': 'pepper',
    'chilli': 'pepper',
    'chilly': 'pepper',
    'chili': 'pepper',
    'capsicum': 'pepper',
    'potatoes': 'potato',
    'raspberries': 'raspberry',
    'rasp berry': 'raspberry',
    'rasp berries': 'raspberry',
    'soybeans': 'soybean',
    'soy': 'soybean',
    'soy bean': 'soybean',
    'soy beans': 'soybean',
    'strawberries': 'strawberry',
    'straw berry': 'strawberry',
    'straw berries': 'strawberry',
    'maize': 'corn',
  };

  /// Initialize speech recognition
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('Speech error: $error'),
        onStatus: (status) => debugPrint('Speech status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech init error: $e');
      return false;
    }
  }

  /// Check if speech recognition is available
  static bool get isAvailable => _isInitialized;

  /// Check if currently listening
  static bool get isListening => _isListening;

  /// Start listening for voice input
  /// Returns recognized text via callback
  /// Vibrates when a keyword is detected
  static Future<void> startListening({
    required Function(String) onResult,
    required Function(String?) onKeywordDetected,
    Function()? onListeningStarted,
    Function()? onListeningStopped,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('Speech recognition not available');
        return;
      }
    }

    if (_isListening) return;

    _isListening = true;
    _lastDetectedKeyword = null;
    onListeningStarted?.call();

    await _speech.listen(
      onResult: (result) async {
        final text = result.recognizedWords.toLowerCase();
        onResult(result.recognizedWords);

        // Check for keywords
        final detectedKeyword = _detectKeyword(text);
        if (detectedKeyword != null &&
            detectedKeyword != _lastDetectedKeyword) {
          _lastDetectedKeyword = detectedKeyword;
          // Vibration pulse when keyword detected
          await _triggerVibration();
          onKeywordDetected(detectedKeyword);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  /// Stop listening
  static Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;
  }

  /// Cancel listening
  static Future<void> cancelListening() async {
    await _speech.cancel();
    _isListening = false;
  }

  /// Detect if any keyword is in the text, returning the canonical crop name
  static String? _detectKeyword(String text) {
    String? bestMatch;
    int maxIndex = -1;

    // We want the keyword matched CLOSEST to the end of the text
    // (the most recently spoken one)
    for (final keyword in keywords) {
      final index = text.lastIndexOf(keyword);
      if (index > maxIndex) {
        maxIndex = index;
        bestMatch = aliasMap[keyword] ?? keyword;
      }
    }
    return bestMatch;
  }

  /// Trigger vibration pulse
  static Future<void> _triggerVibration() async {
    try {
      // FIX (dead_code + dead_null_aware_expression): Vibration.hasVibrator()
      // returns non-nullable `bool` in vibration ^2.0.0, so `?? false` was
      // unreachable dead code and the null-aware operator was unnecessary.
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        // Short vibration pulse (200ms)
        await Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  /// Manually trigger vibration (for external use)
  static Future<void> vibrate({int duration = 200}) async {
    await _triggerVibration();
  }

  /// Get all available locales
  static Future<List<String>> getLocales() async {
    if (!_isInitialized) await initialize();
    final locales = await _speech.locales();
    return locales.map((l) => l.localeId).toList();
  }
}
