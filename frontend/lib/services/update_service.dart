import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../config/api_config.dart';

class UpdateService {
  static const String currentVersion = '1.0.0';

  static Future<void> checkForUpdate(BuildContext context) async {
    // Only show update prompt on Android (not web, not iOS)
    if (kIsWeb) return;

    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.apiUrl}/version'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final latestVersion = data['latestVersion'] as String;
      final downloadUrl = data['downloadUrl'] as String;
      final forceUpdate = data['forceUpdate'] as bool? ?? false;
      final releaseNotes = data['releaseNotes'] as String? ?? '';

      if (_isNewerVersion(latestVersion, currentVersion)) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            latestVersion,
            downloadUrl,
            releaseNotes,
            forceUpdate,
          );
        }
      }
    } catch (_) {
      // Silently fail — never block the user if update check fails
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    final l = latest.split('.').map(int.parse).toList();
    final c = current.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String latestVersion,
    String downloadUrl,
    String releaseNotes,
    bool forceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Available 🌿'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A new version v$latestVersion is available.'),
            if (releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(releaseNotes, style: const TextStyle(color: Colors.grey)),
            ],
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _launchUrl(downloadUrl);
            },
            child: const Text('Download Update'),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
