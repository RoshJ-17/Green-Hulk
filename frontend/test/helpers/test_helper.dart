import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample_app_1/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Globally disables real HTTP calls in tests to prevent side effects
/// and ensure tests are fast and deterministic.
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

/// Wraps a widget with the necessary providers and configuration for testing.
/// 
/// This helper:
/// 1. Disables real network calls via [MockHttpOverrides].
/// 2. Mocks [SharedPreferences] with [mockPrefs].
/// 3. Provides an [AppState] instance to the widget tree.
/// 4. Wraps the [child] in a [MaterialApp] with the specified [routes].
Future<Widget> wrapWithProviders(
  Widget child, {
  AppState? appState,
  Map<String, Object>? mockPrefs,
  Map<String, WidgetBuilder>? routes,
}) async {
  // Ensure network calls are mocked
  HttpOverrides.global = MockHttpOverrides();
  
  // Set initial mock values for SharedPreferences
  SharedPreferences.setMockInitialValues(mockPrefs ?? {});
  
  // Initialize or use provided AppState
  final state = appState ?? AppState();
  if (appState == null) {
    await state.init();
  }

  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(
      home: child,
      debugShowCheckedModeBanner: false,
      routes: routes ?? {},
      onGenerateRoute: routes == null 
        ? (settings) => MaterialPageRoute(builder: (_) => child)
        : null,
    ),
  );
}
