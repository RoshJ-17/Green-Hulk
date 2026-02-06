import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CropSelectionScreen extends StatelessWidget {
  const CropSelectionScreen({Key? key}) : super(key: key);

  static const List<Map<String, String>> crops = [
    {'name': 'Rice', 'asset': 'assets/icons/rice.png'},
    {'name': 'Wheat', 'asset': 'assets/icons/wheat.png'},
    {'name': 'Tomato', 'asset': 'assets/icons/tomato.png'},
    {'name': 'Maize', 'asset': 'assets/icons/corn.png'},
    {'name': 'Cotton', 'asset': 'assets/icons/cotton.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Crop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 26),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 26),
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'What crop do you want to diagnose?',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Grid with BETTER PROPORTIONS - icons fill the card better
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95, // Slightly taller cards
                  ),
                  itemCount: crops.length,
                  itemBuilder: (context, index) {
                    final crop = crops[index];
                    return _buildCropCard(
                      context,
                      crop['name']!,
                      crop['asset']!,
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

  Widget _buildCropCard(BuildContext context, String cropName, String assetPath) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$cropName selected',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // MUCH BIGGER ICON - fills the card properly
              Expanded(
                flex: 3,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.agriculture,
                      size: 80,
                      color: AppTheme.accentGreen,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Crop name
              Text(
                cropName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}