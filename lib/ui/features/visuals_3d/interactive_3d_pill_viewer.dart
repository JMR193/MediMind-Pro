import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/apple_glass_decorations.dart';

enum Pill3DType {
  capsule,
  scoredTablet,
  diamondTablet,
  dropperBottle,
}

class Interactive3dPillViewer extends StatefulWidget {
  final Pill3DType initialType;
  final Color primaryColor;
  final Color secondaryColor;
  final String imprint;
  final double size;
  final bool autoRotate;

  const Interactive3dPillViewer({
    super.key,
    this.initialType = Pill3DType.capsule,
    this.primaryColor = const Color(0xFF0284C7),
    this.secondaryColor = const Color(0xFFF43F5E),
    this.imprint = '500',
    this.size = 240,
    this.autoRotate = false,
  });

  @override
  State<Interactive3dPillViewer> createState() => _Interactive3dPillViewerState();
}

class _Interactive3dPillViewerState extends State<Interactive3dPillViewer>
    with SingleTickerProviderStateMixin {
  late Pill3DType _type;
  late Color _primaryColor;
  late Color _secondaryColor;
  late String _imprint;

  double _rotX = -0.25;
  double _rotY = 0.45;
  double _scale = 1.0;
  bool _isAutoRotating = true;

  late AnimationController _turntableController;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _primaryColor = widget.primaryColor;
    _secondaryColor = widget.secondaryColor;
    _imprint = widget.imprint;
    _isAutoRotating = widget.autoRotate;

    _turntableController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addListener(() {
        if (_isAutoRotating) {
          setState(() {
            _rotY += 0.015;
          });
        }
      });

    if (_isAutoRotating) {
      _turntableController.repeat();
    }
  }

  @override
  void dispose() {
    _turntableController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _isAutoRotating = false;
      _rotY += details.delta.dx * 0.015;
      _rotX -= details.delta.dy * 0.015;
      // Clamp pitch to prevent inverted flipping
      _rotX = _rotX.clamp(-1.2, 1.2);
    });
  }

  void _resetOrientation() {
    AppleGlassDecorations.lightHaptic();
    setState(() {
      _rotX = -0.25;
      _rotY = 0.45;
      _scale = 1.0;
      _isAutoRotating = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3D Orbital Canvas Container
        GestureDetector(
          onPanUpdate: _onPanUpdate,
          onDoubleTap: _resetOrientation,
          child: Container(
            width: widget.size * 1.3,
            height: widget.size * 1.3,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 0.85,
                colors: [
                  Theme.of(context).cardColor,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withAlpha(25),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Floor 3D Grid & Depth Rings
                CustomPaint(
                  size: Size(widget.size * 1.2, widget.size * 1.2),
                  painter: _FloorDepthPainter(primaryColor: _primaryColor),
                ),

                // 3D Matrix Perspective Transform Layer
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // Perspective focal distance
                    ..scale(_scale)
                    ..rotateX(_rotX)
                    ..rotateY(_rotY),
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _Pill3dPainter(
                      type: _type,
                      primaryColor: _primaryColor,
                      secondaryColor: _secondaryColor,
                      imprint: _imprint,
                      rotX: _rotX,
                      rotY: _rotY,
                    ),
                  ),
                ),

                // Top Floating Control Badges
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded, color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _isAutoRotating ? 'Auto-Orbiting' : 'Drag to Rotate 360°',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                // Auto-spin toggle & reset button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () {
                          setState(() {
                            _isAutoRotating = !_isAutoRotating;
                            if (_isAutoRotating) {
                              _turntableController.repeat();
                            } else {
                              _turntableController.stop();
                            }
                          });
                        },
                        iconSize: 16,
                        tooltip: 'Toggle Turntable Spin',
                        icon: Icon(_isAutoRotating ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        onPressed: _resetOrientation,
                        iconSize: 16,
                        tooltip: 'Reset 3D View',
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),

                // Zoom Slider at bottom
                Positioned(
                  bottom: 6,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_out, size: 14, color: Colors.grey),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _scale,
                            min: 0.7,
                            max: 1.6,
                            onChanged: (v) => setState(() => _scale = v),
                          ),
                        ),
                      ),
                      const Icon(Icons.zoom_in, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Pill Model Type Selector Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTypeChip(Pill3DType.capsule, '💊 Bicolor Capsule', const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              _buildTypeChip(Pill3DType.scoredTablet, '⚪ Scored Tablet', const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _buildTypeChip(Pill3DType.diamondTablet, '🔷 Diamond Rim', const Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              _buildTypeChip(Pill3DType.dropperBottle, '💧 Eye Dropper', const Color(0xFF06B6D4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(Pill3DType type, String label, Color accent) {
    final isSelected = _type == type;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: accent.withAlpha(40),
      side: BorderSide(color: isSelected ? accent : Colors.transparent),
      onSelected: (val) {
        if (val) {
          AppleGlassDecorations.lightHaptic();
          setState(() {
            _type = type;
            if (type == Pill3DType.dropperBottle) {
              _primaryColor = const Color(0xFF0284C7);
              _secondaryColor = const Color(0xFFE2E8F0);
            } else if (type == Pill3DType.scoredTablet) {
              _primaryColor = const Color(0xFFF8FAFC);
              _secondaryColor = const Color(0xFFE2E8F0);
              _imprint = 'M 500';
            } else if (type == Pill3DType.diamondTablet) {
              _primaryColor = const Color(0xFF6366F1);
              _secondaryColor = const Color(0xFF4338CA);
              _imprint = '20';
            } else {
              _primaryColor = const Color(0xFF0284C7);
              _secondaryColor = const Color(0xFFF43F5E);
              _imprint = 'ATV';
            }
          });
        }
      },
    );
  }
}

class _Pill3dPainter extends CustomPainter {
  final Pill3DType type;
  final Color primaryColor;
  final Color secondaryColor;
  final String imprint;
  final double rotX;
  final double rotY;

  _Pill3dPainter({
    required this.type,
    required this.primaryColor,
    required this.secondaryColor,
    required this.imprint,
    required this.rotX,
    required this.rotY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (type) {
      case Pill3DType.capsule:
        _draw3dCapsule(canvas, cx, cy, size.width * 0.38, size.height * 0.72);
        break;
      case Pill3DType.scoredTablet:
        _draw3dScoredTablet(canvas, cx, cy, size.width * 0.44);
        break;
      case Pill3DType.diamondTablet:
        _draw3dDiamondTablet(canvas, cx, cy, size.width * 0.44);
        break;
      case Pill3DType.dropperBottle:
        _draw3dDropperBottle(canvas, cx, cy, size.width * 0.36, size.height * 0.78);
        break;
    }
  }

  void _draw3dCapsule(Canvas canvas, double cx, double cy, double w, double h) {
    // 3D Bicolor Gel Capsule:
    // Top half: secondaryColor (e.g. Red)
    // Bottom half: primaryColor (e.g. Blue)
    // Dynamic light specular highlight running down the cylinder

    final halfH = h / 2;
    final r = w / 2;

    // Specular highlight offset based on rotation
    final lightShiftX = math.sin(rotY) * (w * 0.25);
    final lightShiftY = math.cos(rotX) * (h * 0.1);

    // 1. Lower Half (Primary Body)
    final lowerRect = Rect.fromLTRB(cx - r, cy, cx + r, cy + halfH);
    final lowerGradient = LinearGradient(
      begin: Alignment(-1.0 + (rotY / math.pi), -0.5),
      end: Alignment(1.0 + (rotY / math.pi), 0.5),
      colors: [
        primaryColor.withAlpha(200),
        Color.lerp(primaryColor, Colors.white, 0.4)!,
        primaryColor,
        Color.lerp(primaryColor, Colors.black, 0.45)!,
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );

    final lowerPath = Path()
      ..moveTo(cx - r, cy)
      ..lineTo(cx + r, cy)
      ..lineTo(cx + r, cy + halfH - r)
      ..arcToPoint(Offset(cx - r, cy + halfH - r), radius: Radius.circular(r), clockwise: true)
      ..close();

    final lowerPaint = Paint()..shader = lowerGradient.createShader(lowerRect);
    canvas.drawPath(lowerPath, lowerPaint);

    // 2. Upper Half (Secondary Cap - overlapping center band)
    final upperRect = Rect.fromLTRB(cx - r - 2, cy - halfH, cx + r + 2, cy + 3);
    final upperGradient = LinearGradient(
      begin: Alignment(-1.0 + (rotY / math.pi), -0.5),
      end: Alignment(1.0 + (rotY / math.pi), 0.5),
      colors: [
        secondaryColor.withAlpha(220),
        Color.lerp(secondaryColor, Colors.white, 0.45)!,
        secondaryColor,
        Color.lerp(secondaryColor, Colors.black, 0.4)!,
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );

    final upperPath = Path()
      ..moveTo(cx - r - 1.5, cy + 2)
      ..lineTo(cx + r + 1.5, cy + 2)
      ..lineTo(cx + r + 1.5, cy - halfH + r)
      ..arcToPoint(Offset(cx - r - 1.5, cy - halfH + r), radius: Radius.circular(r + 1.5), clockwise: false)
      ..close();

    final upperPaint = Paint()..shader = upperGradient.createShader(upperRect);
    canvas.drawPath(upperPath, upperPaint);

    // 3. Central Joint Ring (Cap Overlap Rim)
    final rimPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(cx - r - 1.5, cy + 2), Offset(cx + r + 1.5, cy + 2), rimPaint);

    // 4. Glossy Specular Glass Sheen across entire capsule
    final sheenPaint = Paint()
      ..color = Colors.white.withAlpha(120)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - r * 0.35 + lightShiftX, cy + lightShiftY), width: 6, height: h * 0.75),
        const Radius.circular(3),
      ),
      sheenPaint,
    );

    // 5. Imprint text on body
    _drawImprintText(canvas, Offset(cx, cy + halfH * 0.45), imprint, Colors.white.withAlpha(190));
  }

  void _draw3dScoredTablet(Canvas canvas, double cx, double cy, double radius) {
    // 3D Scored Circular Tablet with Chamfer Rim
    final lightShiftX = math.sin(rotY) * (radius * 0.3);
    final lightShiftY = math.cos(rotX) * (radius * 0.3);

    // Outer Rim (Chamfered Bevel)
    final bevelPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.35 + (rotY / math.pi), -0.35 + (rotX / math.pi)),
        radius: 0.95,
        colors: [
          Colors.white,
          primaryColor,
          Color.lerp(primaryColor, Colors.black, 0.35)!,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    canvas.drawCircle(Offset(cx, cy), radius, bevelPaint);

    // Inner Face
    final faceRadius = radius * 0.88;
    final facePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.2 + (rotY / math.pi), -0.2 + (rotX / math.pi)),
        radius: 0.95,
        colors: [
          Colors.white.withAlpha(240),
          primaryColor,
          Color.lerp(primaryColor, Colors.grey.shade400, 0.5)!,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: faceRadius));

    canvas.drawCircle(Offset(cx, cy), faceRadius, facePaint);

    // Debossed Score Line (Break-line in center)
    final scorePaint = Paint()
      ..color = Colors.black.withAlpha(90)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final scoreHighlight = Paint()
      ..color = Colors.white.withAlpha(180)
      ..strokeWidth = 1.5;

    final scoreAngle = rotY * 0.3;
    final dx = math.cos(scoreAngle) * (faceRadius * 0.85);
    final dy = math.sin(scoreAngle) * (faceRadius * 0.85);

    canvas.drawLine(Offset(cx - dx, cy - dy), Offset(cx + dx, cy + dy), scorePaint);
    canvas.drawLine(Offset(cx - dx + 1, cy - dy + 1), Offset(cx + dx + 1, cy + dy + 1), scoreHighlight);

    // Imprint on upper & lower halves
    _drawImprintText(canvas, Offset(cx, cy - faceRadius * 0.45), imprint, Colors.black45);
    _drawImprintText(canvas, Offset(cx, cy + faceRadius * 0.45), 'Rx', Colors.black38);
  }

  void _draw3dDiamondTablet(Canvas canvas, double cx, double cy, double radius) {
    // Polygonal Diamond Shaped Tablet with Faceted Edges
    final path = Path()
      ..moveTo(cx, cy - radius)
      ..lineTo(cx + radius * 0.85, cy)
      ..lineTo(cx, cy + radius)
      ..lineTo(cx - radius * 0.85, cy)
      ..close();

    final diamondGradient = LinearGradient(
      begin: Alignment(-1.0 + (rotY / math.pi), -1.0),
      end: Alignment(1.0, 1.0),
      colors: [
        Color.lerp(primaryColor, Colors.white, 0.4)!,
        primaryColor,
        secondaryColor,
        Color.lerp(secondaryColor, Colors.black, 0.4)!,
      ],
    );

    final paint = Paint()
      ..shader = diamondGradient.createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawPath(path, paint);

    // Beveled Inner facet
    final innerPath = Path()
      ..moveTo(cx, cy - radius * 0.72)
      ..lineTo(cx + radius * 0.62, cy)
      ..lineTo(cx, cy + radius * 0.72)
      ..lineTo(cx - radius * 0.62, cy)
      ..close();

    final innerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        colors: [Colors.white.withAlpha(200), primaryColor],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius * 0.72));

    canvas.drawPath(innerPath, innerPaint);
    _drawImprintText(canvas, Offset(cx, cy), imprint, Colors.white70);
  }

  void _draw3dDropperBottle(Canvas canvas, double cx, double cy, double w, double h) {
    // 3D Ophthalmic Bottle with Nozzle & Sloshing Liquid Physics Meniscus
    final r = w / 2;
    final bodyH = h * 0.58;
    final capH = h * 0.28;
    final tipH = h * 0.14;

    // 1. Translucent Plastic Bottle Body
    final bodyRect = Rect.fromLTRB(cx - r, cy - bodyH * 0.2, cx + r, cy + bodyH * 0.8);
    final bottlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.0 + (rotY / math.pi), 0),
        end: const Alignment(1.0, 0),
        colors: [
          Colors.white.withAlpha(200),
          const Color(0xFFE2E8F0).withAlpha(180),
          Colors.white.withAlpha(240),
          const Color(0xFFCBD5E1).withAlpha(220),
        ],
      ).createShader(bodyRect);

    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(16)), bottlePaint);

    // 2. Liquid Meniscus Level inside bottle (reacts to rotY tilt!)
    final liquidH = bodyH * 0.55;
    final liquidTilt = math.sin(rotY) * 12;
    final liquidPath = Path()
      ..moveTo(cx - r + 3, cy + bodyH * 0.25 + liquidTilt)
      ..quadraticBezierTo(cx, cy + bodyH * 0.25 - liquidTilt * 0.5, cx + r - 3, cy + bodyH * 0.25 - liquidTilt)
      ..lineTo(cx + r - 3, cy + bodyH * 0.8 - 4)
      ..lineTo(cx - r + 3, cy + bodyH * 0.8 - 4)
      ..close();

    final liquidPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withAlpha(140),
          primaryColor.withAlpha(240),
        ],
      ).createShader(bodyRect);
    canvas.drawPath(liquidPath, liquidPaint);

    // 3. Threaded Cap Collar & Cap
    final capRect = Rect.fromCenter(center: Offset(cx, cy - bodyH * 0.32), width: w * 0.72, height: capH);
    final capPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, Color.lerp(primaryColor, Colors.white, 0.4)!, primaryColor],
      ).createShader(capRect);
    canvas.drawRRect(RRect.fromRectAndRadius(capRect, const Radius.circular(8)), capPaint);

    // 4. Precision Dropper Tip Nozzle
    final tipPath = Path()
      ..moveTo(cx - w * 0.2, cy - bodyH * 0.32 - capH * 0.5)
      ..lineTo(cx + w * 0.2, cy - bodyH * 0.32 - capH * 0.5)
      ..lineTo(cx + 4, cy - bodyH * 0.32 - capH * 0.5 - tipH)
      ..lineTo(cx - 4, cy - bodyH * 0.32 - capH * 0.5 - tipH)
      ..close();
    final tipPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawPath(tipPath, tipPaint);

    // Droplet forming at the tip
    final dropletPaint = Paint()..color = primaryColor.withAlpha(220);
    canvas.drawCircle(Offset(cx, cy - bodyH * 0.32 - capH * 0.5 - tipH - 3), 4, dropletPaint);
  }

  void _drawImprintText(Canvas canvas, Offset center, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _Pill3dPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.imprint != imprint ||
        oldDelegate.rotX != rotX ||
        oldDelegate.rotY != rotY;
  }
}

class _FloorDepthPainter extends CustomPainter {
  final Color primaryColor;
  _FloorDepthPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.88;

    final paint = Paint()
      ..color = primaryColor.withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Concentric 3D Perspective Ellipses
    for (int i = 1; i <= 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: size.width * (0.35 * i), height: 18.0 * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloorDepthPainter oldDelegate) => false;
}
