import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sample_app_1/main.dart' as app;
import 'package:sample_app_1/services/app_state.dart';
import 'package:sample_app_1/services/history_service.dart';
import 'package:provider/provider.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(seconds: 1);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MockHttpOverrides();

  group('End-to-End App Test', () {
    testWidgets('Complete user flow: Login -> Dashboard -> History',
        (WidgetTester tester) async {
      debugPrint('Starting App...');
      app.main();
      await tester.pumpAndSettle();

      debugPrint('Waiting for Splash Screen...');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 3. Login Flow (Step 1: Phone)
      if (find.text('Welcome Back').evaluate().isNotEmpty) {
        debugPrint('At Login Screen Step 1');
        await tester.enterText(find.byType(TextFormField), '9876543210');
        await tester.tap(find.text('Send OTP'));
        await tester.pumpAndSettle();

        debugPrint('At Login Screen Step 2 (OTP)');
        expect(find.text('Verify Phone'), findsOneWidget);
        
        // Enter 123456 into the 6 boxes
        // In LoginScreen, the firstFormField is Phone, then 6 OTP fields appear
        for (int i = 0; i < 6; i++) {
          final otpField = find.byType(TextField).at(i);
          await tester.enterText(otpField, (i + 1).toString());
          await tester.pump(const Duration(milliseconds: 100));
        }
        
        await tester.pumpAndSettle();
      }

      debugPrint('Checking for Dashboard...');
      await tester.pumpAndSettle();
      
      // The Dashboard has "Dashboard" in the bottom nav or app bar
      expect(find.text('Dashboard'), findsWidgets);
      
      debugPrint('Navigating to History...');
      final historyTab = find.byIcon(Icons.history_rounded);
      if (historyTab.evaluate().isNotEmpty) {
        await tester.tap(historyTab);
        await tester.pumpAndSettle();
        expect(find.text('Scan History'), findsOneWidget);
        debugPrint('At History Screen');
      }

      debugPrint('Navigating back to Dashboard...');
      final dashTab = find.byIcon(Icons.dashboard_outlined);
      if (dashTab.evaluate().isNotEmpty) {
        await tester.tap(dashTab);
        await tester.pumpAndSettle();
        debugPrint('Back at Dashboard');
      }

      expect(find.text('Scan Crop'), findsOneWidget);
      debugPrint('Test Finished Successfully');
    });
  });
}
