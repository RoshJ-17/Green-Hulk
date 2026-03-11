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
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Styled Header with back arrow ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/main', (route) => false),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.history_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    appState.tr('history_title'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // ── Body ──────────────────────────────────────────────────
            Expanded(
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
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _confirmDelete(),
                              onDismissed: (_) {
                                final idx = HistoryService.history.indexWhere((r) => r.id == item.id);
                                if (idx >= 0) HistoryService.removeResult(idx);
                                setState(() {});
                                context.read<AppState>().refreshStatsLocal();
                              },
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
                                cropName: item.cropName,
                                diseaseName: item.diseaseName,
                                onTap: () {
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
          ],
        ),
      ),
    );
  }

  /// CONFIRM DELETE DIALOG — only shows the dialog and returns the user's choice.
  /// Actual removal is handled by the Dismissible's onDismissed callback.
  Future<bool?> _confirmDelete() async {
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
            onPressed: () => Navigator.pop(context, true),
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
