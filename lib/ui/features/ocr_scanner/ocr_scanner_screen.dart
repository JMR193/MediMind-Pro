import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../data/services/prescription_parser_service.dart';
import '../../../data/services/interaction_service.dart';
import '../../../data/services/tts_service.dart';
import '../../../domain/models/medication.dart';
import '../../core/theme.dart';
import '../medication_wizard/add_medication_screen.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  File? _imageFile;
  bool _isScanning = false;
  String _rawExtractedText = '';
  List<ParsedMedicationDraft> _parsedDrafts = [];
  bool _isSpeaking = false;
  final _picker = ImagePicker();
  TextRecognitionScript _selectedScript = TextRecognitionScript.latin;
  late TextRecognizer _textRecognizer;
  final _parserService = PrescriptionParserService();
  final _interactionService = InteractionService();
  final _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: _selectedScript);
  }

  void _switchScript(TextRecognitionScript script) {
    if (_selectedScript == script) return;
    _textRecognizer.close();
    setState(() {
      _selectedScript = script;
      _textRecognizer = TextRecognizer(script: script);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          'OCR Script: ${script == TextRecognitionScript.latin ? "English / Latin" : "Devanagari (Hindi/Marathi)"}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );
      if (picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
        _isScanning = true;
        _rawExtractedText = '';
        _parsedDrafts = [];
      });

      final inputImage = InputImage.fromFilePath(picked.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      _processExtractedText(recognizedText.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanner error: $e')),
      );
    }
  }

  void _loadSamplePrescription(({String title, String subtitle, String text}) sample) {
    setState(() {
      _imageFile = null;
      _isScanning = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _processExtractedText(sample.text);
    });
  }

  void _processExtractedText(String text) {
    if (!mounted) return;
    final drafts = _parserService.parsePrescription(text);

    setState(() {
      _isScanning = false;
      _rawExtractedText = text;
      _parsedDrafts = drafts;
    });

    if (drafts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No medications automatically detected. You can add one manually using + below.')),
        );
      }
    }
  }

  Future<void> _toggleTtsSummary(List<ParsedMedicationDraft> drafts) async {
    if (_isSpeaking) {
      await _ttsService.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }

    if (drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medications selected to read aloud.')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.write('Prescription summary. Detected ${drafts.length} medication${drafts.length > 1 ? "s" : ""}. ');
    for (int i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      final timing = d.instruction == AdminInstruction.beforeMeal
          ? 'before food'
          : d.instruction == AdminInstruction.atBedtime
              ? 'at bedtime'
              : 'after food';
      final duration = d.durationDays != null ? 'for ${d.durationDays} days' : '';
      buffer.write('Medication ${i + 1}: ${d.name} ${d.strength}, take ${d.frequencyLabel}, $timing $duration. ');
      if (d.isEyeMedication) {
        buffer.write('Eye drops require a 5 to 10 minute gap between drops. ');
      }
    }

    setState(() => _isSpeaking = true);
    await _ttsService.speak(buffer.toString());
    if (mounted) setState(() => _isSpeaking = false);
  }

  void _addManualMedicine() {
    final draft = ParsedMedicationDraft(
      rawLine: 'Manual Entry',
      name: 'New Medication',
      strength: '500 mg',
      category: MedCategory.oral,
      dosageUnit: DosageUnit.tablets,
      frequencyPattern: '1-0-1',
      frequencyLabel: 'Twice daily',
      scheduleTimes: ['08:00', '20:00'],
      durationDays: 7,
      instruction: AdminInstruction.afterMeal,
      confidence: 1.0,
      isSelected: true,
    );

    setState(() {
      _parsedDrafts.add(draft);
    });

    _showEditDraftSheet(draft, _parsedDrafts.length - 1);
  }

  void _showEditDraftSheet(ParsedMedicationDraft draft, int index) {
    final nameCtrl = TextEditingController(text: draft.name);
    final strengthCtrl = TextEditingController(text: draft.strength);
    final notesCtrl = TextEditingController(text: draft.clinicalNotes ?? '');
    int days = draft.durationDays ?? 7;
    String frequencyLabel = draft.frequencyLabel;
    List<String> times = List.from(draft.scheduleTimes);
    bool isEye = draft.isEyeMedication;
    bool isOint = draft.isOintment;
    String eyeTarget = draft.eyeTarget ?? 'Both Eyes (OU)';
    AdminInstruction instruction = draft.instruction;
    MedCategory category = draft.category;
    DosageUnit unit = draft.dosageUnit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Extracted Medicine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Verify or adjust detected prescription details', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Medication Name *', prefixIcon: Icon(Icons.medication_outlined)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: strengthCtrl,
                        decoration: const InputDecoration(labelText: 'Strength (e.g. 500mg, 0.5%)', prefixIcon: Icon(Icons.fitness_center_outlined)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<DosageUnit>(
                        initialValue: unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: DosageUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.name))).toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => unit = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: frequencyLabel,
                  decoration: const InputDecoration(labelText: 'Frequency', prefixIcon: Icon(Icons.repeat_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'Once daily (Morning)', child: Text('1-0-0 • Once daily (Morning)')),
                    DropdownMenuItem(value: 'Once daily (Night)', child: Text('0-0-1 • Once daily (Bedtime)')),
                    DropdownMenuItem(value: 'Twice daily', child: Text('1-0-1 • Twice daily')),
                    DropdownMenuItem(value: 'Three times daily', child: Text('1-1-1 • Three times daily')),
                    DropdownMenuItem(value: 'Four times daily', child: Text('1-1-1-1 • Four times daily')),
                    DropdownMenuItem(value: 'At bedtime', child: Text('HS • At bedtime')),
                    DropdownMenuItem(value: 'As needed', child: Text('SOS / PRN • As needed')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setSheetState(() {
                        frequencyLabel = v;
                        if (v.contains('Twice')) {
                          times = ['08:00', '20:00'];
                        } else if (v.contains('Three')) {
                          times = ['08:00', '14:00', '20:00'];
                        } else if (v.contains('Four')) {
                          times = ['08:00', '12:00', '16:00', '20:00'];
                        } else if (v.contains('Night') || v.contains('bedtime')) {
                          times = ['21:30'];
                        } else {
                          times = ['08:00'];
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: days,
                        decoration: const InputDecoration(labelText: 'Duration (Days)', prefixIcon: Icon(Icons.calendar_month_outlined)),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3 Days')),
                          DropdownMenuItem(value: 5, child: Text('5 Days')),
                          DropdownMenuItem(value: 7, child: Text('7 Days (1 week)')),
                          DropdownMenuItem(value: 10, child: Text('10 Days')),
                          DropdownMenuItem(value: 14, child: Text('14 Days (2 weeks)')),
                          DropdownMenuItem(value: 21, child: Text('21 Days')),
                          DropdownMenuItem(value: 30, child: Text('30 Days (1 month)')),
                          DropdownMenuItem(value: 60, child: Text('60 Days (2 months)')),
                          DropdownMenuItem(value: 90, child: Text('90 Days (3 months)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setSheetState(() => days = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<AdminInstruction>(
                        initialValue: instruction,
                        decoration: const InputDecoration(labelText: 'Food Timing', prefixIcon: Icon(Icons.restaurant_outlined)),
                        items: const [
                          DropdownMenuItem(value: AdminInstruction.afterMeal, child: Text('After Food (PC)')),
                          DropdownMenuItem(value: AdminInstruction.beforeMeal, child: Text('Before Food (AC)')),
                          DropdownMenuItem(value: AdminInstruction.withMeal, child: Text('With Meals')),
                          DropdownMenuItem(value: AdminInstruction.atBedtime, child: Text('At Bedtime (HS)')),
                          DropdownMenuItem(value: AdminInstruction.asNeeded, child: Text('As Needed (PRN)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setSheetState(() => instruction = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Is this an Eye Medication?', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Enables 5-min wash-out timer & 28-day bottle window', style: TextStyle(fontSize: 11)),
                  secondary: const Icon(Icons.remove_red_eye_outlined),
                  value: isEye,
                  onChanged: (v) {
                    setSheetState(() {
                      isEye = v;
                      if (v) {
                        category = isOint ? MedCategory.eyeOintment : MedCategory.eyeDrop;
                        unit = isOint ? DosageUnit.applyTopical : DosageUnit.drops;
                      } else {
                        category = MedCategory.oral;
                        unit = DosageUnit.tablets;
                      }
                    });
                  },
                ),
                if (isEye) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Is this an Eye Ointment?', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Sequencing rule: apply 10 min AFTER liquid eye drops', style: TextStyle(fontSize: 11)),
                    value: isOint,
                    onChanged: (v) {
                      setSheetState(() {
                        isOint = v;
                        category = v ? MedCategory.eyeOintment : MedCategory.eyeDrop;
                        unit = v ? DosageUnit.applyTopical : DosageUnit.drops;
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: eyeTarget,
                    decoration: const InputDecoration(labelText: 'Target Eye', prefixIcon: Icon(Icons.visibility_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'Both Eyes (OU)', child: Text('Both Eyes (OU)')),
                      DropdownMenuItem(value: 'Left Eye (OS)', child: Text('Left Eye (OS)')),
                      DropdownMenuItem(value: 'Right Eye (OD)', child: Text('Right Eye (OD)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setSheetState(() => eyeTarget = v);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Doctor Instructions / Notes', prefixIcon: Icon(Icons.notes_outlined)),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    final updated = draft.copyWith(
                      name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : draft.name,
                      strength: strengthCtrl.text.trim(),
                      category: category,
                      dosageUnit: unit,
                      frequencyLabel: frequencyLabel,
                      scheduleTimes: times,
                      durationDays: days,
                      instruction: instruction,
                      isEyeMedication: isEye,
                      isOintment: isOint,
                      eyeTarget: eyeTarget,
                      clinicalNotes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                      totalQuantity: (times.length * days).clamp(1, 500),
                    );

                    setState(() {
                      _parsedDrafts[index] = updated;
                    });
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Save Changes'),
                  style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmAndBatchSchedule() {
    final selectedDrafts = _parsedDrafts.where((d) => d.isSelected).toList();
    if (selectedDrafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one medication to schedule.')),
      );
      return;
    }

    final repo = context.read<MedicationRepository>();
    final medsToAdd = selectedDrafts.map((d) => d.toMedication(doctorName: 'Scanned Prescription')).toList();

    repo.addMultipleMedications(medsToAdd);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.withAlpha(30), shape: BoxShape.circle),
              child: const Icon(Icons.verified_outlined, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text('✅ ${medsToAdd.length} Medications Scheduled!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'All medication reminders, daily routines, and eye timing protocols have been activated.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.withAlpha(200)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Return to Dashboard
              },
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('View Today\'s Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    final selectedDrafts = _parsedDrafts.where((d) => d.isSelected).toList();
    final selectedCount = selectedDrafts.length;
    final eyeDropCount = selectedDrafts.where((d) => d.isEyeMedication).length;
    final activeWarnings = _parsedDrafts.isNotEmpty
        ? _interactionService.checkInteractions(
            existingMedications: repo.medications,
            newDrafts: selectedDrafts,
          )
        : <DrugInteractionWarning>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Prescription Scanner'),
        actions: [
          if (_parsedDrafts.isNotEmpty)
            IconButton(
              icon: Icon(_isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
              tooltip: _isSpeaking ? 'Stop read-out' : 'Read prescription summary',
              color: _isSpeaking ? MediMindTheme.alertRed : null,
              onPressed: () => _toggleTtsSummary(selectedDrafts),
            ),
          PopupMenuButton<TextRecognitionScript>(
            icon: const Icon(Icons.translate_outlined),
            tooltip: 'OCR Language Script',
            initialValue: _selectedScript,
            onSelected: _switchScript,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: TextRecognitionScript.latin,
                child: Text('Latin / English (Default)'),
              ),
              PopupMenuItem(
                value: TextRecognitionScript.devanagari,
                child: Text('Devanagari (Hindi / Marathi)'),
              ),
            ],
          ),
          PopupMenuButton<({String title, String subtitle, String text})>(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Try Sample Prescriptions',
            onSelected: _loadSamplePrescription,
            itemBuilder: (_) => PrescriptionParserService.samplePrescriptions
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(s.subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      bottomNavigationBar: _parsedDrafts.isNotEmpty
          ? Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addManualMedicine,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Missing'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: selectedCount > 0 ? _confirmAndBatchSchedule : null,
                      icon: const Icon(Icons.alarm_add_outlined),
                      label: Text('Schedule ($selectedCount)'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Capture / Upload Card
            Container(
              width: double.infinity,
              height: _parsedDrafts.isNotEmpty ? 160 : 260,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor, width: 2),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.document_scanner_outlined, size: 54, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 10),
                        const Text('Scan Medical Prescription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        const Text('AI detects medicines, timing, matrix (1-0-1) & days', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Scan Action Buttons
            if (_isScanning)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('On-device AI analyzing prescription & medications...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _loadSamplePrescription(PrescriptionParserService.samplePrescriptions.first),
                    icon: const Icon(Icons.flash_on_outlined, color: Colors.amber, size: 18),
                    label: const Text('Sample'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ],
              ),

            if (_parsedDrafts.isNotEmpty) ...[
              const SizedBox(height: 20),

              // Drug Interaction Safety Alerts
              if (activeWarnings.isNotEmpty) ...[
                ...activeWarnings.map((warning) => _buildInteractionAlertCard(warning)),
                const SizedBox(height: 8),
              ] else if (eyeDropCount >= 2) ...[
                // Ophthalmic Wash-Out Spacing Advisory Banner
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withAlpha(26),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0284C7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFF0284C7), size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Multiple Eye Medications Detected', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 13)),
                            SizedBox(height: 4),
                            Text(
                              'MediMind will automatically enforce a 5 to 10-minute interval timer between drops to prevent corneal wash-out.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Header Bar with Selection Counter and TTS Read-Aloud
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Extracted Medications (${_parsedDrafts.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _toggleTtsSummary(selectedDrafts),
                        icon: Icon(_isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined, size: 14),
                        label: Text(_isSpeaking ? 'Stop' : 'Read Aloud', style: const TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _isSpeaking ? MediMindTheme.alertRed : Theme.of(context).colorScheme.primary,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () {
                          final allSelected = _parsedDrafts.every((d) => d.isSelected);
                          setState(() {
                            for (var d in _parsedDrafts) {
                              d.isSelected = !allSelected;
                            }
                          });
                        },
                        child: Text(
                          _parsedDrafts.every((d) => d.isSelected) ? 'Deselect All' : 'Select All',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // List of Parsed Medication Cards
              ..._parsedDrafts.asMap().entries.map((entry) {
                final idx = entry.key;
                final draft = entry.value;
                return _buildMedicationDraftCard(draft, idx);
              }),

              const SizedBox(height: 12),

              // Collapsible Raw OCR Text
              Card(
                child: ExpansionTile(
                  title: const Text('View Raw OCR Text', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Cross-verify text recognized by camera', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  leading: const Icon(Icons.notes_outlined, size: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _rawExtractedText,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.green.withAlpha(20), borderRadius: BorderRadius.circular(14)),
              child: const Row(
                children: [
                  Icon(Icons.lock_outlined, color: Colors.green, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '🔒 100% On-Device AI: Prescriptions are parsed locally on your phone. No images or private medical data leave your device.',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationDraftCard(ParsedMedicationDraft draft, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: draft.isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: draft.isSelected,
                  onChanged: (v) {
                    setState(() => draft.isSelected = v ?? false);
                  },
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: draft.isEyeMedication ? const Color(0xFF0284C7).withAlpha(26) : Colors.green.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    draft.isEyeMedication ? Icons.remove_red_eye_outlined : Icons.medication_outlined,
                    color: draft.isEyeMedication ? const Color(0xFF0284C7) : Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Row(
                        children: [
                          if (draft.strength.isNotEmpty)
                            Text(
                              draft.strength,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: draft.confidence >= 0.8 ? const Color(0xFFD8F3DC) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(draft.confidence * 100).toInt()}% match',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: draft.confidence >= 0.8 ? const Color(0xFF2D6A4F) : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (draft.correctedFrom != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4, bottom: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF7C3AED).withAlpha(70)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 11, color: Color(0xFF7C3AED)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '✨ AI corrected typo from "${draft.correctedFrom}"',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit medication details',
                  onPressed: () => _showEditDraftSheet(draft, index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: 'Remove',
                  onPressed: () {
                    setState(() => _parsedDrafts.removeAt(index));
                  },
                ),
              ],
            ),
            const Divider(height: 16),
            // Chips row: Frequency, Times, Days, Instruction
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  avatar: const Icon(Icons.repeat, size: 14),
                  label: Text(draft.frequencyLabel, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                Chip(
                  avatar: const Icon(Icons.access_time, size: 14),
                  label: Text(draft.scheduleTimes.join(', '), style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                if (draft.durationDays != null)
                  Chip(
                    avatar: const Icon(Icons.calendar_today, size: 14),
                    label: Text('${draft.durationDays} Days', style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                Chip(
                  avatar: const Icon(Icons.restaurant, size: 14),
                  label: Text(
                    draft.instruction == AdminInstruction.beforeMeal
                        ? 'Before Food'
                        : draft.instruction == AdminInstruction.atBedtime
                            ? 'At Bedtime'
                            : 'After Food',
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                if (draft.route != null)
                  Chip(
                    avatar: const Icon(Icons.alt_route_rounded, size: 14, color: Color(0xFF2D6A4F)),
                    label: Text(draft.route!, style: const TextStyle(fontSize: 11, color: Color(0xFF2D6A4F), fontWeight: FontWeight.w600)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                if (draft.isEyeMedication && draft.eyeTarget != null)
                  Chip(
                    avatar: const Icon(Icons.visibility, size: 14, color: Color(0xFF0284C7)),
                    label: Text(draft.eyeTarget!, style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                if (draft.isOintment)
                  const Chip(
                    avatar: Icon(Icons.medical_services_outlined, size: 14, color: Colors.teal),
                    label: Text('Ointment (After Drops)', style: TextStyle(fontSize: 11, color: Colors.teal)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            if (draft.chronotherapyAdvice != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF52B788).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF52B788).withAlpha(77)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF2D6A4F)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Circadian: ${draft.chronotherapyAdvice}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF1B4332), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (draft.safetyWarning != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 15, color: Colors.amber.shade900),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        draft.safetyWarning!,
                        style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (draft.clinicalNotes != null) ...[
              const SizedBox(height: 6),
              Text(
                '💡 ${draft.clinicalNotes}',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final med = draft.toMedication();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddMedicationScreen(editMedication: med)),
                    );
                  },
                  icon: const Icon(Icons.tune, size: 14),
                  label: const Text('Fine-tune in Wizard', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionAlertCard(DrugInteractionWarning warning) {
    Color cardColor;
    Color borderColor;
    IconData icon;
    String badgeLabel;

    switch (warning.severity) {
      case InteractionSeverity.critical:
        cardColor = MediMindTheme.alertRed.withAlpha(20);
        borderColor = MediMindTheme.alertRed;
        icon = Icons.dangerous_outlined;
        badgeLabel = 'CRITICAL DRUG INTERACTION';
        break;
      case InteractionSeverity.moderate:
        cardColor = MediMindTheme.warningOrange.withAlpha(20);
        borderColor = MediMindTheme.warningOrange;
        icon = Icons.warning_amber_rounded;
        badgeLabel = 'MODERATE INTERACTION RISK';
        break;
      case InteractionSeverity.advisory:
        cardColor = const Color(0xFF0284C7).withAlpha(20);
        borderColor = const Color(0xFF0284C7);
        icon = Icons.info_outline;
        badgeLabel = 'CLINICAL ADVISORY PROTOCOL';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor, size: 20),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: borderColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: borderColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${warning.drugA.toUpperCase()} + ${warning.drugB.toUpperCase()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            warning.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: borderColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            warning.description,
            style: const TextStyle(fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor.withAlpha(40)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.medical_information_outlined, size: 16, color: borderColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Clinical Advice: ${warning.clinicalRecommendation}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
