import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sample_app_1/main.dart' as app;

/**
 * Frontend Integration Tests
 */
void main() {
  // Initialize the integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /**
   * Smoke Test: App Boot
   * Verifies that the app starts without crashing.
   */
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    // Start the app
    app.main();

    // Wait for the app to settle and animations to finish
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // If we reached here without exception, test passes
    expect(true, true);
  });
}