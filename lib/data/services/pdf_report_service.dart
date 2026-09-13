import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../domain/models/medication.dart';
import '../../domain/models/medication_log.dart';

class PdfReportService {
  static Future<Uint8List> generateDoctorReport({
    required List<Medication> medications,
    required List<MedicationLog> logs,
    required double adherenceRate,
    required String patientName,
    String? periodString,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final now = DateTime.now();
    final period = periodString ?? '${DateFormat('MMM 1').format(now)} – ${DateFormat('MMM d, yyyy').format(now)}';

    // Calculate Per-Medication Taken vs Missed statistics
    final Map<String, Map<String, int>> perMedStats = {};
    for (final med in medications) {
      perMedStats[med.name] = {'taken': 0, 'missed': 0, 'snoozed': 0};
    }
    for (final log in logs) {
      if (!perMedStats.containsKey(log.medicationName)) {
        perMedStats[log.medicationName] = {'taken': 0, 'missed': 0, 'snoozed': 0};
      }
      if (log.status == LogStatus.taken) {
        perMedStats[log.medicationName]!['taken'] = (perMedStats[log.medicationName]!['taken'] ?? 0) + 1;
      } else if (log.status == LogStatus.skipped || log.status == LogStatus.missed) {
        perMedStats[log.medicationName]!['missed'] = (perMedStats[log.medicationName]!['missed'] ?? 0) + 1;
      } else if (log.status == LogStatus.snoozed) {
        perMedStats[log.medicationName]!['snoozed'] = (perMedStats[log.medicationName]!['snoozed'] ?? 0) + 1;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Eye & Systemic Medication Adherence Report',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 4),
                    pw.Text('Patient: $patientName', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Period: $period', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
                    pw.Text('Generated On: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: adherenceRate >= 80 ? PdfColors.green100 : PdfColors.orange100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: adherenceRate >= 80 ? PdfColors.green800 : PdfColors.orange800, width: 1.5),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('Overall Adherence', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('${adherenceRate.toStringAsFixed(0)}%',
                          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: adherenceRate >= 80 ? PdfColors.green900 : PdfColors.orange900)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1.5, color: PdfColors.blue800),
            pw.SizedBox(height: 12),

            // Per-Medication Taken vs Missed Table
            pw.Text('Medication Adherence Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Medication', 'Category / Form', 'Taken', 'Missed', 'Adherence %'],
              data: perMedStats.entries.map((entry) {
                final taken = entry.value['taken'] ?? 0;
                final missed = entry.value['missed'] ?? 0;
                final total = taken + missed;
                final rate = total > 0 ? ((taken / total) * 100).toStringAsFixed(0) : '100';
                final med = medications.firstWhere((m) => m.name == entry.key, orElse: () => medications.first);
                return [
                  entry.key,
                  med.isOintment ? 'Ointment' : med.requiresEyeDropProtocol ? 'Eye Drop' : med.category.name.toUpperCase(),
                  '$taken',
                  '$missed',
                  '$rate%',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),

            // Active Regimen Details
            pw.Text('Active Prescriptions & Regimens', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Medication', 'Strength', 'Dose & Times', 'Frequency', 'Doctor / Rx'],
              data: medications.map((m) {
                return [
                  m.name,
                  m.strength,
                  '${m.dosageAmount.toStringAsFixed(0)} ${m.dosageUnit.name}\n${m.scheduleTimes.join(", ")}',
                  m.frequency,
                  'Dr. ${m.prescribingDoctor ?? "N/A"}\nRx: ${m.rxNumber ?? "N/A"}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue600),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),

            // Recent Dose Administration Logs
            pw.Text('Recent Administration Logbook', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            if (logs.isEmpty)
              pw.Text('No dosage logs recorded in this period.', style: const pw.TextStyle(color: PdfColors.grey700))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Timestamp', 'Medication', 'Time', 'Status', 'Notes / Reason'],
                data: logs.reversed.take(15).map((l) {
                  return [
                    dateFormat.format(l.timestamp),
                    l.medicationName,
                    l.scheduledTime,
                    l.status.name.toUpperCase(),
                    l.skipReason ?? (l.notes ?? '-'),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
              ),

            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Confidential Medical Report — MediMind Pro Clinical Edition',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.Text('Doctor Review Copy', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
