import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../widgets/shared_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  @override
  Widget build(BuildContext context) {
    // Get history from service
    final historyItems = HistoryService.history;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: SafeArea(
        child: historyItems.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                itemCount: historyItems.length,
                itemBuilder: (context, index) {
                  final item = historyItems[index];

                  return Dismissible(
                    key: UniqueKey(), // Use UniqueKey for simplicity
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(index),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white, size: 30),
                    ),
                    child: HistoryItemCard(
                      imagePath: item.imagePath,
                      date: _formatDate(item.date),
                      cropName: '${item.cropName} - ${item.diseaseName}',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/treatment',
                          arguments: item,
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  /// CONFIRM DELETE DIALOG
  Future<bool?> _confirmDelete(int index) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Scan?"),
        content: const Text("Are you sure you want to remove this diagnosis from history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => HistoryService.removeResult(index));
              Navigator.pop(context, true);
            },
            child: const Text("Delete"),
          ),
        ],
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
            Icon(Icons.history, size: 100, color: AppTheme.lightGreen),
            SizedBox(height: AppTheme.spacingLarge),
            Text(
              'No scan history yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Text(
              'No scans yet — your future diagnoses will appear here',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.accentGreen),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final month = months[date.month - 1];
    return '${date.day} $month ${date.year}';
  }
}

