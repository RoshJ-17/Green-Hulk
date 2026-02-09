import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
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
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }
}
/// STAR RATING WIDGET
class StarRating extends StatelessWidget {
  final int rating;
  final Function(int) onChanged;
  const StarRating({
    super.key,
    required this.rating,
    required this.onChanged,
  });
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
  final VoidCallback onTap;
  const HistoryItemCard({
    super.key,
    required this.imagePath,
    required this.date,
    required this.cropName,
    required this.onTap,
  });
 @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              /// IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imagePath.startsWith('assets') 
                  ? Image.asset(
                      imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_not_supported, size: 50),
                    )
                  : Image.file(
                      File(imagePath),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image, size: 50),
                    ),
              ),
              const SizedBox(width: 12),
              /// TEXT AREA (IMPORTANT FIX)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(date, style: const TextStyle(color: Colors.grey)),
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
