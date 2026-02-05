import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';

// Task 7: Language Selection Screen
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
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Choose Your Language',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'अपनी भाषा चुनें',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.accentGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXLarge),
              
              // Language options in a nice grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.2,
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
      child: InkWell(
        onTap: () {
          onLanguageSelected(Locale(languageCode));
          Navigator.pushReplacementNamed(context, '/crops');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 6),
              Text(
                languageName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}