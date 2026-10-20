import 'dart:math' as math;
import 'package:flutter/material.dart';

enum LotusStage {
  bud,      // Day 1-3: Closed bud with soft anticipation
  blooming, // Day 4-13: Opening petals as routine forms
  blossom,  // Day 14+: Radiant lotus in full bloom
}

class LotusBloomWidget extends StatefulWidget {
  final LotusStage stage;
  final double size;
  final bool animate;
  final String? subtitle;

  const LotusBloomWidget({
    super.key,
    required this.stage,
    this.size = 220,
    this.animate = true,
    this.subtitle,
  });

  @override
  State<LotusBloomWidget> createState() => _LotusBloomWidgetState();
}

class _LotusBloomWidgetState extends State<LotusBloomWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final breath = widget.animate ? _controller.value * 0.05 : 0.0;
            return CustomPaint(
              size: Size(widget.size, widget.size * 0.95),
              painter: _LotusPainter(
                stage: widget.stage,
                breathProgress: breath,
              ),
            );
          },
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC026D3),
            ),
          ),
        ],
      ],
    );
  }
}

class _LotusPainter extends CustomPainter {
  final LotusStage stage;
  final double breathProgress;

  _LotusPainter({required this.stage, required this.breathProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    final baseWidth = size.width * 0.22;
    final baseHeight = size.height * 0.48;

    // Glowing Ambient Aura
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE879F9).withOpacity(0.35),
          const Color(0xFFA21CAF).withOpacity(0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.48));
    canvas.drawCircle(center, size.width * 0.48, auraPaint);

    final petalGradient = const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFFC026D3), Color(0xFFE879F9), Color(0xFFFDF2F8)],
    );

    switch (stage) {
      case LotusStage.bud:
        // Closed graceful droplet-shaped lotus bud
        _drawPetal(canvas, center.translate(-16, 4), baseWidth * 0.72, baseHeight * 0.88, -0.18, petalGradient, size);
        _drawPetal(canvas, center.translate(16, 4), baseWidth * 0.72, baseHeight * 0.88, 0.18, petalGradient, size);
        _drawPetal(canvas, center, baseWidth * 0.82, baseHeight * 0.96, 0, petalGradient, size);
        break;

      case LotusStage.blooming:
        // Half-open lotus with outer petals spreading
        _drawPetal(canvas, center.translate(-38, 8), baseWidth * 0.68, baseHeight * 0.76, -0.42 + breathProgress, petalGradient, size);
        _drawPetal(canvas, center.translate(38, 8), baseWidth * 0.68, baseHeight * 0.76, 0.42 - breathProgress, petalGradient, size);
        _drawPetal(canvas, center.translate(-20, 4), baseWidth * 0.74, baseHeight * 0.84, -0.20, petalGradient, size);
        _drawPetal(canvas, center.translate(20, 4), baseWidth * 0.74, baseHeight * 0.84, 0.20, petalGradient, size);
        _drawPetal(canvas, center, baseWidth * 0.80, baseHeight * 0.90, 0, petalGradient, size);
        break;

      case LotusStage.blossom:
        // Wide fully bloomed lotus flower
        for (double angle in [-0.82, -0.58, -0.34, -0.14, 0.14, 0.34, 0.58, 0.82]) {
          final xOffset = math.sin(angle) * (size.width * 0.24);
          _drawPetal(canvas, center.translate(xOffset, 12), baseWidth * 0.62, baseHeight * 0.70, angle, petalGradient, size);
        }
        _drawPetal(canvas, center.translate(-24, 6), baseWidth * 0.70, baseHeight * 0.80, -0.24, petalGradient, size);
        _drawPetal(canvas, center.translate(24, 6), baseWidth * 0.70, baseHeight * 0.80, 0.24, petalGradient, size);
        _drawPetal(canvas, center, baseWidth * 0.76, baseHeight * 0.86, 0, petalGradient, size);
        break;
    }
  }

  void _drawPetal(
    Canvas canvas,
    Offset origin,
    double width,
    double height,
    double angle,
    Gradient gradient,
    Size size,
  ) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, height * 0.5)
      ..cubicTo(-width, height * 0.2, -width * 0.9, -height * 0.45, 0, -height * 0.55)
      ..cubicTo(width * 0.9, -height * 0.45, width, height * 0.2, 0, height * 0.5)
      ..close();

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCenter(center: Offset.zero, width: width * 2, height: height * 2),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Delicate translucent border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LotusPainter oldDelegate) =>
      oldDelegate.stage != stage || oldDelegate.breathProgress != breathProgress;
}
