import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/theme.dart';
import '../../core/one_ui_widgets.dart';

class PunctalOcclusionScreen extends StatefulWidget {
  final String medicationName;
  final String targetEye;
  final int durationSeconds;

  const PunctalOcclusionScreen({
    super.key,
    this.medicationName = 'Eye Drop Medication',
    this.targetEye = 'Both Eyes (OU)',
    this.durationSeconds = 60,
  });

  @override
  State<PunctalOcclusionScreen> createState() => _PunctalOcclusionScreenState();
}

class _PunctalOcclusionScreenState extends State<PunctalOcclusionScreen> with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    AppleGlassDecorations.mediumHaptic();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds % 10 == 0) {
          AppleGlassDecorations.lightHaptic();
        }
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
        AppleGlassDecorations.heavyHaptic();
        _showSuccessDialog();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = widget.durationSeconds;
      _isRunning = false;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Protocol Complete!'),
          ],
        ),
        content: const Text(
          'Punctal occlusion complete. By pressing the tear duct for 60 seconds, you maximized ocular absorption and prevented systemic side effects (such as bitter taste or blood pressure changes).',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_remainingSeconds / widget.durationSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punctal Occlusion Timer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Clinical Information Card
            OneUiWidgets.bannerCard(
              context: context,
              title: 'Nasolacrimal Duct Compression',
              subtitle: 'Gently pinch the inner corner of your eye next to the nose to seal the tear duct.',
              icon: Icons.compress_rounded,
              accentColor: const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 24),

            // Animated Anatomical Compression Beacon
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = _isRunning ? 1.0 + (_pulseController.value * 0.08) : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.withAlpha(40),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                          ),
                        ),
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF7C3AED).withAlpha(_isRunning ? 120 : 50),
                                const Color(0xFF0284C7).withAlpha(30),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                              const Text('SECONDS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Medication Context
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.water_drop, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.medicationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Target: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning ? Colors.amber : const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(_isRunning ? 'Pause Timer' : 'Start Occlusion (60s)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  icon: const Icon(Icons.replay_rounded),
                  tooltip: 'Reset',
                  onPressed: _resetTimer,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3-Step Technique Walkthrough
            const Text('Clinical Technique Walkthrough', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildStepTile('1', 'Instill 1 drop inside lower eyelid pouch.'),
            _buildStepTile('2', 'Gently close your eyelid without squeezing or blinking.'),
            _buildStepTile('3', 'Press index finger firmly against the inner corner of the eye for 60 seconds.'),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTile(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF7C3AED).withAlpha(40),
            child: Text(num, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3))),
        ],
      ),
    );
  }
}
