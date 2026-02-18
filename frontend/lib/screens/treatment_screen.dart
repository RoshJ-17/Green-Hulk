import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_result.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/ai_model_service.dart';
import '../services/audio_service.dart';
import '../services/treatment_api_service.dart';

class TreatmentScreen extends StatefulWidget {
  final ScanResult result;
  final bool isFromHistory;

  const TreatmentScreen({
    super.key,
    required this.result,
    this.isFromHistory = false,
  });

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen>
    with SingleTickerProviderStateMixin {
  late final ScanResult result;
  late TabController _tabController;

  bool showOrganicTreatment = true;
  bool organicOnlyMode = false;
  bool speaking = false;
  int rating = 0;

  late FlutterTts tts;

  // API-fetched treatment data
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _diseaseData;

  // Structured treatment data
  Map<String, dynamic>? _selectedOrganicTreatment;
  Map<String, dynamic>? _selectedChemicalTreatment;

  @override
  void initState() {
    super.initState();
    result = widget.result;
    _tabController = TabController(length: 3, vsync: this);

    if (!widget.isFromHistory) {
      HistoryService.addResult(result);
    }

    rating = result.rating ?? 0;

    tts = FlutterTts();
    tts.setCompletionHandler(() {
      if (mounted) setState(() => speaking = false);
    });

    _fetchTreatments();
  }

  @override
  void dispose() {
    tts.stop();
    _tabController.dispose();
    super.dispose();
  }

  /// Fetch treatments from backend API
  Future<void> _fetchTreatments() async {
    if (!result.hasDisease) {
      setState(() => _isLoading = false);
      return;
    }

    // Build disease key - prefer fullLabel, fallback to constructed key
    final diseaseKey =
        result.fullLabel ?? '${result.cropName}___${result.diseaseName}';

    try {
      final data = await TreatmentApiService.getTreatments(diseaseKey);
      if (mounted) {
        if (data != null) {
          _diseaseData = data;
          final allTreatments = data['treatments'] as List<dynamic>? ?? [];

          // Select first of each type
          _selectedOrganicTreatment = _findTreatment(allTreatments, true);
          _selectedChemicalTreatment = _findTreatment(allTreatments, false);
        } else {
          _errorMessage = 'Could not load treatments. Using default advice.';
          _setFallbackData();
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching treatments: $e');
      if (mounted) {
        _errorMessage = 'Connection error. Using offline advice.';
        _setFallbackData();
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic>? _findTreatment(List<dynamic> treatments, bool organic) {
    for (final t in treatments) {
      if (t is Map<String, dynamic> &&
          (t['is_organic'] == organic ||
              t['type'] == (organic ? 'organic' : 'chemical'))) {
        return t;
      }
    }
    return null;
  }

  void _setFallbackData() {
    _selectedOrganicTreatment = {
      'name': 'General Organic Management',
      'steps': [
        {
          'action': 'Remove affected leaves',
          'icon': '🍂',
          'timeframe': 'today',
        },
        {
          'action': 'Apply neem oil solution',
          'icon': '🌿',
          'timeframe': 'today',
        },
      ],
    };
    _selectedChemicalTreatment = {
      'name': 'Standard Chemical Control',
      'steps': [
        {'action': 'Wear protective gear', 'icon': '🧤', 'timeframe': 'today'},
        {
          'action': 'Apply recommended fungicide',
          'icon': '🧪',
          'timeframe': 'today',
        },
      ],
    };
  }

  /// SPEECH TEXT
  String _buildTreatmentSpeech() {
    if (!result.hasDisease) {
      return "Good news! Your crop appears healthy.";
    }

    final treatment = showOrganicTreatment
        ? _selectedOrganicTreatment
        : _selectedChemicalTreatment;
    if (treatment == null) return "No specific treatments available.";

    final steps = treatment['steps'] as List<dynamic>? ?? [];
    String speech =
        "Detected disease ${result.diseaseName}. Treatment: ${treatment['name']}. ";

    for (var step in steps) {
      speech += "${step['action']}. ";
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

  /// Print/Save treatment plan
  Future<void> _shareTreatmentPlan() async {
    await AudioService.playButtonClick();

    final treatment = showOrganicTreatment
        ? _selectedOrganicTreatment
        : _selectedChemicalTreatment;
    if (treatment == null) return;

    final steps = treatment['steps'] as List<dynamic>? ?? [];

    String planText =
        '''
🌿 CROP CARE TREATMENT PLAN
================================
Crop: ${result.cropName}
Condition: ${AIModelService.getDiseaseDisplayName(result)}
Confidence: ${AIModelService.getConfidenceDisplay(result.confidence)}
Method: ${treatment['name']}

📋 TREATMENT STEPS:
''';

    for (int i = 0; i < steps.length; i++) {
      final s = steps[i];
      planText += '\n${i + 1}. ${s['action']} (${s['timeframe'] ?? 'today'})';
    }

    if (_diseaseData?['prevention'] != null) {
      planText += '\n\n🛡️ PREVENTION TIPS:';
      for (var p in (_diseaseData!['prevention'] as List)) {
        planText += '\n• ${p['action']}';
      }
    }

    planText +=
        '\n\n📅 Generated: ${DateTime.now().toString().split('.')[0]}\n🌱 Green-Hulk App';

    await Share.share(
      planText,
      subject: 'Treatment Plan - ${result.diseaseName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Treatment Plan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Treatment Plan"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTreatmentPlan,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTreatmentTab(),
                _buildPreventionTab(),
                _buildRemedyTab(),
              ],
            ),
          ),
          _buildRatingAndActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Text(
            AIModelService.getDiseaseDisplayName(result),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(
                AIModelService.getConfidenceDisplay(result.confidence),
                _getConfidenceColor(result.confidence),
              ),
              if (result.severity != null) ...[
                const SizedBox(width: 8),
                _buildBadge(
                  result.severity!,
                  _getSeverityColor(result.severity!),
                ),
              ],
            ],
          ),
          if (_diseaseData?['description'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _diseaseData!['description'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTabHeader() {
    return TabBar(
      controller: _tabController,
      labelColor: AppTheme.primaryGreen,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppTheme.primaryGreen,
      tabs: const [
        Tab(text: "Treatments", icon: Icon(Icons.medication_liquid)),
        Tab(text: "Prevention", icon: Icon(Icons.shield)),
        Tab(text: "Remedies", icon: Icon(Icons.home_repair_service)),
      ],
    );
  }

  Widget _buildTreatmentTab() {
    if (!result.hasDisease) {
      return _buildHealthyState();
    }

    final treatment = showOrganicTreatment
        ? _selectedOrganicTreatment
        : _selectedChemicalTreatment;

    return Column(
      children: [
        _buildOrganicToggle(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeButton("Organic", showOrganicTreatment, () {
                  setState(() => showOrganicTreatment = true);
                }, enabled: !organicOnlyMode),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeButton("Chemical", !showOrganicTreatment, () {
                  setState(() => showOrganicTreatment = false);
                }, enabled: !organicOnlyMode),
              ),
            ],
          ),
        ),
        Expanded(
          child: treatment == null
              ? _buildEmptyState(
                  "No ${showOrganicTreatment ? 'organic' : 'chemical'} treatments found.",
                )
              : _buildStepsList(treatment),
        ),
      ],
    );
  }

  Widget _buildOrganicToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco, color: AppTheme.organicGreen, size: 20),
          const SizedBox(width: 8),
          const Text(
            "Prefer Organic",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Switch(
            value: organicOnlyMode,
            activeThumbColor: AppTheme.organicGreen,
            onChanged: (val) {
              AudioService.playButtonClick();
              setState(() {
                organicOnlyMode = val;
                if (val) showOrganicTreatment = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    String label,
    bool active,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? AppTheme.primaryGreen : Colors.grey.shade100,
        foregroundColor: active ? Colors.white : Colors.grey.shade700,
        elevation: active ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStepsList(Map<String, dynamic> treatment) {
    final steps = treatment['steps'] as List<dynamic>? ?? [];
    final safety = treatment['safety_warnings'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          treatment['name'] ?? "Recommended Actions",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final isToday =
              (s['timeframe'] as String?).toString().toLowerCase() == 'today';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isToday ? AppTheme.primaryGreen : Colors.blue)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    s['icon'] ?? (i + 1).toString(),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              title: Text(
                s['action'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                isToday ? "DO THIS TODAY" : "FOLLOW-UP WITHIN A WEEK",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isToday ? AppTheme.primaryGreen : Colors.blue,
                ),
              ),
            ),
          );
        }),
        if (safety.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Safety Warnings",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...safety.map(
                  (msg) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "• $msg",
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreventionTab() {
    final prevention = _diseaseData?['prevention'] as List? ?? [];
    if (prevention.isEmpty) {
      return _buildEmptyState("No specific prevention tips found.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prevention.length,
      itemBuilder: (context, i) {
        final item = prevention[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.shield, color: Colors.blue),
            title: Text(item['action']),
            subtitle: Text("Priority: ${item['importance'] ?? 'Normal'}"),
          ),
        );
      },
    );
  }

  Widget _buildRemedyTab() {
    final remedies = _diseaseData?['home_remedies'] as List? ?? [];
    if (remedies.isEmpty) {
      return _buildEmptyState(
        "No home remedies documented for this condition.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: remedies.length,
      itemBuilder: (context, i) {
        final r = remedies[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              r['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Effectiveness: ${(r['effectiveness'] * 100).toInt()}%",
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ingredients:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...(r['ingredients'] as List).map((ing) => Text("• $ing")),
                    const SizedBox(height: 8),
                    const Text(
                      "Preparation:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(r['preparation']),
                    const SizedBox(height: 8),
                    const Text(
                      "Frequency:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(r['frequency']),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          const Text(
            "Healthy Crop!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "No treatment plan is currently needed.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade300, size: 100),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingAndActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Was this helpful?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => _onRatingSelected(index + 1),
                    child: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 24,
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: speaking ? stopSpeaking : speakTreatment,
                  icon: Icon(speaking ? Icons.stop : Icons.volume_up),
                  label: Text(speaking ? "Stop" : "Listen"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/crops',
                      (r) => r.isFirst,
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("New Scan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onRatingSelected(int score) {
    if (!mounted) return;
    AudioService.playButtonClick();
    setState(() => rating = score);
    result.rating = score;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Thanks for the reward! $score stars."),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'early stage':
        return Colors.blue;
      case 'medium':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
