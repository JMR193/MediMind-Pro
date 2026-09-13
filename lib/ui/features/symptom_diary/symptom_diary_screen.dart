import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/symptom_log.dart';
import '../../core/theme.dart';

class SymptomDiaryScreen extends StatelessWidget {
  const SymptomDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom Diary')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSymptomSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Symptom'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final logs = repo.symptomLogs;
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.health_and_safety_outlined, size: 72, color: Colors.grey.withAlpha(102)),
                  const SizedBox(height: 16),
                  const Text('No Symptoms Logged', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tap + to log eye or medication side effects', style: TextStyle(color: Colors.grey.withAlpha(153))),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildEscalationBanner(context, logs),
              const SizedBox(height: 12),
              ...logs.reversed.map((log) => _buildSymptomCard(context, log)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEscalationBanner(BuildContext context, List<SymptomLog> logs) {
    final serious = logs.where((l) => l.requiresUrgentEscalation).toList();
    if (serious.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MediMindTheme.alertRed.withAlpha(26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MediMindTheme.alertRed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: MediMindTheme.alertRed),
              SizedBox(width: 8),
              Text('Urgent Symptoms Logged', style: TextStyle(fontWeight: FontWeight.bold, color: MediMindTheme.alertRed, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('You have logged symptoms that may require professional attention. Please contact your doctor or visit urgent care.', style: TextStyle(fontSize: 12, color: MediMindTheme.alertRed)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.phone_outlined, size: 16, color: MediMindTheme.alertRed),
            label: const Text('Contact Doctor', style: TextStyle(color: MediMindTheme.alertRed)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: MediMindTheme.alertRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomCard(BuildContext context, SymptomLog log) {
    final severityColor = log.severity >= 7 ? MediMindTheme.alertRed : log.severity >= 4 ? MediMindTheme.warningOrange : MediMindTheme.successGreen;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: severityColor.withAlpha(26), shape: BoxShape.circle),
              child: Center(
                child: Text('${log.severity}\n/10', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: severityColor)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(log.symptomLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (log.requiresUrgentEscalation) ...[
                        const SizedBox(width: 6),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: MediMindTheme.alertRed.withAlpha(26), borderRadius: BorderRadius.circular(4)), child: const Text('URGENT', style: TextStyle(fontSize: 9, color: MediMindTheme.alertRed, fontWeight: FontWeight.bold))),
                      ],
                    ],
                  ),
                  if (log.affectedEye != null)
                    Text('Eye: ${log.affectedEye}', style: const TextStyle(fontSize: 11, color: Color(0xFF7C3AED))),
                  if (log.notes != null)
                    Text(log.notes!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(DateFormat('MMM dd, yyyy · HH:mm').format(log.timestamp), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSymptomSheet(BuildContext context) {
    SymptomType selected = SymptomType.redness;
    int severity = 3;
    String? eye = 'Both';
    final notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Log Symptom', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<SymptomType>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Symptom Type', prefixIcon: Icon(Icons.healing_outlined)),
                items: SymptomType.values.map((s) => DropdownMenuItem(value: s, child: Text(_symptomLabel(s)))).toList(),
                onChanged: (v) { if (v != null) setState(() => selected = v); },
              ),
              const SizedBox(height: 12),
              Text('Severity: $severity / 10', style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(value: severity.toDouble(), min: 1, max: 10, divisions: 9, label: '$severity', onChanged: (v) => setState(() => severity = v.toInt())),
              DropdownButtonFormField<String>(
                initialValue: eye,
                decoration: const InputDecoration(labelText: 'Affected Eye', prefixIcon: Icon(Icons.remove_red_eye_outlined)),
                items: ['Left', 'Right', 'Both', 'None'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => eye = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.note_outlined)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              if (severity >= 8 || selected == SymptomType.floaters)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: MediMindTheme.alertRed.withAlpha(26), borderRadius: BorderRadius.circular(10), border: Border.all(color: MediMindTheme.alertRed)),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_outlined, color: MediMindTheme.alertRed, size: 16),
                      SizedBox(width: 6),
                      Expanded(child: Text('High severity or floaters/flashes — please contact your doctor or visit urgent care.', style: TextStyle(fontSize: 11, color: MediMindTheme.alertRed))),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final log = SymptomLog(id: const Uuid().v4(), timestamp: DateTime.now(), symptomType: selected, severity: severity, notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(), affectedEye: eye, escalationTriggered: severity >= 8);
                  context.read<MedicationRepository>().addSymptomLog(log);
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Save Symptom'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _symptomLabel(SymptomType t) {
    switch (t) {
      case SymptomType.redness: return 'Redness';
      case SymptomType.pain: return 'Eye Pain';
      case SymptomType.blurredVision: return 'Blurred Vision';
      case SymptomType.discharge: return 'Discharge';
      case SymptomType.irritation: return 'Irritation / Itching';
      case SymptomType.headache: return 'Headache';
      case SymptomType.dryness: return 'Dryness';
      case SymptomType.lightSensitivity: return 'Light Sensitivity';
      case SymptomType.floaters: return 'Floaters / Flashes';
      case SymptomType.swelling: return 'Swelling';
      case SymptomType.other: return 'Other';
    }
  }
}
