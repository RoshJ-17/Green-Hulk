import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:sample_app_1/services/app_state.dart';
import 'helpers/test_helper.dart';

void main() {
  testWidgets('SettingsScreen renders profile, language and app sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(
        const SettingsScreen(),
        routes: {
          '/main': (_) => const Scaffold(body: Text('Main Screen')),
          '/login': (_) => const Scaffold(body: Text('Login Screen')),
        },
      ),
    );

    await tester.pumpAndSettle();

    // Check headers and sections
    expect(find.text('Settings'), findsWidgets); // App bar title
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('App'), findsOneWidget);

    // Check key tiles
    expect(find.text('App Language'), findsOneWidget);
    expect(find.text('About CropCare'), findsOneWidget);
  });

  testWidgets('SettingsScreen expands language picker',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(
        const SettingsScreen(),
        routes: {
          '/main': (_) => const Scaffold(body: Text('Main Screen')),
        },
      ),
    );

    await tester.pumpAndSettle();

    // Language picker should initially not be visible
    expect(find.text('हिन्दी'), findsNothing);

    // Tap the App Language tile
    await tester.tap(find.text('App Language'));
    await tester.pumpAndSettle();

    // Language options should now be visible
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
  });

  testWidgets('SettingsScreen opens About dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(
        const SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the About CropCare tile
    await tester.tap(find.text('About CropCare'));
    await tester.pumpAndSettle();

    // Dialog should appear
    expect(find.text('CropCare uses AI to diagnose plant diseases from photos.\n\nVersion 1.0.0\nBuilt with Flutter & Machine Learning'), findsOneWidget);
    
    // Tap Close
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    
    // Dialog should be dismissed
    expect(find.text('CropCare uses AI to diagnose plant diseases from photos.\n\nVersion 1.0.0\nBuilt with Flutter & Machine Learning'), findsNothing);
  });
}
