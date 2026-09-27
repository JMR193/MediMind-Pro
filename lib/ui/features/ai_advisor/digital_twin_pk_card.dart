import 'package:flutter/material.dart';
import '../../../data/services/pharmacokinetic_simulator.dart';
import '../../core/apple_glass_decorations.dart';

/// Interactive Digital Twin Pharmacokinetic Curve & Blood Plasma Visualizer.
class DigitalTwinPkCard extends StatefulWidget {
  final String medicationName;
  final double doseMg;
  final List<DateTime> pastDoseTimestamps;

  const DigitalTwinPkCard({
    super.key,
    required this.medicationName,
    this.doseMg = 20.0,
    this.pastDoseTimestamps = const [],
  });

  @override
  State<DigitalTwinPkCard> createState() => _DigitalTwinPkCardState();
}

class _DigitalTwinPkCardState extends State<DigitalTwinPkCard> {
  String _selectedScenario = 'on_time'; // 'on_time', 'delayed_4h', 'double_dose', 'missed'
  late DrugPkProfile _profile;
  late PkSimulationResult _simulation;

  @override
  void initState() {
    super.initState();
    _recalculateSimulation();
  }

  @override
  void didUpdateWidget(covariant DigitalTwinPkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medicationName != widget.medicationName ||
        oldWidget.doseMg != widget.doseMg) {
      _recalculateSimulation();
    }
  }

  void _recalculateSimulation() {
    _profile = PharmacokineticSimulatorService.getProfileForMedication(
      widget.medicationName,
    );

    if (_selectedScenario == 'on_time') {
      _simulation = PharmacokineticSimulatorService.simulateRegimen(
        profile: _profile,
        doseMg: widget.doseMg,
        pastDoseTimestamps: widget.pastDoseTimestamps,
        now: DateTime.now(),
        hoursToSimulateAhead: 24,
      );
    } else {
      _simulation = PharmacokineticSimulatorService.simulateWhatIfScenario(
        profile: _profile,
        baseDoseMg: widget.doseMg,
        now: DateTime.now(),
        scenarioType: _selectedScenario,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_simulation.currentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppleGlassDecorations.frostedGlassBox(
        color: Colors.white,
        opacity: 0.85,
        borderRadius: 20,
        borderColor: const Color(0xFF0D9488).withAlpha(50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile.drugName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${_profile.drugClass} • Half-Life: ${_profile.halfLifeHours.toStringAsFixed(1)}h',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1.2),
                ),
                child: Text(
                  _getStatusLabel(_simulation.currentStatus),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Plasma Status Overview
          Row(
            children: [
              _buildMetricTile(
                'Simulated Plasma',
                '${_simulation.currentConcentration.toStringAsFixed(1)} ug/L',
                statusColor,
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                'Effective Window',
                '${_profile.minimumEffectiveConc.toStringAsFixed(0)} - ${_profile.minimumToxicConc.toStringAsFixed(0)}',
                const Color(0xFF0D9488),
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                'Coverage',
                '${_simulation.timeAboveMecPercent.toStringAsFixed(0)}% in target',
                Colors.indigo,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // PK Curve Custom Canvas Chart
          Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              painter: _PkCurvePainter(
                result: _simulation,
                profile: _profile,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(const Color(0xFF10B981), 'Optimal Window (MEC-MTC)'),
              _buildLegendItem(const Color(0xFFEF4444), 'Toxic Limit (MTC)'),
              _buildLegendItem(const Color(0xFF38BDF8), 'Plasma Level Curve'),
            ],
          ),

          const SizedBox(height: 16),

          // What-If Simulation Selector
          Text(
            '🧪 Interactive "What-If" Scenario Tester',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildScenarioChip('on_time', '🟢 Normal Routine', Colors.teal),
                const SizedBox(width: 8),
                _buildScenarioChip('delayed_4h', '🟡 4 Hours Late', Colors.amber.shade700),
                const SizedBox(width: 8),
                _buildScenarioChip('missed', '⚪ Skipped Dose', Colors.grey.shade700),
                const SizedBox(width: 8),
                _buildScenarioChip('double_dose', '🔴 Double Dosed (2x)', Colors.red),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Clinical Rationale & Recommendation Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology_outlined, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      'Clinical Recommendation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _simulation.recommendation,
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
                if (_simulation.clinicalWarnings.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ..._simulation.clinicalWarnings.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚠️ ', style: TextStyle(fontSize: 10)),
                          Expanded(
                            child: Text(
                              w,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildScenarioChip(String key, String label, Color activeColor) {
    final isSelected = _selectedScenario == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      onSelected: (val) {
        if (val) {
          AppleGlassDecorations.mediumHaptic();
          setState(() {
            _selectedScenario = key;
            _recalculateSimulation();
          });
        }
      },
    );
  }

  Color _getStatusColor(PlasmaSafetyStatus status) {
    switch (status) {
      case PlasmaSafetyStatus.optimalTherapeutic:
        return const Color(0xFF10B981);
      case PlasmaSafetyStatus.subtherapeutic:
        return const Color(0xFFF59E0B);
      case PlasmaSafetyStatus.approachingToxic:
        return const Color(0xFFEA580C);
      case PlasmaSafetyStatus.toxicOverdose:
        return const Color(0xFFEF4444);
    }
  }

  String _getStatusLabel(PlasmaSafetyStatus status) {
    switch (status) {
      case PlasmaSafetyStatus.optimalTherapeutic:
        return 'TARGET SAFE';
      case PlasmaSafetyStatus.subtherapeutic:
        return 'SUBTHERAPEUTIC';
      case PlasmaSafetyStatus.approachingToxic:
        return 'HIGH RISK';
      case PlasmaSafetyStatus.toxicOverdose:
        return 'TOXIC OVERDOSE';
    }
  }
}

/// Custom Canvas Painter rendering high-precision blood plasma curves and therapeutic windows.
class _PkCurvePainter extends CustomPainter {
  final PkSimulationResult result;
  final DrugPkProfile profile;

  _PkCurvePainter({required this.result, required this.profile});

  @override
  void paint(Canvas canvas, Size size) {
    final points = result.curvePoints;
    if (points.isEmpty) return;

    // Find min and max for scaling
    final maxC = math.max(
      profile.minimumToxicConc * 1.25,
      points.map((p) => p.concentration).reduce(math.max),
    );
    final scaleY = size.height / (maxC <= 0 ? 1.0 : maxC);
    final scaleX = size.width / (points.length - 1);

    // 1. Shaded Therapeutic Window Band (MEC to MTC)
    final mecY = size.height - (profile.minimumEffectiveConc * scaleY);
    final mtcY = size.height - (profile.minimumToxicConc * scaleY);

    final windowPaint = Paint()
      ..color = const Color(0xFF10B981).withAlpha(40)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(0, mtcY.clamp(0, size.height), size.width, mecY.clamp(0, size.height)),
      windowPaint,
    );

    // 2. Toxic Threshold Line (MTC - Red Dashed)
    final toxicLinePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, mtcY), Offset(size.width, mtcY), toxicLinePaint);

    // 3. Minimum Effective Line (MEC - Green)
    final mecLinePaint = Paint()
      ..color = const Color(0xFF10B981).withAlpha(150)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, mecY), Offset(size.width, mecY), mecLinePaint);

    // 4. Now Indicator Line (Center of 48h window = offset 0.0)
    final nowIndex = points.indexWhere((p) => p.hourOffset >= 0);
    if (nowIndex != -1) {
      final nowX = nowIndex * scaleX;
      final nowLinePaint = Paint()
        ..color = Colors.white30
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(nowX, 0), Offset(nowX, size.height), nowLinePaint);
    }

    // 5. Plasma Concentration Curve
    final curvePath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = i * scaleX;
      final y = size.height - (points[i].concentration * scaleY);
      if (i == 0) {
        curvePath.moveTo(x, y);
      } else {
        curvePath.lineTo(x, y);
      }
    }

    final curvePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(curvePath, curvePaint);

    // 6. Draw Current Point Dot
    if (nowIndex != -1 && nowIndex < points.length) {
      final currentX = nowIndex * scaleX;
      final currentY = size.height - (points[nowIndex].concentration * scaleY);

      final dotOuterPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final dotInnerPaint = Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(currentX, currentY), 5.0, dotOuterPaint);
      canvas.drawCircle(Offset(currentX, currentY), 3.0, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PkCurvePainter oldDelegate) {
    return oldDelegate.result != result || oldDelegate.profile != profile;
  }
}
