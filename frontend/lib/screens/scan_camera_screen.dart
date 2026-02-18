import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/history_service.dart';
import '../services/pending_upload_service.dart';
import '../services/ai_model_service.dart';
import '../services/audio_service.dart';
import '../services/connectivity_service.dart';
import '../services/camera_service.dart';
import '../models/scan_result.dart';

class ScanCameraScreen extends StatefulWidget {
  final String cropName;

  const ScanCameraScreen({super.key, required this.cropName});

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? controller;
  Future<void>? initializeControllerFuture;
  late FlutterTts tts;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool flashOn = false;
  bool heatmapOn = false;
  bool isProcessing = false;
  bool speaking = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    tts = FlutterTts();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initCamera();
    _initConnectivity();
    _initAIModel();
  }

  Future<void> _initConnectivity() async {
    _isOffline = ConnectivityService.isOffline;

    ConnectivityService.addListener((isOnline) async {
      if (!mounted) return;
      setState(() => _isOffline = !isOnline);

      if (isOnline) {
        await HistoryService.fetchHistory();
      }
    });
  }

  Future<void> _initAIModel() async {
    await AIModelService.initialize();
  }

  Future<void> _initCamera() async {
    if (backCamera == null) await initCameras();

    if (backCamera == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No camera found")));
      return;
    }

    controller = CameraController(
      backCamera!,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    initializeControllerFuture = controller!.initialize();

    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller?.dispose();
    tts.stop();
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------- CAPTURE ----------------
  Future<void> captureImage() async {
    if (controller == null || initializeControllerFuture == null) return;

    setState(() => isProcessing = true);

    try {
      await AudioService.playCameraShutter();
      await initializeControllerFuture;
      final image = await controller!.takePicture();

      if (_isOffline) {
        // Save to pending queue
        await PendingUploadService.addPendingUpload(
          imagePath: image.path,
          cropName: widget.cropName,
          heatmap: heatmapOn,
        );

        final offlineResult = ScanResult(
          cropName: widget.cropName,
          diseaseName: "Offline Scan (Queued)",
          confidence: 0.0,
          imagePath: image.path,
          hasDisease: true,
        );

        if (!mounted) return;

        // Show visual feedback for capture even when offline
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Scan saved! Will process when online."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, offlineResult);
        return;
      }

      // Visual feedback: border glow/flash effect
      if (mounted) {
        setState(() => isProcessing = true);
      }

      final result = await _analyzeImageWithAI(image.path);
      HistoryService.addResult(result);

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (mounted) setState(() => isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<ScanResult> _analyzeImageWithAI(String imagePath) async {
    try {
      if (_isOffline) {
        return ScanResult(
          cropName: widget.cropName,
          diseaseName: "Offline Scan (Will Verify Online)",
          confidence: 0.50,
          imagePath: imagePath,
          hasDisease: true,
        );
      }

      return await AIModelService.analyzeImage(
        imagePath: imagePath,
        cropName: widget.cropName,
      );
    } catch (e) {
      debugPrint("Analysis error: $e");
      // Fallback result for demo/error handling
      return ScanResult(
        cropName: widget.cropName,
        diseaseName: "Analysis Failed",
        confidence: 0.0,
        imagePath: imagePath,
        hasDisease: false,
      );
    }
  }

  // ---------- VOICE ----------
  Future<void> toggleVoiceGuide() async {
    if (speaking) {
      await tts.stop();
      setState(() => speaking = false);
    } else {
      await tts.speak("Align the leaf inside the outline and hold steady");
      setState(() => speaking = true);
    }
  }

  // ---------- FLASH ----------
  Future<void> toggleFlash() async {
    if (controller == null) return;
    setState(() => flashOn = !flashOn);
    await controller!.setFlashMode(flashOn ? FlashMode.torch : FlashMode.off);
  }

  // ---------- HEATMAP ----------
  void toggleHeatmap() {
    setState(() => heatmapOn = !heatmapOn);
    AudioService.playButtonClick();
  }

  // ---------- GALLERY ----------
  Future<void> pickFromGallery() async {
    await AudioService.playButtonClick();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => isProcessing = true);
    final result = await _analyzeImageWithAI(file.path);
    HistoryService.addResult(result);

    if (!mounted) return;
    Navigator.pop(context, result);
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// CAMERA PREVIEW
          Positioned.fill(
            child: initializeControllerFuture != null
                ? FutureBuilder(
                    future: initializeControllerFuture,
                    builder: (_, s) => s.connectionState == ConnectionState.done
                        ? CameraPreview(controller!)
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.green,
                            ),
                          ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
          ),

          /// SEMI-TRANSPARENT OVERLAY
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),

          /// FOCUS BOX (GREEN RECTANGLE)
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: boxSize,
                  height: boxSize * 1.2,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isProcessing
                          ? Colors.orange.withValues(
                              alpha: _pulseAnimation.value,
                            )
                          : Colors.green.withValues(
                              alpha: _pulseAnimation.value,
                            ),
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (isProcessing ? Colors.orange : Colors.green)
                            .withValues(alpha: 0.3 * _pulseAnimation.value),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: isProcessing
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 12),
                              Text(
                                "Analyzing...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                );
              },
            ),
          ),

          /// TOP BAR
          SafeArea(
            child: Column(
              children: [
                if (_isOffline)
                  Container(
                    width: double.infinity,
                    color: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 14),
                        SizedBox(width: 8),
                        Text(
                          "YOU ARE OFFLINE - SCANS WILL BE CACHED",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      _isOffline
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.wifi_off,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "OFFLINE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              "Scan ${widget.cropName}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              heatmapOn
                                  ? Icons.whatshot
                                  : Icons.whatshot_outlined,
                              color: heatmapOn ? Colors.orange : Colors.white,
                            ),
                            onPressed: toggleHeatmap,
                          ),
                          IconButton(
                            icon: Icon(
                              flashOn ? Icons.flash_on : Icons.flash_off,
                              color: flashOn ? Colors.yellow : Colors.white,
                            ),
                            onPressed: toggleFlash,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// INSTRUCTION TEXT
          Align(
            alignment: const Alignment(0, -0.7),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Center the leaf in the box",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          /// BOTTOM CONTROLS
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircleButton(
                      icon: speaking ? Icons.stop : Icons.mic,
                      color: speaking
                          ? Colors.red
                          : Colors.blue.withValues(alpha: 0.8),
                      onTap: toggleVoiceGuide,
                    ),

                    /// CAPTURE BUTTON
                    GestureDetector(
                      onTap: isProcessing ? null : captureImage,
                      child: Container(
                        width: 90,
                        height: 90,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: isProcessing
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.green,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.green,
                                  size: 40,
                                ),
                        ),
                      ),
                    ),

                    _buildCircleButton(
                      icon: Icons.photo_library,
                      color: Colors.purple.withValues(alpha: 0.8),
                      onTap: pickFromGallery,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
