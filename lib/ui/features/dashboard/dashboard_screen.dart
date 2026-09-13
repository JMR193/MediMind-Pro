import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/services/device_integration_service.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/medication_log.dart';
import '../../core/utils.dart';
import '../../core/theme.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/dynamic_island_pill.dart';
import '../../core/one_ui_widgets.dart';
import '../eye_drop_assistant/eye_drop_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../ocr_scanner/ocr_scanner_screen.dart';
import '../voice_assistant/voice_assistant_modal.dart';
import '../symptom_diary/symptom_diary_screen.dart';
import '../streak/streak_screen.dart';
import '../device_integration/device_optimization_screen.dart';
import '../medications/refill_tracker_screen.dart';
import '../medications/interaction_matrix_screen.dart';
import '../profile/emergency_medical_id_screen.dart';
import '../../../data/services/ai_assistant_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        final settings = repo.settings;
        final today = DateTime.now();
        final adherence = repo.calculateAdherenceRate();
        final refillAlerts = repo.medicationsNeedingRefill;
        final expiringAlerts = repo.expiringMedications;
        final openedExpiring = repo.openedWindowExpiringMedications;
        final eyeConflicts = repo.checkEyeMedicationConflicts();
        final eyeSession = repo.activeEyeDropSession;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Apple iOS 18 Dynamic Island Pill
              if (settings.dynamicIslandEnabled) ...[
                const DynamicIslandPill(),
                const SizedBox(height: 14),
              ],

              // Samsung One UI Reachability Header OR Standard Greeting Card
              if (settings.uiDesignStyle == UiDesignStyle.samsungOneUi)
                _buildSamsungOneUiHeader(context, today, adherence, repo.userProfile?.name ?? 'Patient')
              else
                _buildGreetingCard(context, today, adherence, repo.userProfile?.name ?? 'Patient'),

              const SizedBox(height: 16),

              // OEM Device Reliability & Battery Exemption Banner
              _buildOemReliabilityBanner(context),
              const SizedBox(height: 16),

              // Smart Tools Quick Access Grid
              _buildQuickAccessGrid(context),
              const SizedBox(height: 16),
              // AI Proactive Daily Tasks & Education Widget
              _buildAiDailyTasksCard(context),
              const SizedBox(height: 16),
              // Active Eye Drop Protocol Timer Banner
              if (eyeSession != null) ...[
                _buildEyeDropActiveBanner(context, eyeSession.medicationName, eyeSession.secondsRemaining, repo),
                const SizedBox(height: 16),
              ],
              // Ophthalmic Timing & Sequencing Advisory Banner
              if (eyeConflicts.isNotEmpty) ...[
                _buildEyeConflictBanner(context, eyeConflicts),
                const SizedBox(height: 16),
              ],
              // Refill & Expiry Warnings
              if (refillAlerts.isNotEmpty || expiringAlerts.isNotEmpty || openedExpiring.isNotEmpty) ...[
                _buildAlertsSection(context, refillAlerts, expiringAlerts, openedExpiring),
                const SizedBox(height: 16),
              ],
              _buildSectionTitle(context, "Today's Medication Schedule"),
              const SizedBox(height: 8),
              if (repo.medications.isEmpty)
                _buildEmptyMedsCard(context)
              else
                ...repo.medications.map((med) => _buildMedicationDoseCard(context, med, repo, today)),
              const SizedBox(height: 16),
              _buildSectionTitle(context, "Recent Activity Log"),
              const SizedBox(height: 8),
              _buildRecentLogsSection(context, repo.logs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSamsungOneUiHeader(BuildContext context, DateTime today, double adherence, String name) {
    final hour = today.hour;
    final greeting = hour < 12 ? 'Good Morning ☀️' : hour < 17 ? 'Good Afternoon 🌤️' : 'Good Evening 🌙';

    return OneUiWidgets.reachabilityHeader(
      context: context,
      title: '$greeting,\n$name',
      subtitle: 'MEDIMIND CLINICAL COMPANION',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              '${adherence.toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Text(
              'Adherence',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOemReliabilityBanner(BuildContext context) {
    return Consumer<DeviceIntegrationService>(
      builder: (context, deviceService, _) {
        final score = deviceService.reliabilityScore;
        if (score >= 95) return const SizedBox.shrink();

        final guide = deviceService.getGuide(deviceService.detectedBrand);

        return InkWell(
          onTap: () {
            AppleGlassDecorations.mediumHaptic();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeviceOptimizationScreen()),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MediMindTheme.warningOrange.withAlpha(22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: MediMindTheme.warningOrange.withAlpha(120)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MediMindTheme.warningOrange.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.battery_alert_rounded, color: MediMindTheme.warningOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${guide.brandName} Alarm Whitelist Needed',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: MediMindTheme.warningOrange),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reliability: $score%. Battery saver may delay alarms while asleep. Tap to fix.',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: MediMindTheme.warningOrange, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreetingCard(BuildContext context, DateTime today, double adherence, String name) {
    final hour = today.hour;
    String greeting = hour < 12 ? 'Good Morning ☀️' : hour < 17 ? 'Good Afternoon 🌤️' : 'Good Evening 🌙';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting, $name', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Clinical adherence tracking active', style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.white.withAlpha(230), size: 16),
                    const SizedBox(width: 4),
                    Text('On-Device Privacy Guarded', style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(38),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${adherence.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('adherence', style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Smart Assistant Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            TextButton(
              onPressed: () => VoiceAssistantModal.show(context),
              child: const Row(
                children: [
                  Icon(Icons.mic, size: 16, color: Color(0xFF0284C7)),
                  SizedBox(width: 4),
                  Text('Voice Command', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToolButton(
              context,
              icon: Icons.psychology_outlined,
              label: 'AI Chat',
              color: const Color(0xFF7C3AED),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.document_scanner_outlined,
              label: 'Scan Rx',
              color: const Color(0xFF0284C7),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OcrScannerScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.health_and_safety_outlined,
              label: 'Symptoms',
              color: const Color(0xFF059669),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomDiaryScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.local_fire_department_outlined,
              label: 'Streaks',
              color: const Color(0xFFEA580C),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.smartphone_rounded,
              label: 'Reliability',
              color: const Color(0xFF0D9488),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceOptimizationScreen())),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToolButton(
              context,
              icon: Icons.inventory_2_outlined,
              label: 'Refills',
              color: const Color(0xFF2563EB),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RefillTrackerScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.shield_outlined,
              label: 'Interactions',
              color: const Color(0xFFDC2626),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InteractionMatrixScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.badge_outlined,
              label: 'Medical ID',
              color: const Color(0xFFE11D48),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMedicalIdScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.water_drop_outlined,
              label: 'Eye Drops',
              color: const Color(0xFF0D9488),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeDropScreen())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(51)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEyeConflictBanner(BuildContext context, List<String> conflicts) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, color: Color(0xFF7C3AED), size: 20),
              SizedBox(width: 8),
              Text('Ophthalmic Timing & Sequencing Advisory', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ...conflicts.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(c, style: const TextStyle(fontSize: 12, height: 1.3)),
              )),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context, List<Medication> refills, List<Medication> expiring, List<Medication> openedExpiring) {
    return Column(
      children: [
        for (final m in refills)
          InkWell(
            onTap: () {
              AppleGlassDecorations.lightHaptic();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RefillTrackerScreen()));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: MediMindTheme.warningOrange.withAlpha(26), borderRadius: BorderRadius.circular(12), border: Border.all(color: MediMindTheme.warningOrange.withAlpha(77))),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: MediMindTheme.warningOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Refill Alert: "${m.name}" has only ${m.totalInventoryCount} doses left (~${m.estimatedDaysSupplyRemaining} days supply). Tap to manage refills.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: MediMindTheme.warningOrange),
                ],
              ),
            ),
          ),
        for (final m in expiring)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: MediMindTheme.alertRed.withAlpha(20), borderRadius: BorderRadius.circular(12), border: Border.all(color: MediMindTheme.alertRed.withAlpha(77))),
            child: Row(
              children: [
                const Icon(Icons.event_busy_outlined, color: MediMindTheme.alertRed, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Expiry Warning: "${m.name}" ${m.isExpired ? "has expired!" : "expires within 30 days!"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MediMindTheme.alertRed)),
                ),
              ],
            ),
          ),
        for (final m in openedExpiring)
          InkWell(
            onTap: () {
              AppleGlassDecorations.lightHaptic();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RefillTrackerScreen()));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.purple.withAlpha(20), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.withAlpha(77))),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_bottom_outlined, color: Colors.purple, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Opened Bottle Window: "${m.name}" opened shelf life ends in ${m.daysRemainingAfterOpening ?? 0} days (28-day safety limit). Tap to restock.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple)),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.purple),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyMedsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.medication_outlined, size: 48, color: Colors.grey.withAlpha(102)),
              const SizedBox(height: 8),
              const Text('No medications scheduled yet', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Tap + or scan a prescription to add your first medicine', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEyeDropActiveBanner(BuildContext context, String medName, int secondsRemaining, MedicationRepository repo) {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final isReady = secondsRemaining <= 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Eye Drop Protocol Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  isReady ? '✅ Safe to apply next drop!' : 'Next drop in ${minutes}m ${seconds.toString().padLeft(2, '0')}s',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeDropScreen())),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text('View Timer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationDoseCard(BuildContext context, Medication med, MedicationRepository repo, DateTime today) {
    final color = hexToColor(med.colorHex);
    final icon = getMedicationIcon(med.iconName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          if (med.isHighPriorityAlarm)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: MediMindTheme.alertRed.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('CRITICAL', style: TextStyle(color: MediMindTheme.alertRed, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      Text('${med.strength} · ${med.frequency}', style: TextStyle(color: Colors.grey.withAlpha(204), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: color),
                const SizedBox(width: 4),
                Text('Scheduled: ${med.scheduleTimes.join(', ')}', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
                const Spacer(),
                Text('${med.totalInventoryCount} left', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const Divider(height: 20),
            // Quick action buttons: Take, Snooze (with 5/10/15m options), Skip (with reason)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      repo.logDose(
                        medication: med,
                        scheduledTime: med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : '08:00',
                        status: LogStatus.taken,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✅ ${med.name} dose recorded.'), backgroundColor: MediMindTheme.successGreen),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Take'),
                    style: FilledButton.styleFrom(
                      backgroundColor: MediMindTheme.successGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSnoozeDialog(context, med, repo),
                    icon: const Icon(Icons.snooze, size: 16),
                    label: const Text('Snooze'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSkipReasonDialog(context, med, repo),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Skip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSnoozeDialog(BuildContext context, Medication med, MedicationRepository repo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Snooze Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Choose how long to snooze ${med.name}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [5, 10, 15, 30].map((mins) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () {
                        repo.logDose(
                          medication: med,
                          scheduledTime: med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : '08:00',
                          status: LogStatus.snoozed,
                          notes: 'Snoozed for $mins minutes',
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('⏰ ${med.name} snoozed for $mins minutes.')),
                        );
                      },
                      child: Text('$mins m', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showSkipReasonDialog(BuildContext context, Medication med, MedicationRepository repo) {
    final reasons = ['Side effects', 'Ran out of medicine', 'Doctor advised', 'Felt unwell', 'Forgot during travel', 'Other'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason for Skipping', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tracking skip reasons helps your doctor optimize treatment', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            ...reasons.map((r) => ListTile(
                  title: Text(r),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    repo.logDose(
                      medication: med,
                      scheduledTime: med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : '08:00',
                      status: LogStatus.skipped,
                      skipReason: r,
                    );
                    Navigator.pop(ctx);
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

  Widget _buildRecentLogsSection(BuildContext context, List<MedicationLog> logs) {
    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No doses logged yet today', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: logs.reversed.take(5).map((l) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(logStatusIcon(l.status), color: logStatusColor(l.status)),
            title: Text(l.medicationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Scheduled: ${l.scheduledTime}${l.skipReason != null ? " · Reason: ${l.skipReason}" : ""}'),
            trailing: Text(
              l.status.name.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: logStatusColor(l.status), fontSize: 11),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildAiDailyTasksCard(BuildContext context) {
    return Consumer<AiAssistantService>(
      builder: (context, aiService, _) {
        final tasks = aiService.dailyTasks;
        final count = aiService.completedTasksCount;
        final total = tasks.length;
        if (tasks.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: const Color(0xFF7C3AED).withAlpha(77))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFF7C3AED).withAlpha(26), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.psychology, color: Color(0xFF7C3AED), size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text('AI Health Tasks & Routine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                      child: const Text('Academy & Coach →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$count of $total tasks completed today (${(aiService.taskProgress * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: aiService.taskProgress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.withAlpha(51),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                ),
                const SizedBox(height: 12),
                ...tasks.take(3).map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => aiService.toggleTask(t.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Icon(
                            t.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                            size: 18,
                            color: t.isCompleted ? MediMindTheme.successGreen : const Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                                color: t.isCompleted ? Colors.grey : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
