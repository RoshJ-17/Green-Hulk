import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/main.dart';
import 'package:sample_app_1/services/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // We do NOT call appState.init() here as it might trigger hangs
    // or real network calls if environment detection is tricky.
    // The default AppState is enough for a smoke test.
    final appState = AppState();

    // Build our app
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const CropDiagnosisApp(),
      ),
    );
    
    // SplashScreen has a 2-second delay in initState.
    // We must pump enough time to clear this timer, or the test fails.
    await tester.pump(const Duration(seconds: 2)); 

    // Verify splash screen content
    expect(find.text('CropCare'), findsOneWidget);
    expect(find.text('AI Crop Disease Diagnosis'), findsOneWidget);
  });
}
