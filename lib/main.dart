import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'data/repositories/medication_repository.dart';
import 'data/services/storage_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/tasker_service.dart';
import 'data/services/ai_assistant_service.dart';
import 'domain/models/app_settings.dart';
import 'ui/core/theme.dart';
import 'ui/features/dashboard/dashboard_screen.dart';
import 'ui/features/medications/medications_list_screen.dart';
import 'ui/features/tasker_automation/tasker_screen.dart';
import 'ui/features/medication_wizard/add_medication_screen.dart';
import 'ui/features/settings/settings_screen.dart';
import 'ui/features/profile/profile_screen.dart';
import 'ui/features/ai_assistant/ai_assistant_screen.dart';
import 'ui/features/symptom_diary/symptom_diary_screen.dart';
import 'ui/features/caregiver/caregiver_screen.dart';
import 'ui/features/streak/streak_screen.dart';
import 'ui/features/ocr_scanner/ocr_scanner_screen.dart';
import 'ui/features/voice_assistant/voice_assistant_modal.dart';
import 'ui/features/lock/app_lock_screen.dart';
import 'ui/features/medications/refill_tracker_screen.dart';
import 'ui/features/medications/interaction_matrix_screen.dart';
import 'ui/features/profile/emergency_medical_id_screen.dart';
import 'ui/features/medications/digital_pillbox_screen.dart';
import 'ui/features/eye_drop_assistant/punctal_occlusion_screen.dart';
import 'ui/features/medications/tapering_schedule_screen.dart';
import 'ui/features/profile/family_profiles_screen.dart';
import 'ui/features/vitals/vitals_tracker_screen.dart';
import 'ui/features/renal_calculator/renal_guard_screen.dart';
import 'ui/features/pill_identifier/pill_identifier_screen.dart';
import 'ui/features/compliance/compliance_screen.dart';
import 'ui/features/qr_share/qr_code_share_screen.dart';
import 'ui/core/in_app_notification_overlay.dart';
import 'ui/core/floating_pill_nav_bar.dart';
import 'ui/features/reports/intake_history_screen.dart';
import 'ui/features/onboarding/lotus_onboarding_screen.dart';

import 'data/services/device_integration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await StorageService.init();
  final notificationService = NotificationService();
  await notificationService.init();

  final repository = MedicationRepository(
    storageService: storageService,
    notificationService: notificationService,
    taskerService: TaskerService(),
  );

  final aiService = AiAssistantService();
  aiService.updateMedications(repository.medications);
  repository.addListener(() {
    aiService.updateMedications(repository.medications);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MedicationRepository>.value(value: repository),
        ChangeNotifierProvider<AiAssistantService>.value(value: aiService),
        ChangeNotifierProvider<DeviceIntegrationService>(create: (_) => DeviceIntegrationService()),
      ],
      child: const MediMindApp(),
    ),
  );
}

class MediMindApp extends StatelessWidget {
  const MediMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        final settings = repo.settings;
        final themeMode = settings.themeMode == AppThemeMode.light
            ? ThemeMode.light
            : settings.themeMode == AppThemeMode.dark
                ? ThemeMode.dark
                : ThemeMode.system;

        final locale = Locale(settings.languageCode);

        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            // Material You dynamic palette used when in Adaptive or Material3 mode
            final useDynamic = settings.uiDesignStyle == UiDesignStyle.auto ||
                settings.uiDesignStyle == UiDesignStyle.material3;

            return MaterialApp(
              title: 'MediMind Pro',
              theme: useDynamic
                  ? MediMindTheme.lightThemeWith(lightDynamic)
                  : MediMindTheme.lightTheme,
              darkTheme: useDynamic
                  ? MediMindTheme.darkThemeWith(darkDynamic)
                  : MediMindTheme.darkTheme,
              themeMode: themeMode,
              locale: locale,
              supportedLocales: AppLanguage.supported.map((l) => Locale(l.code)).toList(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                return InAppNotificationOverlay(
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const AppLockScreen(
                child: MainShell(),
              ),
            );
          },
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardScreen(),
    MedicationsListScreen(),
    TaskerScreen(),
    IntakeHistoryScreen(),
  ];

  final _titles = ['Today\'s Dashboard', 'My Medications', 'Smart Automation', 'Intake History'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(_titles[_currentIndex]),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
            tooltip: 'Offline AI Assistant',
          ),
          IconButton(
            icon: const Icon(Icons.mic_none_outlined),
            onPressed: () => VoiceAssistantModal.show(context),
            tooltip: 'Voice Command',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            tooltip: 'Settings',
          ),
        ],
      ),
      drawer: _buildAppDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddActionSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add / Record'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: FloatingPillNavBar(
        selectedIndex: _currentIndex,
        onItemSelected: (i) => setState(() => _currentIndex = i),
        onAiPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
          );
        },
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    final profile = repo.userProfile;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(profile?.name ?? 'Patient User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: Text(profile?.primaryDoctorName != null ? 'Doctor: ${profile!.primaryDoctorName}' : 'MediMind Pro Clinical Edition'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 36),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, const Color(0xFF0284C7)],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Patient Profile'),
            subtitle: const Text('Medical history, blood group, allergies'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined, color: Color(0xFFE11D48)),
            title: const Text('Emergency Medical ID (ICE)'),
            subtitle: const Text('Offline QR, blood group & ER contacts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyMedicalIdScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB)),
            title: const Text('Smart Refill & Inventory'),
            subtitle: const Text('Stock prediction & 1-tap pharmacy orders'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RefillTrackerScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: Color(0xFFDC2626)),
            title: const Text('Clinical Interaction Matrix'),
            subtitle: const Text('Drug-drug, food & condition warnings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InteractionMatrixScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.psychology_outlined, color: Color(0xFF7C3AED)),
            title: const Text('Offline AI Assistant'),
            subtitle: const Text('Medication advice & interactions'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined, color: Color(0xFF0284C7)),
            title: const Text('OCR Prescription Scanner'),
            subtitle: const Text('Extract medications from photo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OcrScannerScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined, color: Color(0xFF059669)),
            title: const Text('Symptom Diary'),
            subtitle: const Text('Track pain, redness & escalation'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomDiaryScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline, color: Color(0xFFDB2777)),
            title: const Text('Caregiver Management'),
            subtitle: const Text('Family alerts for missed doses'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_view_rounded, color: Color(0xFF0284C7)),
            title: const Text('Digital 4-Slot Pillbox'),
            subtitle: const Text('Morning, Noon, Evening & Bedtime 1-tap take'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalPillboxScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.compress_rounded, color: Color(0xFF7C3AED)),
            title: const Text('Punctal Occlusion Timer'),
            subtitle: const Text('Prevent systemic absorption of eye drops'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PunctalOcclusionScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_down_rounded, color: Color(0xFF0D9488)),
            title: const Text('Clinical Tapering Protocols'),
            subtitle: const Text('Steroid step-down & titration timelines'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TaperingScheduleScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_rounded, color: Color(0xFFE11D48)),
            title: const Text('Clinical Vitals & Glaucoma IOP'),
            subtitle: const Text('Blood pressure, diurnal eye pressure & glucose'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalsTrackerScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate_outlined, color: Color(0xFF0284C7)),
            title: const Text('Renal & Hepatic Guard'),
            subtitle: const Text('CrCl & eGFR dosage adjustment safety calculator'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RenalGuardScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.family_restroom_rounded, color: Color(0xFFEA580C)),
            title: const Text('Family & Patient Profiles'),
            subtitle: const Text('Switch between parents, kids & dependents'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyProfilesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_fire_department_outlined, color: Color(0xFFEA580C)),
            title: const Text('Streaks & Badges'),
            subtitle: const Text('Gamified adherence achievements'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.saved_search_rounded, color: Color(0xFF6366F1)),
            title: const Text('Visual Pill & Drug Identifier'),
            subtitle: const Text('Filter by shape, color, imprint & scoring'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PillIdentifierScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0D9488)),
            title: const Text('Quick Response (QR) Hub'),
            subtitle: const Text('Share regimen & import prescriptions with DDI check'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QrCodeShareScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined, color: Color(0xFF059669)),
            title: const Text('HIPAA & GDPR Compliance'),
            subtitle: const Text('Zero-cloud audit, WCAG 2.1 AA & Right to be Forgotten'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplianceScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.spa_outlined, color: Color(0xFF2D6A4F)),
            title: const Text('Mindful Habit Tour'),
            subtitle: const Text('Explore the 3-stage lotus bloom journey'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => LotusOnboardingScreen(onFinish: () => Navigator.pop(ctx))));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings & Languages'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  void _showAddActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Schedule or Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.edit_note_outlined, color: Theme.of(context).colorScheme.primary),
              ),
              title: const Text('Add Medication Manually'),
              subtitle: const Text('Enter eye drops, tablets, ointment schedule'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMedicationScreen()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE11D48).withAlpha(26), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.favorite_rounded, color: Color(0xFFE11D48)),
              ),
              title: const Text('Log Clinical Vitals / IOP Pressure'),
              subtitle: const Text('Record blood pressure, eye pressure or glucose'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VitalsTrackerScreen()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF0D9488).withAlpha(26), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.trending_down_rounded, color: Color(0xFF0D9488)),
              ),
              title: const Text('Setup Clinical Taper / Titration Plan'),
              subtitle: const Text('Pre-built post-op steroid step-down regimens'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TaperingScheduleScreen()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.document_scanner_outlined, color: Colors.blue),
              ),
              title: const Text('Scan Prescription with Camera (OCR)'),
              subtitle: const Text('Automatic text detection and scheduling'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OcrScannerScreen()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.purple.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.mic_outlined, color: Colors.purple),
              ),
              title: const Text('Speak to Schedule (Voice Assistant)'),
              subtitle: const Text('"Remind me to use eye drops at 8 AM"'),
              onTap: () {
                Navigator.pop(ctx);
                VoiceAssistantModal.show(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.healing_outlined, color: Colors.green),
              ),
              title: const Text('Log a Symptom or Side Effect'),
              subtitle: const Text('Record eye redness, pain, or blurred vision'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomDiaryScreen()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withAlpha(26), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB)),
              ),
              title: const Text('Check Refills & Inventory'),
              subtitle: const Text('Review stock depletion dates & order refills'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RefillTrackerScreen()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF0D9488).withAlpha(26), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0D9488)),
              ),
              title: const Text('Quick Response (QR) Share & Import'),
              subtitle: const Text('Share regimen or scan incoming prescriptions'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QrCodeShareScreen()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withAlpha(26), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.saved_search_rounded, color: Color(0xFF6366F1)),
              ),
              title: const Text('Identify Pill by Shape / Color'),
              subtitle: const Text('Search active cabinet or clinical drug library'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PillIdentifierScreen()));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
