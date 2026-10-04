import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/apple_glass_decorations.dart';

class Ophthalmic3dDropSimulator extends StatefulWidget {
  final String medicationName;
  final VoidCallback? onDropCompleted;

  const Ophthalmic3dDropSimulator({
    super.key,
    this.medicationName = 'Latanoprost 0.005%',
    this.onDropCompleted,
  });

  @override
  State<Ophthalmic3dDropSimulator> createState() => _Ophthalmic3dDropSimulatorState();
}

class _Ophthalmic3dDropSimulatorState extends State<Ophthalmic3dDropSimulator>
    with TickerProviderStateMixin {
  late AnimationController _dropAnimationController;
  late AnimationController _rippleController;

  late Animation<double> _bottleTilt;
  late Animation<double> _dropFormation;
  late Animation<double> _dropFall;
  late Animation<double> _corneaRipple;

  bool _isDropping = false;
  bool _punctalOcclusionActive = false;

  @override
  void initState() {
    super.initState();

    _dropAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 1. Bottle tilts into position (0% - 25%)
    _bottleTilt = Tween<double>(begin: 0.0, end: -math.pi / 4).animate(
      CurvedAnimation(
        parent: _dropAnimationController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
      ),
    );

    // 2. Drop forms at nozzle tip (25% - 50%)
    _dropFormation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dropAnimationController,
        curve: const Interval(0.25, 0.50, curve: Curves.easeIn),
      ),
    );

    // 3. Drop falls to cornea (50% - 70%)
    _dropFall = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dropAnimationController,
        curve: const Interval(0.50, 0.70, curve: Curves.easeInQuad),
      ),
    );

    // 4. Cornea ripple dispersion (70% - 100%)
    _corneaRipple = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dropAnimationController,
        curve: const Interval(0.68, 1.0, curve: Curves.easeOut),
      ),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _dropAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isDropping = false;
          _punctalOcclusionActive = true;
        });
        AppleGlassDecorations.heavyHaptic();
        widget.onDropCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _dropAnimationController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _triggerDropSimulation() {
    if (_isDropping) return;
    AppleGlassDecorations.mediumHaptic();
    setState(() {
      _isDropping = true;
      _punctalOcclusionActive = false;
    });
    _dropAnimationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFEFF), Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFA5F3FC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withAlpha(20),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF0891B2), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3D Eye Drop Technique Simulator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(widget.medicationName, style: const TextStyle(fontSize: 11, color: Color(0xFF0891B2), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              FilledButton.tonal(
                onPressed: _isDropping ? null : _triggerDropSimulation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0891B2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_isDropping ? 'Instilling...' : '▶ Practice Drop', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Central 3D Canvas
          Center(
            child: SizedBox(
              width: 260,
              height: 220,
              child: AnimatedBuilder(
                animation: _dropAnimationController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _Ophthalmic3dPainter(
                      bottleTilt: _bottleTilt.value,
                      dropFormation: _dropFormation.value,
                      dropFall: _dropFall.value,
                      corneaRipple: _corneaRipple.value,
                    ),
                  );
                },
              ),
            ),
          ),

          // Punctal Occlusion Guidance Badge
          if (_punctalOcclusionActive) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Punctal Occlusion Active: Gently press the inner corner of your eye for 60 seconds to prevent systemic absorption.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Ophthalmic3dPainter extends CustomPainter {
  final double bottleTilt;
  final double dropFormation;
  final double dropFall;
  final double corneaRipple;

  _Ophthalmic3dPainter({
    required this.bottleTilt,
    required this.dropFormation,
    required this.dropFall,
    required this.corneaRipple,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // 1. Draw 3D Anatomical Eye Cornea at bottom
    final eyeY = size.height * 0.78;
    final eyeW = size.width * 0.72;
    final eyeH = 48.0;

    // Sclera
    final scleraRect = Rect.fromCenter(center: Offset(cx, eyeY), width: eyeW, height: eyeH);
    final scleraPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
      ).createShader(scleraRect);
    canvas.drawOval(scleraRect, scleraPaint);

    // Iris & Pupil (Hazel / Blue-green realistic lens)
    final irisRadius = 26.0;
    final irisPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF0284C7), Color(0xFF0F766E), Color(0xFF134E4A)],
      ).createShader(Rect.fromCircle(center: Offset(cx, eyeY), radius: irisRadius));
    canvas.drawCircle(Offset(cx, eyeY), irisRadius, irisPaint);

    // Pupil
    canvas.drawCircle(Offset(cx, eyeY), 10, Paint()..color = Colors.black);

    // Cornea Specular Curvature Highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 8, eyeY - 6), width: 14, height: 6),
      Paint()..color = Colors.white.withAlpha(200),
    );

    // Tear-Film Ripple Dispersion Wave
    if (corneaRipple > 0.05) {
      for (int i = 1; i <= 3; i++) {
        final r = (corneaRipple * 36.0 * i).clamp(0.0, eyeW * 0.45);
        final opacity = ((1.0 - corneaRipple) * 180).toInt().clamp(0, 255);
        final ripplePaint = Paint()
          ..color = const Color(0xFF06B6D4).withAlpha(opacity ~/ i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawOval(Rect.fromCenter(center: Offset(cx, eyeY), width: r * 2, height: r * 0.65), ripplePaint);
      }
    }

    // 2. Draw 3D Dropper Bottle at Top with Dynamic Tilt
    canvas.save();
    canvas.translate(cx, size.height * 0.28);
    canvas.rotate(bottleTilt);

    // Dropper Bottle Body
    final bottlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
      ).createShader(const Rect.fromLTWH(-20, -60, 40, 60));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-18, -60, 36, 60), const Radius.circular(10)), bottlePaint);

    // Dropper Tip
    final tipPath = Path()
      ..moveTo(-10, 0)
      ..lineTo(10, 0)
      ..lineTo(3, 20)
      ..lineTo(-3, 20)
      ..close();
    canvas.drawPath(tipPath, Paint()..color = const Color(0xFF0284C7));

    canvas.restore();

    // 3. Falling Liquid Droplet
    final nozzleY = size.height * 0.28 + math.cos(bottleTilt) * 20;

    if (dropFormation > 0.0 && dropFall < 1.0) {
      final currentDropY = nozzleY + (dropFall * (eyeY - nozzleY - 6));
      final dropSize = (dropFormation * 8.0).clamp(2.0, 8.0);

      final dropPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFF38BDF8), Color(0xFF0284C7)],
        ).createShader(Rect.fromCircle(center: Offset(cx, currentDropY), radius: dropSize));

      // Teardrop shape
      final dropPath = Path()
        ..moveTo(cx, currentDropY - dropSize * 1.3)
        ..quadraticBezierTo(cx + dropSize, currentDropY, cx, currentDropY + dropSize)
        ..quadraticBezierTo(cx - dropSize, currentDropY, cx, currentDropY - dropSize * 1.3);

      canvas.drawPath(dropPath, dropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Ophthalmic3dPainter oldDelegate) => true;
}
