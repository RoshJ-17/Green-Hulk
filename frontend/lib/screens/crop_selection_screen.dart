import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/farmer_crop_service.dart';
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
                onPressed: _startScan,
                child: const Text(
                  "Scan Selected Crop",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
