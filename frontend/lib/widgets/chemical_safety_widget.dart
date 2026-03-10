// lib/widgets/chemical_safety_widget.dart
import 'package:flutter/material.dart';

/// Shows chemical safety information: danger labels, safety gear checklist,
/// pollinator warning, and hand-wash reminder.
class ChemicalSafetyWidget extends StatelessWidget {
  final Map<String, dynamic>? chemicalTreatment;

  const ChemicalSafetyWidget({super.key, this.chemicalTreatment});

  String get _toxicityLevel {
    final t = chemicalTreatment?['toxicity'];
    if (t is String) return t;
    return 'Moderate';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety,
                  color: Colors.red, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Chemical Safety \u26a0\ufe0f',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.red,
                  ),
                ),
              ),
              _dangerBadge(),
            ],
          ),
          const SizedBox(height: 12),

          const Text('Required Safety Gear:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          _gearItem(Icons.back_hand, 'Chemical-resistant gloves'),
          _gearItem(Icons.masks, 'Face mask / respirator'),
          _gearItem(Icons.visibility, 'Safety goggles'),
          _gearItem(Icons.checkroom, 'Long-sleeve clothing'),
          _gearItem(Icons.do_not_step, 'Rubber boots'),

          const SizedBox(height: 12),

          // Pollinator warning
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Row(
              children: [
                Text('\ud83d\udc1d', style: TextStyle(fontSize: 22)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pollinator Warning',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 2),
                      Text(
                        'Do NOT spray when bees are active (10am\u20134pm). '
                        'Spray in early morning or late evening to protect pollinators.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Wash hands reminder
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.wash, color: Colors.blue, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('After Spraying',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 2),
                      Text(
                        '\u2022 Wash hands and face thoroughly with soap\n'
                        '\u2022 Change and wash work clothes separately\n'
                        '\u2022 Do not eat, drink, or smoke while handling chemicals\n'
                        '\u2022 Store chemicals away from food and children',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dangerBadge() {
    Color badgeColor;
    String label;
    switch (_toxicityLevel.toLowerCase()) {
      case 'high':
      case 'very high':
        badgeColor = Colors.red;
        label = '\u2620\ufe0f HIGH DANGER';
        break;
      case 'low':
        badgeColor = Colors.green;
        label = '\u2713 LOW RISK';
        break;
      default:
        badgeColor = Colors.orange;
        label = '\u26a0 CAUTION';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeColor)),
    );
  }

  Widget _gearItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_box, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
