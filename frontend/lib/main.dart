import 'package:flutter/material.dart';
import 'screens/language_selection_screen.dart';
import 'screens/crop_selection_screen.dart';
import 'screens/history_screen.dart';
import 'screens/treatment_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CropDiagnosisApp());
}

class CropDiagnosisApp extends StatefulWidget {
  const CropDiagnosisApp({Key? key}) : super(key: key);

  @override
  State<CropDiagnosisApp> createState() => _CropDiagnosisAppState();
}

class _CropDiagnosisAppState extends State<CropDiagnosisApp> {
  Locale _locale = const Locale('en'); // Default language

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Diagnosis',
      theme: AppTheme.highContrastTheme,
      locale: _locale,
      debugShowCheckedModeBanner: false,
      home: LanguageSelectionScreen(onLanguageSelected: _changeLanguage),
      routes: {
        '/language': (context) => LanguageSelectionScreen(onLanguageSelected: _changeLanguage),
        '/crops': (context) => const CropSelectionScreen(),
        '/history': (context) => const HistoryScreen(),
        '/treatment': (context) => const TreatmentScreen(),
      },
    );
  }
}