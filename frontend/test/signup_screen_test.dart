import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/signup_screen.dart';
import 'package:sample_app_1/services/app_state.dart';
import 'test_helper.dart';

void main() {
  testWidgets('SignupScreen renders essential UI',
      (WidgetTester tester) async {
    await mockSharedPreferences();
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      createTestWidget(
        child: const SignupScreen(),
        appState: appState,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Join CropCare'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget); // AppBar title
    expect(find.text('Already have an account? '), findsOneWidget);
  });

  testWidgets('Shows validation errors when fields are empty',
      (WidgetTester tester) async {
    await mockSharedPreferences();
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      createTestWidget(
        child: const SignupScreen(),
        appState: appState,
      ),
    );

    await tester.pumpAndSettle();

    final sendOtpButton = find.text('Send OTP');

    await tester.ensureVisible(sendOtpButton);
    await tester.tap(sendOtpButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your phone number'), findsOneWidget);
  });
}
