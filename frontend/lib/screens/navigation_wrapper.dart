// lib/screens/navigation_wrapper.dart
//
// 5-tab bottom navigation:
//   0 → Dashboard   (home stats + quick actions)
//   1 → Scan        (directly to camera with 'any' crop)
//   2 → History     (HistoryScreen)
//   3 → Map         (MapScreen)
//   4 → Settings    (SettingsScreen)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'crop_selection_screen.dart';
import 'history_screen.dart';
import 'map_screen.dart';
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
    CropSelectionScreen(), // shown only when no crops selected
    HistoryScreen(),
    MapScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) async {
    // Scan tab: always go directly to camera with 'any' (model identifies crop)
    if (index == 1) {
      if (!mounted) return;
      final ScanResult? result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const ScanCameraScreen(cropName: 'any')),
      );
      if (!mounted) return;
      if (result != null) {
        Navigator.pushNamed(context, '/treatment',
            arguments: {'result': result, 'isFromHistory': false});
      }
      return; // don't change tab index
    }

    setState(() => _selectedIndex = index);
    if (index == 0 && mounted) {
      context.read<AppState>().refreshStats();
    }
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
              _buildNavItem(Icons.map_outlined, Icons.map, context.read<AppState>().tr('nav_map'), 3),
              _buildNavItem(Icons.settings_outlined, Icons.settings, context.read<AppState>().tr('nav_settings'), 4),
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
