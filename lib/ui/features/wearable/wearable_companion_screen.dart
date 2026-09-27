import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/services/wearable_sync_service.dart';
import '../../../domain/models/medication_log.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/utils.dart';

class WearableCompanionScreen extends StatefulWidget {
  const WearableCompanionScreen({super.key});

  @override
  State<WearableCompanionScreen> createState() => _WearableCompanionScreenState();
}

class _WearableCompanionScreenState extends State<WearableCompanionScreen> {
  final _wearableService = WearableSyncService();

  // Watch simulation state
  int _selectedWatchIndex = 0; // 0: Upcoming Dose, 1: Punctal Timer, 2: Adherence Ring
  Timer? _wristPunctalTimer;
  int _wristPunctalSeconds = 60;
  bool _isWristPunctalRunning = false;

  @override
  void dispose() {
    _wristPunctalTimer?.cancel();
    super.dispose();
  }

  void _startWristPunctalCoach() {
    _wristPunctalTimer?.cancel();
    setState(() {
      _wristPunctalSeconds = 60;
      _isWristPunctalRunning = true;
    });
    WearableSyncService.triggerWristHapticFeedback(WearableHapticPattern.gentlePulse);

    _wristPunctalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_wristPunctalSeconds <= 1) {
        timer.cancel();
        setState(() {
          _wristPunctalSeconds = 0;
          _isWristPunctalRunning = false;
        });
        WearableSyncService.triggerWristHapticFeedback(WearableHapticPattern.strongAlert);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⌚ Wrist Punctal Occlusion complete!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      } else {
        setState(() => _wristPunctalSeconds--);
        // Pulse wrist haptics every 10 seconds
        if (_wristPunctalSeconds % 10 == 0) {
          WearableSyncService.triggerWristHapticFeedback(WearableHapticPattern.subtleTick);
        }
      }
    });
  }

  void _stopWristPunctalCoach() {
    _wristPunctalTimer?.cancel();
    setState(() {
      _wristPunctalSeconds = 60;
      _isWristPunctalRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wearableService,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.watch, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wearable Companion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Wear OS & Apple Watch Sync', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Force Sync to Smartwatch',
                onPressed: () async {
                  await _wearableService.triggerSync();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⌚ Schedules & timers synced with smartwatch!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: Consumer<MedicationRepository>(
            builder: (context, repo, _) {
              final payload = _wearableService.buildSyncPayload(
                medications: repo.activeMedications,
                logs: repo.logs,
                isPunctalActive: _isWristPunctalRunning,
                activeTimerSeconds: _wristPunctalSeconds,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Interactive Smartwatch Hardware Simulator
                  _buildWatchHardwareSection(context, payload, repo),
                  const SizedBox(height: 20),

                  // 2. Watch Face Mode Selector
                  _buildWatchFaceModeSelector(),
                  const SizedBox(height: 20),

                  // 3. Smartwatch Sync Status Banner
                  _buildSyncStatusCard(context, payload),
                  const SizedBox(height: 20),

                  // 4. Wearable Configuration & Haptics
                  _buildWearableSettingsCard(context),
                  const SizedBox(height: 20),

                  // 5. Wrist Eye Drop & Occlusion Guidance
                  _buildWristOphthalmicGuideCard(context),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────
  // Watch Hardware Simulation Frame
  // ──────────────────────────────────────────
  Widget _buildWatchHardwareSection(
    BuildContext context,
    WearableSyncPayload payload,
    MedicationRepository repo,
  ) {
    final isCircular = _wearableService.preferredShape == WearableWatchShape.circular;

    return Center(
      child: Column(
        children: [
          // Shape Switcher Tabs (Circular vs Rectangular)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildShapeChoiceChip(
                  label: 'Pixel / Galaxy (Circle)',
                  icon: Icons.circle_outlined,
                  isSelected: isCircular,
                  onTap: () {
                    AppleGlassDecorations.lightHaptic();
                    _wearableService.setPreferredShape(WearableWatchShape.circular);
                  },
                ),
                const SizedBox(width: 4),
                _buildShapeChoiceChip(
                  label: 'Apple Watch (Rect)',
                  icon: Icons.crop_square_rounded,
                  isSelected: !isCircular,
                  onTap: () {
                    AppleGlassDecorations.lightHaptic();
                    _wearableService.setPreferredShape(WearableWatchShape.roundedRect);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // The Watch Bezel & Screen
          Container(
            width: isCircular ? 290 : 270,
            height: isCircular ? 290 : 330,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircular ? null : BorderRadius.circular(46),
              border: Border.all(color: const Color(0xFF334155), width: 7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(120),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isCircular ? 140 : 36),
              child: Container(
                color: Colors.black,
                child: _buildWatchScreenContent(context, payload, repo),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Watch Face Screens
  // ──────────────────────────────────────────
  Widget _buildWatchScreenContent(
    BuildContext context,
    WearableSyncPayload payload,
    MedicationRepository repo,
  ) {
    switch (_selectedWatchIndex) {
      case 0:
        return _buildWatchNextDoseView(payload, repo);
      case 1:
        return _buildWatchPunctalView();
      case 2:
      default:
        return _buildWatchAdherenceView(payload);
    }
  }

  // Screen 1: Next Dose Wrist Tile
  Widget _buildWatchNextDoseView(WearableSyncPayload payload, MedicationRepository repo) {
    final nextMed = payload.upcomingTiles.isNotEmpty ? payload.upcomingTiles.first : null;
    final currentTime = DateFormat('HH:mm').format(DateTime.now());

    if (nextMed == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(currentTime, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 36),
            const SizedBox(height: 6),
            const Text('All Done!', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const Text('No pending doses', style: TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      );
    }

    final medColor = hexToColor(nextMed.colorHex);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Watch Status Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(currentTime, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(nextMed.isEyeDrop ? Icons.remove_red_eye : Icons.medication, color: medColor, size: 12),
                  const SizedBox(width: 4),
                  Text(nextMed.scheduledTime, style: TextStyle(color: medColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          // Central Medication Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: medColor.withAlpha(90)),
            ),
            child: Column(
              children: [
                Text(
                  nextMed.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${nextMed.strength} • ${nextMed.categoryName}',
                  style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 10),
                ),
              ],
            ),
          ),

          // Wrist Tactile Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    WearableSyncService.triggerWristHapticFeedback(WearableHapticPattern.gentlePulse);
                    final actualMed = repo.medications.firstWhere((m) => m.id == nextMed.id, orElse: () => repo.medications.first);
                    repo.logDose(
                      medication: actualMed,
                      scheduledTime: nextMed.scheduledTime,
                      status: LogStatus.taken,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⌚ Wrist logged: ${nextMed.name} taken!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('✓ Taken', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    WearableSyncService.triggerWristHapticFeedback(WearableHapticPattern.subtleTick);
                    final actualMed = repo.medications.firstWhere((m) => m.id == nextMed.id, orElse: () => repo.medications.first);
                    repo.snoozeDose(actualMed, 10);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⏰ ${nextMed.name} snoozed 10m on wrist.'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('⏰ 10m', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Screen 2: 60s Wrist Punctal Occlusion Coach
  Widget _buildWatchPunctalView() {
    final progress = (60 - _wristPunctalSeconds) / 60.0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text('👁️ Punctal Coach', style: TextStyle(color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.bold)),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF0D9488)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_wristPunctalSeconds',
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const Text('SECONDS', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Text(
            _isWristPunctalRunning ? 'Keep tear-duct pressed' : 'Press duct & start timer',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
          GestureDetector(
            onTap: _isWristPunctalRunning ? _stopWristPunctalCoach : _startWristPunctalCoach,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _isWristPunctalRunning ? Colors.red.shade700 : const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _isWristPunctalRunning ? 'Stop' : 'Start 60s',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Screen 3: Live Adherence Ring
  Widget _buildWatchAdherenceView(WearableSyncPayload payload) {
    final percent = payload.adherencePercentage.toInt();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text('Today Adherence', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: (payload.adherencePercentage / 100).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF0284C7)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${payload.totalTakenToday}/${payload.totalScheduledToday} taken',
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Wrist Sync Active', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Watch Face Mode Switcher Pills
  // ──────────────────────────────────────────
  Widget _buildWatchFaceModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildModeTab(0, 'Next Dose', Icons.medication_outlined),
          _buildModeTab(1, 'Punctal 60s', Icons.timer_outlined),
          _buildModeTab(2, 'Adherence Ring', Icons.donut_large_outlined),
        ],
      ),
    );
  }

  Widget _buildModeTab(int index, String label, IconData icon) {
    final isSelected = _selectedWatchIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppleGlassDecorations.lightHaptic();
          setState(() => _selectedWatchIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Sync Status Card
  // ──────────────────────────────────────────
  Widget _buildSyncStatusCard(BuildContext context, WearableSyncPayload payload) {
    final lastSyncText = _wearableService.lastSyncTimestamp != null
        ? DateFormat('HH:mm:ss').format(_wearableService.lastSyncTimestamp!)
        : 'Auto-sync active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleGlassDecorations.frostedGlassBox(
        color: Colors.white,
        opacity: 0.9,
        borderRadius: 18,
        borderColor: const Color(0xFF0284C7).withAlpha(50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bluetooth_connected, color: Color(0xFF0284C7), size: 18),
                  SizedBox(width: 8),
                  Text('Smartwatch Sync Channel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('CONNECTED', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Last sync: $lastSyncText • ${payload.upcomingTiles.length} active doses staged on smartwatch.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _wearableService.triggerSync();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('⌚ Dispatched fresh regimen payload to wrist.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_to_mobile, size: 16),
                  label: const Text('Push Regimen Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Wearable Settings Card
  // ──────────────────────────────────────────
  Widget _buildWearableSettingsCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.watch_outlined, color: Color(0xFF0284C7)),
            title: const Text('Wearable Sync Bridge'),
            subtitle: const Text('Mirror alarms and timers on Wear OS & Apple Watch', style: TextStyle(fontSize: 11)),
            value: _wearableService.isWearableSyncEnabled,
            onChanged: (v) => _wearableService.toggleWearableSync(v),
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: const Icon(Icons.vibration, color: Color(0xFF7C3AED)),
            title: const Text('Tactile Wrist Haptics'),
            subtitle: const Text('Distinctive pulses for drops, pills, and countdowns', style: TextStyle(fontSize: 11)),
            value: _wearableService.wristHapticsEnabled,
            onChanged: (v) => _wearableService.toggleWristHaptics(v),
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: const Icon(Icons.screen_lock_portrait_outlined, color: Color(0xFF0D9488)),
            title: const Text('Wrist Screen Wake on Dose Due'),
            subtitle: const Text('Automatically lights up smartwatch display', style: TextStyle(fontSize: 11)),
            value: _wearableService.screenWakeOnAlarm,
            onChanged: (v) => _wearableService.toggleScreenWake(v),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.speed, color: Colors.orange),
            title: const Text('Haptic Vibration Pattern'),
            subtitle: Text(_getPatternLabel(_wearableService.hapticPattern), style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHapticPatternPicker(context),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Wrist Ophthalmic Guide Card
  // ──────────────────────────────────────────
  Widget _buildWristOphthalmicGuideCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withAlpha(20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF0D9488).withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, color: Color(0xFF0D9488)),
              SizedBox(width: 8),
              Text(
                'Wrist Ophthalmic Clinical Companion',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Punctal Occlusion: Smartwatch pulses every 10 seconds to confirm tear duct compression without opening eyes.\n'
            '• 5-Minute Spacing Rule: Watch vibrates gently when wash-out safety interval has passed, readying the next bottle.\n'
            '• Hands-Free Logging: Tap "Taken" on wrist right after instillation.',
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _getPatternLabel(WearableHapticPattern p) {
    switch (p) {
      case WearableHapticPattern.subtleTick:
        return 'Subtle Single Tick';
      case WearableHapticPattern.gentlePulse:
        return 'Gentle Medium Pulse';
      case WearableHapticPattern.strongAlert:
        return 'Strong Double Alert (Recommended)';
      case WearableHapticPattern.emergencyStaccato:
        return 'Emergency Triple Staccato';
    }
  }

  void _showHapticPatternPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Wrist Haptic Vibration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...WearableHapticPattern.values.map((p) => ListTile(
                  title: Text(_getPatternLabel(p)),
                  trailing: _wearableService.hapticPattern == p ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    _wearableService.setHapticPattern(p);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
