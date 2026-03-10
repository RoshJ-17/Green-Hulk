import 'dart:convert';
import 'package:http/http.dart' as http;

/// Translates text using the Gemini Flash API.
///
/// Usage:
///   1. Set [apiKey] to your Gemini API key (obtain at https://aistudio.google.com/).
///   2. Call [translate] with the English text and a target language code
///      (e.g. 'hi', 'ta', 'te', 'kn', 'bn', 'pa').
///
/// Results are cached per (text, langCode) pair so repeated calls are free.
class GeminiTranslationService {
  // ────────────────────────────────────────────────────────────────────
  // Set your Gemini API key here.  Leave blank to disable translation
  // (the service will silently return the original English text).
  static const String apiKey = 'AIzaSyBPBTcrhSMJpjlgggJ07Vy-8F769cGiiGE';
  // ────────────────────────────────────────────────────────────────────

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-1.5-flash-latest:generateContent';

  static final Map<String, String> _cache = {};

  static const Map<String, String> _languageNames = {
    'hi': 'Hindi',
    'ta': 'Tamil',
    'te': 'Telugu',
    'kn': 'Kannada',
    'bn': 'Bengali',
    'pa': 'Punjabi',
    'en': 'English',
  };

  /// Translates [text] into [targetLangCode].
  /// Returns original [text] if [targetLangCode] is 'en', the API key is
  /// not set, or a network/API error occurs.
  static Future<String> translate(String text, String targetLangCode) async {
    if (targetLangCode == 'en' || apiKey.isEmpty || text.trim().isEmpty) {
      return text;
    }

    final cacheKey = '$targetLangCode|$text';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final langName = _languageNames[targetLangCode] ?? targetLangCode;
    final prompt =
        'Translate the following agricultural text into $langName. '
        'Return ONLY the translated text with no extra explanation.\n\n'
        'Text: $text';

    try {
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.2,
                'maxOutputTokens': 1024,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final translated = (data['candidates'] as List?)
                ?.firstOrNull?['content']?['parts']
                ?.firstOrNull?['text'] as String? ??
            text;
        final result = translated.trim();
        _cache[cacheKey] = result;
        return result;
      }
    } catch (_) {
      // Network error or timeout — fall back silently
    }
    return text;
  }

  /// Translates a list of strings in parallel. Useful for translating
  /// multiple treatment steps at once.
  static Future<List<String>> translateAll(
      List<String> texts, String targetLangCode) async {
    return Future.wait(texts.map((t) => translate(t, targetLangCode)));
  }

  /// Clears the in-memory translation cache.
  static void clearCache() => _cache.clear();
}
