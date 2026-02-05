import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';

// Task 8: Crop Selection Screen with Grid Layout
class CropSelectionScreen extends StatelessWidget {
  const CropSelectionScreen({Key? key}) : super(key: key);

  // Task 9: Crop data with asset paths
  static const List<Map<String, String>> crops = [
    {
      'name': 'Rice',
      'asset': 'assets/icons/rice.png',
    },
    {
      'name': 'Wheat',
      'asset': 'assets/icons/wheat.png',
    },
    {
      'name': 'Tomato',
      'asset': 'assets/icons/tomato.png',
    },
    {
      'name': 'Maize',
      'asset': 'assets/icons/maize.png',
    },
    {
      'name': 'Cotton',
      'asset': 'assets/icons/cotton.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Crop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: AppTheme.iconSize),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
          IconButton(
            icon: const Icon(Icons.language, size: AppTheme.iconSize),
            onPressed: () {
              Navigator.pushNamed(context, '/language');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                'What crop do you want to diagnose?',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              
              // Grid layout for crop icons
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns for better touch targets
                    crossAxisSpacing: AppTheme.spacingMedium,
                    mainAxisSpacing: AppTheme.spacingMedium,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: crops.length,
                  itemBuilder: (context, index) {
                    final crop = crops[index];
                    return CropIconCard(
                      cropName: crop['name']!,
                      assetPath: crop['asset']!,
                      onTap: () {
                        // Navigate to camera/scan screen (not in Sprint 1)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${crop['name']} selected',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}