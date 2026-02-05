import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';

// Task 11: Treatment Screen
class TreatmentScreen extends StatefulWidget {
  const TreatmentScreen({Key? key}) : super(key: key);

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  bool showOrganicTreatment = true;

  // Sample treatment data (in real app, this comes from AI diagnosis)
  final Map<String, dynamic> organicTreatment = {
    'type': 'Organic Treatment',
    'disease': 'Leaf Blight',
    'steps': [
      {
        'title': 'Remove Affected Leaves',
        'description': 'Carefully remove and destroy all infected leaves. Do not compost them.',
        'icon': Icons.cut,
      },
      {
        'title': 'Apply Neem Oil Spray',
        'description': 'Mix 5ml neem oil with 1 liter water. Spray on all plant surfaces in early morning.',
        'icon': Icons.water_drop,
      },
      {
        'title': 'Improve Air Circulation',
        'description': 'Space plants properly and prune dense foliage to reduce humidity around leaves.',
        'icon': Icons.air,
      },
      {
        'title': 'Apply Organic Fertilizer',
        'description': 'Use compost or vermicompost to strengthen plant immunity.',
        'icon': Icons.eco,
      },
    ],
  };

  final Map<String, dynamic> chemicalTreatment = {
    'type': 'Chemical Treatment',
    'disease': 'Leaf Blight',
    'steps': [
      {
        'title': 'Safety First',
        'description': 'Wear protective gloves, mask, and clothing before handling chemicals.',
        'icon': Icons.health_and_safety,
      },
      {
        'title': 'Apply Fungicide',
        'description': 'Use Copper Oxychloride 50% WP at 3g per liter. Spray thoroughly on all plant parts.',
        'icon': Icons.science,
      },
      {
        'title': 'Repeat Application',
        'description': 'Repeat spray after 10-12 days if symptoms persist. Maximum 3 applications.',
        'icon': Icons.repeat,
      },
      {
        'title': 'Harvest Interval',
        'description': 'Wait at least 15 days after last spray before harvesting.',
        'icon': Icons.warning,
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final treatment = showOrganicTreatment ? organicTreatment : chemicalTreatment;
    final steps = treatment['steps'] as List<Map<String, dynamic>>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treatment Plan'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Disease info header
            Container(
              color: AppTheme.lightGreen.withOpacity(0.2),
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                children: [
                  Text(
                    treatment['disease'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  if (showOrganicTreatment)
                    const OrganicBadge(isOrganic: true),
                ],
              ),
            ),

            // Treatment type toggle
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      'Organic',
                      Icons.eco,
                      showOrganicTreatment,
                      () => setState(() => showOrganicTreatment = true),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: _buildToggleButton(
                      'Chemical',
                      Icons.science,
                      !showOrganicTreatment,
                      () => setState(() => showOrganicTreatment = false),
                    ),
                  ),
                ],
              ),
            ),

            // Treatment steps
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  bottom: AppTheme.spacingLarge,
                ),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return TreatmentStepCard(
                    stepNumber: index + 1,
                    title: step['title'],
                    description: step['description'],
                    icon: step['icon'],
                    isOrganic: showOrganicTreatment,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.accentGreen : AppTheme.white,
        foregroundColor: isSelected ? AppTheme.white : AppTheme.primaryGreen,
        minimumSize: const Size(0, 52),
        side: BorderSide(
          color: isSelected ? AppTheme.accentGreen : AppTheme.lightGreen,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isSelected ? 3 : 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}