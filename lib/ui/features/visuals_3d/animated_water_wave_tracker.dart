import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/apple_glass_decorations.dart';

class AnimatedWaterWaveTracker extends StatefulWidget {
  final double currentMl;
  final double targetMl;
  final ValueChanged<double>? onWaterLogged;

  const AnimatedWaterWaveTracker({
    super.key,
    this.currentMl = 1250,
    this.targetMl = 2000,
    this.onWaterLogged,
  });

  @override
  State<AnimatedWaterWaveTracker> createState() => _AnimatedWaterWaveTrackerState();
}

class _AnimatedWaterWaveTrackerState extends State<AnimatedWaterWaveTracker>
    with SingleTickerProviderStateMixin {
  late double _currentMl;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _currentMl = widget.currentMl;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _addGlass(double ml) {
    AppleGlassDecorations.mediumHaptic();
    setState(() {
      _currentMl = (_currentMl + ml).clamp(0, widget.targetMl * 1.5);
    });
    widget.onWaterLogged?.call(_currentMl);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💧 Logged ${ml.toInt()}ml water! Total: ${_currentMl.toInt()}ml'),
        backgroundColor: const Color(0xFF0284C7),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentMl / widget.targetMl).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withAlpha(18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Hydration & Pill Swallowing',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentMl.toInt()} / ${widget.targetMl.toInt()} ml',
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Central Animated Fluid Wave Glass & Intake Stats
          Row(
            children: [
              // 3D Glass with Animated Sinusoidal Liquid
              SizedBox(
                width: 110,
                height: 140,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _WaterGlassPainter(
                        waveProgress: _waveController.value,
                        fillRatio: progress,
                      ),
                      child: Center(
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: progress > 0.5 ? Colors.white : const Color(0xFF0369A1),
                            shadows: [
                              Shadow(
                                color: Colors.black.withAlpha(progress > 0.5 ? 80 : 0),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),

              // Educational Tip & Quick Log Triggers
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clinical Best Practice:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0369A1)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Taking oral tablets with 200–250ml water prevents esophageal adhesion and ensures rapid gastric dissolution.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.35),
                    ),
                    const SizedBox(height: 12),

                    // Quick Log Buttons
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => _addGlass(250),
                          icon: const Icon(Icons.local_drink_rounded, size: 16),
                          label: const Text('+250 ml', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _addGlass(100),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0284C7)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('+100 ml', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterGlassPainter extends CustomPainter {
  final double waveProgress;
  final double fillRatio;

  _WaterGlassPainter({
    required this.waveProgress,
    required this.fillRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glass Container Path (Slight taper from top to bottom)
    final glassPath = Path()
      ..moveTo(w * 0.12, 10)
      ..lineTo(w * 0.22, h - 8)
      ..quadraticBezierTo(w * 0.23, h, w * 0.28, h)
      ..lineTo(w * 0.72, h)
      ..quadraticBezierTo(w * 0.77, h, w * 0.78, h - 8)
      ..lineTo(w * 0.88, 10)
      ..close();

    // 1. Glass Background & Rim
    final glassBgPaint = Paint()..color = Colors.white.withAlpha(160);
    canvas.drawPath(glassPath, glassBgPaint);

    canvas.save();
    canvas.clipPath(glassPath);

    // 2. Dual Sinusoidal Water Wave
    final waterY = h - (h * fillRatio * 0.88);

    // Back Wave (Slightly darker blue)
    final backWavePath = Path();
    backWavePath.moveTo(0, waterY);
    for (double x = 0; x <= w; x++) {
      final y = waterY + math.sin((x / w * 2 * math.pi) + (waveProgress * 2 * math.pi) + 1.2) * 5;
      backWavePath.lineTo(x, y);
    }
    backWavePath.lineTo(w, h);
    backWavePath.lineTo(0, h);
    backWavePath.close();

    final backWavePaint = Paint()
      ..color = const Color(0xFF0284C7).withAlpha(150);
    canvas.drawPath(backWavePath, backWavePaint);

    // Front Wave (Vibrant aqua gradient)
    final frontWavePath = Path();
    frontWavePath.moveTo(0, waterY);
    for (double x = 0; x <= w; x++) {
      final y = waterY + math.sin((x / w * 2 * math.pi) - (waveProgress * 2 * math.pi)) * 6;
      frontWavePath.lineTo(x, y);
    }
    frontWavePath.lineTo(w, h);
    frontWavePath.lineTo(0, h);
    frontWavePath.close();

    final frontWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF38BDF8),
          const Color(0xFF0284C7),
          const Color(0xFF0369A1),
        ],
      ).createShader(Rect.fromLTWH(0, waterY, w, h - waterY));

    canvas.drawPath(frontWavePath, frontWavePaint);

    // 3. Rising Micro-Bubbles
    final bubblePaint = Paint()..color = Colors.white.withAlpha(180);
    for (int i = 0; i < 5; i++) {
      final bx = (w * 0.3) + (i * 12);
      final by = h - ((waveProgress * h * 0.7 + i * 25) % (h * fillRatio + 1));
      if (by > waterY) {
        canvas.drawCircle(Offset(bx, by), 2.0 + (i % 2), bubblePaint);
      }
    }

    canvas.restore();

    // 4. Glass Surface Highlights & Specular Rim Outline
    final rimPaint = Paint()
      ..color = const Color(0xFF0284C7).withAlpha(70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(glassPath, rimPaint);

    // Specular highlight down the left edge of glass
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.18, 18), Offset(w * 0.25, h - 18), highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterGlassPainter oldDelegate) => true;
}
