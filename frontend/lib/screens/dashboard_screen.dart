// lib/screens/dashboard_screen.dart
//
// Home dashboard showing:
//   • Top greeting header with gradient
//   • Stats row: Total Scans / Diseased Plants
//   • Quick action cards: Scan Crop & View History

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../config/crop_data.dart';
import 'scan_camera_screen.dart';
import '../models/scan_result.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().refreshStats();
    });
  }

  // ── Smart scan: if 1 crop → camera directly; if >1 → picker; else → /crops ──
  Future<void> _onScanTap() async {
    final appState = context.read<AppState>();
    final selected = appState.selectedCrops;
    if (selected.isEmpty) {
      Navigator.pushNamed(context, '/crops');
      return;
    }
    String cropToScan;
    if (selected.length == 1) {
      cropToScan = selected.first;
    } else {
      final picked = await _showCropPicker(appState);
      if (!mounted || picked == null) return;
      cropToScan = picked;
    }
    if (!mounted) return;
    final ScanResult? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScanCameraScreen(cropName: cropToScan)),
    );
    if (!mounted) return;
    if (result != null) {
      Navigator.pushNamed(context, '/treatment',
          arguments: {'result': result, 'isFromHistory': false});
    }
  }

  Future<String?> _showCropPicker(AppState appState) {
    final selected = appState.selectedCrops;
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(appState.tr('scan_which_crop'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen)),
          ),
          const SizedBox(height: 8),
          ...selected.map((name) {
            final asset = cropAsset(name);
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.lightGreen.withValues(alpha: 0.3),
                child: asset != null
                    ? ClipOval(child: Image.asset(asset, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.agriculture, color: AppTheme.primaryGreen)))
                    : const Icon(Icons.agriculture, color: AppTheme.primaryGreen),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, name),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              _buildHeader(context, appState),

              // ── Crop Banner ─────────────────────────────────────────
              _buildCropBanner(context, appState),

              const SizedBox(height: 8),

              // ── Stats ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.tr('your_activity'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.qr_code_scanner_rounded,
                            label: appState.tr('total_scans'),
                            value: '${appState.totalScans}',
                            color: AppTheme.primaryGreen,
                            bgColor: AppTheme.primaryGreen.withValues(alpha: 0.08),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.bug_report_outlined,
                            label: appState.tr('diseased_plants'),
                            value: '${appState.diseasedScans}',
                            color: Colors.orange.shade700,
                            bgColor: Colors.orange.shade50,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Quick Actions ────────────────────────────────────
                    Text(
                      appState.tr('quick_actions'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildQuickAction(
                      context: context,
                      icon: Icons.camera_alt_rounded,
                      title: appState.tr('scan_crop'),
                      subtitle: appState.tr('take_photo_subtitle'),
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGreen, Color(0xFF43A047)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      // Smart scan: go directly to camera if ≥1 crop selected
                      onTap: _onScanTap,
                    ),

                    const SizedBox(height: 14),

                    _buildQuickAction(
                      context: context,
                      icon: Icons.history_rounded,
                      title: appState.tr('scan_history'),
                      subtitle: appState.tr('view_previous'),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentGreen,
                          AppTheme.accentGreen.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/history'),
                    ),

                    const SizedBox(height: 24),

                    // ── Tips Card ────────────────────────────────────────
                    _buildTipCard(),

                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryGreen,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(loggedIn ? 'User Profile' : 'Guest User'),
            const SizedBox(height: 8),
            if (!loggedIn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppTheme.primaryGreen),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Login to save history',
                        style: TextStyle(fontSize: 13, color: AppTheme.primaryGreen),
                      ),
                    ),
                  ],
                ),
              ),
            if (loggedIn)
              Text('Logged in', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (loggedIn)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                AuthService.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout'),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState appState) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? appState.tr('good_morning')
        : hour < 17
            ? appState.tr('good_afternoon')
            : appState.tr('good_evening');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.agriculture, color: Colors.white, size: 28),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white, size: 32),
                onPressed: _showProfileDialog,
                tooltip: 'Profile',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$greeting! 🌿',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appState.tr('monitor_subtitle'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // Horizontally scrollable crop banner
  Widget _buildCropBanner(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appState.tr('my_crops'),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // "+" button → go to crop selection page
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/crops'),
                  child: Container(
                    width: 72, height: 72,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: const Icon(Icons.add, color: AppTheme.primaryGreen, size: 32),
                  ),
                ),
                // Selected crop icons
                ...appState.selectedCrops.map((name) {
                  final asset = cropAsset(name);
                  return Container(
                    width: 72, height: 72,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                          blurRadius: 8, offset: const Offset(0, 3))
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40, height: 40,
                          child: ClipOval(
                            child: asset != null
                                ? Image.asset(asset, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.agriculture, color: AppTheme.primaryGreen, size: 30))
                                : const Icon(Icons.agriculture, color: AppTheme.primaryGreen, size: 30),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_outline, color: AppTheme.accentGreen, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'For best scan results, capture the leaf in good lighting and keep the camera steady.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
