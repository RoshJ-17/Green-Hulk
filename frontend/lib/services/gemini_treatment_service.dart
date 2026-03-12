import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiTreatmentService {
  static const String apiKey = 'AIzaSyBKPN1U23u54p31mjTiaQYa5RvHhNYkPgg';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';
  static const Map<String, String> _languageNames = {
    'hi': 'Hindi',
    'ta': 'Tamil',
    'te': 'Telugu',
    'kn': 'Kannada',
    'bn': 'Bengali',
    'pa': 'Punjabi',
    'en': 'English',
  };

  static Future<Map<String, dynamic>> fetchTreatmentPlan(
    String cropName,
    String diseaseName,
    String langCode,
  ) async {
    final langName = _languageNames[langCode] ?? 'English';
    final prompt =
        '''
You are an expert plant pathologist and agronomist.
I have a $cropName plant that has been diagnosed with $diseaseName.
Please provide a comprehensive treatment plan in STRICT JSON format with no markdown wrappers or extra text.
Provide the entire JSON values translated into $langName language (the keys must remain exactly as specified in English).
The JSON must follow this exact structure:
{
  "description": "A short 2 sentence description of the disease.",
  "treatments": [
    {
      "name": "General Organic Management",
      "type": "organic",
      "is_organic": true,
      "steps": [
        { "action": "Step 1...", "icon": "??", "timeframe": "today" },
        { "action": "Step 2...", "icon": "??", "timeframe": "ongoing" }
      ]
    },
    {
      "name": "Standard Chemical Control",
      "type": "chemical",
      "is_organic": false,
      "steps": [
        { "action": "Step 1...", "icon": "??", "timeframe": "today" },
        { "action": "Step 2...", "icon": "??", "timeframe": "ongoing" }
      ]
    }
  ],
  "prevention": [
    { "action": "Prevention advice 1...", "icon": "???" },
    { "action": "Prevention advice 2...", "icon": "???" }
  ],
  "remedies": [
    { "action": "Home remedy 1...", "icon": "?" },
    { "action": "Home remedy 2...", "icon": "?" }
  ]
}
''';

    final uri = Uri.parse('$_endpoint?key=$apiKey');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      String text =
          jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      if (text.startsWith('```json')) {
        text = text.substring(7);
      } else if (text.startsWith('```')) {
        text = text.substring(3);
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
      return jsonDecode(text.trim());
    } else {
      throw Exception(
        'Failed to generate treatment from AI. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  static Future<String> askQuestion(
    String cropName,
    String diseaseName,
    String langCode,
    List<Map<String, String>> chatHistory,
  ) async {
    final langName = _languageNames[langCode] ?? 'English';
    List<Map<String, dynamic>> contents = [
      {
        "role": "user",
        "parts": [
          {
            "text":
                "Topic: $cropName with $diseaseName.\nYou are a helpful agricultural AI assistant answering in $langName. Keep responses brief, clear, and relevant to this topic.",
          },
        ],
      },
      {
        "role": "model",
        "parts": [
          {
            "text":
                "Understood. I will answer your questions about $cropName and $diseaseName in $langName.",
          },
        ],
      },
    ];

    for (var msg in chatHistory) {
      contents.add({
        "role": msg['role'], // 'user' or 'model'
        "parts": [
          {"text": msg['text']},
        ],
      });
    }

    final uri = Uri.parse('$_endpoint?key=$apiKey');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"contents": contents}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
    } else {
      return "Sorry, I couldn't reach the AI right now.";
    }
  }
}
