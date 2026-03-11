import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/treatment_screen.dart';
import 'package:sample_app_1/models/scan_result.dart';
import 'package:sample_app_1/services/app_state.dart';
import 'test_helper.dart';

void main() {
  setUp(() async {
    await mockSharedPreferences();
  });

  ScanResult createHealthyResult() {
    return ScanResult(
      id: "1",
      imagePath: "test_image.jpg",
      cropName: "Tomato",
      diseaseName: "Healthy",
      confidence: 0.95,
      hasDisease: false,
      date: DateTime.now(),
    );
  }

  testWidgets("TreatmentScreen renders healthy state correctly",
      (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      createTestWidget(
        child: TreatmentScreen(result: createHealthyResult()),
        appState: appState,
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text("Healthy Crop!"), findsOneWidget);
    expect(find.text("No treatment plan is currently needed."), findsOneWidget);
  });

  testWidgets("Tabs are visible",
      (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      createTestWidget(
        child: TreatmentScreen(result: createHealthyResult()),
        appState: appState,
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text("Treatments"), findsOneWidget);
    expect(find.text("Prevention"), findsOneWidget);
    expect(find.text("Remedies"), findsOneWidget);
  });

  testWidgets("Rating stars update and show snackbar",
      (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      createTestWidget(
        child: TreatmentScreen(result: createHealthyResult()),
        appState: appState,
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    // Tap a star
    await tester.tap(find.byIcon(Icons.star_border).at(2));
    await tester.pump();

    expect(find.textContaining("Thanks for the reward!"), findsOneWidget);
  });
}
