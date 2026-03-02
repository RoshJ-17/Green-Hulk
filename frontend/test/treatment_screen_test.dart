import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/treatment_screen.dart';
import 'package:sample_app_1/models/scan_result.dart';

void main() {
  // Create a healthy scan result that matches your model
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

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      routes: {
        '/crops': (context) =>
            const Scaffold(body: Center(child: Text("Crops Screen"))),
      },
      home: child,
    );
  }

  testWidgets("TreatmentScreen renders healthy state correctly",
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        TreatmentScreen(result: createHealthyResult()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("Healthy Crop!"), findsOneWidget);
    expect(find.text("No treatment plan is currently needed."), findsOneWidget);
  });

  testWidgets("Tabs are visible",
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        TreatmentScreen(result: createHealthyResult()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("Treatments"), findsOneWidget);
    expect(find.text("Prevention"), findsOneWidget);
    expect(find.text("Remedies"), findsOneWidget);
  });

  testWidgets("Rating stars update and show snackbar",
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        TreatmentScreen(result: createHealthyResult()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.star_border).at(2));
    await tester.pump();

    expect(find.textContaining("Thanks for the reward!"), findsOneWidget);
  });

  testWidgets("New Scan button navigates correctly",
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        TreatmentScreen(result: createHealthyResult()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text("New Scan"));
    await tester.pumpAndSettle();

    expect(find.text("Crops Screen"), findsOneWidget);
  });
}
