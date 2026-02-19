import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders UI correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login Screen')),
        },
        home: const SplashScreen(),
      ),
    );

    await tester.pump(); // First frame

    // Check UI elements
    expect(find.text('CropCare'), findsOneWidget);
    expect(find.text('AI Crop Disease Diagnosis'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Let timer finish to avoid pending timer error
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen navigates to login after 2 seconds',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login Screen')),
        },
        home: const SplashScreen(),
      ),
    );

    await tester.pump(); // Start timer
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });
}
