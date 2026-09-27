import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/services/clinical_chart_assistant_service.dart';
import '../../core/apple_glass_decorations.dart';

/// Elite Interactive AI Chart Assistant & Telemetry View.
class ChartAssistantView extends StatefulWidget {
  final MedicationRepository repository;

  const ChartAssistantView({
    super.key,
    required this.repository,
  });

  @override
  State<ChartAssistantView> createState() => _ChartAssistantViewState();
}

class _ChartAssistantViewState extends State<ChartAssistantView> {
  ChartTimeframe _timeframe = ChartTimeframe.sevenDays;
  ChartVisualMode _visualMode = ChartVisualMode.adherenceTrend;
  String _selectedInquiryQuery = 'forecast';
  String? _inquiryAnswer;
  late ChartAssistantReport _report;

  static const _quickInquiries = [
    ('forecast', '📈 Forecast Next Week', 'What is my adherence forecast?'),
    ('jitter', '⏱️ Circadian Timing Jitter', 'How much timing jitter do I have?'),
    ('risk', '⚠️ Highest-Risk Dose Window', 'What is my highest-risk dose window?'),
    ('distribution', '🍩 Time of Day Distribution', 'Show my dose distribution by time of day'),
    ('doctor', '📋 Doctor Telemetry Digest', 'Generate a doctor report summary'),
  ];

  @override
  void initState() {
    super.initState();
    _recalculateReport();
    _answerInquiry('forecast');
  }

  void _recalculateReport() {
    _report = ClinicalChartAssistantService.analyzeChartTelemetry(
      medications: widget.repository.activeMedications,
      logs: widget.repository.logs,
      timeframe: _timeframe,
    );
  }

  void _answerInquiry(String key) {
    final queryItem = _quickInquiries.firstWhere((q) => q.$1 == key);
    final answer = ClinicalChartAssistantService.answerChartInquiry(
      query: queryItem.$3,
      report: _report,
    );
    setState(() {
      _selectedInquiryQuery = key;
      _inquiryAnswer = answer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adherenceColor = _report.overallAdherencePercent >= 80.0
        ? const Color(0xFF10B981)
        : const Color(0xFFEA580C);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Clinical Chart Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Predictive Telemetry • Linear Regression • Jitter Analysis',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withAlpha(100)),
                      ),
                      child: const Text(
                        'LIVE AI',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Timeframe Selector
                Row(
                  children: [
                    _buildTimeframeChip(ChartTimeframe.sevenDays, '7 Days'),
                    const SizedBox(width: 8),
                    _buildTimeframeChip(ChartTimeframe.fourteenDays, '14 Days'),
                    const SizedBox(width: 8),
                    _buildTimeframeChip(ChartTimeframe.thirtyDays, '30 Days'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4 Key Telemetry Metrics
          Row(
            children: [
              _buildMetricCard(
                'Adherence Rate',
                '${_report.overallAdherencePercent.toStringAsFixed(1)}%',
                'WHO Target ≥80%',
                adherenceColor,
                Icons.task_alt_rounded,
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                '7D Forecast',
                '${_report.adherenceForecastPercent.toStringAsFixed(1)}%',
                _report.trajectorySlope >= 0 ? 'Trending Up ↗' : 'Trending Down ↘',
                _report.trajectorySlope >= 0 ? const Color(0xFF10B981) : const Color(0xFFEA580C),
                Icons.trending_up_rounded,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetricCard(
                'Timing Jitter',
                '±${_report.timingJitterMinutes.toStringAsFixed(0)} min',
                _report.timingJitterMinutes < 20 ? 'High Precision' : 'Variable Drift',
                const Color(0xFF0284C7),
                Icons.schedule_rounded,
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                'Intake Breakdown',
                '${_report.totalDosesTaken} / ${_report.totalDosesTaken + _report.totalDosesMissed}',
                '${_report.totalDosesMissed} missed doses',
                const Color(0xFF7C3AED),
                Icons.pie_chart_outline_rounded,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Visual Mode Tab Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildVisualModeTab(ChartVisualMode.adherenceTrend, 'Trend Curve', Icons.show_chart_rounded),
                _buildVisualModeTab(ChartVisualMode.intakeComparison, 'Intake Bars', Icons.bar_chart_rounded),
                _buildVisualModeTab(ChartVisualMode.timeOfDayDistribution, 'Time Pie', Icons.pie_chart_rounded),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Interactive Chart Container
          Container(
            height: 240,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: AppleGlassDecorations.frostedGlassBox(
              color: Colors.white,
              opacity: 0.95,
              borderRadius: 20,
              borderColor: const Color(0xFF0D9488).withAlpha(40),
            ),
            child: _buildSelectedChart(),
          ),

          const SizedBox(height: 16),

          // AI Conversational Chart Inquiries
          const Text(
            '🤖 Ask the Chart Assistant:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickInquiries.map((inq) {
                final isSelected = _selectedInquiryQuery == inq.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(inq.$2, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0D9488),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    onSelected: (val) {
                      if (val) {
                        AppleGlassDecorations.lightHaptic();
                        _answerInquiry(inq.$1);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // AI Response Card
          if (_inquiryAnswer != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, size: 18, color: Color(0xFF0D9488)),
                      const SizedBox(width: 8),
                      const Text(
                        'Chart Assistant Insight',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                        tooltip: 'Copy response',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _inquiryAnswer!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied chart insight to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _inquiryAnswer!,
                    style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Clinical Diagnostics List
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.checklist_rounded, size: 16, color: Color(0xFF0D9488)),
                    SizedBox(width: 6),
                    Text(
                      'AI Clinical Telemetry Findings',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F766E)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._report.clinicalInsights.map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $insight',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF134E4A), height: 1.3),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimeframeChip(ChartTimeframe tf, String label) {
    final isSelected = _timeframe == tf;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppleGlassDecorations.lightHaptic();
          setState(() {
            _timeframe = tf;
            _recalculateReport();
            _answerInquiry(_selectedInquiryQuery);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D9488) : Colors.white12,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String sub, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualModeTab(ChartVisualMode mode, String label, IconData icon) {
    final isSelected = _visualMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppleGlassDecorations.lightHaptic();
          setState(() => _visualMode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedChart() {
    switch (_visualMode) {
      case ChartVisualMode.adherenceTrend:
        return _buildLineChart();
      case ChartVisualMode.intakeComparison:
        return _buildBarChart();
      case ChartVisualMode.timeOfDayDistribution:
        return _buildPieChart();
      case ChartVisualMode.timingJitter:
        return _buildLineChart();
    }
  }

  // 1. Line Chart: Adherence Trend & Moving Average
  Widget _buildLineChart() {
    final points = _report.dailyPoints;
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].adherencePercent));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 105,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (v, m) => Text(
                '${v.toInt()}%',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                // Show labels evenly
                final show = points.length <= 7 || idx % (points.length ~/ 7) == 0;
                if (!show) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    points[idx].dayLabel,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 80,
              color: const Color(0xFF10B981).withAlpha(120),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                style: const TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                labelResolver: (_) => '80% WHO Benchmark',
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF0D9488),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3.5,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: const Color(0xFF0D9488),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D9488).withAlpha(60),
                  const Color(0xFF0D9488).withAlpha(5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Bar Chart: Intake vs Scheduled
  Widget _buildBarChart() {
    final points = _report.dailyPoints;
    final groups = <BarChartGroupData>[];

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: p.scheduledDoses.toDouble(),
            color: Colors.grey.shade300,
            width: 7,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: p.takenDoses.toDouble(),
            color: const Color(0xFF0D9488),
            width: 7,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ));
    }

    return BarChart(
      BarChartData(
        barGroups: groups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                final show = points.length <= 7 || idx % 2 == 0;
                if (!show) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(points[idx].dayLabel, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // 3. Pie Chart: Time-of-Day Distribution
  Widget _buildPieChart() {
    final td = _report.timeDistribution;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 36,
              sections: [
                PieChartSectionData(
                  color: const Color(0xFFF59E0B),
                  value: td.morningCount.toDouble(),
                  title: '${td.morningPercent.toStringAsFixed(0)}%',
                  radius: 36,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: const Color(0xFF0284C7),
                  value: td.noonCount.toDouble(),
                  title: '${td.noonPercent.toStringAsFixed(0)}%',
                  radius: 36,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: const Color(0xFFEA580C),
                  value: td.eveningCount.toDouble(),
                  title: '${td.eveningPercent.toStringAsFixed(0)}%',
                  radius: 36,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: const Color(0xFF7C3AED),
                  value: td.bedtimeCount.toDouble(),
                  title: '${td.bedtimePercent.toStringAsFixed(0)}%',
                  radius: 36,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPieLegend(const Color(0xFFF59E0B), '☀️ Morning (${td.morningCount})'),
              const SizedBox(height: 6),
              _buildPieLegend(const Color(0xFF0284C7), '🌤️ Midday (${td.noonCount})'),
              const SizedBox(height: 6),
              _buildPieLegend(const Color(0xFFEA580C), '🌅 Evening (${td.eveningCount})'),
              const SizedBox(height: 6),
              _buildPieLegend(const Color(0xFF7C3AED), '🌙 Bedtime (${td.bedtimeCount})'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 10, color: Color(0xFF334155), fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
