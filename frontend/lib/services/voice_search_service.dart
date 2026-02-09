import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

/// Voice Search Service
/// Recognizes keywords: "Tomato", "Blight", "Rice"
/// Provides vibration feedback when a keyword is detected
class VoiceSearchService {
  static final SpeechToText _speech = SpeechToText();
  static bool _isInitialized = false;
  static bool _isListening = false;

  /// Keywords to recognize
  static const List<String> keywords = ['tomato', 'blight', 'rice'];

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
    onListeningStarted?.call();

    await _speech.listen(
      onResult: (result) async {
        final text = result.recognizedWords.toLowerCase();
        onResult(result.recognizedWords);

        // Check for keywords
        final detectedKeyword = _detectKeyword(text);
        if (detectedKeyword != null) {
          // Vibration pulse when keyword detected
          await _triggerVibration();
          onKeywordDetected(detectedKeyword);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
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

  /// Detect if any keyword is in the text
  static String? _detectKeyword(String text) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return keyword;
      }
    }
    return null;
  }

  /// Trigger vibration pulse
  static Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
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
