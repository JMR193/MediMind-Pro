import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/clinical_taper.dart';
import '../../../domain/models/medication.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/one_ui_widgets.dart';

class TaperingScheduleScreen extends StatelessWidget {
  const TaperingScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        final taperingMeds = repo.activeMedications.where((m) => m.taperPlan != null).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Clinical Tapering & Titration'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_task_rounded),
                tooltip: 'Add Taper Plan',
                onPressed: () => _showAddTaperSheet(context, repo),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OneUiWidgets.bannerCard(
                  context: context,
                  title: 'Step-Down Titration Protocols',
                  subtitle: 'Automated dosage step-downs for steroids and post-operative regimens.',
                  icon: Icons.trending_down_rounded,
                  accentColor: const Color(0xFF0D9488),
                ),
                const SizedBox(height: 16),

                if (taperingMeds.isEmpty)
                  _buildEmptyState(context, repo)
                else
                  ...taperingMeds.map((med) => _buildTaperCard(context, med, repo)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, MedicationRepository repo) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.timeline_rounded, size: 48, color: Colors.grey.withAlpha(120)),
              const SizedBox(height: 12),
              const Text('No Active Tapering Protocols', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              const Text(
                'Add a structured step-down plan for post-cataract steroid drops or oral medications.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Clinical Taper Plan'),
                onPressed: () => _showAddTaperSheet(context, repo),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaperCard(BuildContext context, Medication med, MedicationRepository repo) {
    final plan = med.taperPlan!;
    final currentStep = plan.currentStep;
    final progress = plan.overallProgressPercentage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0D9488).withAlpha(50), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0D9488).withAlpha(15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.trending_down_rounded, color: Color(0xFF0D9488)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(plan.indication, style: const TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: plan.isCompleted ? Colors.green.withAlpha(25) : const Color(0xFF0D9488).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  plan.isCompleted ? 'Completed' : 'Stage /',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: plan.isCompleted ? Colors.green : const Color(0xFF0D9488),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: Colors.grey.withAlpha(40),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('% completed', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(' of  total days', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),

          // Current Step Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Regimen: ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Day  of  in this stage. Times: ',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (currentStep.clinicalInstruction.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaperSheet(BuildContext context, MedicationRepository repo) {
    final availableMeds = repo.activeMedications;
    if (availableMeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a medication first before creating a taper plan.')),
      );
      return;
    }

    String selectedMedId = availableMeds.first.id;
    int selectedTemplate = 0; // 0: Post-Cataract, 1: Oral Steroid

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Clinical Taper Protocol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),

              const Text('Select Medication:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedMedId,
                items: availableMeds.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                onChanged: (val) {
                  if (val != null) setSheetState(() => selectedMedId = val);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Clinical Protocol Template:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              RadioListTile<int>(
                value: 0,
                groupValue: selectedTemplate,
                title: const Text('Post-Cataract Prednisolone Taper (4 Weeks)'),
                subtitle: const Text('Wk 1: 4x/day, Wk 2: 3x/day, Wk 3: 2x/day, Wk 4: 1x/day'),
                onChanged: (v) => setSheetState(() => selectedTemplate = v!),
              ),
              RadioListTile<int>(
                value: 1,
                groupValue: selectedTemplate,
                title: const Text('Oral Prednisone Step-Down (3 Weeks)'),
                subtitle: const Text('Wk 1: 40mg (2 tab), Wk 2: 20mg (1 tab), Wk 3: 10mg (0.5 tab)'),
                onChanged: (v) => setSheetState(() => selectedTemplate = v!),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final targetMed = repo.activeMedications.firstWhere((m) => m.id == selectedMedId);
                    ClinicalTaperPlan plan;

                    if (selectedTemplate == 0) {
                      plan = ClinicalTaperPlan(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        medicationName: targetMed.name,
                        indication: 'Post-Cataract Steroid Protocol',
                        startDate: DateTime.now(),
                        steps: const [
                          TitrationStep(stepNumber: 1, dosageAmount: 1, frequencyDescription: '4 times daily', timesOfDay: ['08:00', '12:00', '16:00', '20:00'], durationDays: 7, clinicalInstruction: 'Week 1: High anti-inflammatory suppression'),
                          TitrationStep(stepNumber: 2, dosageAmount: 1, frequencyDescription: '3 times daily', timesOfDay: ['08:00', '14:00', '20:00'], durationDays: 7, clinicalInstruction: 'Week 2: Moderate step-down'),
                          TitrationStep(stepNumber: 3, dosageAmount: 1, frequencyDescription: '2 times daily', timesOfDay: ['08:00', '20:00'], durationDays: 7, clinicalInstruction: 'Week 3: Maintenance step-down'),
                          TitrationStep(stepNumber: 4, dosageAmount: 1, frequencyDescription: 'Once daily', timesOfDay: ['08:00'], durationDays: 7, clinicalInstruction: 'Week 4: Final taper to prevent rebound uveitis'),
                        ],
                      );
                    } else {
                      plan = ClinicalTaperPlan(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        medicationName: targetMed.name,
                        indication: 'Oral Prednisone Taper Protocol',
                        startDate: DateTime.now(),
                        steps: const [
                          TitrationStep(stepNumber: 1, dosageAmount: 2, frequencyDescription: '40 mg daily (2 tabs)', timesOfDay: ['08:00'], durationDays: 7, clinicalInstruction: 'Week 1: High dose suppression'),
                          TitrationStep(stepNumber: 2, dosageAmount: 1, frequencyDescription: '20 mg daily (1 tab)', timesOfDay: ['08:00'], durationDays: 7, clinicalInstruction: 'Week 2: Moderate taper'),
                          TitrationStep(stepNumber: 3, dosageAmount: 0.5, frequencyDescription: '10 mg daily (0.5 tab)', timesOfDay: ['08:00'], durationDays: 7, clinicalInstruction: 'Week 3: Adrenal recovery taper'),
                        ],
                      );
                    }

                    final updated = targetMed.copyWith(
                      taperPlan: plan,
                      dosageAmount: plan.steps.first.dosageAmount,
                      frequency: plan.steps.first.frequencyDescription,
                      scheduleTimes: plan.steps.first.timesOfDay,
                    );

                    repo.updateMedication(updated);
                    Navigator.pop(ctx);
                    AppleGlassDecorations.mediumHaptic();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✓ Taper protocol attached to ${targetMed.name}')),
                    );
                  },
                  child: const Text('Attach Taper Protocol', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
