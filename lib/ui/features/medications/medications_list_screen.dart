import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../core/utils.dart';
import '../../core/theme.dart';
import '../companion/medi_buddy_character.dart';
import '../medication_wizard/add_medication_screen.dart';

class MedicationsListScreen extends StatelessWidget {
  const MedicationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        final meds = repo.medications;

        if (meds.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MediBuddyCharacter(
                    mood: MediBuddyMood.happy,
                    outfit: MediBuddyOutfit.doctor,
                    size: 150,
                    customSpeechText: 'Your medicine cabinet is currently clean and empty! Tap below to add your first prescription.',
                  ),
                  const SizedBox(height: 16),
                  const Text('No Medications in Cabinet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tap below to add your scheduled pills, drops, or inhalers.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.withAlpha(179))),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMedicationScreen())),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Medication'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: meds.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _MedCard(medication: meds[i], repo: repo),
        );
      },
    );
  }
}

class _MedCard extends StatelessWidget {
  final Medication medication;
  final MedicationRepository repo;

  const _MedCard({required this.medication, required this.repo});

  @override
  Widget build(BuildContext context) {
    final med = medication;
    final color = hexToColor(med.colorHex);
    final icon = getMedicationIcon(med.iconName);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withAlpha(38), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          if (med.isHighPriorityAlarm)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: MediMindTheme.alertRed.withAlpha(26), borderRadius: BorderRadius.circular(6)),
                              child: const Text('CRITICAL', style: TextStyle(fontSize: 9, color: MediMindTheme.alertRed, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      Text('${med.strength}  ·  ${medCategoryLabel(med.category)}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(153))),
                      Text('${med.dosageAmount.toStringAsFixed(0)} ${dosageUnitLabel(med.dosageUnit)} · ${adminInstructionLabel(med.instruction)}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                // Schedule times
                const Icon(Icons.schedule_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(med.scheduleTimes.join(', '), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                // Inventory badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: med.needsRefill ? MediMindTheme.warningOrange.withAlpha(26) : color.withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(med.needsRefill ? Icons.warning_outlined : Icons.inventory_2_outlined, size: 12, color: med.needsRefill ? MediMindTheme.warningOrange : color),
                      const SizedBox(width: 4),
                      Text('${med.totalInventoryCount} left', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: med.needsRefill ? MediMindTheme.warningOrange : color)),
                    ],
                  ),
                ),
              ],
            ),
            if (med.requiresEyeDropProtocol) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.remove_red_eye_outlined, size: 13, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 4),
                  Text('Eye Protocol: ${med.eyeTarget} · ${med.eyeDropGapMinutes} min gap', style: const TextStyle(fontSize: 11, color: Color(0xFF7C3AED))),
                ],
              ),
            ],
            if (med.prescribingDoctor != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outlined, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(med.prescribingDoctor!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (med.rxNumber != null) ...[
                    const Text(' · ', style: TextStyle(color: Colors.grey)),
                    Text(med.rxNumber!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
