import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sample_app_1/services/app_state.dart';

/// Wraps a widget with the necessary providers for testing.
Widget createTestWidget({
  required Widget child,
  AppState? appState,
  bool includeMaterialApp = true,
  Map<String, WidgetBuilder>? routes,
}) {
  final content = ChangeNotifierProvider<AppState>.value(
    value: appState ?? AppState(),
    child: child,
  );

  if (includeMaterialApp) {
    return MaterialApp(
      routes: routes ?? {},
      home: Scaffold(body: content),
    );
  }
  return content;
}

/// Mocks SharedPreferences for testing.
Future<void> mockSharedPreferences() async {
  SharedPreferences.setMockInitialValues({});
}
