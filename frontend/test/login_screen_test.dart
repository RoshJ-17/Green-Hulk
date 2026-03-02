import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders essential UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Core UI elements
    expect(find.text('CropCare'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);

    // Two input fields
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Buttons
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });

  testWidgets('Shows validation errors when fields are empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll to make Login button visible
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter your email or phone number'),
      findsOneWidget,
    );

    expect(
      find.text('Please enter your password'),
      findsOneWidget,
    );
  });

  testWidgets('Forgot password dialog opens',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password'), findsOneWidget);
    expect(
      find.textContaining('Password reset functionality'),
      findsOneWidget,
    );
  });
}
