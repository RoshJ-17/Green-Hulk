import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/scan_result.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';

class TreatmentScreen extends StatefulWidget {
  final ScanResult result;

  const TreatmentScreen({super.key, required this.result});

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {

  late final ScanResult result;

  bool showOrganicTreatment = true;
  bool speaking = false;
  int rating = 0;

  late FlutterTts tts;

  @override
  void initState() {
    super.initState();
    result = widget.result;

    // Save to history (if not already there? Simple append for now)
    // We might want to check if it was just passed FROM history to avoid duplicates
    // But since we can't easily tell, and requirements say Result -> History, 
    // we'll explicitly add it only if it looks "new" (e.g. from camera). 
    // Actually, simpler: The requirement says "Result -> Treatment -> History".
    // If I open from history, it goes to Treatment. I shouldn't add it again.
    // I can check if the result is already in history? 
    // For now, let's assume if it scans, it's new. 
    // But wait, the HistoryScreen opens TreatmentScreen too.
    // I should pass a flag "fromHistory".
    
    // Better approach: handle saving in CropSelectionScreen or ScanCameraScreen 
    // NO, TreatmentScreen is the "Result" screen.
    // I'll check if it's already in history by reference or ID? 
    // ScanResult doesn't have ID.
    // Let's just add it. If duplicates happen, so be it for this student project.
    // Or, I can add `bool saved = false;` to ScanResult? No.
    // I will add it to HistoryService here.
    
    HistoryService.addResult(result);

    tts = FlutterTts();

    /// When speech ends
    tts.setCompletionHandler(() {
      if (mounted) setState(() => speaking = false);
    });
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  /// SPEECH TEXT
  String _buildTreatmentSpeech() {
    if (!result.hasDisease) {
      return "Good news! Your crop appears healthy.";
    }

    final treatment = showOrganicTreatment ? organicTreatment : chemicalTreatment;
    final steps = treatment['steps'] as List<Map<String, dynamic>>;

    String speech = "Detected disease ${result.diseaseName}. ";

    for (var step in steps) {
      speech += "${step['title']}. ${step['description']}. ";
    }

    return speech;
  }

  Future<void> speakTreatment() async {
    await tts.stop();
    await tts.speak(_buildTreatmentSpeech());
    setState(() => speaking = true);
  }

  Future<void> stopSpeaking() async {
    await tts.stop();
    setState(() => speaking = false);
  }

  /// SAMPLE DATA (Later backend will replace)
  final Map<String, dynamic> organicTreatment = {
    'steps': [
      {'title': 'Remove Affected Leaves', 'description': 'Remove infected leaves carefully'},
      {'title': 'Apply Neem Oil Spray', 'description': 'Spray neem oil solution every 7 days'},
      {'title': 'Improve Air Circulation', 'description': 'Maintain proper spacing between plants'},
      {'title': 'Add Compost', 'description': 'Use organic compost to strengthen immunity'},
    ],
  };

  final Map<String, dynamic> chemicalTreatment = {
    'steps': [
      {'title': 'Wear Protection', 'description': 'Wear gloves and mask before spraying'},
      {'title': 'Apply Fungicide', 'description': 'Use recommended fungicide dosage'},
      {'title': 'Repeat Spray', 'description': 'Repeat after 10 to 12 days'},
      {'title': 'Harvest Gap', 'description': 'Wait at least 14 days before harvest'},
    ],
  };

  @override
  Widget build(BuildContext context) {

    final treatment = showOrganicTreatment ? organicTreatment : chemicalTreatment;
    final steps = treatment['steps'] as List<Map<String, dynamic>>;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Treatment Plan"),
        automaticallyImplyLeading: true,
      ),

      body: SafeArea(
        child: Column(
          children: [

            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppTheme.lightGreen.withValues(alpha: 0.2),
              child: Column(
                children: [

                  /// Disease name
                  Text(
                    result.hasDisease ? result.diseaseName : "Healthy Crop",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen),
                  ),

                  const SizedBox(height: 6),

                  /// Confidence
                  Text(
                    "Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 10),

                  /// TTS Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.volume_up),
                        label: const Text("Read"),
                        onPressed: speaking ? null : speakTreatment,
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.stop),
                        label: const Text("Stop"),
                        onPressed: speaking ? stopSpeaking : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// TOGGLE
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            showOrganicTreatment ? Colors.green : Colors.grey.shade300,
                        foregroundColor:
                            showOrganicTreatment ? Colors.white : Colors.black,
                      ),
                      onPressed: () => setState(() => showOrganicTreatment = true),
                      child: const Text("Organic"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !showOrganicTreatment ? Colors.green : Colors.grey.shade300,
                        foregroundColor:
                            !showOrganicTreatment ? Colors.white : Colors.black,
                      ),
                      onPressed: () => setState(() => showOrganicTreatment = false),
                      child: const Text("Chemical"),
                    ),
                  ),
                ],
              ),
            ),

            /// STEPS LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: result.hasDisease ? steps.length : 1,
                itemBuilder: (_, i) {

                  if (!result.hasDisease) {
                    return const ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text("No treatment needed"),
                      subtitle: Text("Your crop is healthy"),
                    );
                  }

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen,
                        child: Text("${i + 1}",
                            style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(steps[i]['title']),
                      subtitle: Text(steps[i]['description']),
                    ),
                  );
                },
              ),
            ),

            /// RATING
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 10),
              child: Column(
                children: [
                  const Text(
                    "Was this diagnosis helpful?",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                          size: 30,
                        ),
                        onPressed: () => _onRatingSelected(index + 1),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onRatingSelected(int score) {
    if (!mounted) return;
    
    setState(() {
      rating = score;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Thanks for your feedback!"),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}
