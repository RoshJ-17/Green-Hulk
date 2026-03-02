import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../widgets/shared_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    await HistoryService.fetchHistory();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyItems = HistoryService.history;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : historyItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingMedium,
                ),
                itemCount: historyItems.length,
                itemBuilder: (context, index) {
                  final item = historyItems[index];

                  return Dismissible(
                    key: ValueKey(item.id), // Flaw #6: Use unique ID
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(index),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    child: HistoryItemCard(
                      imagePath: item.imagePath,
                      date: _formatDate(item.date),
                      cropName: '${item.cropName} - ${item.diseaseName}',
                      onTap: () {
                        // Flaw #6: Pass isFromHistory flag
                        Navigator.pushNamed(
                          context,
                          '/treatment',
                          arguments: {'result': item, 'isFromHistory': true},
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
        content: const Text(
          "Are you sure you want to remove this diagnosis from history?",
        ),
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Text(
              'No scans yet — your future diagnoses will appear here',
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

  // Flaw #17: Use intl package for consistent date formatting
  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}
