import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/crop_selection_screen.dart';
import 'screens/history_screen.dart';
import 'screens/treatment_screen.dart';
import 'models/scan_result.dart';
import 'theme/app_theme.dart';
import 'services/camera_service.dart';

/// 🔥 VERY IMPORTANT — APP STARTS HERE
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initCameras(); // initialize camera BEFORE app starts

  runApp(const CropDiagnosisApp());
}

class CropDiagnosisApp extends StatefulWidget {
  const CropDiagnosisApp({super.key});

  @override
  State<CropDiagnosisApp> createState() => _CropDiagnosisAppState();
}

class _CropDiagnosisAppState extends State<CropDiagnosisApp> {
  Locale _locale = const Locale('en');

  void _changeLanguage(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CropCare',
      theme: AppTheme.highContrastTheme,
      locale: _locale,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/language': (context) => LanguageSelectionScreen(onLanguageSelected: _changeLanguage),
        '/crops': (context) => const CropSelectionScreen(),
        '/history': (context) => const HistoryScreen(),
      },

      /// receives ScanResult after camera
      onGenerateRoute: (settings) {
        if (settings.name == '/treatment') {
          final result = settings.arguments as ScanResult;
          return MaterialPageRoute(
            builder: (_) => TreatmentScreen(result: result),
          );
        }
        return null;
      },
    );
  }
}
