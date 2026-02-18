import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final Function(Locale) onLanguageSelected;

  const LanguageSelectionScreen({super.key, required this.onLanguageSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Language')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Text(
                'Choose Your Language',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'अपनी भाषा चुनें',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.accentGreen),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Language options in grid - BETTER PROPORTIONS
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.0, // Square cards for more height
                  children: [
                    _buildLanguageCard(context, 'English', 'en', '🌐'),
                    _buildLanguageCard(context, 'हिन्दी', 'hi', '🇮🇳'),
                    _buildLanguageCard(context, 'தமிழ்', 'ta', '🌾'),
                    _buildLanguageCard(context, 'తెలుగు', 'te', '🌿'),
                    _buildLanguageCard(context, 'ಕನ್ನಡ', 'kn', '🍃'),
                    _buildLanguageCard(context, 'বাংলা', 'bn', '🌱'),
                    _buildLanguageCard(context, 'ਪੰਜਾਬੀ', 'pa', '🌻'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    String languageName,
    String languageCode,
    String emoji,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          onLanguageSelected(Locale(languageCode));
          Navigator.pushReplacementNamed(context, '/main');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(emoji, style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    languageName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
