import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/history_screen.dart';
import 'package:sample_app_1/services/history_service.dart';
import 'package:sample_app_1/models/scan_result.dart';

void main() {
  setUp(() {
    HistoryService.clear();
  });

  testWidgets('Shows empty state when no history exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No scan history yet'), findsOneWidget);
    expect(find.textContaining('No scans yet'), findsOneWidget);
  });

  testWidgets('Displays history items when present',
      (WidgetTester tester) async {
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
      const MaterialApp(
        home: HistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Tomato - Early Blight'), findsOneWidget);
  });

  testWidgets('Delete dialog appears when swiping item',
      (WidgetTester tester) async {
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
      const MaterialApp(
        home: HistoryScreen(),
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
      const MaterialApp(
        home: HistoryScreen(),
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
    expect(find.text('No scan history yet'), findsOneWidget);
  });
}
