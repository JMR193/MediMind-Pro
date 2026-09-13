import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/medication_log.dart';
import '../../core/utils.dart';
import '../../core/theme.dart';
import '../medication_wizard/add_medication_screen.dart';
import '../eye_drop_assistant/eye_drop_screen.dart';

/// Full-screen high-priority alarm overlay for critical medications
/// (Insulin, Anticoagulants, Anti-rejection drugs)
class AlarmModalScreen extends StatelessWidget {
  final Medication medication;

  const AlarmModalScreen({super.key, required this.medication});

  @override
  Widget build(BuildContext context) {
    final icon = getMedicationIcon(medication.iconName);

    return Scaffold(
      backgroundColor: MediMindTheme.alertRed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Alarm header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 24),
              const Text('⚠️  CRITICAL MEDICATION ALARM', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Text(medication.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('${medication.dosageAmount.toStringAsFixed(0)} ${dosageUnitLabel(medication.dosageUnit)} · ${medication.strength}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(adminInstructionLabel(medication.instruction),
                  style: const TextStyle(color: Colors.white60, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              // Doctor / Rx info
              if (medication.prescribingDoctor != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outlined, color: Colors.white70, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Prescribed by: ${medication.prescribingDoctor}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            if (medication.rxNumber != null)
                              Text('Rx: ${medication.rxNumber}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (medication.clinicalNotes != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white60, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(medication.clinicalNotes!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Action buttons
              FilledButton.icon(
                onPressed: () => _takeDose(context),
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: const Text('TAKE DOSE NOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: MediMindTheme.alertRed,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _snooze(context),
                      icon: const Icon(Icons.snooze_outlined, color: Colors.white),
                      label: const Text('Snooze 15m', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _skipWithReason(context),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.white70),
                      label: const Text('Skip', style: TextStyle(color: Colors.white70)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AddMedicationScreen(editMedication: medication))),
                child: const Text('Edit Medication', style: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _takeDose(BuildContext context) {
    final repo = context.read<MedicationRepository>();
    repo.logDose(
      medication: medication,
      scheduledTime: medication.scheduleTimes.isNotEmpty ? medication.scheduleTimes.first : '00:00',
      status: LogStatus.taken,
    );
    if (medication.requiresEyeDropProtocol) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EyeDropScreen()));
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${medication.name} taken — dose recorded.'), backgroundColor: MediMindTheme.successGreen),
      );
    }
  }

  void _snooze(BuildContext context) {
    final repo = context.read<MedicationRepository>();
    repo.logDose(
      medication: medication,
      scheduledTime: medication.scheduleTimes.isNotEmpty ? medication.scheduleTimes.first : '00:00',
      status: LogStatus.snoozed,
      notes: 'Snoozed for 15 minutes from alarm overlay',
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⏰ Alarm snoozed for 15 minutes.')));
  }

  void _skipWithReason(BuildContext context) {
    Navigator.pop(context);
    final repo = context.read<MedicationRepository>();
    repo.logDose(
      medication: medication,
      scheduledTime: medication.scheduleTimes.isNotEmpty ? medication.scheduleTimes.first : '00:00',
      status: LogStatus.skipped,
      skipReason: 'Dismissed from critical alarm overlay',
    );
  }
}
