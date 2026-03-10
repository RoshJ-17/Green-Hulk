import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_result.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/ai_model_service.dart';
import '../services/audio_service.dart';
import '../services/treatment_api_service.dart';
import '../services/app_state.dart';
import '../services/localization_service.dart';
import '../services/gemini_translation_service.dart';
import '../widgets/weather_advisory_card.dart';
import '../widgets/medicine_calculator_widget.dart';
import '../widgets/chemical_safety_widget.dart';
import '../widgets/prevention_section_widget.dart';

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
  String _langCode = 'en';

  static const _ttsLocaleMap = {
    'en': 'en-IN', 'hi': 'hi-IN', 'ta': 'ta-IN',
    'te': 'te-IN', 'kn': 'kn-IN', 'bn': 'bn-IN', 'pa': 'pa-IN',
  };

  // Translated disease name for TTS
  String? _translatedDiseaseName;

  // API-fetched treatment data
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _diseaseData;

  // Structured treatment data
  Map<String, dynamic>? _selectedOrganicTreatment;
  Map<String, dynamic>? _selectedChemicalTreatment;

  // Heatmap
  bool           _showHeatmap   = false;
  Uint8List?     _heatmapBytes;
  bool           _heatmapLoading = false;

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
      if (!mounted) return;
      setState(() => speaking = false);
    });

    _fetchTreatments();
    _decodeHeatmap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = context.read<AppState>().locale.languageCode;
    if (lang != _langCode) {
      _langCode = lang;
      _configureTts(lang);
    }
  }

  Future<void> _configureTts(String langCode) async {
    final locale = _ttsLocaleMap[langCode] ?? 'en-IN';
    await tts.setLanguage(locale);
    await tts.setSpeechRate(0.45);
    await tts.setVolume(1.0);
  }

  // ── Heatmap ──────────────────────────────────────────────────────────────

  void _decodeHeatmap() {
    if (result.heatmapPng == null) return;
    try {
      _heatmapBytes = base64Decode(result.heatmapPng!);
    } catch (_) {}
  }

  Future<void> _fetchHeatmapIfNeeded() async {
    if (_heatmapBytes != null || result.heatmapPng != null) {
      setState(() => _showHeatmap = !_showHeatmap);
      return;
    }

    // Heatmap wasn't requested at scan time → fetch it now
    setState(() => _heatmapLoading = true);
    try {
      final refreshed = await AIModelService.analyzeImage(
        imagePath: result.imagePath,
        cropName: result.cropName,
        withHeatmap: true,
      );

      if (!mounted) return;

      if (refreshed.heatmapPng != null) {
        _heatmapBytes = base64Decode(refreshed.heatmapPng!);
        setState(() {
          _showHeatmap = true;
          _heatmapLoading = false;
        });
      }
      if (refreshed.heatmapPng != null && mounted) {
        _heatmapBytes = base64Decode(refreshed.heatmapPng!);
        setState(() {
          _showHeatmap   = true;
          _heatmapLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _heatmapLoading = false);
    }
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
    if (!mounted) return;
    setState(() => _isLoading = false);
    return;
  }

  final diseaseKey =
      result.fullLabel ?? '${result.cropName}___${result.diseaseName}';

  try {
    final data = await TreatmentApiService.getTreatments(diseaseKey);

    if (!mounted) return;

    if (data != null) {
      final translated = await _translateDiseaseData(data, _langCode);

      if (!mounted) return;

      _diseaseData = translated;

      if (_langCode != 'en') {
        _translatedDiseaseName =
            await GeminiTranslationService.translate(result.diseaseName, _langCode);
      } else {
        _translatedDiseaseName = result.diseaseName;
      }

      if (!mounted) return;

      final allTreatments = _diseaseData!['treatments'] as List<dynamic>? ?? [];

      _selectedOrganicTreatment = _findTreatment(allTreatments, true);
      _selectedChemicalTreatment = _findTreatment(allTreatments, false);
    } else {
      _errorMessage = 'Could not load treatments. Using default advice.';
      _setFallbackData();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

  } catch (e) {
    debugPrint('Error fetching treatments: $e');

    if (!mounted) return;

    _errorMessage = 'Connection error. Using offline advice.';
    _setFallbackData();

    setState(() => _isLoading = false);
  }
}

  /// Deep-copies and translates relevant string fields in the treatment API
  /// response into [langCode].  Returns the mutated copy (or the original if
  /// translation is disabled / an error occurs).
  Future<Map<String, dynamic>> _translateDiseaseData(
      Map<String, dynamic> data, String langCode) async {
    if (langCode == 'en' || GeminiTranslationService.apiKey.isEmpty) {
      return data;
    }

    // Work on a shallow copy so we don't mutate the API cache
    final translated = Map<String, dynamic>.from(data);

    // Translate description
    if (translated['description'] is String) {
      translated['description'] = await GeminiTranslationService.translate(
          translated['description'] as String, langCode);
    }

    // Translate each treatment's name + steps
    if (translated['treatments'] is List) {
      final treatments = (translated['treatments'] as List).map((t) async {
        if (t is! Map) return t;
        final tMap = Map<String, dynamic>.from(t as Map<String, dynamic>);
        if (tMap['name'] is String) {
          tMap['name'] = await GeminiTranslationService.translate(
              tMap['name'] as String, langCode);
        }
        if (tMap['steps'] is List) {
          tMap['steps'] = await Future.wait(
            (tMap['steps'] as List).map((s) async {
              if (s is! Map) return s;
              final sMap = Map<String, dynamic>.from(s as Map<String, dynamic>);
              if (sMap['action'] is String) {
                sMap['action'] = await GeminiTranslationService.translate(
                    sMap['action'] as String, langCode);
              }
              return sMap;
            }),
          );
        }
        return tMap;
      });
      translated['treatments'] = await Future.wait(treatments);
    }

    // Translate prevention actions
    if (translated['prevention'] is List) {
      translated['prevention'] = await Future.wait(
        (translated['prevention'] as List).map((p) async {
          if (p is! Map) return p;
          final pMap = Map<String, dynamic>.from(p as Map<String, dynamic>);
          if (pMap['action'] is String) {
            pMap['action'] = await GeminiTranslationService.translate(
                pMap['action'] as String, langCode);
          }
          return pMap;
        }),
      );
    }

    // Translate remedies actions
    if (translated['remedies'] is List) {
      translated['remedies'] = await Future.wait(
        (translated['remedies'] as List).map((r) async {
          if (r is! Map) return r;
          final rMap = Map<String, dynamic>.from(r as Map<String, dynamic>);
          if (rMap['action'] is String) {
            rMap['action'] = await GeminiTranslationService.translate(
                rMap['action'] as String, langCode);
          }
          return rMap;
        }),
      );
    }

    return translated;
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
      return L10nService.tr('tts_healthy', _langCode);
    }

    final treatment = showOrganicTreatment
        ? _selectedOrganicTreatment
        : _selectedChemicalTreatment;
    if (treatment == null) {
      return L10nService.tr('tts_no_treatments', _langCode);
    }

    final steps = treatment['steps'] as List<dynamic>? ?? [];
    final detected = L10nService.tr('tts_detected', _langCode);
    final treatmentLabel = L10nService.tr('tts_treatment', _langCode);
    String speech = "$detected ${_translatedDiseaseName ?? result.diseaseName}. $treatmentLabel: ${treatment['name']}. ";

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
    if (!mounted) return;
    await AudioService.playButtonClick();

    final treatment = showOrganicTreatment
        ? _selectedOrganicTreatment
        : _selectedChemicalTreatment;
    if (treatment == null) return;

    final steps = treatment['steps'] as List<dynamic>? ?? [];
    final appState = context.read<AppState>();

    String planText =
        '''
🌿 CROP CARE TREATMENT PLAN
================================
Crop:      ${appState.trCrop(result.cropName)}
Condition: ${AIModelService.getDiseaseDisplayName(result)}
Severity:  ${result.severity ?? 'Unknown'}
Confidence:${AIModelService.getConfidenceDisplay(result.confidence)}
Method:    ${treatment['name']}

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
    final appState = context.watch<AppState>();
    // Update TTS locale whenever language changes
    final currentLang = appState.locale.languageCode;
    if (currentLang != _langCode) {
      _langCode = currentLang;
      _configureTts(currentLang);
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          title: Text(appState.tr('treatment_plan')),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          appState.tr('treatment_plan'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(
                AIModelService.getConfidenceDisplay(result.confidence),
                _getConfidenceColor(result.confidence),
              ),
              if (result.severity != null)
                _buildBadge(
                  result.severity!,
                  _getSeverityColor(result.severity!),
                ),
              // Heatmap toggle badge
              GestureDetector(
                onTap: _fetchHeatmapIfNeeded,
                child: _buildBadge(
                  _heatmapLoading
                      ? 'Loading heatmap…'
                      : _showHeatmap
                          ? '🌡 Hide Heatmap'
                          : '🌡 Show Heatmap',
                  Colors.deepOrange,
                ),
              ),
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

          // ── Grad-CAM heatmap panel ──────────────────────────────────────
          if (_showHeatmap && _heatmapBytes != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.memory(_heatmapBytes!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      color: Colors.black54,
                      child: const Text(
                        'Grad-CAM — Red areas influenced the diagnosis most',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final appState = context.read<AppState>();
    return TabBar(
      controller: _tabController,
      labelColor: AppTheme.primaryGreen,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppTheme.primaryGreen,
      tabs: [
        Tab(text: appState.tr('treatments'), icon: const Icon(Icons.medication_liquid)),
        Tab(text: appState.tr('prevention'), icon: const Icon(Icons.shield)),
        Tab(text: appState.tr('remedies'), icon: const Icon(Icons.home_repair_service)),
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

    return ListView(
      children: [
        // Weather Advisory (US3.3)
        const WeatherAdvisoryCard(),

        _buildOrganicToggle(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeButton(context.read<AppState>().tr('organic_tab'), showOrganicTreatment, () {
                  setState(() => showOrganicTreatment = true);
                }, enabled: !organicOnlyMode),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeButton(context.read<AppState>().tr('chemical_tab'), !showOrganicTreatment, () {
                  setState(() => showOrganicTreatment = false);
                }, enabled: !organicOnlyMode),
              ),
            ],
          ),
        ),
        if (treatment == null)
          _buildEmptyState(
            "No ${showOrganicTreatment ? 'organic' : 'chemical'} treatments found.",
          )
        else
          _buildStepsInline(treatment),

        // Chemical-only: Medicine Calculator (US3.4) & Safety (US3.5)
        if (!showOrganicTreatment) ...[  
          MedicineCalculatorWidget(chemicalTreatment: _selectedChemicalTreatment),
          ChemicalSafetyWidget(chemicalTreatment: _selectedChemicalTreatment),
        ],
      ],
    );
  }

  Widget _buildOrganicToggle() {
    final appState = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco, color: AppTheme.organicGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            appState.tr('prefer_organic'),
            style: const TextStyle(fontWeight: FontWeight.w600),
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

  /// Non-scrollable inline version of steps (used inside the outer ListView)
  Widget _buildStepsInline(Map<String, dynamic> treatment) {
    final steps = treatment['steps'] as List<dynamic>? ?? [];
    final safety = treatment['safety_warnings'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
    );
  }

  // Prevention Tab (US3.6 — enhanced)
  Widget _buildPreventionTab() {
    if (!result.hasDisease) {
      return _buildHealthyState();
    }

    final prevention = _diseaseData?['prevention'] as List? ?? [];
    return PreventionSectionWidget(
      cropName: result.cropName,
      diseaseName: result.diseaseName,
      apiPrevention: prevention,
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
    final appState = context.read<AppState>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          Text(
            appState.tr('healthy_crop'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            appState.tr('no_treatment_needed'),
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
              Text(
                context.watch<AppState>().tr('was_this_helpful'),
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                  label: Text(speaking ? context.read<AppState>().tr('stop') : context.read<AppState>().tr('listen')),
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
                  label: Text(context.read<AppState>().tr('new_scan')),
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
