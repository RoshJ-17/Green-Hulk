import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample_app_1/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Globally disables real HTTP calls in tests.
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

/// Wraps a widget with the necessary providers for testing.
/// Also initializes SharedPreferences with mock values.
Future<Widget> wrapWithProviders(
  Widget child, {
  AppState? appState,
  Map<String, Object>? mockPrefs,
  Map<String, WidgetBuilder>? routes,
}) async {
  HttpOverrides.global = MockHttpOverrides();
  SharedPreferences.setMockInitialValues(mockPrefs ?? {});
  
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
