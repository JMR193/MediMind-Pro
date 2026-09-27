import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication_log.dart';
import '../../../domain/models/symptom_log.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/theme.dart';
import '../symptom_diary/symptom_diary_screen.dart';

class CareLinkElderlyCareWidget extends StatefulWidget {
  const CareLinkElderlyCareWidget({super.key});

  @override
  State<CareLinkElderlyCareWidget> createState() => _CareLinkElderlyCareWidgetState();
}

class _CareLinkElderlyCareWidgetState extends State<CareLinkElderlyCareWidget> {
  String? _selectedMood;
  DateTime? _lastMoodLoggedTime;

  static const List<Map<String, dynamic>> _moodOptions = [
    {
      'label': 'Great',
      'emoji': '😄',
      'color': Color(0xFF10B981),
      'isUrgent': false,
    },
    {
      'label': 'Good',
      'emoji': '🙂',
      'color': Color(0xFF0284C7),
      'isUrgent': false,
    },
    {
      'label': 'Fair',
      'emoji': '😐',
      'color': Color(0xFFF59E0B),
      'isUrgent': false,
    },
    {
      'label': 'In Pain',
      'emoji': '🤕',
      'color': Color(0xFFEA580C),
      'isUrgent': true,
    },
    {
      'label': 'Dizzy',
      'emoji': '😵',
      'color': Color(0xFFDC2626),
      'isUrgent': true,
    },
  ];

  void _onMoodSelected(BuildContext context, Map<String, dynamic> option, MedicationRepository repo) {
    AppleGlassDecorations.mediumHaptic();
    final label = option['label'] as String;
    final isUrgent = option['isUrgent'] as bool;

    setState(() {
      _selectedMood = label;
      _lastMoodLoggedTime = DateTime.now();
    });

    if (isUrgent) {
      // Automatically log to Symptom Diary
      final symptomType = label == 'In Pain' ? SymptomType.pain : SymptomType.other;
      repo.addSymptomLog(
        SymptomLog(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          symptomType: symptomType,
          severity: label == 'In Pain' ? 7 : 8,
          notes: 'Well-being check-in: Patient reported feeling "$label".',
          escalationTriggered: true,
        ),
      );

      _showCaregiverAlertPrompt(context, label, repo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Well-being recorded: Feeling $label ${_moodOptions.firstWhere((m) => m['label'] == label)['emoji']}'),
          backgroundColor: option['color'] as Color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCaregiverAlertPrompt(BuildContext context, String mood, MedicationRepository repo) {
    final caregiver = repo.caregivers.isNotEmpty ? repo.caregivers.first : null;
    final caregiverName = caregiver?.name ?? repo.activeProfile.emergencyContactName ?? 'Caregiver';
    final caregiverPhone = caregiver?.phone ?? repo.activeProfile.emergencyContactPhone;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MediMindTheme.alertRed.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: MediMindTheme.alertRed, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attention: Feeling $mood',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text(
                        'Would you like to alert your caregiver or log detailed symptoms?',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (caregiverPhone != null && caregiverPhone.isNotEmpty) ...[
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse('tel:$caregiverPhone');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: MediMindTheme.alertRed,
                ),
                icon: const Icon(Icons.call),
                label: Text('Call $caregiverName ($caregiverPhone)'),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomDiaryScreen()));
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.medical_information_outlined),
              label: const Text('Open Symptom Diary & Log Details'),
            ),
          ],
        ),
      ),
    );
  }

  void _callEmergencyNumber(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.emergency_outlined, color: MediMindTheme.alertRed, size: 48),
        title: const Text('Emergency Assistance (SOS)'),
        content: const Text(
          'Do you need immediate medical help? This will dial your regional emergency services (911 / 112).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MediMindTheme.alertRed),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse('tel:911');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            child: const Text('Call 911 / 112 Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    final activeProfile = repo.activeProfile;
    final todayLogs = repo.logs.where((l) {
      final now = DateTime.now();
      return l.timestamp.year == now.year &&
          l.timestamp.month == now.month &&
          l.timestamp.day == now.day;
    }).toList();

    final takenCount = todayLogs.where((l) => l.status == LogStatus.taken).length;
    final totalScheduledCount = repo.activeMedications.fold<int>(
      0,
      (sum, m) => sum + (m.scheduleTimes.isNotEmpty ? m.scheduleTimes.length : 1),
    );
    final completionRatio = totalScheduledCount > 0
        ? (takenCount / totalScheduledCount).clamp(0.0, 1.0)
        : 1.0;

    final caregiver = repo.caregivers.isNotEmpty ? repo.caregivers.first : null;
    final caregiverName = caregiver?.name ?? activeProfile.emergencyContactName ?? 'Family Caregiver';
    final caregiverPhone = caregiver?.phone ?? activeProfile.emergencyContactPhone;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF0284C7).withAlpha(40),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: CareLink Badge & Caregiver Quick-Dial
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CareLink • Elderly Care',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'Caring for ${activeProfile.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Emergency SOS Chip
              InkWell(
                onTap: () => _callEmergencyNumber(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MediMindTheme.alertRed.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: MediMindTheme.alertRed.withAlpha(80)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emergency, color: MediMindTheme.alertRed, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: MediMindTheme.alertRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Care Activity Summary Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Circular Ring
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: completionRatio,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.withAlpha(40),
                        color: completionRatio >= 1.0
                            ? MediMindTheme.successGreen
                            : const Color(0xFF0284C7),
                      ),
                      Center(
                        child: Text(
                          '${(completionRatio * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completionRatio >= 1.0
                            ? 'All Daily Meds Completed! 🎉'
                            : '$takenCount of $totalScheduledCount doses completed',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        caregiverPhone != null
                            ? 'Caregiver: $caregiverName'
                            : 'No caregiver assigned yet',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (caregiverPhone != null && caregiverPhone.isNotEmpty)
                  IconButton.filledTonal(
                    icon: const Icon(Icons.phone, size: 18),
                    tooltip: 'Call $caregiverName',
                    onPressed: () async {
                      final uri = Uri.parse('tel:$caregiverPhone');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Daily Well-Being / Mood Check-In (CareLink Signature Feature)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'How are you feeling right now?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (_lastMoodLoggedTime != null)
                Text(
                  'Checked at ${TimeOfDay.fromDateTime(_lastMoodLoggedTime!).format(context)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _moodOptions.map((opt) {
              final label = opt['label'] as String;
              final emoji = opt['emoji'] as String;
              final color = opt['color'] as Color;
              final isSelected = _selectedMood == label;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => _onMoodSelected(context, opt, repo),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withAlpha(40)
                            : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withAlpha(50),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? color : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
