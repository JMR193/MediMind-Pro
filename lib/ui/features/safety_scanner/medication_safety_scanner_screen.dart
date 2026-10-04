import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/medication_log.dart';

enum ScanVerificationState {
  idle,
  scanning,
  matchSuccess,
  mismatchHazard,
}

class MedicationSafetyScannerScreen extends StatefulWidget {
  const MedicationSafetyScannerScreen({super.key});

  @override
  State<MedicationSafetyScannerScreen> createState() => _MedicationSafetyScannerScreenState();
}

class _MedicationSafetyScannerScreenState extends State<MedicationSafetyScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  ScanVerificationState _state = ScanVerificationState.idle;
  String _scannedLabel = '';
  String _hazardDetails = '';
  Medication? _targetMedication;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final meds = context.read<MedicationRepository>().activeMedications;
      if (meds.isNotEmpty) {
        setState(() {
          _targetMedication = meds.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  void _verifyScan(String detectedText) {
    HapticFeedback.mediumImpact();
    setState(() {
      _state = ScanVerificationState.scanning;
      _scannedLabel = detectedText;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      final target = _targetMedication;
      if (target == null) {
        setState(() {
          _state = ScanVerificationState.matchSuccess;
          _scannedLabel = detectedText;
        });
        return;
      }

      final normalizedDetected = detectedText.toLowerCase().trim();
      final normalizedTarget = target.name.toLowerCase().trim();

      // Check if matches scheduled medication name
      if (normalizedDetected.contains(normalizedTarget) ||
          normalizedTarget.contains(normalizedDetected)) {
        HapticFeedback.heavyImpact();
        setState(() {
          _state = ScanVerificationState.matchSuccess;
        });
      } else {
        // HAZARD: Wrong bottle!
        HapticFeedback.vibrate();
        setState(() {
          _state = ScanVerificationState.mismatchHazard;
          _hazardDetails =
              'Scanned bottle "$detectedText" does NOT match your scheduled "${target.name} (${target.dosage})". Instilling or swallowing this could cause severe toxicity!';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    final meds = repo.activeMedications;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Text('Scan-Before-Swallow HUD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _isTorchOn ? Colors.amber : Colors.white70),
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scheduled Dose Verification Selector
          _buildTargetMedicationHeader(meds),

          // Central Optical Viewfinder
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildCameraBackdrop(),
                _buildViewfinderReticle(),
                if (_state == ScanVerificationState.scanning)
                  _buildScanningLaser(),
                if (_state == ScanVerificationState.matchSuccess)
                  _buildMatchOverlay(),
                if (_state == ScanVerificationState.mismatchHazard)
                  _buildHazardOverlay(),
              ],
            ),
          ),

          // Lower Control & Interactive Testing Bar
          _buildControlDeck(context, repo),
        ],
      ),
    );
  }

  Widget _buildTargetMedicationHeader(List<Medication> meds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Colors.cyanAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TARGET SCHEDULED DOSE',
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                if (meds.isEmpty)
                  const Text('No medications in cabinet', style: TextStyle(color: Colors.white70, fontSize: 13))
                else
                  DropdownButton<Medication>(
                    value: _targetMedication ?? meds.first,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    underline: const SizedBox(),
                    isDense: true,
                    items: meds.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text('${m.name} (${m.dosage})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _targetMedication = val;
                          _state = ScanVerificationState.idle;
                        });
                      }
                    },
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(50),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: const Text('ACTIVE', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraBackdrop() {
    return Container(
      color: const Color(0xFF0A0F1D),
      child: Center(
        child: Opacity(
          opacity: 0.15,
          child: Icon(Icons.camera_alt_outlined, size: 140, color: Colors.blue[200]),
        ),
      ),
    );
  }

  Widget _buildViewfinderReticle() {
    final borderColor = _state == ScanVerificationState.matchSuccess
        ? Colors.greenAccent
        : _state == ScanVerificationState.mismatchHazard
            ? Colors.redAccent
            : Colors.cyanAccent;

    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: borderColor.withAlpha(60),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Corner crosshairs
          Positioned(top: 8, left: 8, child: _crosshair(borderColor)),
          Positioned(top: 8, right: 8, child: _crosshair(borderColor)),
          Positioned(bottom: 8, left: 8, child: _crosshair(borderColor)),
          Positioned(bottom: 8, right: 8, child: _crosshair(borderColor)),
          Center(
            child: Text(
              _state == ScanVerificationState.idle
                  ? 'Align Barcode / Vial Label\nWithin Reticle'
                  : '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _crosshair(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color.withAlpha(100),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildScanningLaser() {
    return AnimatedBuilder(
      animation: _laserController,
      builder: (context, child) {
        return Positioned(
          top: 100 + (_laserController.value * 220),
          child: Container(
            width: 240,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withAlpha(200),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchOverlay() {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(210),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 56),
          const SizedBox(height: 8),
          const Text(
            'VERIFIED SAFE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          Text(
            'Match: $_scannedLabel',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ready to administer scheduled dose.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardOverlay() {
    return Container(
      width: 270,
      height: 270,
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(230),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.yellow, width: 3),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.yellow, size: 56),
          const SizedBox(height: 6),
          const Text(
            'CRITICAL HAZARD!',
            style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          const Text(
            'WRONG MEDICATION DETECTED',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            _hazardDetails,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildControlDeck(BuildContext context, MedicationRepository repo) {
    final targetName = _targetMedication?.name ?? 'Sample Rx';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          if (_state == ScanVerificationState.matchSuccess) ...[
            FilledButton.icon(
              onPressed: () {
                if (_targetMedication != null) {
                  repo.logDose(
                    medication: _targetMedication!,
                    scheduledTime: _targetMedication!.scheduleTimes.isNotEmpty
                        ? _targetMedication!.scheduleTimes.first
                        : '08:00',
                    status: LogStatus.taken,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Verified dose logged for ${_targetMedication!.name}!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.verified_rounded),
              label: const Text('Confirm & Log Dose Taken'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_state == ScanVerificationState.mismatchHazard) ...[
            FilledButton.icon(
              onPressed: () {
                setState(() => _state = ScanVerificationState.idle);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset Scanner (Do Not Ingest!)'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Simulation Test Rig for Instant Hands-On Demonstration
          const Text(
            '🧪 Interactive Simulation Rig (Test Without Physical Vial)',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _verifyScan(targetName),
                  icon: const Icon(Icons.check, color: Colors.greenAccent, size: 16),
                  label: const Text('Simulate Correct Vial', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.greenAccent)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _verifyScan('Warfarin 5mg (Anticoagulant)'),
                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                  label: const Text('Simulate Wrong Vial', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
