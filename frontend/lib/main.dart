import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/crop_selection_screen.dart';
import 'screens/history_screen.dart';
import 'screens/navigation_wrapper.dart';
import 'screens/treatment_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'models/scan_result.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'services/camera_service.dart';
import 'services/connectivity_service.dart';
import 'services/ai_model_service.dart';
import 'services/voice_search_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AppState (reads saved language + session)
  final appState = AppState();
  await appState.init();

  if (!kIsWeb) {
    await initCameras();
    await VoiceSearchService.initialize();
  }

  await ConnectivityService.initialize();
  await AIModelService.initialize();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const CropDiagnosisApp(),
    ),
  );
}

class CropDiagnosisApp extends StatelessWidget {
  const CropDiagnosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp whenever locale changes
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'CropCare',
      theme: AppTheme.highContrastTheme,
      locale: appState.locale,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/splash':    (_) => const SplashScreen(),
        '/login':     (_) => const LoginScreen(),
        '/signup':    (_) => const SignupScreen(),
        '/language':  (_) => LanguageSelectionScreen(
              onLanguageSelected: (loc) {
                context.read<AppState>().changeLanguage(loc.languageCode);
              },
            ),
        '/main':      (_) => const NavigationWrapper(),
        '/crops':     (_) => const CropSelectionScreen(),
        '/history':   (_) => const HistoryScreen(),
        '/onboarding':(_) => const OnboardingScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/settings':  (_) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/treatment') {
          if (settings.arguments is Map) {
            final args   = settings.arguments as Map;
            final result = args['result'] as ScanResult;
            final isFromHistory = args['isFromHistory'] as bool? ?? false;
            return MaterialPageRoute(
              builder: (_) => TreatmentScreen(
                result: result,
                isFromHistory: isFromHistory,
              ),
            );
          } else {
            final result = settings.arguments as ScanResult;
            return MaterialPageRoute(
              builder: (_) => TreatmentScreen(result: result),
            );
          }
        }
        return null;
      },
    );
  }
}
