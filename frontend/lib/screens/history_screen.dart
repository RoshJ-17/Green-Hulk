import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
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
    final appState = context.watch<AppState>();
    final historyItems = HistoryService.history;

    return Scaffold(
      appBar: AppBar(title: Text(appState.tr('history_title'))),
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
                      cropName: appState.trCrop(item.cropName),
                      diseaseName: item.diseaseName,
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
    final appState = context.read<AppState>();
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(appState.tr('delete_scan')),
        content: Text(appState.tr('delete_scan_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appState.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => HistoryService.removeResult(index));
              Navigator.pop(context, true);
            },
            child: Text(appState.tr('delete')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final appState = context.read<AppState>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                size: 72,
                color: AppTheme.accentGreen,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              appState.tr('no_scans_yet'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              appState.tr('start_scanning'),
              style: const TextStyle(
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
