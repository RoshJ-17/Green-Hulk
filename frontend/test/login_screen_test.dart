import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/login_screen.dart';
import 'helpers/test_helper.dart';

void main() {
  testWidgets('LoginScreen renders essential UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(const LoginScreen()),
    );

    await tester.pumpAndSettle();

    // Core UI elements
    expect(find.text('CropCare'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login to continue'), findsOneWidget);

    // One input field in Step 1 (Phone)
    expect(find.byType(TextFormField), findsOneWidget);

    // Buttons
    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('Shows validation errors when fields are empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(const LoginScreen()),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter your mobile number'),
      findsOneWidget,
    );
  });

  testWidgets('Input number and tap Send OTP switches to Step 2',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await wrapWithProviders(const LoginScreen()),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '9876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    // Check if we are now in Step 2
    expect(find.text('Verify Phone'), findsOneWidget);
    expect(find.textContaining('9876543210'), findsWidgets);
    expect(find.text('Verify & Login'), findsOneWidget);
  });
}
