import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/dashboard_screen.dart';
import 'helpers/test_helper.dart';

void main() {
  testWidgets('DashboardScreen renders greeting and stats',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(
        const DashboardScreen(),
        routes: {
          '/settings': (_) => const Scaffold(body: Text('Settings Screen')),
          '/history': (_) => const Scaffold(body: Text('History Screen')),
          '/crops': (_) => const Scaffold(body: Text('Crop Selection')),
        },
      ),
    );

    await tester.pumpAndSettle();

    // Check greeting text is present (Good morning/afternoon/evening)
    expect(find.textContaining('Good'), findsOneWidget);
    
    // Check key static text
    expect(find.text('Your Activity'), findsOneWidget);
    expect(find.text('Total Scans'), findsOneWidget);
    expect(find.text('Diseased Plants'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Scan Crop'), findsOneWidget);
    expect(find.text('Scan History'), findsOneWidget);
    
    // Check crop banner add button
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('DashboardScreen navigates to history',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(
        const DashboardScreen(),
        routes: {
          '/settings': (_) => const Scaffold(body: Text('Settings Screen')),
          '/history': (_) => const Scaffold(body: Text('History Screen')),
          '/crops': (_) => const Scaffold(body: Text('Crop Selection')),
        },
      ),
    );

    await tester.pumpAndSettle();
    
    final historyBtn = find.text('Scan History');
    await tester.ensureVisible(historyBtn);
    await tester.tap(historyBtn);
    await tester.pumpAndSettle();

    expect(find.text('History Screen'), findsOneWidget);
  });

  testWidgets('DashboardScreen navigates to settings when profile icon tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(
        const DashboardScreen(),
        routes: {
          '/settings': (_) => const Scaffold(body: Text('Settings Screen')),
          '/history': (_) => const Scaffold(body: Text('History Screen')),
          '/crops': (_) => const Scaffold(body: Text('Crop Selection')),
        },
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.account_circle));
    await tester.pumpAndSettle();

    expect(find.text('Settings Screen'), findsOneWidget);
  });
}
