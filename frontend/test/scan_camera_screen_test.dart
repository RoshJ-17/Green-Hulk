import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:sample_app_1/screens/scan_camera_screen.dart';
import 'helpers/test_helper.dart';
import 'package:sample_app_1/services/camera_service.dart';

void main() {
  testWidgets('ScanCameraScreen renders basic UI elements when initialized',
      (WidgetTester tester) async {
    // Mock cameras to get past the initial checking logic
    backCamera = const CameraDescription(
      name: 'Test Camera',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );
      
    await tester.pumpWidget(
      await wrapWithProviders(
        const ScanCameraScreen(cropName: 'Tomato'),
        routes: {},
      ),
    );

    // Give it a moment, but keep it simple
    await tester.pump();

    // The screen should render the top bar with crop name
    expect(find.text('Scan Tomato'), findsOneWidget);

    // Focus instruction box
    expect(find.text('Centre the leaf in the box'), findsOneWidget);

    // Toolbar icons
    expect(find.byIcon(Icons.flash_off), findsOneWidget);
    expect(find.byIcon(Icons.whatshot_outlined), findsOneWidget);

    // Bottom action row icons (Mic, Camera shutter, Gallery)
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.byIcon(Icons.photo_library), findsOneWidget);
  });
}
