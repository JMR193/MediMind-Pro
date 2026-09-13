import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/medication_repository.dart';
import '../../domain/models/medication.dart';
import '../../domain/models/medication_log.dart';
import 'apple_glass_decorations.dart';

class DynamicIslandPill extends StatefulWidget {
  final VoidCallback? onTakeAction;

  const DynamicIslandPill({super.key, this.onTakeAction});

  @override
  State<DynamicIslandPill> createState() => _DynamicIslandPillState();
}

class _DynamicIslandPillState extends State<DynamicIslandPill> {
  bool _isExpanded = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 1-second refresh for live timer
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleExpanded() {
    AppleGlassDecorations.mediumHaptic();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        // Check for active eye drop protocol
        final activeProtocol = repo.activeEyeDropSession;

        // Check for next upcoming dose
        final nextMed = _getNextDueMedication(repo);

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Center(
          child: GestureDetector(
            onTap: _toggleExpanded,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.fastOutSlowIn,
              width: _isExpanded ? MediaQuery.of(context).size.width - 32 : 320,
              padding: EdgeInsets.symmetric(
                horizontal: _isExpanded ? 20 : 16,
                vertical: _isExpanded ? 16 : 10,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(_isExpanded ? 28 : 36),
                border: Border.all(
                  color: activeProtocol != null
                      ? const Color(0xFF7C3AED).withAlpha(160)
                      : const Color(0xFF38BDF8).withAlpha(100),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(120),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  if (activeProtocol != null)
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withAlpha(60),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_isExpanded ? 28 : 36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: _buildIslandContent(context, repo, activeProtocol, nextMed),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIslandContent(
    BuildContext context,
    MedicationRepository repo,
    dynamic activeProtocol,
    Medication? nextMed,
  ) {
    if (activeProtocol != null) {
      return _buildEyeDropIsland(context, repo, activeProtocol);
    } else if (nextMed != null) {
      return _buildUpcomingDoseIsland(context, repo, nextMed);
    } else {
      return _buildAllCaughtUpIsland(context);
    }
  }

  /// Active Eye Drop Spacing Timer State
  Widget _buildEyeDropIsland(
    BuildContext context,
    MedicationRepository repo,
    dynamic protocol,
  ) {
    if (!_isExpanded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFA78BFA),
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.3, 1.3),
                duration: 900.ms,
              ),
          const SizedBox(width: 8),
          const Icon(Icons.remove_red_eye_rounded, color: Color(0xFFA78BFA), size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Eye Drop Gap Active',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withAlpha(70),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Active',
              style: TextStyle(color: Color(0xFFA78BFA), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.remove_red_eye_rounded, color: Color(0xFFA78BFA), size: 18),
                SizedBox(width: 8),
                Text(
                  'Eye Drop Spacing Protocol',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white60, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _toggleExpanded,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Waiting between ocular medications prevents drug washout and ensures full therapeutic absorption.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                AppleGlassDecorations.lightHaptic();
                repo.completeEyeDropProtocol();
                setState(() => _isExpanded = false);
              },
              child: const Text('Complete Session', style: TextStyle(color: Color(0xFFA78BFA))),
            ),
          ],
        ),
      ],
    );
  }

  /// Upcoming Dose Island State
  Widget _buildUpcomingDoseIsland(
    BuildContext context,
    MedicationRepository repo,
    Medication med,
  ) {
    final nextTime = med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : 'Now';

    if (!_isExpanded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF38BDF8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.medication_rounded, color: Color(0xFF38BDF8), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Next: ${med.name} (${med.strength})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withAlpha(80),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              nextTime,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withAlpha(60),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.alarm_on_rounded, color: Color(0xFF38BDF8), size: 16),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Upcoming Dose',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                nextTime,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          med.name,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          '${med.dosageAmount.toInt()} ${med.dosageUnit.name} (${med.strength}) · ${med.instruction.name}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  AppleGlassDecorations.lightHaptic();
                  setState(() => _isExpanded = false);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withAlpha(60)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Dismiss', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  AppleGlassDecorations.mediumHaptic();
                  repo.logDose(
                    medication: med,
                    scheduledTime: nextTime,
                    status: LogStatus.taken,
                  );
                  setState(() => _isExpanded = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✓ Marked ${med.name} as taken!')),
                  );
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Take Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// All Caught Up State
  Widget _buildAllCaughtUpIsland(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'MediMind Active • All caught up',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Text('✓', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Medication? _getNextDueMedication(MedicationRepository repo) {
    if (repo.medications.isEmpty) return null;
    return repo.medications.first;
  }
}
