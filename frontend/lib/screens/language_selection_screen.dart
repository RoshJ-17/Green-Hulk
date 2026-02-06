import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final Function(Locale) onLanguageSelected;

  const LanguageSelectionScreen({
    Key? key,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Language'),
      ),
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.accentGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Language options in grid - BETTER PROPORTIONS
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.4, // Better ratio for card height
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
          Navigator.pushReplacementNamed(context, '/crops');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 40), // Bigger emoji
              ),
              const SizedBox(height: 10),
              Text(
                languageName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}