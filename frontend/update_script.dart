import 'dart:io';

void main() {
  var file = File(r'c:\Users\druva\Developer\Software-plant-diagnosis\Green-Hulk\frontend\lib\screens\treatment_screen.dart');
  var content = file.readAsStringSync();

  content = content.replaceFirst(
    'import \'../services/treatment_api_service.dart\';',
    'import \'../services/gemini_treatment_service.dart\';\nimport \'../widgets/ai_chat_bottom_sheet.dart\';'
  );

  var startIndex = content.indexOf('  /// Fetch treatments from backend API');
  var endIndex = content.indexOf('  Map<String, dynamic>? _findTreatment(List<dynamic> treatments, bool organic) {');

  if (startIndex != -1 && endIndex != -1) {
    var newMethod = '''  /// Fetch AI-generated treatment plan
  Future<void> _fetchTreatments() async {
    if (!result.hasDisease) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final lang = context.read<AppState>().locale.languageCode;
      final data = await GeminiTreatmentService.fetchTreatmentPlan(
          result.cropName, result.diseaseName, lang);

      if (!mounted) return;

      _diseaseData = data;
      if (lang != 'en') {
        _translatedDiseaseName = await GeminiTranslationService.translate(result.diseaseName, lang);
      } else {
        _translatedDiseaseName = result.diseaseName;
      }

      final allTreatments = _diseaseData!['treatments'] as List<dynamic>? ?? [];

      _selectedOrganicTreatment = _findTreatment(allTreatments, true);
      _selectedChemicalTreatment = _findTreatment(allTreatments, false);
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching treatments from AI: ');
      if (!mounted) return;
      _errorMessage = 'Could not load AI treatments. Using default offline advice.';
      _setFallbackData();
      setState(() => _isLoading = false);
    }
  }

''';
    content = content.replaceRange(startIndex, endIndex, newMethod);
    file.writeAsStringSync(content);
    print('Updated successfully!');
  } else {
    print('Failed to find markers.');
  }
}
