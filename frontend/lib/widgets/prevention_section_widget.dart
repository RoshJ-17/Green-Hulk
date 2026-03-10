// lib/widgets/prevention_section_widget.dart
import 'package:flutter/material.dart';

/// Enhanced prevention tab content with structured sections:
/// crop rotation, soil health, resistant seed varieties.
class PreventionSectionWidget extends StatelessWidget {
  final String cropName;
  final String diseaseName;
  final List<dynamic> apiPrevention;

  const PreventionSectionWidget({
    super.key,
    required this.cropName,
    required this.diseaseName,
    required this.apiPrevention,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Existing API prevention tips
        if (apiPrevention.isNotEmpty) ...[
          _sectionHeader(
              Icons.shield, 'Disease-Specific Prevention', Colors.blue),
          const SizedBox(height: 8),
          ...apiPrevention.map((item) => _preventionCard(
                item['action'] as String? ?? '',
                item['importance'] as String? ?? 'Normal',
              )),
          const SizedBox(height: 20),
        ],

        // Crop Rotation
        _sectionHeader(Icons.rotate_right, 'Crop Rotation', Colors.green),
        const SizedBox(height: 8),
        _infoCard(
          icon: '\ud83d\udd04',
          title: 'Why Rotate Crops?',
          content:
              'Rotating crops breaks disease cycles. Pathogens that '
              'attack $cropName will die off when a different crop family '
              'is planted in the same soil.',
        ),
        _tipCard(
            'Rotate every 2\u20133 seasons with a different crop family'),
        _tipCard(
            'Avoid planting $cropName in the same spot for consecutive years'),
        _tipCard(
            'Good rotation partners: legumes (add nitrogen), cereals, root vegetables'),
        _tipCard(
            'Keep at least 3 years before returning $cropName to the same plot'),
        const SizedBox(height: 20),

        // Soil Health
        _sectionHeader(Icons.grass, 'Soil Health', Colors.brown),
        const SizedBox(height: 8),
        _infoCard(
          icon: '\ud83c\udf31',
          title: 'Healthy Soil = Healthy Plants',
          content:
              'Good soil health builds natural disease resistance. '
              'Balanced pH, organic matter, and beneficial microorganisms '
              'help plants fight infections.',
        ),
        _tipCard(
            'Test soil pH annually \u2014 most crops prefer pH 6.0\u20137.0'),
        _tipCard(
            'Add compost or well-rotted manure to improve soil structure'),
        _tipCard('Use mulch to maintain moisture and suppress weeds'),
        _tipCard('Avoid waterlogging \u2014 ensure proper drainage'),
        _tipCard(
            'Apply bio-fertilizers (Trichoderma, Pseudomonas) to suppress soil pathogens'),
        const SizedBox(height: 20),

        // Resistant Seeds
        _sectionHeader(Icons.eco, 'Resistant Varieties', Colors.teal),
        const SizedBox(height: 8),
        _infoCard(
          icon: '\ud83c\udf3e',
          title: 'Choose Wisely',
          content:
              'Planting disease-resistant varieties is the most effective '
              'long-term strategy. Ask your local seed supplier for varieties '
              'resistant to ${diseaseName.replaceAll('_', ' ')}.',
        ),
        _tipCard(
            'Look for certified disease-resistant seeds when buying'),
        _tipCard(
            'Check with your local agricultural extension office for recommended varieties'),
        _tipCard('Use treated seeds to prevent soil-borne infections'),
        _tipCard(
            'Keep records of which varieties performed best on your farm'),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(content,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _tipCard(String tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.tips_and_updates,
            color: Colors.amber, size: 20),
        title: Text(tip, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _preventionCard(String action, String importance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.shield, color: Colors.blue),
        title: Text(action),
        subtitle: Text('Priority: $importance'),
      ),
    );
  }
}
