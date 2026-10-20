import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../core/theme.dart';
import 'eye_hospital_post_op_hub.dart';

class EyeDropScreen extends StatefulWidget {
  const EyeDropScreen({super.key});

  @override
  State<EyeDropScreen> createState() => _EyeDropScreenState();
}

class _EyeDropScreenState extends State<EyeDropScreen> with TickerProviderStateMixin {
  Timer? _timer;
  int _remaining = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final repo = context.read<MedicationRepository>();
      final session = repo.activeEyeDropSession;
      if (session == null) {
        _timer?.cancel();
        return;
      }
      setState(() {
        _remaining = session.secondsRemaining;
      });
      if (_remaining <= 0) {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        final session = repo.activeEyeDropSession;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Eye Drop Protocol'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.local_hospital_outlined),
                tooltip: 'Eye Hospital & Post-Op Center',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeHospitalPostOpHub()));
                },
              ),
              if (session != null)
                TextButton(
                  onPressed: () {
                    repo.completeEyeDropProtocol();
                    Navigator.pop(context);
                  },
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          body: session == null
              ? _buildNoSessionView(context)
              : _buildProtocolView(context, session, repo),
        );
      },
    );
  }

  Widget _buildNoSessionView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_red_eye_outlined, size: 80, color: Colors.grey.withAlpha(128)),
          const SizedBox(height: 16),
          const Text('No Active Eye Drop Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Log an eye drop medication to activate the protocol timer.', style: TextStyle(color: Colors.grey.withAlpha(179)), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Dashboard'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2D6A4F),
              side: const BorderSide(color: Color(0xFF2D6A4F)),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeHospitalPostOpHub()));
            },
            icon: const Icon(Icons.local_hospital_outlined),
            label: const Text('Open Eye Hospital & Post-Op Center'),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolView(BuildContext context, dynamic session, MedicationRepository repo) {
    final seconds = session.secondsRemaining as int;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final total = session.requiredGapMinutes * 60;
    final progress = total > 0 ? 1.0 - (seconds / total) : 1.0;
    final safeToAdminister = seconds <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Eye animation timer
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withAlpha(
                        safeToAdminister ? 77 : (38 + (_pulseController.value * 51)).round(),
                      ),
                      blurRadius: 20 + (_pulseController.value * 20),
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  safeToAdminister
                      ? const Text('SAFE ✅', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                      : Text('${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  if (!safeToAdminister)
                    const Text('wait time', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey.withAlpha(51),
              valueColor: AlwaysStoppedAnimation<Color>(
                safeToAdminister ? MediMindTheme.successGreen : const Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Drug info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medication_outlined, color: Color(0xFF7C3AED), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(session.medicationName as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.visibility_outlined, 'Target Eye', session.targetEye as String, const Color(0xFF7C3AED)),
                  const SizedBox(height: 8),
                  _infoRow(Icons.timer_outlined, 'Gap Required', '${session.requiredGapMinutes} minutes between drops', MediMindTheme.warningOrange),
                  const SizedBox(height: 8),
                  if (session.contactLensRemoved)
                    _infoRow(Icons.remove_red_eye_outlined, 'Contact Lens Reminder', 'Remove lenses before applying — wait 15 min to re-insert', MediMindTheme.alertRed),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Clinical guidance cards
          Card(
            color: const Color(0xFF7C3AED).withAlpha(13),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('👁️  Clinical Ophthalmic Protocol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF7C3AED))),
                  const SizedBox(height: 12),
                  _protocolStep('1', 'Wash hands thoroughly before touching the eye area.'),
                  _protocolStep('2', 'Remove soft contact lenses before applying eye drops.'),
                  _protocolStep('3', 'Tilt head back and look upward.'),
                  _protocolStep('4', 'Gently pull lower eyelid down to form a pocket.'),
                  _protocolStep('5', 'Apply prescribed number of drops into the conjunctival sac — do NOT touch the eye.'),
                  _protocolStep('6', 'Close eye gently. Press inner corner (punctal occlusion) for 60 seconds.'),
                  _protocolStep('7', 'WAIT ${session.requiredGapMinutes} full minutes before applying next eye drop medication.'),
                  _protocolStep('8', 'Wait 15 minutes before re-inserting contact lenses.'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          if (safeToAdminister)
            FilledButton.icon(
              onPressed: () {
                repo.completeEyeDropProtocol();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Protocol Complete — Close'),
              style: FilledButton.styleFrom(
                backgroundColor: MediMindTheme.successGreen,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () {
                repo.completeEyeDropProtocol();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close),
              label: const Text('Cancel Protocol'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color)),
                TextSpan(text: value, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _protocolStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF7C3AED)),
            child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
