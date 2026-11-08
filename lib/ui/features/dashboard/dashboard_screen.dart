import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/medication_log.dart';
import '../../core/utils.dart';
import '../../core/apple_glass_decorations.dart';
import '../eye_drop_assistant/eye_hospital_post_op_hub.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../medications/refill_tracker_screen.dart';
import '../medications/interaction_matrix_screen.dart';
import '../profile/emergency_medical_id_screen.dart';
import '../profile/profile_screen.dart';
import '../medication_wizard/add_medication_screen.dart';
import '../medications/medication_detail_specs_screen.dart';
import '../alarm/medicine_alarm_dialog.dart';
import '../companion/medi_buddy_character.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
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
        final todayLogs = logs
            .where((l) =>
                l.timestamp.year == today.year &&
                l.timestamp.month == today.month &&
                l.timestamp.day == today.day)
            .toList();

        int totalScheduled = 0;
        for (final m in medications) {
          totalScheduled += m.scheduleTimes.length;
        }
        if (totalScheduled == 0 && medications.isNotEmpty) {
          totalScheduled = medications.length;
        }

        final completedDoses =
            todayLogs.where((l) => l.status == LogStatus.taken).length;
        final progress = totalScheduled > 0
            ? (completedDoses / totalScheduled).clamp(0.0, 1.0)
            : 0.0;
        final adherenceRate = repo.calculateAdherenceRate();

        final eyeSession = repo.activeEyeDropSession;
        final refillAlerts = repo.medicationsNeedingRefill;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Personalized Header
              _buildHeader(context, greeting, patientName, today, medications),
              const SizedBox(height: 18),

              // 2. Today's Progress Card (Calming Green Gradient)
              _buildProgressCard(completedDoses, totalScheduled, progress, adherenceRate),
              const SizedBox(height: 18),

              // 3. Pip Friendly AI Companion Greeting
              _buildCompanionCard(context, patientName, adherenceRate, completedDoses, totalScheduled),
              const SizedBox(height: 18),

              // 4. Active Eye Drop Session Banner
              if (eyeSession != null) ...[
                _buildEyeDropBanner(context, eyeSession.medicationName, eyeSession.secondsRemaining, repo),
                const SizedBox(height: 18),
              ],

              // 5. Low Inventory / Refill Alert Banner
              if (refillAlerts.isNotEmpty) ...[
                _buildRefillBanner(context, refillAlerts),
                const SizedBox(height: 18),
              ],

              // 6. Today's Medication Schedule (Real-Time Interactive)
              _buildScheduleSection(context, repo, medications, todayLogs),
              const SizedBox(height: 24),

              // 7. Quick Clinical Tools Grid
              _buildQuickActionsGrid(context),
              const SizedBox(height: 24),

              // 8. Recent Activity Log
              _buildRecentActivitySection(context, repo.logs),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String greeting,
    String patientName,
    DateTime today,
    List<Medication> medications,
  ) {
    return Row(
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
            // Bell Notification with live pending indicator
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1B4332), size: 26),
                  tooltip: 'Next Reminder',
                  onPressed: () {
                    if (medications.isNotEmpty) {
                      MedicineAlarmDialog.show(
                        context,
                        medication: medications.first,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No active reminders currently.')),
                      );
                    }
                  },
                ),
                if (medications.isNotEmpty)
                  Positioned(
                    right: 12,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D6A4F),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            // Profile Avatar
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.2),
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
    );
  }

  Widget _buildProgressCard(
    int completedDoses,
    int totalScheduled,
    double progress,
    double adherenceRate,
  ) {
    return Container(
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
            color: const Color(0xFF52B788).withValues(alpha: 0.15),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF2D6A4F), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${adherenceRate.toInt()}% Adherence',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D6A4F)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completedDoses of $totalScheduled doses completed today',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D6A4F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionCard(
    BuildContext context,
    String name,
    double adherence,
    int completed,
    int total,
  ) {
    String motivation;
    if (completed == total && total > 0) {
      motivation = 'Fantastic work, $name! All your scheduled doses for today are complete! 🌿';
    } else if (completed > 0) {
      motivation = 'Great progress! You are staying on track with your health schedule today. 👍';
    } else {
      motivation = 'Good day, $name! Let\'s keep your on-time medication streak going strong today.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const MediBuddyCharacter(
            mood: MediBuddyMood.happy,
            outfit: MediBuddyOutfit.doctor,
            size: 64,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Pip • Health Companion',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.shield_outlined, size: 14, color: Color(0xFF52B788)),
                    SizedBox(width: 3),
                    Text(
                      'Offline AI',
                      style: TextStyle(fontSize: 10, color: Color(0xFF52B788), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  motivation,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEyeDropBanner(
    BuildContext context,
    String medName,
    int remainingSeconds,
    MedicationRepository repo,
  ) {
    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC4B5FD)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eye Drop Interval Active',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5B21B6)),
                ),
                const SizedBox(height: 2),
                Text(
                  '$medName: Wait 5 min before next drop to avoid washout ($mins:${secs.toString().padLeft(2, '0')} remaining)',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6D28D9)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => repo.completeEyeDropProtocol(),
            child: const Text('Dismiss', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRefillBanner(BuildContext context, List<Medication> lowMeds) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${lowMeds.length} Medication(s) Running Low',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                ),
                Text(
                  lowMeds.map((m) => m.name).take(2).join(', '),
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RefillTrackerScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Refill'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(
    BuildContext context,
    MedicationRepository repo,
    List<Medication> medications,
    List<MedicationLog> todayLogs,
  ) {
    if (medications.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.medication_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'No Medications Scheduled',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your daily prescriptions to track doses in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Medication'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    // Categorize into time slots
    final morningMeds = <(Medication, String)>[];
    final afternoonMeds = <(Medication, String)>[];
    final eveningMeds = <(Medication, String)>[];
    final bedtimeMeds = <(Medication, String)>[];

    for (final med in medications) {
      for (final t in med.scheduleTimes) {
        final hour = int.tryParse(t.split(':')[0]) ?? 8;
        if (hour >= 5 && hour < 12) {
          morningMeds.add((med, t));
        } else if (hour >= 12 && hour < 17) {
          afternoonMeds.add((med, t));
        } else if (hour >= 17 && hour < 21) {
          eveningMeds.add((med, t));
        } else {
          bedtimeMeds.add((med, t));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Schedule",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        const SizedBox(height: 12),
        if (morningMeds.isNotEmpty)
          _buildTimeSlotGroup(context, repo, 'Morning', '☀️ 08:00 AM', morningMeds, todayLogs),
        if (afternoonMeds.isNotEmpty)
          _buildTimeSlotGroup(context, repo, 'Afternoon', '🌤️ 01:00 PM', afternoonMeds, todayLogs),
        if (eveningMeds.isNotEmpty)
          _buildTimeSlotGroup(context, repo, 'Evening', '🌅 06:00 PM', eveningMeds, todayLogs),
        if (bedtimeMeds.isNotEmpty)
          _buildTimeSlotGroup(context, repo, 'Bedtime', '🌙 09:30 PM', bedtimeMeds, todayLogs),
      ],
    );
  }

  Widget _buildTimeSlotGroup(
    BuildContext context,
    MedicationRepository repo,
    String slotTitle,
    String defaultTime,
    List<(Medication, String)> items,
    List<MedicationLog> todayLogs,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header for slot
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  slotTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4332),
                  ),
                ),
                Text(
                  defaultTime,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...items.map((item) {
            final med = item.$1;
            final scheduledTime = item.$2;

            // Check if taken today
            final isTaken = todayLogs.any((l) =>
                l.medicationId == med.id &&
                l.scheduledTime == scheduledTime &&
                l.status == LogStatus.taken);

            return _buildMedicationRow(context, repo, med, scheduledTime, isTaken);
          }),
        ],
      ),
    );
  }

  Widget _buildMedicationRow(
    BuildContext context,
    MedicationRepository repo,
    Medication med,
    String scheduledTime,
    bool isTaken,
  ) {
    final color = hexToColor(med.colorHex);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicationDetailSpecsScreen(medication: med),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Category Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isTaken ? const Color(0xFFD8F3DC) : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                med.category == MedCategory.eyeDrop || med.category == MedCategory.eyeOintment
                    ? Icons.remove_red_eye_outlined
                    : med.category == MedCategory.inhaler
                        ? Icons.air_outlined
                        : med.category == MedCategory.injectable
                            ? Icons.vaccines_outlined
                            : Icons.medication_outlined,
                color: isTaken ? const Color(0xFF2D6A4F) : color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Name and Instruction
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isTaken ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${med.strength} • ${adminInstructionLabel(med.instruction)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            // Action: Taken checkmark or Take button
            if (isTaken)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3DC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Color(0xFF2D6A4F)),
                    SizedBox(width: 4),
                    Text(
                      'Taken',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      repo.snoozeDose(med, 15);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('⏰ ${med.name} snoozed 15 min.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Snooze', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () {
                      AppleGlassDecorations.mediumHaptic();
                      repo.logDose(
                        medication: med,
                        scheduledTime: scheduledTime,
                        status: LogStatus.taken,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF2D6A4F),
                          content: Text('✅ ${med.name} logged as taken!'),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Take', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      (
        'Add Medication',
        Icons.add_circle_outline_rounded,
        const Color(0xFF2D6A4F),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMedicationScreen())),
      ),
      (
        'AI Assistant',
        Icons.psychology_outlined,
        const Color(0xFF7C3AED),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
      ),
      (
        'Eye Care Hub',
        Icons.remove_red_eye_outlined,
        const Color(0xFF0284C7),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeHospitalPostOpHub())),
      ),
      (
        'Refill & Stock',
        Icons.inventory_2_outlined,
        const Color(0xFFD97706),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RefillTrackerScreen())),
      ),
      (
        'Interactions',
        Icons.shield_outlined,
        const Color(0xFFDC2626),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InteractionMatrixScreen())),
      ),
      (
        'Medical ID (ICE)',
        Icons.badge_outlined,
        const Color(0xFFE11D48),
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMedicalIdScreen())),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Clinical Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, i) {
            final a = actions[i];
            return InkWell(
              onTap: a.$4,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: a.$3.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.$2, color: a.$3, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.$1,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, List<MedicationLog> logs) {
    final recentLogs = logs.reversed.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        const SizedBox(height: 12),
        if (recentLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No activity recorded yet today.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentLogs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, i) {
                final l = recentLogs[i];
                final statusColor = l.status == LogStatus.taken
                    ? const Color(0xFF2D6A4F)
                    : l.status == LogStatus.snoozed
                        ? const Color(0xFFD97706)
                        : const Color(0xFFDC2626);

                return ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      l.status == LogStatus.taken
                          ? Icons.check
                          : l.status == LogStatus.snoozed
                              ? Icons.alarm
                              : Icons.close,
                      color: statusColor,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    l.medicationName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, h:mm a').format(l.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l.status.name.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
