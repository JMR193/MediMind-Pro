import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../domain/models/medication.dart';
import '../../core/theme.dart';
import '../medication_wizard/add_medication_screen.dart';

class VoiceAssistantModal extends StatefulWidget {
  const VoiceAssistantModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceAssistantModal(),
    );
  }

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _wordsSpoken = '';
  Map<String, dynamic>? _parsedIntent;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _initSpeech();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
      if (_speechAvailable) {
        _startListening();
      }
    } catch (_) {
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  void _startListening() async {
    if (!_speechAvailable || !mounted) return;
    setState(() {
      _isListening = true;
      _wordsSpoken = '';
      _parsedIntent = null;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _wordsSpoken = result.recognizedWords;
          if (result.finalResult || _wordsSpoken.length > 5) {
            _parsedIntent = _parseVoiceCommand(_wordsSpoken);
          }
        });
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  void _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
    if (_wordsSpoken.isNotEmpty) {
      setState(() {
        _parsedIntent = _parseVoiceCommand(_wordsSpoken);
      });
    }
  }

  /// Voice command parser: extracts medication name, dosage times, and categories
  Map<String, dynamic> _parseVoiceCommand(String speech) {
    final lower = speech.toLowerCase();
    String medName = 'Eye Drops';
    bool isEyeDrop = lower.contains('eye') || lower.contains('drop') || lower.contains('ointment');
    List<String> times = [];

    // Check specific known names
    final knownMeds = ['latanoprost', 'timolol', 'atorvastatin', 'salbutamol', 'insulin', 'prednisolone', 'erythromycin', 'metformin'];
    for (final m in knownMeds) {
      if (lower.contains(m)) {
        medName = m[0].toUpperCase() + m.substring(1);
        if (m == 'latanoprost' || m == 'timolol' || m == 'prednisolone' || m == 'erythromycin') {
          isEyeDrop = true;
        }
        break;
      }
    }

    // Extract hours from words like "at 8 am and 8 pm", "at 9:00", etc.
    final timePattern = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', caseSensitive: false);
    final matches = timePattern.allMatches(lower);
    for (final m in matches) {
      final hourStr = m.group(1);
      final minStr = m.group(2) ?? '00';
      final amPm = m.group(3)?.toLowerCase();

      if (hourStr != null) {
        int hour = int.tryParse(hourStr) ?? 8;
        if (amPm == 'pm' && hour < 12) hour += 12;
        if (amPm == 'am' && hour == 12) hour = 0;
        final formatted = '${hour.toString().padLeft(2, '0')}:${minStr.padLeft(2, '0')}';
        if (!times.contains(formatted)) times.add(formatted);
      }
    }

    if (times.isEmpty) {
      if (lower.contains('morning')) times.add('08:00');
      if (lower.contains('evening') || lower.contains('night')) times.add('20:00');
      if (lower.contains('bedtime')) times.add('21:30');
    }

    if (times.isEmpty) times = ['08:00', '20:00'];

    return {
      'name': medName,
      'isEyeDrop': isEyeDrop,
      'times': times,
      'frequency': times.length == 1 ? 'Once daily' : times.length == 2 ? 'Twice daily' : 'Multiple times',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(77), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Voice Medication Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            _isListening ? 'Listening... Speak your reminder' : 'Tap microphone to speak',
            style: TextStyle(fontSize: 12, color: Colors.grey.withAlpha(204)),
          ),
          const SizedBox(height: 24),
          // Pulsing Mic Icon
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, child) {
                final scale = _isListening ? 1.0 + (_animCtrl.value * 0.15) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [MediMindTheme.alertRed, const Color(0xFFE11D48)]
                            : [Theme.of(context).colorScheme.primary, const Color(0xFF0284C7)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? MediMindTheme.alertRed : Theme.of(context).colorScheme.primary).withAlpha(102),
                          blurRadius: 16,
                          spreadRadius: _isListening ? 4 : 0,
                        ),
                      ],
                    ),
                    child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 36),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Transcript or example
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _wordsSpoken.isNotEmpty
                  ? '“$_wordsSpoken”'
                  : 'Example: "Remind me to use my eye drops at 8 AM and 8 PM"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontStyle: _wordsSpoken.isEmpty ? FontStyle.italic : FontStyle.normal,
                color: _wordsSpoken.isEmpty ? Colors.grey : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (_parsedIntent != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.primary)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Text('Draft Schedule Created', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('• Medication: ${_parsedIntent!['name']}', style: const TextStyle(fontSize: 13)),
                    Text('• Frequency: ${_parsedIntent!['frequency']}', style: const TextStyle(fontSize: 13)),
                    Text('• Scheduled Times: ${(_parsedIntent!['times'] as List).join(', ')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    if (_parsedIntent!['isEyeDrop'])
                      const Text('• Eye Drop Protocol: Enabled (5-min safety interval)', style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final draft = Medication(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: _parsedIntent!['name'],
                          strength: 'Prescribed dose',
                          category: _parsedIntent!['isEyeDrop'] ? MedCategory.eyeDrop : MedCategory.oral,
                          dosageUnit: _parsedIntent!['isEyeDrop'] ? DosageUnit.drops : DosageUnit.tablets,
                          dosageAmount: 1,
                          instruction: AdminInstruction.afterMeal,
                          frequency: _parsedIntent!['frequency'],
                          scheduleTimes: List<String>.from(_parsedIntent!['times']),
                          totalInventoryCount: 30,
                          refillThreshold: 5,
                          colorHex: '#0284C7',
                          iconName: _parsedIntent!['isEyeDrop'] ? 'eye_drop' : 'pill',
                          requiresEyeDropProtocol: _parsedIntent!['isEyeDrop'],
                          eyeTarget: 'Both Eyes (OU)',
                          eyeDropGapMinutes: 5,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddMedicationScreen(editMedication: draft)),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Review & Save Schedule'),
                      style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
