import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/splash_screen.dart';
import 'helpers/test_helper.dart';

void main() {
  testWidgets('SplashScreen renders UI correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(
        const SplashScreen(),
        routes: {
          '/language': (_) => const Scaffold(body: Text('Language Screen')),
          '/login': (_) => const Scaffold(body: Text('Login Screen')),
        },
      ),
    );

    await tester.pump(); // First frame

    // Check UI elements
    expect(find.text('CropCare'), findsOneWidget);
    expect(find.text('AI Crop Disease Diagnosis'), findsOneWidget);
    
    // SplashScreen uses an image asset
    expect(find.byType(Image), findsOneWidget);

    // Let timer finish to avoid pending timer error
    await tester.pump(const Duration(seconds: 3));
    
    // We don't use pumpAndSettle because CircularProgressIndicator animates infinitely
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('SplashScreen navigates to login after 2 seconds',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(
        const SplashScreen(),
        mockPrefs: {'has_selected_language': true},
        routes: {
          '/language': (_) => const Scaffold(body: Text('Language Screen')),
          '/login': (_) => const Scaffold(body: Text('Login Screen')),
        },
      ),
    );

    await tester.pump(); // Start timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    
    expect(find.text('Login Screen'), findsOneWidget);
  });
}
