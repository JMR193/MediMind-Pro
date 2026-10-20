import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/medication_log.dart';
import '../visuals_3d/realistic_3d_medicine_card.dart';
import '../alarm/smart_medicine_reminder_dialog.dart';
import '../profile/profile_screen.dart';
import '../medications/medication_detail_specs_screen.dart';

class ModernHealthcareDashboardView extends StatelessWidget {
  const ModernHealthcareDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    final profile = repo.userProfile;
    final patientName = profile?.name ?? 'Alex';
    final medications = repo.medications;
    final logs = repo.logs;
    final today = DateTime.now();

    final greeting = today.hour < 12
        ? 'Good Morning'
        : today.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    // Calculate today's dose completion
    final todayLogs = logs.where((l) =>
        l.timestamp.year == today.year &&
        l.timestamp.month == today.month &&
        l.timestamp.day == today.day).toList();

    final totalScheduled = medications.isNotEmpty ? medications.length : 3;
    final completedDoses = todayLogs.where((l) => l.status == LogStatus.taken).length;
    final progress = (completedDoses / (totalScheduled > 0 ? totalScheduled : 1)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personalized Header (Matching Image 3 Screen 1)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $patientName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d').format(today),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Bell with Notification Badge
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1B4332), size: 26),
                      onPressed: () {
                        if (medications.isNotEmpty) {
                          SmartMedicineReminderDialog.show(
                            context,
                            medication: medications.first,
                            onTaken: () {},
                            onSnooze: () {},
                          );
                        }
                      },
                    ),
                    Positioned(
                      right: 12,
                      top: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                // Circular Profile Avatar Photo
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D6A4F).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Today's Progress Card (Matching Image 3 Screen 1)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD8F3DC), Color(0xFFB7E4C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF52B788).withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Progress",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF2D6A4F), size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.6),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D6A4F)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$completedDoses of $totalScheduled doses Completed',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D6A4F),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Upcoming Medicine Section Header
        const Text(
          'Upcoming Medicine',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        const SizedBox(height: 12),

        // Chronological Groups
        _buildTimeGroup(context, repo, 'Morning', '8:00 AM', medications.take(2).toList(), todayLogs),
        const SizedBox(height: 16),
        _buildTimeGroup(context, repo, 'Evening', '4:00 PM', medications.skip(2).take(2).toList(), todayLogs),
        const SizedBox(height: 20),

        // Proactive AI Insights Banner (Matching Image 3 Screen 2 / 3)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8F3DC)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFD8F3DC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, color: Color(0xFF2D6A4F), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MediAI Clinical Insight',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332), fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your evening routine is 92% consistent! Keep spacing doses 4 hours apart for optimal steady-state absorption.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTimeGroup(
    BuildContext context,
    MedicationRepository repo,
    String slotName,
    String timeStr,
    List<Medication> meds,
    List<MedicationLog> logs,
  ) {
    if (meds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              slotName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F)),
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...meds.map((med) {
          final isTaken = logs.any((l) => l.medicationId == med.id && l.status == LogStatus.taken);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // 3D Mini Thumbnail
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Realistic3dMedicineCard(medication: med),
                  ),
                ),
                const SizedBox(width: 14),
                // Title and Strength
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MedicationDetailSpecsScreen(medication: med)),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          med.strength,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),
                // Action Button: Green circle check vs "Upcoming..." badge (Matching Image 3 Screen 1)
                if (isTaken)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2D6A4F), width: 1.5),
                    ),
                    child: const Icon(Icons.check, size: 20, color: Color(0xFF2D6A4F)),
                  )
                else
                  InkWell(
                    onTap: () {
                      SmartMedicineReminderDialog.show(
                        context,
                        medication: med,
                        onTaken: () {
                          repo.logDose(
                            medication: med,
                            scheduledTime: med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : '08:00',
                            status: LogStatus.taken,
                          );
                        },
                        onSnooze: () {},
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Upcoming...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
