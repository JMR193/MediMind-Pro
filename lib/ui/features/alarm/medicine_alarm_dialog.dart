import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/medication_log.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../companion/medi_buddy_character.dart';

class MedicineAlarmDialog extends StatefulWidget {
  final Medication medication;
  final String scheduledTime;

  const MedicineAlarmDialog({
    super.key,
    required this.medication,
    required this.scheduledTime,
  });

  static Future<void> show(BuildContext context, Medication medication, String scheduledTime) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MedicineAlarmDialog(medication: medication, scheduledTime: scheduledTime),
    );
  }

  @override
  State<MedicineAlarmDialog> createState() => _MedicineAlarmDialogState();
}

class _MedicineAlarmDialogState extends State<MedicineAlarmDialog> with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  late Animation<double> _bellAnimation;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _bellAnimation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  void _onTaken(MedicationRepository repo) {
    AppleGlassDecorations.heavyHaptic();
    repo.logDose(
      medication: widget.medication,
      scheduledTime: widget.scheduledTime,
      status: LogStatus.taken,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${widget.medication.name} recorded as TAKEN!'),
        backgroundColor: MediMindTheme.successGreen,
      ),
    );
  }

  void _onSnooze(MedicationRepository repo, int minutes) {
    AppleGlassDecorations.mediumHaptic();
    repo.snoozeDose(widget.medication, minutes);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⏰ ${widget.medication.name} snoozed for $minutes minutes.')),
    );
  }

  void _onSkip(MedicationRepository repo) {
    AppleGlassDecorations.lightHaptic();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason for Skipping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Tracking skip reasons helps your doctor and guardian optimize care:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            ...['Side effects', 'Felt unwell', 'Ran out of medicine', 'Doctor advised hold', 'Other'].map((r) => ListTile(
                  title: Text(r),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    repo.logDose(
                      medication: widget.medication,
                      scheduledTime: widget.scheduledTime,
                      status: LogStatus.skipped,
                      skipReason: r,
                    );
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Recorded skipped dose ($r).')),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4A90E2);
    final med = widget.medication;
    final color = hexToColor(med.colorHex);
    final icon = getMedicationIcon(med.iconName);
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final repo = context.read<MedicationRepository>();
    final userName = repo.userProfile?.name ?? 'Friend';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Greeting & Time (MediLink Slide 16)
            Text(
              '$greeting, $userName!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Time to take your medicine',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primaryBlue.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.scheduledTime,
                style: const TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ringing Bell & Pip Companion Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCDE1FF), Color(0xFFE2EDFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withAlpha(60),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: RotationTransition(
                      turns: _bellAnimation,
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: primaryBlue,
                        size: 38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                MediBuddyCharacter(
                  mood: med.isOphthalmic ? MediBuddyMood.dropletGuide : MediBuddyMood.encouraging,
                  outfit: MediBuddyOutfit.doctor,
                  size: 96,
                  customSpeechText: med.isOphthalmic
                      ? 'Drop time! Wash your hands first!'
                      : 'Take with a glass of water!',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Medication Pill Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${med.dosageAmount.toInt()} ${med.dosageUnit.name} • ${med.strength}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                        if (med.instruction.name.isNotEmpty)
                          Text(
                            med.instruction.name.replaceAll('_', ' '),
                            style: const TextStyle(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Taken Button (Solid Blue)
            FilledButton.icon(
              onPressed: () => _onTaken(repo),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Taken', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),

            // 2. Snooze 10 Min Button
            OutlinedButton.icon(
              onPressed: () => _onSnooze(repo, 10),
              icon: const Icon(Icons.snooze_rounded, color: primaryBlue),
              label: const Text('Snooze 10 Min', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryBlue.withAlpha(120), width: 1.5),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),

            // 3. Skip Button
            TextButton(
              onPressed: () => _onSkip(repo),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Skip this dose', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 12),

            // Friendly Reassurance Footer (MediLink Slide 16)
            Text(
              'Stay healthy! Don’t miss your medicines.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
