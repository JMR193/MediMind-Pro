import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/services/renal_hepatic_calculator_service.dart';
import '../../core/one_ui_widgets.dart';

class RenalGuardScreen extends StatefulWidget {
  const RenalGuardScreen({super.key});

  @override
  State<RenalGuardScreen> createState() => _RenalGuardScreenState();
}

class _RenalGuardScreenState extends State<RenalGuardScreen> {
  final _ageCtrl = TextEditingController(text: '65');
  final _weightCtrl = TextEditingController(text: '70');
  final _scrCtrl = TextEditingController(text: '1.2');
  bool _isFemale = false;

  double _crCl = 60.8;
  double _egfr = 58.4;
  List<RenalDoseGuideline> _guidelines = [];

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 65;
    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 70.0;
    final scr = double.tryParse(_scrCtrl.text.trim()) ?? 1.2;

    final crCl = RenalHepaticCalculatorService.calculateCockcroftGaultCrCl(
      age: age,
      weightKg: weight,
      serumCreatinineMgDl: scr,
      isFemale: _isFemale,
    );

    final egfr = RenalHepaticCalculatorService.calculateCkdEpiEgfr(
      age: age,
      serumCreatinineMgDl: scr,
      isFemale: _isFemale,
    );

    final repo = context.read<MedicationRepository>();
    final guidelines = RenalHepaticCalculatorService.evaluateRenalAdjustments(
      medications: repo.activeMedications,
      crCl: crCl,
    );

    setState(() {
      _crCl = crCl;
      _egfr = egfr;
      _guidelines = guidelines;
    });
  }

  String get _ckdStageLabel {
    if (_egfr >= 90) return 'CKD Stage 1 (Normal / High Kidney Function)';
    if (_egfr >= 60) return 'CKD Stage 2 (Mildly Decreased)';
    if (_egfr >= 45) return 'CKD Stage 3a (Mild to Moderate Loss)';
    if (_egfr >= 30) return 'CKD Stage 3b (Moderate to Severe Loss)';
    if (_egfr >= 15) return 'CKD Stage 4 (Severely Decreased)';
    return '🚨 CKD Stage 5 (Kidney Failure / ESRD)';
  }

  Color get _ckdStageColor {
    if (_egfr >= 60) return Colors.green;
    if (_egfr >= 45) return Colors.amber.shade700;
    if (_egfr >= 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renal & Hepatic Guard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Clinical Calculator Card
          OneUiWidgets.squircleCard(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate_outlined, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Text('RENAL FUNCTION CALCULATOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age (Years)', border: OutlineInputBorder()),
                        onChanged: (_) => _recalculate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                        onChanged: (_) => _recalculate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _scrCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Serum Creatinine (mg/dL)', border: OutlineInputBorder()),
                        onChanged: (_) => _recalculate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          const Text('Female:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Switch(
                            value: _isFemale,
                            onChanged: (val) {
                              setState(() => _isFemale = val);
                              _recalculate();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Computed Results Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_ckdStageColor.withAlpha(40), _ckdStageColor.withAlpha(15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _ckdStageColor.withAlpha(100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Creatinine Clearance (CrCl)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text('$_crCl mL/min', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('CKD-EPI eGFR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text('$_egfr mL/min/1.73m²', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _ckdStageColor)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _ckdStageLabel,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _ckdStageColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Prescriptions Safety Analysis
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 20),
              const SizedBox(width: 8),
              const Text('Active Medication Renal Adjustments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          if (_guidelines.isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No renally-impaired dosing flags detected for your current prescriptions at this CrCl level.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._guidelines.map((g) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(g.medicationName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: g.isContraindicated ? Colors.red.withAlpha(26) : Colors.orange.withAlpha(26),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                g.isContraindicated ? 'CONTRAINDICATED' : 'DOSE REDUCTION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: g.isContraindicated ? Colors.red : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Standard Dose: ${g.normalDosage}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('Target Renal Dose: ${g.recommendedRenalDose}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                        const SizedBox(height: 6),
                        Text(g.rationale, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
