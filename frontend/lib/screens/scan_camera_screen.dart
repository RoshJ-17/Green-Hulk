import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../models/scan_result.dart';
import '../screens/treatment_screen.dart';
import '../services/ai_model_service.dart';
import '../services/audio_service.dart';
import '../services/camera_service.dart';
import '../services/connectivity_service.dart';
import '../services/history_service.dart';
import '../services/pending_upload_service.dart';

class ScanCameraScreen extends StatefulWidget {
  final String cropName;

  const ScanCameraScreen({super.key, required this.cropName});

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen>
    with SingleTickerProviderStateMixin {
  // ── Camera ──────────────────────────────────────────────────────────────
  CameraController? controller;
  Future<void>? _initFuture;

  // ── UI state ─────────────────────────────────────────────────────────────
  bool flashOn       = false;
  bool heatmapOn     = false;
  bool isProcessing  = false;
  bool speaking      = false;
  bool _isOffline    = false;

  /// Live blur warning shown while the user is framing the shot.
  bool _blurWarning  = false;

  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;
  late FlutterTts           tts;

  // ── Blur-detection state ──────────────────────────────────────────────
  /// Minimum Laplacian variance accepted as "sharp enough" (same threshold
  /// the backend quality-checker uses).
  static const double _blurThreshold = 100.0;

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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No camera found')));
      return;
    }
    controller = CameraController(
      backCamera!,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initFuture = controller!.initialize();
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

  // ── Blur detection ──────────────────────────────────────────────────────

  /// Compute Laplacian variance of a decoded image (same algorithm as backend).
  double _laplacianVariance(img.Image grey) {
    final w = grey.width;
    final h = grey.height;
    double sum  = 0;
    double sumSq = 0;
    int count   = 0;

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final c = grey.getPixel(x,   y  ).r.toDouble();
        final t = grey.getPixel(x,   y-1).r.toDouble();
        final b = grey.getPixel(x,   y+1).r.toDouble();
        final l = grey.getPixel(x-1, y  ).r.toDouble();
        final r = grey.getPixel(x+1, y  ).r.toDouble();
        final v = (t + b + l + r - 4 * c).abs();
        sum   += v;
        sumSq += v * v;
        count++;
      }
    }
    if (count == 0) return 9999;
    final mean = sum / count;
    return sumSq / count - mean * mean; // variance
  }

  Future<bool> _checkBlur(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return false;
    final thumb = img.copyResize(decoded, width: 200, height: 200);
    final grey  = img.grayscale(thumb);
    final score = _laplacianVariance(grey);
    return score < _blurThreshold;
  }

  // ── Capture pipeline ────────────────────────────────────────────────────
  Future<void> captureImage() async {
    if (controller == null || _initFuture == null || isProcessing) return;

    setState(() => isProcessing = true);

    try {
      await AudioService.playCameraShutter();
      await _initFuture;
      final xFile = await controller!.takePicture();
      final bytes = await xFile.readAsBytes();

      // ── 1. Blur check ──────────────────────────────────────────────────
      final isBlurry = await _checkBlur(bytes);
      if (isBlurry) {
        if (!mounted) return;
        setState(() => isProcessing = false);
        _showBlurWarningDialog(onRetry: captureImage);
        return;
      }

      // ── 2. Square-crop preview ─────────────────────────────────────────
      if (!mounted) return;
      final confirmed = await _showPreviewDialog(bytes);
      if (!confirmed) {
        setState(() => isProcessing = false);
        return; // user tapped "Retake"
      }

      // ── 3. Offline path ────────────────────────────────────────────────
      if (_isOffline) {
        await PendingUploadService.addPendingUpload(
          imagePath: xFile.path,
          cropName:  widget.cropName,
          heatmap:   heatmapOn,
        );
        final offlineResult = ScanResult(
          cropName:    widget.cropName,
          diseaseName: 'Offline Scan (Queued)',
          confidence:  0.0,
          imagePath:   xFile.path,
          hasDisease:  true,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Scan saved! Will process when online.'),
          backgroundColor: Colors.orange,
        ));
        Navigator.pop(context, offlineResult);
        return;
      }

      // ── 4. Analyse ─────────────────────────────────────────────────────
      setState(() => isProcessing = true);
      final result = await AIModelService.analyzeImage(
        imagePath:   xFile.path,
        cropName:    widget.cropName,
        withHeatmap: heatmapOn,
      );
      HistoryService.addResult(result);

      if (!mounted) return;
      // Navigate directly to Treatment screen
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TreatmentScreen(result: result),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Square-crop preview dialog ──────────────────────────────────────────

  /// Crops the image to a centred square, shows a preview and waits for the
  /// user to confirm ("Use this") or retake.
  Future<bool> _showPreviewDialog(Uint8List rawBytes) async {
    final squareBytes = await _squareCrop(rawBytes);
    if (!mounted) return false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Preview',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      squareBytes,
                      width: 260,
                      height: 260,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Does the leaf fill the frame clearly?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          icon: const Icon(Icons.replay),
                          label: const Text('Retake'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Use this'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<Uint8List> _squareCrop(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final s    = decoded.width < decoded.height ? decoded.width : decoded.height;
    final xOff = (decoded.width  - s) ~/ 2;
    final yOff = (decoded.height - s) ~/ 2;
    final cropped = img.copyCrop(decoded,
        x: xOff, y: yOff, width: s, height: s);
    final thumb = img.copyResize(cropped, width: 300, height: 300);
    return Uint8List.fromList(img.encodeJpg(thumb, quality: 90));
  }

  // ── Blur warning dialog ─────────────────────────────────────────────────

  void _showBlurWarningDialog({required VoidCallback onRetry}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.blur_on, color: Colors.orange),
            SizedBox(width: 8),
            Text('Image Too Blurry'),
          ],
        ),
        content: const Text(
          'The photo looks out of focus.\n\n'
          '• Hold the camera still\n'
          '• Tap the screen to focus on the leaf\n'
          '• Make sure there is enough light',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRetry();
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  // ── Voice guide ─────────────────────────────────────────────────────────
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

  // ── Heatmap toggle ───────────────────────────────────────────────────────

  void toggleHeatmap() {
    setState(() => heatmapOn = !heatmapOn);
    AudioService.playButtonClick();
    if (heatmapOn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Grad-CAM heatmap will be generated after scan'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.deepOrange,
      ));
    }
  }

  // ── Gallery ──────────────────────────────────────────────────────────────

  Future<void> pickFromGallery() async {
    await AudioService.playButtonClick();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes    = await file.readAsBytes();
    final isBlurry = await _checkBlur(bytes);

    if (isBlurry && mounted) {
      _showBlurWarningDialog(onRetry: pickFromGallery);
      return;
    }

    if (!mounted) return;
    final confirmed = await _showPreviewDialog(bytes);
    if (!confirmed) return;

    setState(() => isProcessing = true);
    try {
      final result = await AIModelService.analyzeImage(
        imagePath:   file.path,
        cropName:    widget.cropName,
        withHeatmap: heatmapOn,
      );
      HistoryService.addResult(result);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TreatmentScreen(result: result)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: _initFuture != null
                ? FutureBuilder(
                    future: _initFuture,
                    builder: (_, s) =>
                        s.connectionState == ConnectionState.done
                            ? CameraPreview(controller!)
                            : const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.green)),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.green)),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),

          // ── Blur warning banner (live) ─────────────────────────────────
          if (_blurWarning)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.blur_on, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Image too blurry — hold steady & tap to focus',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Focus box
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final boxColor = isProcessing
                    ? Colors.orange.withValues(alpha: _pulseAnimation.value)
                    : Colors.green.withValues(alpha: _pulseAnimation.value);
                return Container(
                  width: boxSize,
                  height: boxSize * 1.2,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: boxColor,
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
                                'Analysing…',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : null,
                );
              },
            ),
          ),

          // Top bar
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

          // Instruction label
          Align(
            alignment: const Alignment(0, -0.7),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Centre the leaf in the box',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // Bottom controls
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
