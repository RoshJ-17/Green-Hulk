import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/crop_selection_screen.dart';

void main() {
  testWidgets('CropSelectionScreen renders UI correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CropSelectionScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Title renders
    expect(find.text('Select Your Crops'), findsOneWidget);

    // Grid is present
    expect(find.byType(GridView), findsOneWidget);

    // Scan button exists
    expect(find.textContaining('Scanning'), findsOneWidget);

    // At least one crop name appears
    expect(find.text('Apple'), findsOneWidget);
  });
}
