import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../core/theme.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/one_ui_widgets.dart';

class DigitalPillboxScreen extends StatelessWidget {
  const DigitalPillboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        final profile = repo.activeProfile;
        final morning = repo.morningMeds;
        final afternoon = repo.afternoonMeds;
        final evening = repo.eveningMeds;
        final night = repo.nightMeds;

        return Scaffold(
          appBar: AppBar(
            title: Text('Pillbox: '),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Pillbox Guidelines',
                onPressed: () => _showPillboxGuidelines(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header overview
                OneUiWidgets.bannerCard(
                  context: context,
                  title: 'Daily 4-Slot Digital Pillbox',
                  subtitle: 'Visual morning-to-night sorting with 1-tap batch logging.',
                  icon: Icons.grid_view_rounded,
                  accentColor: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 16),

                // Slot 1: Morning (05:00 - 10:59)
                _buildPillSlot(
                  context: context,
                  repo: repo,
                  slotTitle: 'Morning Slot',
                  timeRange: '05:00 AM – 10:59 AM',
                  icon: Icons.wb_sunny_rounded,
                  accentColor: const Color(0xFFEA580C),
                  medications: morning,
                ),
                const SizedBox(height: 16),

                // Slot 2: Afternoon (11:00 - 15:59)
                _buildPillSlot(
                  context: context,
                  repo: repo,
                  slotTitle: 'Afternoon Slot',
                  timeRange: '11:00 AM – 03:59 PM',
                  icon: Icons.wb_twilight_rounded,
                  accentColor: const Color(0xFF0284C7),
                  medications: afternoon,
                ),
                const SizedBox(height: 16),

                // Slot 3: Evening (16:00 - 20:59)
                _buildPillSlot(
                  context: context,
                  repo: repo,
                  slotTitle: 'Evening Slot',
                  timeRange: '04:00 PM – 08:59 PM',
                  icon: Icons.wb_sunny_outlined,
                  accentColor: const Color(0xFF7C3AED),
                  medications: evening,
                ),
                const SizedBox(height: 16),

                // Slot 4: Bedtime / Night (21:00 - 04:59)
                _buildPillSlot(
                  context: context,
                  repo: repo,
                  slotTitle: 'Bedtime Slot',
                  timeRange: '09:00 PM – 04:59 AM',
                  icon: Icons.bedtime_rounded,
                  accentColor: const Color(0xFF1E293B),
                  medications: night,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillSlot({
    required BuildContext context,
    required MedicationRepository repo,
    required String slotTitle,
    required String timeRange,
    required IconData icon,
    required Color accentColor,
    required List<Medication> medications,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withAlpha(50), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Slot Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slotTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
                      Text(timeRange, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                if (medications.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Take All'),
                    onPressed: () {
                      AppleGlassDecorations.mediumHaptic();
                      repo.takeAllSlotDoses(slotTitle);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Marked all  medications as taken.'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Slot Medication Items
          if (medications.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.grey.withAlpha(100), size: 18),
                  const SizedBox(width: 8),
                  Text('No doses scheduled for ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: medications.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, idx) {
                final med = medications[idx];
                return Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(med.colorHex.replaceAll('#', '0xFF'))).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        med.category == MedCategory.eyeDrop || med.category == MedCategory.eyeOintment
                            ? Icons.water_drop_outlined
                            : Icons.medication_outlined,
                        color: Color(int.parse(med.colorHex.replaceAll('#', '0xFF'))),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '  •  ()',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                      tooltip: 'Take this dose',
                      onPressed: () {
                        AppleGlassDecorations.lightHaptic();
                        repo.logDose(
                          medication: med,
                          scheduledTime: med.scheduleTimes.first,
                          status: LogStatus.taken,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✓ Took ')),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _showPillboxGuidelines(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: Color(0xFF0284C7)),
                SizedBox(width: 8),
                Text('Digital Pillbox Clinical Guidelines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Morning: Thyroid meds (Levothyroxine) on empty stomach 30m before breakfast.\n'
              '• Afternoon: Multi-vitamins, midday antibiotics.\n'
              '• Evening: Blood pressure, cholesterol, dinner-paired meds.\n'
              '• Bedtime: Glaucoma eye drops (Latanoprost), statins, bedtime ointments.\n'
              '• Eye Drop Spacing: Wait 5-10 minutes between multiple eye drops to avoid drug washout.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Understood'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
