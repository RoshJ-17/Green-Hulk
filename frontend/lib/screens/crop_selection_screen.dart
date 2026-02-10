import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/farmer_crop_service.dart';
import '../services/voice_search_service.dart';
import '../services/audio_service.dart';
import '../services/connectivity_service.dart';
import 'scan_camera_screen.dart';
import '../models/scan_result.dart';

const List<Map<String, String>> crops = [
  {'name': 'Rice', 'asset': 'icons/rice.png'},
  {'name': 'Wheat', 'asset': 'icons/wheat.png'},
  {'name': 'Tomato', 'asset': 'icons/tomato.png'},
  {'name': 'Maize', 'asset': 'icons/corn.png'},
  {'name': 'Cotton', 'asset': 'icons/cotton.png'},
];

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
    
    // Listen for connectivity changes
    ConnectivityService.addListener((isOnline) {
      if (mounted) {
        setState(() => _isOffline = !isOnline);
      }
    });
    
    // Check initial connectivity
    setState(() => _isOffline = ConnectivityService.isOffline);
  }

  @override
  void dispose() {
    VoiceSearchService.stopListening();
    super.dispose();
  }

  /// Start voice search
  Future<void> _startVoiceSearch() async {
    if (_isListening) {
      await VoiceSearchService.stopListening();
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _recognizedText = '';
      _detectedKeyword = null;
    });

    await VoiceSearchService.startListening(
      onResult: (text) {
        setState(() => _recognizedText = text);
      },
      onKeywordDetected: (keyword) {
        if (keyword != null) {
          setState(() => _detectedKeyword = keyword);
          AudioService.playKeywordDetected();
          
          // Auto-select crop if keyword matches
          _selectCropByKeyword(keyword);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recognized: ${keyword.toUpperCase()}'),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onListeningStarted: () => setState(() => _isListening = true),
      onListeningStopped: () => setState(() => _isListening = false),
    );
  }

  /// Auto-select crop based on keyword
  void _selectCropByKeyword(String keyword) {
    // Match keyword to crop name
    final keywordLower = keyword.toLowerCase();
    
    for (final crop in crops) {
      if (crop['name']!.toLowerCase() == keywordLower) {
        if (!FarmerCropService.isSelected(crop['name']!)) {
          setState(() => FarmerCropService.toggleCrop(crop['name']!));
        }
        break;
      }
    }
    
    // Special case: "blight" selects Tomato (common disease)
    if (keywordLower == 'blight') {
      if (!FarmerCropService.isSelected('Tomato')) {
        setState(() => FarmerCropService.toggleCrop('Tomato'));
      }
    }
  }

  /// Opens camera → waits result → opens treatment
  Future<void> _startScan() async {
    final selected = FarmerCropService.selectedCrops;

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one crop")),
      );
      return;
    }

    String? cropToScan;

    if (selected.length == 1) {
      cropToScan = selected.first;
    } else {
      // Show dialog to pick one
      cropToScan = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text("Select crop to scan"),
          children: selected.map((c) => SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, c),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              child: Text(c, style: const TextStyle(fontSize: 16)),
            ),
          )).toList(),
        ),
      );
    }

    if (cropToScan == null) return;
    if (!mounted) return;

    final ScanResult? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanCameraScreen(cropName: cropToScan!),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      Navigator.pushNamed(
        context,
        '/treatment',
        arguments: result,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Crop'),
        actions: [
          // Voice search button
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            tooltip: 'Voice Search',
            onPressed: _startVoiceSearch,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              /// Offline badge
              if (_isOffline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No Internet - Local Scan',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              /// Voice search status
              if (_isListening || _recognizedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isListening ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isListening ? Icons.hearing : Icons.check_circle,
                            color: _isListening ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isListening ? 'Listening...' : 'Voice Search Complete',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isListening ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (_recognizedText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"$_recognizedText"',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (_detectedKeyword != null) ...[
                        const SizedBox(height: 4),
                        Chip(
                          avatar: const Icon(Icons.check, size: 16),
                          label: Text('Keyword: ${_detectedKeyword!.toUpperCase()}'),
                          backgroundColor: AppTheme.lightGreen,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Say: "Tomato", "Rice", or "Blight"',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              Text(
                'Select all crops you grow',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              /// GRID
              Expanded(
                child: GridView.builder(
                  itemCount: crops.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final crop = crops[index];
                    return _buildCropCard(
                      crop['name']!,
                      crop['asset']!,
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              /// SCAN BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  AudioService.playButtonClick();
                  _startScan();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _isOffline ? "Scan (Offline Mode)" : "Scan Selected Crop",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  /// Crop Card
  Widget _buildCropCard(String cropName, String assetPath) {

    final isSelected = FarmerCropService.isSelected(cropName);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.transparent,
          width: 3,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => FarmerCropService.toggleCrop(cropName));
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Expanded(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.agriculture, size: 70, color: Colors.green),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                cropName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),

              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.green),

            ],
          ),
        ),
      ),
    );
  }
}
