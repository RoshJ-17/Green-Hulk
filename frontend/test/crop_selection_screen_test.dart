import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/crop_selection_screen.dart';
import 'package:sample_app_1/services/app_state.dart';
import 'test_helper.dart';

void main() {
  testWidgets('CropSelectionScreen renders UI correctly',
      (WidgetTester tester) async {
    await mockSharedPreferences();
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      createTestWidget(
        child: const CropSelectionScreen(),
        appState: appState,
      ),
    );

    await tester.pumpAndSettle();

    // Title renders (from L10nService: 'select_your_crops' -> 'Select Your Crops' in English)
    expect(find.text('Select Your Crops'), findsOneWidget);

    // Grid is present
    expect(find.byType(GridView), findsOneWidget);

    // Scan button exists (from L10nService: 'start_scanning' -> 'Start Scanning')
    expect(find.text('Start Scanning'), findsOneWidget);

    // At least one crop name appears
    expect(find.text('Apple'), findsOneWidget);
  });
}
