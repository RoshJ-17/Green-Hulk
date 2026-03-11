import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/login_screen.dart';
import 'package:sample_app_1/services/app_state.dart';
import 'test_helper.dart';

void main() {
  testWidgets('LoginScreen renders essential UI',
      (WidgetTester tester) async {
    await mockSharedPreferences();
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      createTestWidget(
        child: const LoginScreen(),
        appState: appState,
      ),
    );

    await tester.pumpAndSettle();

    // Core UI elements
    expect(find.text('CropCare'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);

    // One input field (mobile number)
    expect(find.byType(TextFormField), findsNWidgets(1));

    // Buttons
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget); // FIX: "Sign Up" button text
  });

  testWidgets('Shows validation errors when fields are empty',
      (WidgetTester tester) async {
    await mockSharedPreferences();
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      createTestWidget(
        child: const LoginScreen(),
        appState: appState,
      ),
    );

    await tester.pumpAndSettle();

    // Scroll to make Login button visible
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter your mobile number'),
      findsOneWidget,
    );
  });
}
