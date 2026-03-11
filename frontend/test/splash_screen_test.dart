import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/splash_screen.dart';
import 'package:sample_app_1/services/app_state.dart';
import 'test_helper.dart';

void main() {
  testWidgets('SplashScreen renders UI correctly',
      (WidgetTester tester) async {
    await mockSharedPreferences();
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      createTestWidget(
        child: const SplashScreen(),
        appState: appState,
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login Screen')),
          '/language': (_) => const Scaffold(body: Text('Language Screen')),
          '/main': (_) => const Scaffold(body: Text('Main Screen')),
        },
      ),
    );

    await tester.pump(); // First frame

    // Check UI elements (from SplashScreen code)
    expect(find.text('CropCare'), findsOneWidget);
    expect(find.text('AI Crop Disease Diagnosis'), findsOneWidget);

    // Let timer finish without waiting for infinite animation
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('SplashScreen navigates correctly',
      (WidgetTester tester) async {
    await mockSharedPreferences();
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      createTestWidget(
        child: const SplashScreen(),
        appState: appState,
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login Screen')),
          '/language': (_) => const Scaffold(body: Text('Language Screen')),
          '/main': (_) => const Scaffold(body: Text('Main Screen')),
        },
      ),
    );

    await tester.pump(); // Start timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(); // Handle navigation frame

    // Since it's a mock launch, it should go to /language or /login
    // based on mocked values. Default is likely /language or /login.
    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          (w.data == 'Login Screen' || w.data == 'Language Screen')),
      findsOneWidget,
    );
  });
}
