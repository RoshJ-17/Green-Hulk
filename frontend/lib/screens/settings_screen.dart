// lib/screens/settings_screen.dart
//
// Settings page accessible from the bottom navigation bar (4th tab).
// Features:
//   • Profile section (name / phone from token)
//   • Language picker (inline — no onboarding)
//   • Logout button (only when logged in)
//
// Language change:
//   Updates AppState.changeLanguage() → MaterialApp locale rebuilds → back

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';

// ── Language item data ─────────────────────────────────────────────────────

class _LangItem {
  final String name;
  final String code;
  final String emoji;
  const _LangItem(this.name, this.code, this.emoji);
}

const _languages = [
  _LangItem('English',   'en', '🌐'),
  _LangItem('हिन्दी',   'hi', '🇮🇳'),
  _LangItem('தமிழ்',    'ta', '🌾'),
  _LangItem('తెలుగు',   'te', '🌿'),
  _LangItem('ಕನ್ನಡ',    'kn', '🍃'),
  _LangItem('বাংলা',    'bn', '🌱'),
  _LangItem('ਪੰਜਾਬੀ',   'pa', '🌻'),
];

// ── Screen ─────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showLanguagePicker = false;

  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _changeLanguage(String code) async {
    await context.read<AppState>().changeLanguage(code);
    if (!mounted) return;
    setState(() => _showLanguagePicker = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Language updated!'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AuthService.logout();
    if (!mounted) return;
    context.read<AppState>().setLoggedIn(false);
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState  = context.watch<AppState>();
    final isSession = appState.isLoggedIn;
    final currentLang = _languages.firstWhere(
      (l) => l.code == appState.locale.languageCode,
      orElse: () => _languages.first,
    );

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ───────────────────────────────────────────────────
              _buildHeader(),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Profile Section ──────────────────────────────────
                    _sectionTitle('Profile'),
                    const SizedBox(height: 10),
                    _buildProfileCard(isSession),

                    const SizedBox(height: 24),

                    // ── Language Section ─────────────────────────────────
                    _sectionTitle('Language'),
                    const SizedBox(height: 10),

                    // Current language tile
                    _buildTile(
                      icon: Icons.language,
                      title: 'App Language',
                      subtitle: '${currentLang.emoji}  ${currentLang.name}',
                      trailing: Icon(
                        _showLanguagePicker
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.primaryGreen,
                      ),
                      onTap: () =>
                          setState(() => _showLanguagePicker = !_showLanguagePicker),
                    ),

                    if (_showLanguagePicker)
                      _buildLanguagePicker(currentLang.code),

                    const SizedBox(height: 24),

                    // ── App Section ──────────────────────────────────────
                    _sectionTitle('App'),
                    const SizedBox(height: 10),

                    _buildTile(
                      icon: Icons.info_outline,
                      title: 'About CropCare',
                      subtitle: 'Version 1.0.0 • AI Crop Disease Diagnosis',
                      onTap: () => _showAboutDialog(context),
                    ),

                    const SizedBox(height: 24),

                    // ── Logout ───────────────────────────────────────────
                    if (isSession) ...[
                      _sectionTitle('Account'),
                      const SizedBox(height: 10),
                      _buildTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        iconColor: Colors.red,
                        titleColor: Colors.red,
                        onTap: _logout,
                      ),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 80), // bottom nav space
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sub-widgets
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
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
          const Icon(Icons.settings, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(Icons.person, color: AppTheme.primaryGreen, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn ? 'Farmer Account' : 'Guest User',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoggedIn
                      ? 'Logged in'
                      : 'Login to save your scan history',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (!isLoggedIn)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text(
                'Login',
                style: TextStyle(
                  color: AppTheme.accentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguagePicker(String currentCode) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightGreen.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: _languages.map((lang) {
          final isSelected = lang.code == currentCode;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Text(lang.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(
              lang.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryGreen : Colors.black87,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isSelected
                ? AppTheme.primaryGreen.withValues(alpha: 0.06)
                : null,
            onTap: () => _changeLanguage(lang.code),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color iconColor = AppTheme.primaryGreen,
    Color titleColor = AppTheme.primaryGreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      )),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      )),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.agriculture, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('CropCare'),
          ],
        ),
        content: const Text(
          'CropCare uses AI to diagnose plant diseases from photos.\n\n'
          'Version 1.0.0\n'
          'Built with Flutter & Machine Learning',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
