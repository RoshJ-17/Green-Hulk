import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/app_state.dart';
import '../services/localization_service.dart';
import '../services/gemini_translation_service.dart';

/// NO INTERNET - LOCAL SCAN BADGE
class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'No Internet - Local Scan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// CONFIDENCE BADGE - Displays "90% Certain" etc.
class ConfidenceBadge extends StatelessWidget {
  final double confidence;
  const ConfidenceBadge({super.key, required this.confidence});

  Color _getColor() {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percentage% Certain',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// DISEASE NAME DISPLAY
class DiseaseNameDisplay extends StatelessWidget {
  final String diseaseName;
  final bool hasDisease;
  const DiseaseNameDisplay({
    super.key,
    required this.diseaseName,
    required this.hasDisease,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      hasDisease ? diseaseName : 'Healthy - No Disease Detected',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: hasDisease ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }
}

/// VOICE SEARCH BUTTON
class VoiceSearchButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;
  const VoiceSearchButton({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'voice_search',
      backgroundColor: isListening ? Colors.red : Colors.blue,
      onPressed: onPressed,
      child: Icon(isListening ? Icons.mic : Icons.mic_none),
    );
  }
}

/// AUDIO BUTTON - Plays audio when clicked
class AudioButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  const AudioButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: backgroundColor != null
          ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
          : null,
      onPressed: () {
        // Audio feedback handled by caller
        onPressed();
      },
      child: child,
    );
  }
}

/// ORGANIC BADGE
class OrganicBadge extends StatelessWidget {
  final bool isOrganic;
  const OrganicBadge({super.key, required this.isOrganic});
  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.eco, color: Colors.white),
      label: const Text("Organic Safe"),
      backgroundColor: Colors.green,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// STAR RATING WIDGET
class StarRating extends StatelessWidget {
  final int rating;
  final Function(int) onChanged;
  const StarRating({super.key, required this.rating, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.orange,
            size: 32,
          ),
          onPressed: () => onChanged(index + 1),
        );
      }),
    );
  }
}

/// LOADING OVERLAY
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );
  }
}

/// SPEAK BUTTON (Reusable Voice)
class SpeakButton extends StatefulWidget {
  final String text;
  const SpeakButton({super.key, required this.text});
  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton> {
  final FlutterTts tts = FlutterTts();
  bool speaking = false;
  Future<void> toggle() async {
    if (speaking) {
      await tts.stop();
      setState(() => speaking = false);
    } else {
      await tts.speak(widget.text);
      setState(() => speaking = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(speaking ? Icons.stop : Icons.volume_up),
      label: Text(speaking ? "Stop" : "Read"),
      onPressed: toggle,
    );
  }
}

/// HISTORY ITEM CARD
class HistoryItemCard extends StatelessWidget {
  final String imagePath;
  final String date;
  final String cropName;
  final String diseaseName;
  final VoidCallback onTap;
  const HistoryItemCard({
    super.key,
    required this.imagePath,
    required this.date,
    required this.cropName,
    required this.onTap,
    this.diseaseName = '',
  });
  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final langCode = appState.locale.languageCode;
    final hasDisease =
        diseaseName.isNotEmpty && diseaseName.toLowerCase() != 'healthy';
    final translatedCropName = L10nService.trCrop(cropName, langCode);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              /// IMAGE / THUMBNAIL
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imagePath.startsWith('assets')
                    ? Image.asset(
                        imagePath,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, stackTrace) =>
                            const Icon(Icons.image_not_supported, size: 50),
                      )
                    : kIsWeb
                    ? Image.network(
                        imagePath,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50),
                      )
                    : Image.file(
                        File(imagePath),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50),
                      ),
              ),
              const SizedBox(width: 12),

              /// TEXT AREA — Crop name + Disease chip + Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translatedCropName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Disease name — translated asynchronously via Gemini (cached)
                    FutureBuilder<String>(
                      future: hasDisease
                          ? GeminiTranslationService.translate(diseaseName, langCode)
                          : Future.value(L10nService.tr('healthy', langCode)),
                      initialData: hasDisease
                          ? diseaseName
                          : L10nService.tr('healthy', langCode),
                      builder: (_, snap) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: hasDisease
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          snap.data!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasDisease
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
