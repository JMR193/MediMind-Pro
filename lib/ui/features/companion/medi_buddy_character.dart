import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/apple_glass_decorations.dart';

enum MediBuddyMood {
  happy,
  encouraging,
  celebrating,
  sleeping,
  dropletGuide,
}

enum MediBuddyOutfit {
  doctor,
  nurse,
  casual,
  champion,
}

class MediBuddyCharacter extends StatefulWidget {
  final MediBuddyMood mood;
  final MediBuddyOutfit outfit;
  final double size;
  final bool interactive;
  final bool enableVoiceOnTap;
  final String? customSpeechText;
  final VoidCallback? onTap;

  const MediBuddyCharacter({
    super.key,
    this.mood = MediBuddyMood.happy,
    this.outfit = MediBuddyOutfit.doctor,
    this.size = 180,
    this.interactive = true,
    this.enableVoiceOnTap = true,
    this.customSpeechText,
    this.onTap,
  });

  @override
  State<MediBuddyCharacter> createState() => _MediBuddyCharacterState();
}

class _MediBuddyCharacterState extends State<MediBuddyCharacter>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _blinkController;
  late AnimationController _tapBounceController;
  late AnimationController _celebrationController;

  late Animation<double> _floatAnim;
  late Animation<double> _squashAnim;
  late Animation<double> _blinkAnim;
  late Animation<double> _bounceAnim;
  late Animation<double> _spinAnim;

  Offset _lookDirection = Offset.zero;
  final FlutterTts _tts = FlutterTts();

  static const List<String> _encouragements = [
    'You are doing wonderful today! Keep it up!',
    'Staying on schedule is the best gift for your health!',
    'Don’t forget to drink a glass of fresh water with your meds!',
    'I’m right here with you! Every dose counts!',
    'Great job taking care of yourself!',
    'Tip from Pip: Taking statins at bedtime optimizes cholesterol reduction while you sleep!',
    'Tip from Pip: Space eye drops 5 to 10 minutes apart to prevent medication washout!',
    'Tip from Pip: Gentle 60-second tear-duct pressure keeps eye drops working right where you need them!',
    'Tip from Pip: Take thyroid and stomach medicine on an empty stomach for maximum absorption!',
  ];

  @override
  void initState() {
    super.initState();

    // Idle floating / breathing animation
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    _squashAnim = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    // Blinking animation
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _blinkAnim = Tween<double>(begin: 1.0, end: 0.08).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _scheduleNextBlink();

    // Tap bounce animation
    _tapBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.92).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
    ]).animate(_tapBounceController);

    // Celebration spin
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _spinAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.easeOutBack),
    );

    if (widget.mood == MediBuddyMood.celebrating) {
      _celebrationController.repeat(period: const Duration(milliseconds: 1800));
    }
  }

  Timer? _blinkTimer;

  void _scheduleNextBlink() {
    if (!mounted) return;
    final delay = 2500 + math.Random().nextInt(3500);
    _blinkTimer = Timer(Duration(milliseconds: delay), () async {
      if (!mounted) return;
      if (widget.mood != MediBuddyMood.sleeping && !_blinkController.isAnimating) {
        try {
          await _blinkController.forward();
          if (mounted) await _blinkController.reverse();
        } catch (_) {}
      }
      _scheduleNextBlink();
    });
  }

  @override
  void didUpdateWidget(covariant MediBuddyCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood == MediBuddyMood.celebrating && oldWidget.mood != MediBuddyMood.celebrating) {
      _celebrationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _idleController.dispose();
    _blinkController.dispose();
    _tapBounceController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.interactive) return;
    AppleGlassDecorations.mediumHaptic();

    _tapBounceController.forward(from: 0.0);

    if (widget.enableVoiceOnTap) {
      _speakEncouragement();
    }

    widget.onTap?.call();
  }

  void _speakEncouragement() async {
    try {
      final text = widget.customSpeechText ??
          _encouragements[math.Random().nextInt(_encouragements.length)];
      await _tts.stop();
      await _tts.setSpeechRate(0.48); // Gentle, natural conversational pace
      await _tts.setPitch(1.15); // Friendly, uplifting tone
      await _tts.speak(text);
    } catch (_) {
      // Graceful fallback if TTS engine is inactive
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onPanUpdate: (details) {
        if (!widget.interactive) return;
        setState(() {
          // Normalize pan offset for pupil tracking
          final dx = (details.localPosition.dx / widget.size - 0.5).clamp(-1.0, 1.0);
          final dy = (details.localPosition.dy / widget.size - 0.5).clamp(-1.0, 1.0);
          _lookDirection = Offset(dx, dy);
        });
      },
      onPanEnd: (_) {
        setState(() {
          _lookDirection = Offset.zero;
        });
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleController,
          _blinkController,
          _tapBounceController,
          _celebrationController,
        ]),
        builder: (context, _) {
          final floatOffset = widget.mood == MediBuddyMood.sleeping
              ? _floatAnim.value * 0.4
              : _floatAnim.value;
          final squash = _squashAnim.value;
          final bounce = _bounceAnim.value;
          final spin = widget.mood == MediBuddyMood.celebrating ? _spinAnim.value : 0.0;

          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Transform.rotate(
              angle: spin * 0.15, // gentle tilt during celebration
              child: Transform.scale(
                scaleX: bounce * squash,
                scaleY: bounce / squash,
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.customSpeechText != null &&
                        widget.customSpeechText!.isNotEmpty) ...[
                      Container(
                        constraints: BoxConstraints(maxWidth: widget.size * 1.5),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.customSpeechText!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(
                      width: widget.size,
                      height: widget.size * 1.15,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Confetti / Aura particles for celebrating mood
                          if (widget.mood == MediBuddyMood.celebrating)
                            _buildCelebrationParticles(),

                          // Sleeping Zzz bubbles
                          if (widget.mood == MediBuddyMood.sleeping)
                            _buildSleepingZzz(),

                          // Procedural Vector Character Canvas
                          CustomPaint(
                            size: Size(widget.size, widget.size * 1.15),
                            painter: _MediBuddyPainter(
                              mood: widget.mood,
                              outfit: widget.outfit,
                              blinkProgress: _blinkAnim.value,
                              lookDirection: _lookDirection,
                              idleProgress: _idleController.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCelebrationParticles() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _CelebrationParticlesPainter(progress: _idleController.value),
        ),
      ),
    );
  }

  Widget _buildSleepingZzz() {
    return Positioned(
      top: 0,
      right: widget.size * 0.1,
      child: IgnorePointer(
        child: CustomPaint(
          size: const Size(50, 40),
          painter: _SleepingZzzPainter(progress: _idleController.value),
        ),
      ),
    );
  }
}

class _MediBuddyPainter extends CustomPainter {
  final MediBuddyMood mood;
  final MediBuddyOutfit outfit;
  final double blinkProgress;
  final Offset lookDirection;
  final double idleProgress;

  _MediBuddyPainter({
    required this.mood,
    required this.outfit,
    required this.blinkProgress,
    required this.lookDirection,
    required this.idleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;
    final bodyRadius = size.width * 0.38;

    // 1. Soft Ambient Floor Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final shadowRect = Rect.fromCenter(
      center: Offset(cx, size.height * 0.96),
      width: bodyRadius * 1.6,
      height: 16,
    );
    canvas.drawOval(shadowRect, shadowPaint);

    // 2. Main Capsule / Pill Body with 3D Radial Lighting
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: bodyRadius * 1.8,
        height: bodyRadius * 1.7,
      ),
      Radius.circular(bodyRadius * 0.85),
    );

    // 3D Spherical Radial Gradient Body (Vibrant friendly sky blue / mint gradient)
    final bodyGradient = RadialGradient(
      center: const Alignment(-0.35, -0.45),
      radius: 0.95,
      colors: mood == MediBuddyMood.sleeping
          ? const [Color(0xFFFFFFFF), Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFF64748B)]
          : const [Color(0xFFFFFFFF), Color(0xFFE0F2FE), Color(0xFF38BDF8), Color(0xFF0284C7)],
      stops: const [0.0, 0.45, 0.85, 1.0],
    );

    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(bodyRect.outerRect)
      ..isAntiAlias = true;

    canvas.drawRRect(bodyRect, bodyPaint);

    // 3. Cheeks (Warm Blushing Empathy)
    final blushPaint = Paint()
      ..color = const Color(0xFFF43F5E).withAlpha(mood == MediBuddyMood.sleeping ? 60 : 130)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - bodyRadius * 0.55, cy + bodyRadius * 0.12), width: 22, height: 13),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + bodyRadius * 0.55, cy + bodyRadius * 0.12), width: 22, height: 13),
      blushPaint,
    );

    // 4. Eyes & Eyeballs
    final eyeRadius = bodyRadius * 0.18;
    final eyeSpacing = bodyRadius * 0.46;
    final eyeY = cy - bodyRadius * 0.12;

    _drawEye(
      canvas,
      Offset(cx - eyeSpacing, eyeY),
      eyeRadius,
      isLeft: true,
    );
    _drawEye(
      canvas,
      Offset(cx + eyeSpacing, eyeY),
      eyeRadius,
      isLeft: false,
    );

    // 5. Mouth (Procedural smile or speech)
    _drawMouth(canvas, Offset(cx, cy + bodyRadius * 0.22), bodyRadius * 0.38);

    // 6. Character Accessories / Outfits
    _drawOutfit(canvas, cx, cy, bodyRadius);

    // 7. Shiny 3D Specular Highlight on forehead
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha(160)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - bodyRadius * 0.35, cy - bodyRadius * 0.5),
        width: bodyRadius * 0.4,
        height: bodyRadius * 0.2,
      ),
      highlightPaint,
    );
  }

  void _drawEye(Canvas canvas, Offset center, double radius, {required bool isLeft}) {
    if (mood == MediBuddyMood.sleeping) {
      // Sleeping curved happy closed eyelid
      final sleepPaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(center.dx - radius, center.dy);
      path.quadraticBezierTo(center.dx, center.dy + radius * 0.9, center.dx + radius, center.dy);
      canvas.drawPath(path, sleepPaint);
      return;
    }

    if (blinkProgress <= 0.15) {
      // Fully closed blink slit
      final blinkPaint = Paint()
        ..color = const Color(0xFF0F172A)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy),
        blinkPaint,
      );
      return;
    }

    // Outer Eye Sclera (White with soft 3D shadow)
    final eyeHeight = radius * 2.0 * blinkProgress;
    final scleraRect = Rect.fromCenter(center: center, width: radius * 2.1, height: eyeHeight);
    final scleraPaint = Paint()..color = Colors.white;
    canvas.drawOval(scleraRect, scleraPaint);

    // Iris / Pupil with look direction
    final pupilRadius = radius * 0.72;
    final pupilOffset = Offset(
      lookDirection.dx * (radius * 0.45),
      lookDirection.dy * (radius * 0.35),
    );
    final pupilCenter = center + pupilOffset;

    final irisPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
        stops: [0.3, 1.0],
      ).createShader(Rect.fromCircle(center: pupilCenter, radius: pupilRadius));

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(scleraRect, Radius.circular(radius)));
    canvas.drawCircle(pupilCenter, pupilRadius, irisPaint);

    // Big anime-style specular reflections for adorable charm
    final catchlightPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      pupilCenter + Offset(-pupilRadius * 0.32, -pupilRadius * 0.32),
      pupilRadius * 0.38,
      catchlightPaint,
    );
    canvas.drawCircle(
      pupilCenter + Offset(pupilRadius * 0.35, pupilRadius * 0.35),
      pupilRadius * 0.18,
      catchlightPaint,
    );
    canvas.restore();
  }

  void _drawMouth(Canvas canvas, Offset center, double width) {
    final mouthPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();

    if (mood == MediBuddyMood.celebrating || mood == MediBuddyMood.happy) {
      // Big open happy smile with cute tongue!
      mouthPaint.style = PaintingStyle.fill;
      mouthPaint.color = const Color(0xFF1E293B);

      mouthPath.moveTo(center.dx - width * 0.5, center.dy);
      mouthPath.quadraticBezierTo(
        center.dx,
        center.dy + width * 0.65,
        center.dx + width * 0.5,
        center.dy,
      );
      mouthPath.close();

      canvas.save();
      canvas.drawPath(mouthPath, mouthPaint);

      // Tongue
      canvas.clipPath(mouthPath);
      final tonguePaint = Paint()..color = const Color(0xFFFB7185);
      canvas.drawCircle(
        Offset(center.dx, center.dy + width * 0.45),
        width * 0.35,
        tonguePaint,
      );
      canvas.restore();
    } else {
      // Gentle friendly smile
      mouthPath.moveTo(center.dx - width * 0.45, center.dy);
      mouthPath.quadraticBezierTo(
        center.dx,
        center.dy + width * 0.35,
        center.dx + width * 0.45,
        center.dy,
      );
      canvas.drawPath(mouthPath, mouthPaint);
    }
  }

  void _drawOutfit(Canvas canvas, double cx, double cy, double bodyRadius) {
    switch (outfit) {
      case MediBuddyOutfit.doctor:
        // Medical Stethoscope looped around body
        final stethoPaint = Paint()
          ..color = const Color(0xFF334155)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round;

        final path = Path();
        path.moveTo(cx - bodyRadius * 0.7, cy + bodyRadius * 0.2);
        path.cubicTo(
          cx - bodyRadius * 0.3,
          cy + bodyRadius * 0.9,
          cx + bodyRadius * 0.3,
          cy + bodyRadius * 0.9,
          cx + bodyRadius * 0.7,
          cy + bodyRadius * 0.2,
        );
        canvas.drawPath(path, stethoPaint);

        // Chest Piece Bell
        final chestPiecePaint = Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy + bodyRadius * 0.78), radius: 11));
        canvas.drawCircle(Offset(cx, cy + bodyRadius * 0.78), 11, chestPiecePaint);
        break;

      case MediBuddyOutfit.nurse:
        // White nurse cap with red cross
        final capRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy - bodyRadius * 0.8),
            width: bodyRadius * 0.9,
            height: 28,
          ),
          const Radius.circular(8),
        );
        final capPaint = Paint()..color = Colors.white;
        canvas.drawRRect(capRect, capPaint);

        // Red cross
        final crossPaint = Paint()
          ..color = const Color(0xFFE11D48)
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(cx, cy - bodyRadius * 0.8 - 6),
          Offset(cx, cy - bodyRadius * 0.8 + 6),
          crossPaint,
        );
        canvas.drawLine(
          Offset(cx - 6, cy - bodyRadius * 0.8),
          Offset(cx + 6, cy - bodyRadius * 0.8),
          crossPaint,
        );
        break;

      case MediBuddyOutfit.champion:
        // Gold Ribbon Medal on chest
        final ribbonPaint = Paint()
          ..color = const Color(0xFF3B82F6)
          ..strokeWidth = 6.0;
        canvas.drawLine(Offset(cx - 10, cy + bodyRadius * 0.5), Offset(cx, cy + bodyRadius * 0.7), ribbonPaint);
        canvas.drawLine(Offset(cx + 10, cy + bodyRadius * 0.5), Offset(cx, cy + bodyRadius * 0.7), ribbonPaint);

        final medalPaint = Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFFDE047), Color(0xFFCA8A04)],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy + bodyRadius * 0.76), radius: 14));
        canvas.drawCircle(Offset(cx, cy + bodyRadius * 0.76), 14, medalPaint);

        // Star on medal
        final starPaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(cx, cy + bodyRadius * 0.76), 4, starPaint);
        break;

      case MediBuddyOutfit.casual:
        // No heavy accessories, pure cute pill friend
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MediBuddyPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.outfit != outfit ||
        oldDelegate.blinkProgress != blinkProgress ||
        oldDelegate.lookDirection != lookDirection ||
        oldDelegate.idleProgress != idleProgress;
  }
}

class _CelebrationParticlesPainter extends CustomPainter {
  final double progress;
  _CelebrationParticlesPainter({required this.progress});

  static const _colors = [
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < 14; i++) {
      final angle = (i * (2 * math.pi / 14)) + (progress * math.pi);
      final dist = (size.width * 0.42) + (math.sin(progress * 2 * math.pi + i) * 16);
      final px = cx + math.cos(angle) * dist;
      final py = cy + math.sin(angle) * dist;

      final paint = Paint()
        ..color = _colors[i % _colors.length].withAlpha((180 + 75 * math.sin(progress * math.pi)).toInt())
        ..style = PaintingStyle.fill;

      if (i % 2 == 0) {
        canvas.drawCircle(Offset(px, py), 4.5, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset(px, py), width: 8, height: 8), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationParticlesPainter oldDelegate) => true;
}

class _SleepingZzzPainter extends CustomPainter {
  final double progress;
  _SleepingZzzPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final zzzList = [
      {'text': 'z', 'size': 14.0, 'alpha': 140, 'offset': Offset(10, 24 - progress * 8)},
      {'text': 'Z', 'size': 18.0, 'alpha': 200, 'offset': Offset(22, 14 - progress * 10)},
      {'text': 'Z', 'size': 24.0, 'alpha': 255, 'offset': Offset(36, 4 - progress * 12)},
    ];

    for (final z in zzzList) {
      textPainter.text = TextSpan(
        text: z['text'] as String,
        style: TextStyle(
          fontSize: z['size'] as double,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF6366F1).withAlpha(z['alpha'] as int),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, z['offset'] as Offset);
    }
  }

  @override
  bool shouldRepaint(covariant _SleepingZzzPainter oldDelegate) => true;
}
