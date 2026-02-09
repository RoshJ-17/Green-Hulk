import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

List<CameraDescription> cameras = [];
CameraDescription? backCamera;

Future<void> initCameras() async {
  try {
    cameras = await availableCameras();

    if (cameras.isNotEmpty) {
       // pick back camera safely
      backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
    } else {
      debugPrint("No cameras found");
      // Ideally handled by UI not letting user go to scan screen, 
      // but to prevent crash we just don't set backCamera or handle it.
      // ScanCameraScreen expects backCamera to be set. 
      // We'll leave it but ScanCameraScreen needs to check too.
    }
  } catch (e) {
    debugPrint("Camera initialization failed: $e");
    cameras = [];
  }
}
