import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sample_app_1/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots without crashing', (WidgetTester tester) async {
    app.main();

    
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // If we reached here without exception, test passes
    expect(true, true);
  });
}