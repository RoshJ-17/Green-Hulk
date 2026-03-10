// lib/widgets/medicine_calculator_widget.dart
import 'package:flutter/material.dart';

/// Inline medicine-dosage calculator for the treatment screen.
/// User enters farm size -> shows dosage, water, buckets/tanks needed.
class MedicineCalculatorWidget extends StatefulWidget {
  final Map<String, dynamic>? chemicalTreatment;

  const MedicineCalculatorWidget({super.key, this.chemicalTreatment});

  @override
  State<MedicineCalculatorWidget> createState() =>
      _MedicineCalculatorWidgetState();
}

class _MedicineCalculatorWidgetState extends State<MedicineCalculatorWidget> {
  final _areaController = TextEditingController(text: '1');
  String _unit = 'acre';
  bool _expanded = false;

  double get _dosageMlPerAcre {
    final d = widget.chemicalTreatment?['dosage_ml_per_acre'];
    if (d is num) return d.toDouble();
    return 500;
  }

  double get _waterLPerAcre {
    final w = widget.chemicalTreatment?['water_liters_per_acre'];
    if (w is num) return w.toDouble();
    return 200;
  }

  String get _medicineName =>
      widget.chemicalTreatment?['name'] as String? ?? 'Recommended Pesticide';

  double get _areaInAcres {
    final raw = double.tryParse(_areaController.text) ?? 1;
    if (_unit == 'hectare') return raw * 2.471;
    if (_unit == 'bigha') return raw * 0.625;
    return raw;
  }

  double get _totalDosageMl => _dosageMlPerAcre * _areaInAcres;
  double get _totalWaterL => _waterLPerAcre * _areaInAcres;
  int get _buckets15L => (_totalWaterL / 15).ceil();
  int get _tanks200L => (_totalWaterL / 200).ceil();

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.calculate, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Medicine Dosage Calculator',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text(
                    'Medicine: $_medicineName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _areaController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Farm Size',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: _unit,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'acre', child: Text('Acre')),
                            DropdownMenuItem(
                                value: 'hectare', child: Text('Hectare')),
                            DropdownMenuItem(
                                value: 'bigha', child: Text('Bigha')),
                          ],
                          onChanged: (v) =>
                              setState(() => _unit = v ?? 'acre'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _resultCard(
                        '\ud83d\udc8a Dosage',
                        '${_totalDosageMl.toStringAsFixed(0)} ml',
                        Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      _resultCard(
                        '\ud83d\udca7 Water',
                        '${_totalWaterL.toStringAsFixed(0)} L',
                        Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _resultCard(
                        '\ud83e\udea3 Buckets (15L)',
                        '$_buckets15L',
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _resultCard(
                        '\ud83d\udee2\ufe0f Tanks (200L)',
                        '$_tanks200L',
                        Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.science,
                                color: Colors.amber, size: 18),
                            SizedBox(width: 6),
                            Text('Mixing Guide',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '1. Fill tank half with clean water\n'
                          '2. Add ${_totalDosageMl.toStringAsFixed(0)} ml of $_medicineName\n'
                          '3. Stir well for 2 minutes\n'
                          '4. Top up to ${_totalWaterL.toStringAsFixed(0)} litres\n'
                          '5. Use within 4 hours of mixing',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade800),
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

  Widget _resultCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8))),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
