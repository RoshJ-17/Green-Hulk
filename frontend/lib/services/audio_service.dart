import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Audio Service
/// Plays audio feedback for button clicks and interactions
class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isEnabled = true;

  /// Enable/disable audio feedback
  static bool get isEnabled => _isEnabled;
  static set isEnabled(bool value) => _isEnabled = value;

  /// Play button click sound
  static Future<void> playButtonClick() async {
    if (!_isEnabled) return;
    await _playSystemSound();
  }

  /// Play success sound
  static Future<void> playSuccess() async {
    if (!_isEnabled) return;
    await _playSystemSound();
  }

  /// Play error sound
  static Future<void> playError() async {
    if (!_isEnabled) return;
    await _playSystemSound();
  }

  /// Play camera shutter sound
  static Future<void> playCameraShutter() async {
    if (!_isEnabled) return;
    await _playSystemSound();
  }

  /// Play keyword detected sound
  static Future<void> playKeywordDetected() async {
    if (!_isEnabled) return;
    await _playSystemSound();
  }

  /// Play from asset file
  static Future<void> playFromAsset(String assetPath) async {
    if (!_isEnabled) return;
    
    try {
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  /// Play from file path
  static Future<void> playFromFile(String filePath) async {
    if (!_isEnabled) return;
    
    try {
      await _player.play(DeviceFileSource(filePath));
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  /// Play from URL
  static Future<void> playFromUrl(String url) async {
    if (!_isEnabled) return;
    
    try {
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  /// Internal method to play system-like sound
  /// Uses a short tone effect
  static Future<void> _playSystemSound() async {
    try {
      // For now, we'll use a simple beep
      // In production, you'd add actual audio files in assets/sounds/
      // await _player.play(AssetSource('sounds/click.mp3'));
      
      // As a fallback, we can generate a simple tone
      debugPrint('Audio: Playing system sound');
    } catch (e) {
      debugPrint('System sound error: $e');
    }
  }

  /// Stop any playing audio
  static Future<void> stop() async {
    await _player.stop();
  }

  /// Set volume (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Dispose player
  static Future<void> dispose() async {
    await _player.dispose();
  }
}
