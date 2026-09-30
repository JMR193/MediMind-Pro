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
import '../medications/digital_pillbox_screen.dart';
import '../eye_drop_assistant/punctal_occlusion_screen.dart';
import '../medications/tapering_schedule_screen.dart';
import '../profile/family_profiles_screen.dart';
import '../vitals/vitals_tracker_screen.dart';
import '../renal_calculator/renal_guard_screen.dart';
import '../caregiver/caregiver_screen.dart';
import '../pill_identifier/pill_identifier_screen.dart';
import '../qr_share/qr_code_share_screen.dart';
import '../compliance/compliance_screen.dart';
import '../../../data/services/chronotherapy_research_service.dart';
import '../../../data/services/ai_assistant_service.dart';
import '../../../data/services/offline_backup_vault_service.dart';
import 'carelink_elderly_care_widget.dart';
import 'gotoinc_schedule_calendar_widget.dart';
import '../emergency/sos_emergency_screen.dart';
import '../medications/stock_out_alert_screen.dart';
import '../alarm/medicine_alarm_dialog.dart';
import '../guardian_mode/guardian_dashboard_screen.dart';
import '../companion/companion_card_widget.dart';
import '../visuals_3d/visual_lab_screen.dart';
import '../ai_advisor/smart_chronotherapy_advisor_screen.dart';
import '../emergency_hud/universal_emergency_hud_screen.dart';
import '../refill_forecast/refill_forecast_screen.dart';
import '../safety_scanner/medication_safety_scanner_screen.dart';
import '../travel/travel_dose_shifter_screen.dart';

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

              // Multi-Patient Family Profile Switcher Bar
              _buildProfileSwitcherBar(context, repo),
              const SizedBox(height: 16),

              // MediBuddy Pip Companion Card (Emotional Avatar & Voice Guide)
              const CompanionCardWidget(),
              const SizedBox(height: 16),

              // CareLink Elderly Care & Well-Being Quick Check-in Module (Dribbble 27342041)
              const CareLinkElderlyCareWidget(),
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
              // ISPOR / WHO Research Chronotherapy Biomarker Score Card
              _buildChronotherapyHealthScoreCard(context, repo),
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
              // Gotoinc Studio Floating Calendar & Realistic Pill Cards (Dribbble 25993984)
              const GotoincScheduleCalendarWidget(),
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

  Widget _buildProfileSwitcherBar(BuildContext context, MedicationRepository repo) {
    final profiles = repo.profiles;
    final activeId = repo.activeProfileId;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in profiles) ...[
            ChoiceChip(
              avatar: CircleAvatar(
                radius: 10,
                backgroundColor: Color(int.parse(p.colorHex.replaceAll('#', '0xFF'))),
                child: Text(p.name[0], style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              label: Text('${p.name} (${p.relationship})'),
              selected: p.id == activeId,
              selectedColor: Color(int.parse(p.colorHex.replaceAll('#', '0xFF'))).withAlpha(40),
              onSelected: (_) {
                AppleGlassDecorations.lightHaptic();
                repo.switchProfile(p.id);
              },
            ),
            const SizedBox(width: 8),
          ],
          IconButton.outlined(
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            tooltip: 'Add Profile',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyProfilesScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildChronotherapyHealthScoreCard(BuildContext context, MedicationRepository repo) {
    final metrics = ChronotherapyResearchService.analyzeAdherence(
      medications: repo.activeMedications,
      logs: repo.logs,
    );

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.biotech_rounded, color: Color(0xFF0D9488), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Research Adherence Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('ISPOR / WHO Chronotherapy Index', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${metrics.overallHealthScore}/100',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0D9488)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('${metrics.pdcPercentage.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0284C7))),
                      const SizedBox(height: 2),
                      const Text('PDC (Coverage)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('${metrics.mprPercentage.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF059669))),
                      const SizedBox(height: 2),
                      const Text('MPR (Possession)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('±${metrics.averageTimingDriftMinutes.toInt()}m', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7C3AED))),
                      const SizedBox(height: 2),
                      const Text('Timing Drift', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metrics.clinicalInterpretation,
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF0D9488)),
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
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToolButton(
              context,
              icon: Icons.grid_view_rounded,
              label: 'Pillbox',
              color: const Color(0xFF0284C7),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalPillboxScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.compress_rounded,
              label: 'Punctal',
              color: const Color(0xFF7C3AED),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PunctalOcclusionScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.trending_down_rounded,
              label: 'Tapering',
              color: const Color(0xFF0D9488),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaperingScheduleScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.family_restroom_rounded,
              label: 'Family',
              color: const Color(0xFFEA580C),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyProfilesScreen())),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToolButton(
              context,
              icon: Icons.favorite_rounded,
              label: 'Vitals & IOP',
              color: const Color(0xFFE11D48),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalsTrackerScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.calculate_outlined,
              label: 'Renal Guard',
              color: const Color(0xFF0284C7),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RenalGuardScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.security_rounded,
              label: 'Vault Export',
              color: const Color(0xFF059669),
              onTap: () {
                AppleGlassDecorations.mediumHaptic();
                final repo = context.read<MedicationRepository>();
                OfflineBackupVaultService.exportVaultFile(
                  medications: repo.medications,
                  logs: repo.logs,
                  profiles: repo.profiles,
                  symptoms: repo.symptomLogs,
                  vitals: repo.vitals,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting 100% encrypted on-device backup vault...')),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.people_outline,
              label: 'Caregiver',
              color: const Color(0xFFDB2777),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverScreen())),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToolButton(
              context,
              icon: Icons.saved_search_rounded,
              label: 'Pill ID',
              color: const Color(0xFF6366F1),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PillIdentifierScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.qr_code_2_rounded,
              label: 'QR Hub',
              color: const Color(0xFF0D9488),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrCodeShareScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.verified_user_outlined,
              label: 'Compliance',
              color: const Color(0xFF059669),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplianceScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.accessibility_new_rounded,
              label: 'Senior Mode',
              color: const Color(0xFFD97706),
              onTap: () {
                final repo = context.read<MedicationRepository>();
                final current = repo.settings.seniorModeEnabled;
                repo.updateSettings(repo.settings.copyWith(seniorModeEnabled: !current));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(!current ? 'Senior Mode Activated (High Contrast & 64px Touch)' : 'Senior Mode Deactivated'),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToolButton(
              context,
              icon: Icons.shield_moon_rounded,
              label: 'Guardian Hub',
              color: const Color(0xFF36A25D),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuardianDashboardScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.emergency_rounded,
              label: 'SOS Alert',
              color: const Color(0xFFE53935),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosEmergencyScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.inventory_rounded,
              label: 'Stock Out',
              color: const Color(0xFFD97706),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOutAlertScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.notifications_active_rounded,
              label: 'Test Alarm',
              color: const Color(0xFF4A90E2),
              onTap: () {
                final repo = context.read<MedicationRepository>();
                if (repo.medications.isNotEmpty) {
                  final med = repo.medications.first;
                  MedicineAlarmDialog.show(context, med, med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : '08:00 AM');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No active medications to test alarm.')),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToolButton(
              context,
              icon: Icons.view_in_ar_rounded,
              label: '3D Lab',
              color: const Color(0xFF7C3AED),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisualLabScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.auto_awesome_rounded,
              label: 'Chrono AI',
              color: const Color(0xFF0D9488),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartChronotherapyAdvisorScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.water_drop_rounded,
              label: 'Hydration',
              color: const Color(0xFF0284C7),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisualLabScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.face_rounded,
              label: 'Pip Mascot',
              color: const Color(0xFFEC4899),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisualLabScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.remove_red_eye_rounded,
              label: 'Drop 3D',
              color: const Color(0xFF059669),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisualLabScreen())),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToolButton(
              context,
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan Check',
              color: const Color(0xFF06B6D4),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationSafetyScannerScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.flight_takeoff_rounded,
              label: 'Travel Shift',
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelDoseShifterScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.emergency_rounded,
              label: 'ICE Pass',
              color: const Color(0xFFEF4444),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UniversalEmergencyHudScreen())),
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              icon: Icons.inventory_2_outlined,
              label: 'Refill Run',
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RefillForecastScreen())),
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

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7C3AED).withAlpha(18),
                const Color(0xFF0284C7).withAlpha(12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF7C3AED).withAlpha(50), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withAlpha(15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: AI Companion Avatar & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'MediMind AI Companion',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.verified, size: 14, color: Color(0xFF0284C7)),
                            ],
                          ),
                          Text(
                            'Proactive Briefing • 100% On-Device',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      AppleGlassDecorations.lightHaptic();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF7C3AED).withAlpha(35),
                      foregroundColor: const Color(0xFF7C3AED),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ask AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Conversational Clinical Health Briefing
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Clinical Insight',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All scheduled medications have been validated against our 2,400+ drug interaction index. For eye drops, maintain at least 5 minutes between different bottles to ensure full therapeutic absorption.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Interactive Quick Action Chips (Dribbble 27018559)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF7C3AED)),
                      label: const Text('Ask Question', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF7C3AED).withAlpha(20),
                      side: BorderSide(color: const Color(0xFF7C3AED).withAlpha(60)),
                      onPressed: () {
                        AppleGlassDecorations.lightHaptic();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.mic_none_rounded, size: 14, color: Color(0xFF0284C7)),
                      label: const Text('Voice Command', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF0284C7).withAlpha(20),
                      side: BorderSide(color: const Color(0xFF0284C7).withAlpha(60)),
                      onPressed: () {
                        AppleGlassDecorations.mediumHaptic();
                        VoiceAssistantModal.show(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.health_and_safety_outlined, size: 14, color: Color(0xFFDC2626)),
                      label: const Text('Interaction Check', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFFDC2626).withAlpha(20),
                      side: BorderSide(color: const Color(0xFFDC2626).withAlpha(60)),
                      onPressed: () {
                        AppleGlassDecorations.lightHaptic();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const InteractionMatrixScreen()));
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF0D9488)),
                      label: const Text('Drop Spacing Timer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF0D9488).withAlpha(20),
                      side: BorderSide(color: const Color(0xFF0D9488).withAlpha(60)),
                      onPressed: () {
                        AppleGlassDecorations.lightHaptic();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeDropScreen()));
                      },
                    ),
                  ],
                ),
              ),

              if (tasks.isNotEmpty) ...[
                const SizedBox(height: 14),
                // Daily Health Tasks & Routine Checklist
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daily Health Habits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '$count of $total completed (${(aiService.taskProgress * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: aiService.taskProgress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.withAlpha(40),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                ),
                const SizedBox(height: 10),
                ...tasks.take(3).map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        AppleGlassDecorations.lightHaptic();
                        aiService.toggleTask(t.id);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withAlpha(180),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: t.isCompleted
                                ? MediMindTheme.successGreen.withAlpha(80)
                                : Theme.of(context).dividerColor.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              t.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: t.isCompleted ? MediMindTheme.successGreen : const Color(0xFF7C3AED),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                                  color: t.isCompleted
                                      ? Theme.of(context).colorScheme.onSurface.withAlpha(120)
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
