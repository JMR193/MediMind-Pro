import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/services/clinical_expert_ai_service.dart';
import '../../../data/services/behavioral_ml_engine.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/dose_log.dart';
import '../../core/apple_glass_decorations.dart';
import 'digital_twin_pk_card.dart';
import 'food_interaction_radar_card.dart';

class SmartChronotherapyAdvisorScreen extends StatefulWidget {
  const SmartChronotherapyAdvisorScreen({super.key});

  @override
  State<SmartChronotherapyAdvisorScreen> createState() => _SmartChronotherapyAdvisorScreenState();
}

class _SmartChronotherapyAdvisorScreenState extends State<SmartChronotherapyAdvisorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _sigInputController = TextEditingController(text: 'Metformin 500mg 1 TAB PO BID PC');
  ParsedMedicalSig? _parsedSig;
  String? _selectedPkMedication;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _parseCurrentSig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sigInputController.dispose();
    super.dispose();
  }

  void _parseCurrentSig() {
    setState(() {
      _parsedSig = ClinicalExpertAiService.parseDoctorSig(_sigInputController.text);
    });
  }

  void _applyChronotherapyOptimization(Medication med, String recommendedTime, MedicationRepository repo) {
    AppleGlassDecorations.heavyHaptic();
    final updated = med.copyWith(scheduleTimes: [recommendedTime]);
    repo.updateMedication(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Realigned ${med.name} to $recommendedTime for biological peak absorption!'),
        backgroundColor: const Color(0xFF0D9488),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFF0D9488)),
            SizedBox(width: 8),
            Text('AI Clinical & Chrono Advisor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF0D9488),
          indicatorColor: const Color(0xFF0D9488),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.access_time_filled_rounded, size: 20), text: 'Circadian AI'),
            Tab(icon: Icon(Icons.show_chart_rounded, size: 20), text: 'Digital Twin PK'),
            Tab(icon: Icon(Icons.restaurant_rounded, size: 20), text: 'Food & Diet AI'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Behavioral ML'),
            Tab(icon: Icon(Icons.translate_rounded, size: 20), text: 'Sig Decrypter'),
          ],
        ),
      ),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final meds = repo.activeMedications;
          final logs = repo.logs;

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Chronotherapy Circadian Alignment
              _buildCircadianTab(context, meds, repo),

              // Tab 2: Digital Twin Pharmacokinetic Blood Plasma Simulator
              _buildPkSimulatorTab(context, meds, logs),

              // Tab 3: Drug-Food-Nutrient Interaction AI Radar
              _buildFoodDietAiTab(context, meds),

              // Tab 4: Behavioral Machine Learning & Anomaly Radar
              _buildBehavioralMlTab(context, meds, logs, repo),

              // Tab 5: Doctor Sig Latin Shorthand Decrypter Playground
              _buildSigDecrypterTab(context, repo),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 1: CIRCADIAN CHRONOTHERAPY ALIGNMENT
  // ─────────────────────────────────────────────────────────────
  Widget _buildCircadianTab(BuildContext context, List<Medication> meds, MedicationRepository repo) {
    final evaluations = ClinicalExpertAiService.evaluateRegimen(meds);
    final total = evaluations.length;
    final alignedCount = evaluations.where((e) => e.isOptimallyAligned).length;
    final alignmentScore = total > 0 ? (alignedCount / total) * 100 : 100.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alignment Score Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: alignmentScore >= 80
                    ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
                    : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: alignmentScore >= 80 ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        value: alignmentScore / 100,
                        strokeWidth: 7,
                        backgroundColor: Colors.white,
                        color: alignmentScore >= 80 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                    ),
                    Text(
                      '${alignmentScore.toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: alignmentScore >= 80 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Circadian Synchronization Score',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alignmentScore >= 80
                            ? 'Optimal Biological Timing. Prescriptions coincide with internal organ rhythms.'
                            : '$alignedCount of $total evaluated medications match circadian peaks. Optimization recommended.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 24-Hour Circadian Biological Clock Reference
          _buildCircadianClockGuide(),
          const SizedBox(height: 18),

          // Active Regimen Chrono Evaluation Cards
          const Text(
            'Medication Chronobiological Evaluation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),

          if (evaluations.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text('No chronotherapy-sensitive medications currently active in cabinet.'),
              ),
            )
          else
            ...evaluations.map((eval) => _buildEvaluationCard(eval, repo)),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(ChronotherapyEvaluation eval, MedicationRepository repo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: eval.isOptimallyAligned ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  eval.isOptimallyAligned ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  color: eval.isOptimallyAligned ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    eval.medication.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: eval.isOptimallyAligned ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    eval.isOptimallyAligned ? 'OPTIMAL' : 'ADVISORY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: eval.isOptimallyAligned ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Scheduled: ${eval.currentScheduledTime}  →  Recommended: ${eval.recommendedTime}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
            ),
            const SizedBox(height: 6),
            Text(
              eval.rule.clinicalRationale,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
            ),
            if (!eval.isOptimallyAligned) ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => _applyChronotherapyOptimization(eval.medication, eval.recommendedTime, repo),
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: Text('Realign to ${eval.recommendedTime}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircadianClockGuide() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 6),
              Text('24-Hour Biological Organ Peaks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          _buildCircadianTimelineRow('06:00–08:30', '☀️ Morning Cortisol & Gastric Acid', 'Thyroid (T4), PPIs, Corticosteroids'),
          _buildCircadianTimelineRow('11:30–13:30', '🌤️ Midday Metabolic Peak', 'Insulin, Metformin, Sustained Release Doses'),
          _buildCircadianTimelineRow('20:30–23:00', '🌙 Nocturnal Hepatic Lipogenesis', 'Statins (Cholesterol synthesis peaks at 02:00 AM)'),
          _buildCircadianTimelineRow('04:00–07:00', '👁️ Early Morning Diurnal IOP Surge', 'Glaucoma Prostaglandins (Bedtime dosing required)'),
        ],
      ),
    );
  }

  Widget _buildCircadianTimelineRow(String time, String peak, String drugs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(peak, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text(drugs, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 2: DIGITAL TWIN PHARMACOKINETIC BLOOD PLASMA SIMULATOR
  // ─────────────────────────────────────────────────────────────
  Widget _buildPkSimulatorTab(BuildContext context, List<Medication> meds, List<DoseLog> logs) {
    final activeNames = meds.map((m) => m.name).toList();
    final defaultOptions = [
      if (activeNames.isNotEmpty) ...activeNames,
      'Atorvastatin',
      'Amlodipine',
      'Metoprolol',
      'Warfarin',
      'Metformin',
      'Levothyroxine',
      'Timolol',
    ];

    final currentMed = _selectedPkMedication ?? (activeNames.isNotEmpty ? activeNames.first : 'Atorvastatin');
    final relevantLogs = logs
        .where((l) => l.medicationName.toLowerCase().contains(currentMed.toLowerCase()))
        .map((l) => l.timestamp)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medication Selector Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppleGlassDecorations.frostedGlassBox(
              color: Colors.white,
              opacity: 0.9,
              borderRadius: 16,
              borderColor: const Color(0xFF0D9488).withAlpha(40),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medication_rounded, size: 18, color: Color(0xFF0D9488)),
                    const SizedBox(width: 8),
                    const Text(
                      'Select Drug for PK Simulation:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: defaultOptions.map((name) {
                      final isSelected = currentMed.toLowerCase() == name.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0D9488),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                          onSelected: (val) {
                            if (val) {
                              AppleGlassDecorations.lightHaptic();
                              setState(() => _selectedPkMedication = name);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Main Interactive Digital Twin PK Visualizer
          DigitalTwinPkCard(
            medicationName: currentMed,
            doseMg: 20.0,
            pastDoseTimestamps: relevantLogs,
          ),

          const SizedBox(height: 16),

          // Biomathematics Scientific Explainer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science_rounded, size: 16, color: Color(0xFF0D9488)),
                    SizedBox(width: 6),
                    Text(
                      'Bateman Pharmacokinetic Science',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F766E)),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'The 1-compartment Bateman open model simulates real-time blood plasma curves via extravascular absorption (ka) and hepatic/renal clearance (ke). When doses are taken late, plasma levels dip into the sub-therapeutic failure zone; double-dosing risks crossing the Minimum Toxic Concentration (MTC).',
                  style: TextStyle(fontSize: 11, color: Color(0xFF115E59), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 3: DRUG-FOOD-NUTRIENT INTERACTION AI RADAR
  // ─────────────────────────────────────────────────────────────
  Widget _buildFoodDietAiTab(BuildContext context, List<Medication> meds) {
    final medNames = meds.map((m) => m.name).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FoodInteractionRadarCard(
            activeMedicationNames: medNames,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFEA580C)),
                    SizedBox(width: 6),
                    Text(
                      'Biochemical Synergy & Chelation Notice',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFC2410C)),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Food interactions are governed by intestinal Cytochrome P450 3A4 inhibition (e.g. Grapefruit furanocoumarins), multivalent cation chelation (Calcium/Dairy binding antibiotics), and dietary competitive antagonism (Vitamin K greens counteracting Warfarin). Check before taking meals or supplements.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9A3412), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 4: BEHAVIORAL MACHINE LEARNING & ANOMALIES
  // ─────────────────────────────────────────────────────────────
  Widget _buildBehavioralMlTab(BuildContext context, List<Medication> meds, List<DoseLog> logs, MedicationRepository repo) {
    final riskProfile = BehavioralMlEngine.analyzeAdherenceRisk(medications: meds, logs: repo.logs);
    final adaptiveSuggestions = BehavioralMlEngine.calculateAdaptiveSuggestions(medications: meds, logs: repo.logs);
    final cognitiveAnomaly = BehavioralMlEngine.detectCognitiveDrift(logs: repo.logs);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Predictive Risk Overview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Predictive Adherence Risk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        riskProfile.overallRisk.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(riskProfile.clinicalSummary, style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.35)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Highest Drop-off Day: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Text(riskProfile.highestRiskDay, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    const Spacer(),
                    Text('Vulnerable Time: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Text(riskProfile.highestRiskTimeOfDay, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cognitive Latency Drift Card
          _buildCognitiveDriftCard(cognitiveAnomaly),
          const SizedBox(height: 16),

          // Smart Adaptive Schedule Suggestions
          const Text('Smart Adaptive Schedule Optimization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          if (adaptiveSuggestions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14)),
              child: const Text('No timing drift detected. Current alarm times perfectly match your daily routine.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else
            ...adaptiveSuggestions.map((sug) => _buildAdaptiveCard(sug, repo)),
        ],
      ),
    );
  }

  Widget _buildCognitiveDriftCard(CognitiveLatencyAnomaly anomaly) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: anomaly.isAnomalyDetected ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: anomaly.isAnomalyDetected ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                anomaly.isAnomalyDetected ? Icons.warning_amber_rounded : Icons.psychology_outlined,
                color: anomaly.isAnomalyDetected ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                anomaly.isAnomalyDetected ? 'Cognitive Response Latency Alert' : 'Cognitive Response Latency Monitor',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: anomaly.isAnomalyDetected ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(anomaly.alertMessage, style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3)),
          if (anomaly.isAnomalyDetected) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text(
                'Clinical Recommendation: ${anomaly.recommendedIntervention}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdaptiveCard(AdaptiveTimingRecommendation sug, MedicationRepository repo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sug.medication.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              'Scheduled: ${sug.currentScheduledTime}  →  Actual Routine: ${sug.proposedAdaptiveTime} (±${sug.varianceStandardDeviation.round()}m)',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 4),
            Text(sug.behavioralRationale, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                AppleGlassDecorations.mediumHaptic();
                final updated = sug.medication.copyWith(scheduleTimes: [sug.proposedAdaptiveTime]);
                repo.updateMedication(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated ${sug.medication.name} to ${sug.proposedAdaptiveTime}!')),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Synchronize to ${sug.proposedAdaptiveTime}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 3: MEDICAL 'SIG' LATIN SHORTHAND DECRYPTER
  // ─────────────────────────────────────────────────────────────
  Widget _buildSigDecrypterTab(BuildContext context, MedicationRepository repo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prescription Latin "Sig" Decrypter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'Type or paste doctor prescription shorthand (e.g. PO TID PC, 1 GTT OS QHS) to translate it instantly into clinical schedules.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          // Input TextField
          TextField(
            controller: _sigInputController,
            onChanged: (_) => _parseCurrentSig(),
            decoration: InputDecoration(
              labelText: 'Doctor Sig Shorthand',
              hintText: 'e.g. Latanoprost 0.005% 1 GTT OS QHS',
              prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0D9488)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _sigInputController.clear();
                  _parseCurrentSig();
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Preset Chips
          Wrap(
            spacing: 6,
            children: [
              _buildSigPresetChip('PO TID PC', 'Amoxicillin 500mg 1 TAB PO TID PC'),
              _buildSigPresetChip('1 GTT OS QHS', 'Latanoprost 0.005% 1 GTT OS QHS'),
              _buildSigPresetChip('1 TAB PO QAM AC', 'Omeprazole 20mg 1 TAB PO QAM AC'),
              _buildSigPresetChip('2 PUFF Q4H PRN', 'Albuterol 90mcg 2 PUFF Q4H PRN SOB'),
            ],
          ),
          const SizedBox(height: 16),

          // Decrypted Structured View
          if (_parsedSig != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Text('Natural Language Translation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _parsedSig!.englishTranslation,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
                  ),
                  const Divider(height: 20),
                  _buildSigAttribute('Drug Name', _parsedSig!.medicationName),
                  _buildSigAttribute('Strength', _parsedSig!.strength.isEmpty ? 'Standard' : _parsedSig!.strength),
                  _buildSigAttribute('Route & Form', '${_parsedSig!.category.name.toUpperCase()} (${_parsedSig!.dosageUnit.name})'),
                  _buildSigAttribute('Frequency', _parsedSig!.frequency),
                  _buildSigAttribute('Meal Instruction', _parsedSig!.instruction.name),
                  _buildSigAttribute('Schedule Times', _parsedSig!.scheduleTimes.join(', ')),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () {
                      AppleGlassDecorations.heavyHaptic();
                      final newMed = Medication(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _parsedSig!.medicationName,
                        strength: _parsedSig!.strength,
                        category: _parsedSig!.category,
                        dosageUnit: _parsedSig!.dosageUnit,
                        dosageAmount: _parsedSig!.dosageAmount,
                        instruction: _parsedSig!.instruction,
                        frequency: _parsedSig!.frequency,
                        scheduleTimes: _parsedSig!.scheduleTimes,
                        totalInventoryCount: 30,
                        refillThreshold: 5,
                        colorHex: '#0D9488',
                        iconName: _parsedSig!.category == MedCategory.eyeDrop ? 'eye_drop' : 'pill',
                        profileId: repo.activeProfileId,
                      );
                      repo.addMedication(newMed);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Added ${_parsedSig!.medicationName} to active cabinet!'),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('Add Decrypted Regimen to Cabinet', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildSigPresetChip(String label, String fullSig) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Color(0xFFCBD5E1)),
      onPressed: () {
        AppleGlassDecorations.lightHaptic();
        _sigInputController.text = fullSig;
        _parseCurrentSig();
      },
    );
  }

  Widget _buildSigAttribute(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text('$label:', style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
          Expanded(child: Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }
}
