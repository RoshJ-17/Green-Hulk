import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/history_screen.dart';
import 'package:sample_app_1/services/history_service.dart';
import 'package:sample_app_1/models/scan_result.dart';
import 'package:sample_app_1/services/app_state.dart';
import 'test_helper.dart';

void main() {
  setUp(() async {
    await mockSharedPreferences();
    HistoryService.clear();
  });

  testWidgets('Shows empty state when no history exists',
      (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      createTestWidget(
        child: const HistoryScreen(),
        appState: appState,
      ),
    );

    await tester.pumpAndSettle();

    // Corrected strings based on HistoryScreen code
    expect(find.text('No scans yet.'), findsOneWidget);
    expect(find.text('Start by scanning a crop!'), findsOneWidget);
  });

  testWidgets('Displays history items when present',
      (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    // Add fake history item
    HistoryService.addResult(
      ScanResult(
        cropName: 'Tomato',
        diseaseName: 'Early Blight',
        confidence: 0.92,
        imagePath: 'test.jpg',
        hasDisease: true,
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        child: const HistoryScreen(),
        appState: appState,
      ),
    );

    await tester.pumpAndSettle();

    // Find strings separately as they are in different Text widgets
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('Early Blight'), findsOneWidget);
  });

  testWidgets('Delete dialog appears when swiping item',
      (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    HistoryService.addResult(
      ScanResult(
        cropName: 'Corn',
        diseaseName: 'Rust',
        confidence: 0.85,
        imagePath: 'test.jpg',
        hasDisease: true,
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        child: const HistoryScreen(),
        appState: appState,
      ),
    );

    await tester.pumpAndSettle();

    // Swipe to trigger dismiss
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete Scan?'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Confirm delete removes item',
      (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    HistoryService.addResult(
      ScanResult(
        cropName: 'Apple',
        diseaseName: 'Scab',
        confidence: 0.80,
        imagePath: 'test.jpg',
        hasDisease: true,
      ),
    );

    await tester.pumpWidget(
      createTestWidget(
        child: const HistoryScreen(),
        appState: appState,
      ),
    );

    await tester.pumpAndSettle();

    // Swipe
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Confirm delete
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Now empty state should appear
    expect(find.text('No scans yet.'), findsOneWidget);
  });
}
