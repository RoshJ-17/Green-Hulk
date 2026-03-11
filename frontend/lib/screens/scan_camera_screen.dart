import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../screens/treatment_screen.dart';
import '../services/ai_model_service.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../services/camera_service.dart';
import '../services/connectivity_service.dart';
import '../services/history_service.dart';
import '../services/pending_upload_service.dart';
import '../services/video_scan_service.dart';

class ScanCameraScreen extends StatefulWidget {
  /// Pass the English crop name (e.g. "Tomato") for a single-crop scan,
  /// or "any" to let the AI detect the crop from the selected list.
  final String cropName;

  /// If non-null, the AI-predicted species must match one of these crops.
  /// Pass null for unrestricted auto-detect mode.
  final List<String>? selectedCrops;

  const ScanCameraScreen({super.key, required this.cropName, this.selectedCrops});

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

  // Video scan state (US2.4)
  bool _isVideoScanning = false;
  String _videoStatus = '';

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
    _configureTts();

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

  static const _ttsLocaleMap = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'ta': 'ta-IN',
    'te': 'te-IN',
    'kn': 'kn-IN',
    'bn': 'bn-IN',
    'pa': 'pa-IN',
  };

  Future<void> _configureTts() async {
    final appState = context.read<AppState>();
    final langCode  = appState.locale.languageCode;
    final ttsLang   = _ttsLocaleMap[langCode] ?? 'en-IN';
    await tts.setLanguage(ttsLang);
    await tts.setVoice({'name': '', 'locale': ttsLang});
    await tts.setSpeechRate(0.45);
    await tts.setVolume(1.0);
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Offline - Scan saved for sync'),
          backgroundColor: Colors.orange,
        ));
      }

      // ── 4. Analyse ─────────────────────────────────────────────────────
      setState(() => isProcessing = true);
      final result = await AIModelService.analyzeImage(
        imagePath:   xFile.path,
          cropName:      widget.cropName,
          selectedCrops: widget.selectedCrops,
          withHeatmap:   heatmapOn,
      );

      if (!mounted) return;
      // Navigate directly to Treatment screen (TreatmentScreen saves to history)
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TreatmentScreen(result: result),
        ),
      );
      } on WrongCropException catch (e) {
        if (mounted) setState(() => isProcessing = false);
        if (!mounted) return;
        _showWrongCropDialog(context, e);
      } catch (e) {
        if (mounted) setState(() => isProcessing = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    void _showWrongCropDialog(BuildContext context, WrongCropException e) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
              SizedBox(width: 10),
              Text('Wrong Crop', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    const TextSpan(text: 'Detected: '),
                    TextSpan(
                      text: e.predictedSpecies,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('Expected: ${e.selectedCrop}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 10),
              const Text(
                'Scan the correct crop, or switch to auto-detect to identify any plant automatically.',
                style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Try Again'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScanCameraScreen(cropName: 'any'),
                  ),
                );
              },
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Use Auto-Detect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    Future<bool> _showPreviewDialog(Uint8List squareBytes) async { return await
      showDialog(
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
                Text(
                  context.read<AppState>().tr('preview'),
                  style: const TextStyle(
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
                    context.read<AppState>().tr('leaf_frame_hint'),
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
                          label: Text(context.read<AppState>().tr('retake')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          icon: const Icon(Icons.check_circle),
                          label: Text(context.read<AppState>().tr('use_this')),
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
          children: [
            const Icon(Icons.blur_on, color: Colors.orange),
            const SizedBox(width: 8),
            Text(context.read<AppState>().tr('image_too_blurry')),
          ],
        ),
        content: Text(context.read<AppState>().tr('blur_instructions')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.read<AppState>().tr('cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRetry();
            },
            icon: const Icon(Icons.camera_alt),
            label: Text(context.read<AppState>().tr('try_again')),
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
      final appState = context.read<AppState>();
      await _configureTts();
      await tts.speak(appState.tr('voice_guide_text'));
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
      final appState = context.read<AppState>();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(appState.tr('heatmap_will_generate')),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.deepOrange,
      ));
    }
  }

  // ── Video multi-capture scan (US2.4) ───────────────────────────────────
  Future<void> _startVideoScan() async {
    if (controller == null || _initFuture == null || isProcessing || _isVideoScanning) return;

    setState(() {
      _isVideoScanning = true;
      _videoStatus = 'Starting\u2026';
    });

    try {
      await _initFuture;
      final result = await VideoScanService.rapidCaptureAndAnalyze(
        controller:    controller!,
        cropName:      widget.cropName,
        selectedCrops: widget.selectedCrops,
        withHeatmap:   heatmapOn,
        onStatus: (status) {
          if (mounted) setState(() => _videoStatus = status);
        },
      );

      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TreatmentScreen(result: result),
        ),
      );
    } on WrongCropException catch (e) {
      if (mounted) {
        setState(() {
          _isVideoScanning = false;
          _videoStatus = '';
        });
        _showWrongCropDialog(context, e);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideoScanning = false;
          _videoStatus = '';
        });
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Video scan error: $e')));
    }
  }

  // ── Gallery ──────────────────────────────────────────────────────────────

  Future<void> pickFromGallery() async {
    await AudioService.playButtonClick();

    // Pause camera to avoid simultaneous camera + file-picker use.
    await controller?.pausePreview().catchError((_) {});

    final file = await ImagePicker().pickImage(source: ImageSource.gallery);

    // Resume camera if user cancelled without selecting a file.
    if (file == null) {
      await controller?.resumePreview().catchError((_) {});
      return;
    }


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
          cropName:      widget.cropName,
          selectedCrops: widget.selectedCrops,
          withHeatmap:   heatmapOn,
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TreatmentScreen(result: result)),
      );
      } on WrongCropException catch (e) {
        if (mounted) {
          setState(() => isProcessing = false);
          _showWrongCropDialog(context, e);
        }
      } catch (e) {
        if (mounted) setState(() => isProcessing = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.white, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          context.watch<AppState>().tr('offline_scans_cached'),
                          style: const TextStyle(
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
                                children: [
                                  const Icon(
                                    Icons.wifi_off,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.watch<AppState>().tr('offline_mode'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              context.watch<AppState>().tr('scan_plant'),
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
                        child: Text(
                context.watch<AppState>().tr('centre_leaf'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // Video scan status overlay (US2.4)
          if (_isVideoScanning)
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.orange, strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(_videoStatus,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
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

                    /// VIDEO SCAN BUTTON (US2.4)
                    _buildCircleButton(
                      icon: _isVideoScanning ? Icons.hourglass_top : Icons.videocam,
                      color: _isVideoScanning
                          ? Colors.orange
                          : Colors.red.withValues(alpha: 0.8),
                      onTap: _startVideoScan,
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
