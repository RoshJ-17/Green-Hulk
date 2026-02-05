import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';

// Task 5: History Screen
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  // Sample history data (in real app, this would come from database)
  static final List<Map<String, String>> historyItems = [
    {
      'image': 'assets/images/scan_sample_1.png',
      'date': '2024-02-03',
      'crop': 'Rice - Leaf Blight',
    },
    {
      'image': 'assets/images/scan_sample_2.png',
      'date': '2024-02-01',
      'crop': 'Tomato - Early Blight',
    },
    {
      'image': 'assets/images/scan_sample_3.png',
      'date': '2024-01-28',
      'crop': 'Wheat - Rust Disease',
    },
    {
      'image': 'assets/images/scan_sample_4.png',
      'date': '2024-01-25',
      'crop': 'Maize - Leaf Spot',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
      ),
      body: SafeArea(
        child: historyItems.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingMedium,
                ),
                itemCount: historyItems.length,
                itemBuilder: (context, index) {
                  final item = historyItems[index];
                  return HistoryItemCard(
                    imagePath: item['image']!,
                    date: _formatDate(item['date']!),
                    cropName: item['crop']!,
                    onTap: () {
                      // Navigate to treatment screen with this diagnosis
                      Navigator.pushNamed(
                        context,
                        '/treatment',
                        arguments: item,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.history,
              size: 100,
              color: AppTheme.lightGreen,
            ),
            SizedBox(height: AppTheme.spacingLarge),
            Text(
              'No scan history yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Your past crop diagnoses will appear here',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.accentGreen,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    // Simple date formatting (in real app, use intl package)
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[int.parse(parts[1]) - 1];
      return '${parts[2]} $month ${parts[0]}';
    }
    return dateStr;
  }
}