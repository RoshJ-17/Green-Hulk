import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/screens/signup_screen.dart';

void main() {
  testWidgets('SignupScreen renders essential UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignupScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Join CropCare'), findsOneWidget);
    expect(find.text('Create Account'), findsNWidgets(2)); // AppBar + Button
    expect(find.text('Already have an account? '), findsOneWidget);
  });

  testWidgets('Shows validation errors when fields are empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignupScreen(),
      ),
    );

    await tester.pumpAndSettle();

    final createButton = find.widgetWithText(
        ElevatedButton, 'Create Account');

    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your phone number'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);
  });

  testWidgets('Password visibility toggle works',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignupScreen(),
      ),
    );

    await tester.pumpAndSettle();

    EditableText editable =
        tester.widget(find.byType(EditableText).last);
    expect(editable.obscureText, true);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    editable = tester.widget(find.byType(EditableText).last);
    expect(editable.obscureText, false);
  });

  testWidgets('Password validation rules work correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignupScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Enter short password
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '123');

    final createButton = find.widgetWithText(
        ElevatedButton, 'Create Account');

    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 6 characters'),
        findsOneWidget);

    // Enter password without number
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'abcdef');

    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Password must contain at least one number'),
        findsOneWidget);
  });
}
