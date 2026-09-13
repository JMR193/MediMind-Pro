import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/services/pdf_report_service.dart';
import '../../../domain/models/medication_log.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        final adherence = repo.calculateAdherenceRate();
        final logs = repo.logs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAdherenceCard(context, adherence),
              const SizedBox(height: 16),
              _buildChartCard(context, logs),
              const SizedBox(height: 16),
              _buildStatusBreakdownCard(context, logs),
              const SizedBox(height: 16),
              _buildInteractionWarningsCard(context),
              const SizedBox(height: 16),
              _buildExportCard(context, repo, adherence),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdherenceCard(BuildContext context, double adherence) {
    final color = adherence >= 80 ? MediMindTheme.successGreen : adherence >= 50 ? MediMindTheme.warningOrange : MediMindTheme.alertRed;
    final label = adherence >= 80 ? 'Excellent' : adherence >= 50 ? 'Needs Improvement' : 'Critical – Consult Doctor';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: adherence / 100,
                    strokeWidth: 10,
                    backgroundColor: color.withAlpha(38),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Text('${adherence.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall Adherence Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(6)),
                    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Based on all logged doses in this session.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, List<MedicationLog> logs) {
    // Group by status for bar chart
    final taken = logs.where((l) => l.status == LogStatus.taken).length.toDouble();
    final skipped = logs.where((l) => l.status == LogStatus.skipped).length.toDouble();
    final snoozed = logs.where((l) => l.status == LogStatus.snoozed).length.toDouble();
    final delayed = logs.where((l) => l.status == LogStatus.delayed).length.toDouble();

    if (logs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey.withAlpha(102)),
                const SizedBox(height: 8),
                const Text('No data yet — start logging doses', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dose Status Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: [taken, skipped, snoozed, delayed].reduce((a, b) => a > b ? a : b) + 1,
                  barGroups: [
                    _barGroup(0, taken, MediMindTheme.successGreen),
                    _barGroup(1, skipped, MediMindTheme.alertRed),
                    _barGroup(2, snoozed, MediMindTheme.warningOrange),
                    _barGroup(3, delayed, const Color(0xFF7C3AED)),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Taken', 'Skipped', 'Snoozed', 'Delayed'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(labels[value.toInt()], style: const TextStyle(fontSize: 10)),
                        );
                      },
                    )),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withAlpha(26), strokeWidth: 1)),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 32,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildStatusBreakdownCard(BuildContext context, List<MedicationLog> logs) {
    final statuses = [LogStatus.taken, LogStatus.skipped, LogStatus.snoozed, LogStatus.delayed];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Administration Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              const Text('No dose logs recorded.', style: TextStyle(color: Colors.grey))
            else
              ...logs.reversed.take(10).map((log) {
                final color = logStatusColor(log.status, context);
                final icon = logStatusIcon(log.status);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: color.withAlpha(26),
                    radius: 18,
                    child: Icon(icon, color: color, size: 16),
                  ),
                  title: Text(log.medicationName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('${log.status.name.toUpperCase()} · ${log.scheduledTime}${log.skipReason != null ? ' · ${log.skipReason}' : ''}', style: const TextStyle(fontSize: 11)),
                  trailing: Text('${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                );
              }),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: statuses.map((s) {
                final count = logs.where((l) => l.status == s).length;
                final color = logStatusColor(s, context);
                return Column(
                  children: [
                    Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                    Text(s.name, style: TextStyle(fontSize: 10, color: color)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionWarningsCard(BuildContext context) {
    return Card(
      color: MediMindTheme.alertRed.withAlpha(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_outlined, color: MediMindTheme.warningOrange, size: 20),
                const SizedBox(width: 8),
                const Text('Drug & Food Interaction Advisories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            const _InteractionItem(
              severity: 'CRITICAL',
              severityColor: MediMindTheme.alertRed,
              title: 'Warfarin + NSAIDs (Ibuprofen/Aspirin)',
              detail: 'Multiplied hemorrhage risk. Consult prescribing doctor before any OTC pain reliever.',
            ),
            const _InteractionItem(
              severity: 'HIGH',
              severityColor: Color(0xFFD97706),
              title: 'Statins (Atorvastatin) + Grapefruit Juice',
              detail: 'CYP3A4 inhibition → dangerously elevated statin blood levels → rhabdomyolysis risk.',
            ),
            const _InteractionItem(
              severity: 'HIGH',
              severityColor: Color(0xFFD97706),
              title: 'Quinolone Antibiotics + Calcium / Dairy',
              detail: 'Chelation reduces antibiotic absorption by up to 90%. Take 2h before or 6h after.',
            ),
            const _InteractionItem(
              severity: 'MODERATE',
              severityColor: Color(0xFF0284C7),
              title: 'Eye Drops (Multiple) — Washout Effect',
              detail: 'Wait 5–10 min between different eye drop medications to prevent dilution.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard(BuildContext context, MedicationRepository repo, double adherence) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clinical Report Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            const Text('Generate a doctor-formatted PDF adherence report with complete medication records, dosage logs, and compliance metrics.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final pdfBytes = await PdfReportService.generateDoctorReport(
                  medications: repo.medications,
                  logs: repo.logs,
                  adherenceRate: adherence,
                  patientName: 'Patient (MediMind Pro)',
                );
                if (context.mounted) {
                  await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
                }
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generate & Share Doctor Report'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionItem extends StatelessWidget {
  final String severity;
  final Color severityColor;
  final String title;
  final String detail;

  const _InteractionItem({
    required this.severity,
    required this.severityColor,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: severityColor.withAlpha(26), borderRadius: BorderRadius.circular(4)),
            child: Text(severity, style: TextStyle(fontSize: 9, color: severityColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Text(detail, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
