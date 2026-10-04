import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/models/medication.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import 'interactive_3d_pill_viewer.dart';

/// A photorealistic 3D pharmaceutical card that procedurally renders
/// capsules, scored caplets, and liquid dropper bottles with 3D perspective,
/// specular highlights, fluid physics, and interactive micro-tilt.
class Realistic3dMedicineCard extends StatefulWidget {
  final Medication medication;
  final VoidCallback? onTap;
  final VoidCallback? onTakeDose;
  final bool showActions;
  final bool enableTilt;

  const Realistic3dMedicineCard({
    super.key,
    required this.medication,
    this.onTap,
    this.onTakeDose,
    this.showActions = true,
    this.enableTilt = true,
  });

  @override
  State<Realistic3dMedicineCard> createState() => _Realistic3dMedicineCardState();
}

class _Realistic3dMedicineCardState extends State<Realistic3dMedicineCard>
    with SingleTickerProviderStateMixin {
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  late AnimationController _fluidController;

  @override
  void initState() {
    super.initState();
    _fluidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _fluidController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableTilt) return;
    setState(() {
      _tiltY += details.delta.dx * 0.005;
      _tiltX -= details.delta.dy * 0.005;
      _tiltX = _tiltX.clamp(-0.25, 0.25);
      _tiltY = _tiltY.clamp(-0.25, 0.25);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableTilt) return;
    setState(() {
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
  }

  void _open3dInspector(BuildContext context) {
    AppleGlassDecorations.lightHaptic();
    Pill3DType pType = Pill3DType.capsule;
    if (widget.medication.isOphthalmic) {
      pType = Pill3DType.dropperBottle;
    } else if (widget.medication.dosageUnit == DosageUnit.capsules) {
      pType = Pill3DType.capsule;
    } else {
      pType = Pill3DType.scoredTablet;
    }

    final color = hexToColor(widget.medication.colorHex);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.medication.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '3D Pharmaceutical Inspection • ${widget.medication.strength}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Interactive3dPillViewer(
              initialType: pType,
              primaryColor: color,
              secondaryColor: color.withAlpha(200),
              imprint: widget.medication.strength.replaceAll(RegExp(r'[^0-9]'), ''),
              size: 220,
              autoRotate: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Drag to rotate in 3D • Tap anywhere to inspect geometry',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medication;
    final color = hexToColor(med.colorHex);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateX(_tiltX)
      ..rotateY(_tiltY);

    return GestureDetector(
      onTap: widget.onTap ?? () => _open3dInspector(context),
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: transform,
        transformAlignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: color.withAlpha(isDark ? 60 : 40),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(isDark ? 30 : 25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3D Procedural Canvas Graphic
              Hero(
                tag: 'med_3d_${med.id}',
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withAlpha(40)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _fluidController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(72, 72),
                            painter: _Realistic3dAssetPainter(
                              medication: med,
                              color: color,
                              wavePhase: _fluidController.value * 2 * math.pi,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.view_in_ar_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Medication Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            med.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (med.isOphthalmic)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'EYE DROP',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${med.dosageAmount.toInt()} ${med.dosageUnit.name} • ${med.strength}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            med.scheduleTimes.join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Inventory stock bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (med.totalInventoryCount / (med.refillThreshold * 3).clamp(1, 100)).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey.withAlpha(40),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                med.totalInventoryCount <= med.refillThreshold
                                    ? MediMindTheme.alertRed
                                    : MediMindTheme.successGreen,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${med.totalInventoryCount} left',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: med.totalInventoryCount <= med.refillThreshold
                                ? MediMindTheme.alertRed
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (widget.showActions && widget.onTakeDose != null) ...[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: widget.onTakeDose,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  tooltip: 'Log Dose',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Photorealistic 2.5D/3D Canvas Painter for pharmaceutical items.
class _Realistic3dAssetPainter extends CustomPainter {
  final Medication medication;
  final Color color;
  final double wavePhase;

  _Realistic3dAssetPainter({
    required this.medication,
    required this.color,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (medication.isOphthalmic) {
      _paint3dDropperBottle(canvas, size);
    } else if (medication.dosageUnit == DosageUnit.capsules) {
      _paint3dCapsule(canvas, size);
    } else {
      _paint3dScoredTablet(canvas, size);
    }
  }

  void _paint3dCapsule(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-math.pi / 4);

    const capW = 22.0;
    const capH = 46.0;
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: capW, height: capH),
      const Radius.circular(capW / 2),
    );

    // 1. Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(r.shift(const Offset(3, 3)), shadowPaint);

    // 2. Base capsule clipping
    canvas.save();
    canvas.clipRRect(r);

    // Top half (primary color)
    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withAlpha(180), color.withAlpha(240)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(-capW / 2, -capH / 2, capW, capH / 2));
    canvas.drawRect(Rect.fromLTWH(-capW / 2, -capH / 2, capW, capH / 2), topPaint);

    // Bottom half (translucent white with visible micro-pellets)
    final botPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withAlpha(220), Colors.white.withAlpha(140)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(-capW / 2, 0, capW, capH / 2));
    canvas.drawRect(Rect.fromLTWH(-capW / 2, 0, capW, capH / 2), botPaint);

    // Micro-pellets inside translucent bottom half
    final pelletPaint = Paint()..color = color.withAlpha(160);
    final pelletOffsets = [
      const Offset(-4, 6),
      const Offset(4, 8),
      const Offset(-2, 14),
      const Offset(3, 17),
      const Offset(0, 10),
    ];
    for (final p in pelletOffsets) {
      canvas.drawCircle(p, 1.8, pelletPaint);
    }

    // Joining rim band
    final rimPaint = Paint()
      ..color = Colors.black.withAlpha(40)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-capW / 2, 0), const Offset(capW / 2, 0), rimPaint);

    // 3. Specular highlight streak
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withAlpha(190), Colors.white.withAlpha(10)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-capW / 2 + 2, -capH / 2 + 4, 3, capH - 8));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-capW / 2 + 2, -capH / 2 + 4, 3.5, capH - 8),
        const Radius.circular(2),
      ),
      highlightPaint,
    );

    canvas.restore();
    canvas.restore();
  }

  void _paint3dScoredTablet(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const radius = 22.0;

    // 1. Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(cx + 2, cy + 3), radius, shadowPaint);

    // 2. Beveled Outer Edge
    final bevelPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [
          Colors.white,
          color.withAlpha(180),
          color,
          color.withAlpha(240),
        ],
        stops: const [0.0, 0.45, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, bevelPaint);

    // 3. Debossed Score Line
    final scorePaintDark = Paint()
      ..color = Colors.black.withAlpha(60)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final scorePaintLight = Paint()
      ..color = Colors.white.withAlpha(150)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx - 15, cy - 1), Offset(cx + 15, cy - 1), scorePaintDark);
    canvas.drawLine(Offset(cx - 15, cy + 1), Offset(cx + 15, cy + 1), scorePaintLight);

    // 4. Specular Curved Crescent Highlight
    final crescentPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius - 3),
        -math.pi * 0.8,
        math.pi * 0.5,
      );
    final crescentPaint = Paint()
      ..color = Colors.white.withAlpha(170)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(crescentPath, crescentPaint);
  }

  void _paint3dDropperBottle(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 2, cy + 4), width: 34, height: 48),
        const Radius.circular(10),
      ),
      shadowPaint,
    );

    // 2. Bottle Body
    final bodyRect = Rect.fromCenter(center: Offset(cx, cy + 4), width: 32, height: 44);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(8));

    canvas.save();
    canvas.clipRRect(bodyRRect);

    // Glass translucency base
    final glassPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withAlpha(200),
          Colors.white.withAlpha(100),
          Colors.white.withAlpha(180),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bodyRect);
    canvas.drawRect(bodyRect, glassPaint);

    // Sloshing Liquid inside
    final liquidLevelY = bodyRect.top + 16;
    final liquidPath = Path()
      ..moveTo(bodyRect.left, bodyRect.bottom)
      ..lineTo(bodyRect.right, bodyRect.bottom)
      ..lineTo(bodyRect.right, liquidLevelY + math.sin(wavePhase) * 2)
      ..quadraticBezierTo(
        cx,
        liquidLevelY - math.cos(wavePhase) * 3,
        bodyRect.left,
        liquidLevelY + math.sin(wavePhase + math.pi) * 2,
      )
      ..close();

    final liquidPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withAlpha(220), color.withAlpha(160)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bodyRect);
    canvas.drawPath(liquidPath, liquidPaint);

    // Glass Highlight Glare
    final glarePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withAlpha(200), Colors.white.withAlpha(20)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(bodyRect.left + 3, bodyRect.top + 4, 3, bodyRect.height - 8));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyRect.left + 3, bodyRect.top + 4, 3, bodyRect.height - 8),
        const Radius.circular(1.5),
      ),
      glarePaint,
    );

    canvas.restore();

    // 3. Screw Cap
    final capRect = Rect.fromCenter(center: Offset(cx, cy - 20), width: 22, height: 10);
    final capRRect = RRect.fromRectAndRadius(capRect, const Radius.circular(3));
    final capPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey.shade400, Colors.grey.shade100, Colors.grey.shade400],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(capRect);
    canvas.drawRRect(capRRect, capPaint);

    // 4. Dropper Tip
    final tipRect = Rect.fromCenter(center: Offset(cx, cy - 27), width: 10, height: 6);
    final tipPaint = Paint()..color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(tipRect, const Radius.circular(2)), tipPaint);

    // 5. Forming Tear Drop
    final dropCenter = Offset(cx, cy - 32 + (math.sin(wavePhase).abs() * 2));
    final dropPaint = Paint()..color = color.withAlpha(200);
    canvas.drawCircle(dropCenter, 2.5, dropPaint);
  }

  @override
  bool shouldRepaint(covariant _Realistic3dAssetPainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color ||
        oldDelegate.medication != medication;
  }
}
