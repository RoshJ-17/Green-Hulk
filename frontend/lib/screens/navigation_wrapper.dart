// lib/screens/navigation_wrapper.dart
//
// 4-tab bottom navigation:
//   0 → Dashboard   (home stats + quick actions)
//   1 → Scan        (CropSelectionScreen)
//   2 → History     (HistoryScreen)
//   3 → Settings    (SettingsScreen)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../config/crop_data.dart';
import 'dashboard_screen.dart';
import 'crop_selection_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'scan_camera_screen.dart';
import '../models/scan_result.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  int _selectedIndex = 0;

  // screens are kept alive via IndexedStack
  static const List<Widget> _screens = [
    DashboardScreen(),
    CropSelectionScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) async {
    // Smart scan: if Scan tab tapped and ≥1 crop selected, go directly to camera
    if (index == 1) {
      final appState = context.read<AppState>();
      if (appState.hasCrops) {
        final selected = appState.selectedCrops;
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
        return; // don't change tab index
      }
    }

    setState(() => _selectedIndex = index);
    if (index == 0 && mounted) {
      context.read<AppState>().refreshStats();
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
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: AppTheme.primaryGreen,
            unselectedItemColor: Colors.grey.shade400,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            items: [
              _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, context.read<AppState>().tr('nav_dashboard'), 0),
              _buildNavItem(Icons.center_focus_strong_outlined, Icons.center_focus_strong, context.read<AppState>().tr('nav_scan'), 1),
              _buildNavItem(Icons.history_outlined, Icons.history, context.read<AppState>().tr('nav_history'), 2),
              _buildNavItem(Icons.settings_outlined, Icons.settings, context.read<AppState>().tr('nav_settings'), 3),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(isSelected ? activeIcon : icon),
      ),
      label: label,
    );
  }
}
