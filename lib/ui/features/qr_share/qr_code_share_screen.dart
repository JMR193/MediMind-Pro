import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/services/interaction_service.dart';
import '../../../domain/models/medication.dart';
import '../../core/theme.dart';

class QrCodeShareScreen extends StatefulWidget {
  const QrCodeShareScreen({super.key});

  @override
  State<QrCodeShareScreen> createState() => _QrCodeShareScreenState();
}

class _QrCodeShareScreenState extends State<QrCodeShareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _importTextCtrl = TextEditingController();

  bool _includeDosageDetails = true;
  bool _includeDoctorContacts = true;
  bool _includeOphthalmicSpecs = true;

  // Import state
  List<Medication>? _parsedImportMeds;
  List<DrugInteractionWarning>? _detectedImportInteractions;
  String? _importError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importTextCtrl.dispose();
    super.dispose();
  }

  String _generateQrPayload(MedicationRepository repo) {
    final activeMeds = repo.activeMedications;
    final profile = repo.activeProfile;

    final medList = activeMeds.map((m) {
      final map = <String, dynamic>{
        'name': m.name,
        'strength': m.strength,
        'category': m.category.name,
        'dosageUnit': m.dosageUnit.name,
        'frequency': m.frequency,
        'scheduleTimes': m.scheduleTimes,
      };

      if (_includeDosageDetails) {
        map['dosageAmount'] = m.dosageAmount;
        map['instruction'] = m.instruction.name;
        map['scheduledDaysOfWeek'] = m.scheduledDaysOfWeek;
        map['cycleDaysOn'] = m.cycleDaysOn;
        map['cycleDaysOff'] = m.cycleDaysOff;
      }

      if (_includeOphthalmicSpecs &&
          (m.category == MedCategory.eyeDrop || m.category == MedCategory.eyeOintment)) {
        map['requiresEyeDropProtocol'] = m.requiresEyeDropProtocol;
        map['eyeTarget'] = m.eyeTarget;
        map['eyeDropGapMinutes'] = m.eyeDropGapMinutes;
        map['ophthalmicFormulation'] = m.ophthalmicFormulation.name;
      }

      return map;
    }).toList();

    final payloadMap = {
      'protocol': 'MEDIMIND_REGIMEN_V1',
      'patient': profile.name,
      'exportedAt': DateTime.now().toIso8601String(),
      'medCount': medList.length,
      'medications': medList,
    };

    if (_includeDoctorContacts) {
      payloadMap['doctor'] = profile.primaryDoctorName ?? '';
      payloadMap['doctorPhone'] = profile.primaryDoctorPhone ?? '';
    }

    return jsonEncode(payloadMap);
  }

  void _shareViaText(String payload) {
    SharePlus.instance.share(ShareParams(
      text: payload,
      subject: 'My MediMind Medication Regimen & Schedule',
    ));
  }

  void _parseImportData(String rawJson, MedicationRepository repo) {
    setState(() {
      _importError = null;
      _parsedImportMeds = null;
      _detectedImportInteractions = null;
    });

    if (rawJson.trim().isEmpty) {
      setState(() => _importError = 'Please paste a valid prescription QR code string or JSON.');
      return;
    }

    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final medJsonList = decoded['medications'] as List<dynamic>?;

      if (medJsonList == null || medJsonList.isEmpty) {
        setState(() => _importError = 'No medications found in this QR code.');
        return;
      }

      final parsed = <Medication>[];
      for (final item in medJsonList) {
        final m = item as Map<String, dynamic>;
        parsed.add(
          Medication(
            id: DateTime.now().millisecondsSinceEpoch.toString() +
                (parsed.length + 1).toString(),
            name: m['name']?.toString() ?? 'Unknown Medication',
            strength: m['strength']?.toString() ?? '',
            category: MedCategory.values.firstWhere(
              (c) => c.name == m['category'],
              orElse: () => MedCategory.oral,
            ),
            dosageUnit: DosageUnit.values.firstWhere(
              (d) => d.name == m['dosageUnit'],
              orElse: () => DosageUnit.tablets,
            ),
            dosageAmount: (m['dosageAmount'] as num?)?.toDouble() ?? 1.0,
            instruction: AdminInstruction.values.firstWhere(
              (i) => i.name == m['instruction'],
              orElse: () => AdminInstruction.withMeal,
            ),
            frequency: m['frequency']?.toString() ?? 'Once daily',
            scheduleTimes: (m['scheduleTimes'] as List<dynamic>?)
                    ?.map((t) => t.toString())
                    .toList() ??
                ['08:00'],
            totalInventoryCount: 30,
            refillThreshold: 5,
            colorHex: '#0284C7',
            iconName: 'pill',
            profileId: repo.activeProfileId,
            scheduledDaysOfWeek: (m['scheduledDaysOfWeek'] as List<dynamic>?)
                    ?.map((d) => (d as num).toInt())
                    .toList() ??
                [],
            cycleDaysOn: (m['cycleDaysOn'] as num?)?.toInt(),
            cycleDaysOff: (m['cycleDaysOff'] as num?)?.toInt(),
            requiresEyeDropProtocol: m['requiresEyeDropProtocol'] == true,
            eyeTarget: m['eyeTarget']?.toString(),
            eyeDropGapMinutes: (m['eyeDropGapMinutes'] as num?)?.toInt() ?? 5,
            ophthalmicFormulation: OphthalmicFormulation.values.firstWhere(
              (f) => f.name == m['ophthalmicFormulation'],
              orElse: () => OphthalmicFormulation.solution,
            ),
          ),
        );
      }

      // Check for Drug-Drug Interactions with existing active medications
      final interactionService = InteractionService();
      final allMedsCombined = [...repo.activeMedications, ...parsed];
      final interactions = interactionService.checkMedicationInteractions(allMedsCombined);

      setState(() {
        _parsedImportMeds = parsed;
        _detectedImportInteractions = interactions;
      });
    } catch (e) {
      setState(() => _importError = 'Malformed QR Code payload: ${e.toString()}');
    }
  }

  void _commitImport(MedicationRepository repo) {
    if (_parsedImportMeds == null || _parsedImportMeds!.isEmpty) return;

    for (final med in _parsedImportMeds!) {
      repo.addMedication(med);
    }

    final count = _parsedImportMeds!.length;
    setState(() {
      _parsedImportMeds = null;
      _detectedImportInteractions = null;
      _importTextCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Successfully imported $count medication(s) into your cabinet!'),
        backgroundColor: MediMindTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Response (QR) Hub'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2), text: 'Share Regimen'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Import Prescription'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShareTab(context, repo),
          _buildImportTab(context, repo),
        ],
      ),
    );
  }

  Widget _buildShareTab(BuildContext context, MedicationRepository repo) {
    final qrData = _generateQrPayload(repo);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // QR Code Card
        Center(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 240.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${repo.activeProfile.name} • ${repo.activeMedications.length} Medications',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scan with any MediMind app to import instantly',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Customization Options
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Include Dosage Details & Schedule', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Dose amount, instructions, times, and day cycles', style: TextStyle(fontSize: 11)),
                value: _includeDosageDetails,
                onChanged: (val) => setState(() => _includeDosageDetails = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Include Doctor Contact Details', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Prescribing physician and contact info', style: TextStyle(fontSize: 11)),
                value: _includeDoctorContacts,
                onChanged: (val) => setState(() => _includeDoctorContacts = val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Include Ophthalmic & Eye Protocols', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Formulation ladders and 5-min eye drop gap rules', style: TextStyle(fontSize: 11)),
                value: _includeOphthalmicSpecs,
                onChanged: (val) => setState(() => _includeOphthalmicSpecs = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrData));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Prescription QR payload copied!')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy JSON'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _shareViaText(qrData),
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share Code'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImportTab(BuildContext context, MedicationRepository repo) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: MediMindTheme.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      'Import Prescription Regimen',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paste raw QR payload data or scanned JSON text from another device or clinic.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _importTextCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Paste prescription QR JSON code here...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          _importTextCtrl.text = data!.text!;
                        }
                      },
                      icon: const Icon(Icons.paste, size: 16),
                      label: const Text('Paste from Clipboard'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => _parseImportData(_importTextCtrl.text, repo),
                      child: const Text('Verify & Parse'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_importError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MediMindTheme.alertRed.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MediMindTheme.alertRed),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: MediMindTheme.alertRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _importError!,
                    style: const TextStyle(color: MediMindTheme.alertRed, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Preview Parsed Medications & Safety Interaction Warnings
        if (_parsedImportMeds != null) ...[
          const SizedBox(height: 16),
          if (_detectedImportInteractions != null &&
              _detectedImportInteractions!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MediMindTheme.alertRed.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MediMindTheme.alertRed, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: MediMindTheme.alertRed),
                      SizedBox(width: 8),
                      Text(
                        'Drug-Drug Interaction Warning!',
                        style: TextStyle(
                          color: MediMindTheme.alertRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The incoming medications may interact with your existing cabinet. Review carefully before adding:',
                    style: TextStyle(fontSize: 12, color: MediMindTheme.alertRed),
                  ),
                  const SizedBox(height: 8),
                  ..._detectedImportInteractions!.map(
                    (i) => Text(
                      '• ${i.drugA} + ${i.drugB}: ${i.description}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Ready to Import (${_parsedImportMeds!.length} Medications)',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._parsedImportMeds!.map(
            (m) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.medication, color: MediMindTheme.primaryBlue),
                title: Text('${m.name} ${m.strength}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${m.frequency} • ${m.scheduleTimes.join(", ")}'),
                trailing: Text(
                  m.category == MedCategory.eyeDrop ? 'Eye Drop' : 'Oral',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _commitImport(repo),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: MediMindTheme.successGreen,
            ),
            icon: const Icon(Icons.done_all),
            label: Text('Confirm & Add ${_parsedImportMeds!.length} Meds to Cabinet'),
          ),
        ],
      ],
    );
  }
}
