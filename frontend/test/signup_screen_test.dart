import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/signup_screen.dart';
import 'helpers/test_helper.dart';

void main() {
  testWidgets('SignupScreen renders essential UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(const SignupScreen()),
    );

    await tester.pumpAndSettle();

    expect(find.text('Join CropCare'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget); // AppBar
    expect(find.text('Already have an account? '), findsOneWidget);
    expect(find.text('Login'), findsOneWidget); // TextButton
  });

  testWidgets('Shows validation errors when fields are empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(const SignupScreen()),
    );

    await tester.pumpAndSettle();

    final sendOtpButton = find.widgetWithText(
        ElevatedButton, 'Send OTP');

    await tester.ensureVisible(sendOtpButton);
    await tester.tap(sendOtpButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your phone number'), findsOneWidget);
  });

  testWidgets('Enter details and tap Send OTP switches to Step 2',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(const SignupScreen()),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number'), '9876543210');
    
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Verify Phone'), findsWidgets);
    expect(find.textContaining('9876543210'), findsWidgets);
    expect(find.text('Verify & Create Account'), findsOneWidget);
  });
}
