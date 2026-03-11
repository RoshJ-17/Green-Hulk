import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/map_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'helpers/test_helper.dart';

void main() {
  testWidgets('MapScreen renders tabs and basic UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(
        const MapScreen(),
        routes: {},
      ),
    );

    await tester.pumpAndSettle();

    // App header
    expect(find.text('Crop Health Map'), findsOneWidget);

    // Default tab check (Map View)
    expect(find.text('Legend'), findsOneWidget);
    expect(find.text('Post to Map'), findsOneWidget);

    // Map widget should be present
    expect(find.byType(GoogleMap), findsWidgets);
  });

  testWidgets('MapScreen can switch to Soil tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(
        const MapScreen(),
        routes: {},
      ),
    );

    await tester.pumpAndSettle();

    // Tap Soil tab
    await tester.tap(find.text('Soil'));
    await tester.pumpAndSettle();

    // Verify Soil specific content
    expect(find.text('Soil Information'), findsOneWidget);
  });
}
