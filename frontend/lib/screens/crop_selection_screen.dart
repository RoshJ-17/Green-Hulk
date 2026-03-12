import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../config/crop_data.dart';
import '../services/voice_search_service.dart';
import '../services/audio_service.dart';
import '../services/connectivity_service.dart';
import 'scan_camera_screen.dart';

// Keep the local alias so the rest of the file compiles without renaming.
const crops = kCrops;

class CropSelectionScreen extends StatefulWidget {
  const CropSelectionScreen({super.key});

  @override
  State<CropSelectionScreen> createState() => _CropSelectionScreenState();
}

class _CropSelectionScreenState extends State<CropSelectionScreen> {
  bool _isListening = false;
  String _recognizedText = '';
  String? _detectedKeyword;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await VoiceSearchService.initialize();
    await ConnectivityService.initialize();

    ConnectivityService.addListener((isOnline) {
      if (mounted) {
        setState(() => _isOffline = !isOnline);
      }
    });

    if (mounted) {
      setState(() => _isOffline = ConnectivityService.isOffline);
    }
  }

  @override
  void dispose() {
    VoiceSearchService.stopListening();
    super.dispose();
  }

  /// Toggle voice search ON / OFF
  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      // STOP listening
      await VoiceSearchService.stopListening();
      setState(() => _isListening = false);
      return;
    }

    // START listening
    setState(() {
      _recognizedText = '';
      _detectedKeyword = null;
    });

    await VoiceSearchService.startListening(
      localeCode: context.read<AppState>().locale.languageCode,
      onResult: (text) {
        if (mounted) setState(() => _recognizedText = text);
      },
      onKeywordDetected: (keyword) {
        if (keyword != null && mounted) {
          setState(() => _detectedKeyword = keyword);
          AudioService.playKeywordDetected();
          _selectCropByKeyword(keyword);

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recognized: ${keyword.toUpperCase()}'),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onListeningStarted: () {
        if (mounted) setState(() => _isListening = true);
      },
      onListeningStopped: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  /// Auto-select crop based on keyword (voice search returns canonical crop names)
  void _selectCropByKeyword(String keyword) {
    final keywordLower = keyword.toLowerCase();
    final appState = context.read<AppState>();

    for (final crop in crops) {
      final cropName = crop['name']!.toLowerCase();
      if (cropName == keywordLower ||
          cropName.contains(keywordLower) ||
          keywordLower.contains(cropName)) {
        if (!appState.isCropSelected(crop['name']!)) {
          appState.toggleCrop(crop['name']!);
          setState(() {});
        }
        break;
      }
    }
  }

  /// Opens camera. If crops are selected, validates the scanned plant matches.
  /// If no crops are selected, uses auto-detect mode (any plant).
  Future<void> _startScan() async {
    final appState = context.read<AppState>();
    final selected = appState.selectedCrops.toList();

    if (!mounted) return;

    // Inform user when scanning in auto-detect mode
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-detect mode — scanning any plant 🌿'),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanCameraScreen(
          cropName: 'any',
          selectedCrops: selected.isEmpty ? null : selected,
        ),
      ),
    );
  }

  // Clear All Selection
  void _clearAllSelections() {
    final appState = context.read<AppState>();
    if (appState.selectedCrops.isEmpty) return;
    appState.clearCrops();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appState.tr('all_selections_cleared')),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // ── HERO SECTION ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── TOP ROW: Profile | Title | Clear ──
                  Row(
                    children: [
                      // Back button → goes back to dashboard
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context, '/main', (route) => false),
                        tooltip: 'Back',
                      ),
                      const Spacer(),
                      // Refresh/Clear icon (only when something is selected)
                      if (appState.hasCrops)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _clearAllSelections,
                          tooltip: 'Clear Selection',
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ── Offline badge ──
                  if (_isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Offline Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Title ──
                  Text(
                    appState.tr('select_your_crops'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appState.tr('choose_crop_subtitle'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Selection count badge
                  if (appState.hasCrops) ...[const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${appState.selectedCrops.length}/${AppState.maxCrops} selected',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // ── MIC TOGGLE BUTTON (always visible) ──
                  GestureDetector(
                    onTap: _toggleVoiceSearch,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.red.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _isListening
                              ? Colors.red
                              : Colors.white.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isListening
                                ? appState.tr('stop_listening')
                                : appState.tr('voice_search'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Voice search feedback ──
                  if (_isListening || _recognizedText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _isListening
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isListening
                                      ? Icons.hearing
                                      : Icons.check_circle,
                                  color: _isListening
                                      ? Colors.red
                                      : Colors.green,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isListening
                                    ? 'Listening...'
                                    : 'Voice Detected',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _isListening
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (_recognizedText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '"$_recognizedText"',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (_detectedKeyword != null) ...[
                            const SizedBox(height: 4),
                            Chip(
                              avatar: const Icon(Icons.check, size: 16),
                              label: Text(
                                'Keyword: ${_detectedKeyword!.toUpperCase()}',
                              ),
                              backgroundColor: AppTheme.lightGreen,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Try: "Tomato", "Corn", "Potato"',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),



            // ── CROP GRID ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<AppState>(
                  builder: (context, appState, _) {
                    // Sort: selected crops appear at top
                    final sorted = List<Map<String, String>>.from(kCrops)
                      ..sort((a, b) {
                        final aSelected = appState.isCropSelected(a['name']!) ? 0 : 1;
                        final bSelected = appState.isCropSelected(b['name']!) ? 0 : 1;
                        return aSelected.compareTo(bSelected);
                      });
                    return GridView.builder(
                      itemCount: sorted.length,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        final crop = sorted[index];
                        return _buildCropCard(crop['name']!, crop['asset']!);
                      },
                    );
                  },
                ),
              ),
            ),

            // ── SCAN BUTTON ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  minimumSize: const Size(double.infinity, 60),
                  elevation: 5,
                  shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  AudioService.playButtonClick();
                  _startScan();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isOffline
                          ? 'Scan Offline'
                          : appState.tr('start_scanning'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Crop Card
  Widget _buildCropCard(String cropName, String assetPath) {
    final appState  = context.read<AppState>();
    final isSelected = appState.isCropSelected(cropName);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
          width: isSelected ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            AudioService.playButtonClick();
            final appState = context.read<AppState>();
            final wasSelected = appState.isCropSelected(cropName);
            final added = await appState.toggleCrop(cropName);
            // added==false means at max capacity AND we tried to add (not remove)
            if (!added && !wasSelected) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(appState.tr('max_crops_msg')),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.lightGreen.withValues(alpha: 0.2)
                              : Colors.grey.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                                : Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Container(
                            color: Colors.white,
                            child: assetPath.isNotEmpty
                                ? Image.asset(
                                    assetPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, error, stackTrace) =>
                                        Icon(
                                          Icons.agriculture,
                                          size: 40,
                                          color: isSelected
                                              ? AppTheme.primaryGreen
                                              : Colors.grey.shade400,
                                        ),
                                  )
                                : Icon(
                                    Icons.agriculture,
                                    size: 40,
                                    color: isSelected
                                        ? AppTheme.primaryGreen
                                        : Colors.grey.shade400,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appState.trCrop(cropName),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
