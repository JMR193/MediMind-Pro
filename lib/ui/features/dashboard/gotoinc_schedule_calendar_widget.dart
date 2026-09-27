import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/medication_log.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';

class GotoincScheduleCalendarWidget extends StatefulWidget {
  const GotoincScheduleCalendarWidget({super.key});

  @override
  State<GotoincScheduleCalendarWidget> createState() => _GotoincScheduleCalendarWidgetState();
}

class _GotoincScheduleCalendarWidgetState extends State<GotoincScheduleCalendarWidget> {
  late DateTime _selectedDate;
  String _timeSlotFilter = 'All'; // 'All', 'Morning', 'Afternoon', 'Evening', 'Night'

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  List<DateTime> _getCurrentWeekDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Find Monday of the current week (weekday 1 = Mon ... 7 = Sun)
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  bool _isMedicationInTimeSlot(Medication med, String slot) {
    if (slot == 'All') return true;
    return med.scheduleTimes.any((t) {
      final hour = int.tryParse(t.split(':')[0]) ?? 8;
      switch (slot) {
        case 'Morning':
          return hour >= 5 && hour < 12;
        case 'Afternoon':
          return hour >= 12 && hour < 17;
        case 'Evening':
          return hour >= 17 && hour < 21;
        case 'Night':
          return hour >= 21 || hour < 5;
        default:
          return true;
      }
    });
  }

  void _showSnoozeDialog(BuildContext context, Medication med, MedicationRepository repo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Snooze Reminder — ${med.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Choose how long to pause before re-alerting:', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            ...[5, 10, 15, 30, 60].map((mins) => ListTile(
                  leading: const Icon(Icons.snooze, color: Color(0xFF0284C7)),
                  title: Text('$mins minutes'),
                  onTap: () {
                    repo.snoozeDose(med, mins);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('⏰ ${med.name} snoozed for $mins minutes.')),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showSkipDialog(BuildContext context, Medication med, MedicationRepository repo) {
    String reason = 'Side effects';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text('Skip ${med.name}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please record a reason for clinical tracking:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                items: ['Side effects', 'Nausea / Vomiting', 'Forgot at home', 'Doctor instructed to hold', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) { if (v != null) setDState(() => reason = v); },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: MediMindTheme.alertRed),
              onPressed: () {
                repo.logDose(
                  medication: med,
                  scheduledTime: med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : '08:00',
                  status: LogStatus.skipped,
                  skipReason: reason,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dose skipped: $reason'), backgroundColor: MediMindTheme.warningOrange),
                );
              },
              child: const Text('Skip Dose'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    final weekDays = _getCurrentWeekDays();
    final today = DateTime.now();

    // Filter meds for the selected date and slot
    final scheduledForDay = repo.activeMedications
        .where((m) => m.isScheduledForDay(_selectedDate))
        .where((m) => _isMedicationInTimeSlot(m, _timeSlotFilter))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Gotoinc-Inspired 7-Day Calendar Strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((date) {
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              // Check adherence dot for this day
              final dayLogs = repo.logs.where((l) =>
                  l.timestamp.year == date.year &&
                  l.timestamp.month == date.month &&
                  l.timestamp.day == date.day).toList();
              final allTaken = dayLogs.isNotEmpty && dayLogs.every((l) => l.status == LogStatus.taken);
              final hasMissed = dayLogs.any((l) => l.status == LogStatus.missed || l.status == LogStatus.skipped);

              Color dotColor = Colors.transparent;
              if (allTaken) {
                dotColor = MediMindTheme.successGreen;
              } else if (hasMissed) {
                dotColor = MediMindTheme.warningOrange;
              } else if (date.isBefore(DateTime(today.year, today.month, today.day))) {
                dotColor = Colors.grey.shade400;
              }

              return InkWell(
                onTap: () {
                  AppleGlassDecorations.lightHaptic();
                  setState(() => _selectedDate = date);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0284C7)
                        : isToday
                            ? const Color(0xFF0284C7).withAlpha(25)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? const Color(0xFF0284C7)
                                  : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? const Color(0xFF0284C7)
                                  : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Time Slot Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSlotChip('All', 'All Times'),
              _buildSlotChip('Morning', '☀️ Morning'),
              _buildSlotChip('Afternoon', '🌤️ Afternoon'),
              _buildSlotChip('Evening', '🌅 Evening'),
              _buildSlotChip('Night', '🌙 Night'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. Header showing count for selected day
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${DateFormat('EEEE, MMM d').format(_selectedDate)} (${scheduledForDay.length} Meds)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (scheduledForDay.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  AppleGlassDecorations.mediumHaptic();
                  for (final med in scheduledForDay) {
                    repo.logDose(
                      medication: med,
                      scheduledTime: med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : '08:00',
                      status: LogStatus.taken,
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ All doses for this time batch marked as taken!'),
                      backgroundColor: MediMindTheme.successGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('Take All Batch'),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // 4. Medication List Cards
        if (scheduledForDay.isEmpty)
          _buildEmptyDateState(context)
        else
          ...scheduledForDay.map((med) => _buildGotoincMedicationCard(context, med, repo)),
      ],
    );
  }

  Widget _buildSlotChip(String key, String label) {
    final isSel = _timeSlotFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSel,
        selectedColor: const Color(0xFF0284C7).withAlpha(35),
        onSelected: (val) {
          if (val) {
            AppleGlassDecorations.lightHaptic();
            setState(() => _timeSlotFilter = key);
          }
        },
      ),
    );
  }

  Widget _buildGotoincMedicationCard(BuildContext context, Medication med, MedicationRepository repo) {
    final color = hexToColor(med.colorHex);
    final isEyeMed = med.category == MedCategory.eyeDrop || med.category == MedCategory.eyeOintment;

    // Check if taken today
    final isTakenToday = repo.logs.any((l) =>
        l.medicationId == med.id &&
        l.status == LogStatus.taken &&
        l.timestamp.year == _selectedDate.year &&
        l.timestamp.month == _selectedDate.month &&
        l.timestamp.day == _selectedDate.day);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTakenToday ? 0.5 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isTakenToday
              ? MediMindTheme.successGreen.withAlpha(80)
              : Colors.grey.withAlpha(30),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3D Simulated Pill Icon
                _buildPillAvatar(med, color),
                const SizedBox(width: 14),
                // Medication Name & Strength & Instructions
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              med.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                decoration: isTakenToday ? TextDecoration.lineThrough : null,
                                color: isTakenToday ? Colors.grey : null,
                              ),
                            ),
                          ),
                          if (med.isHighPriorityAlarm)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: MediMindTheme.alertRed.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('CRITICAL', style: TextStyle(color: MediMindTheme.alertRed, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${med.strength} • ${med.frequency}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      // Instruction & Timing Tags
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildMiniBadge(
                            adminInstructionLabel(med.instruction),
                            Icons.restaurant_outlined,
                            const Color(0xFF0D9488),
                          ),
                          if (isEyeMed && med.eyeTarget != null)
                            _buildMiniBadge(
                              med.eyeTarget!,
                              Icons.remove_red_eye_outlined,
                              const Color(0xFF7C3AED),
                            ),
                          if (med.pillImprint != null && med.pillImprint!.isNotEmpty)
                            _buildMiniBadge(
                              'Marking: ${med.pillImprint!}',
                              Icons.text_fields,
                              Colors.blueGrey,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Schedule Times & Stock Battery Indicator
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  med.scheduleTimes.join(', '),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Spacer(),
                Icon(
                  med.totalInventoryCount <= med.refillThreshold
                      ? Icons.battery_alert_rounded
                      : Icons.battery_charging_full_rounded,
                  size: 14,
                  color: med.totalInventoryCount <= med.refillThreshold
                      ? MediMindTheme.alertRed
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${med.totalInventoryCount} left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: med.totalInventoryCount <= med.refillThreshold
                        ? MediMindTheme.alertRed
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // Action Buttons
            if (isTakenToday)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: MediMindTheme.successGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: MediMindTheme.successGreen, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Completed for Selected Day',
                      style: TextStyle(
                        color: MediMindTheme.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: () {
                        AppleGlassDecorations.mediumHaptic();
                        repo.logDose(
                          medication: med,
                          scheduledTime: med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : '08:00',
                          status: LogStatus.taken,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ ${med.name} logged as taken!'),
                            backgroundColor: MediMindTheme.successGreen,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: MediMindTheme.successGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Take Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => _showSnoozeDialog(context, med, repo),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Snooze'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'Skip Dose',
                    onPressed: () => _showSkipDialog(context, med, repo),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillAvatar(Medication med, Color color) {
    BorderRadius radius = BorderRadius.circular(16);
    if (med.pillShape == PillShape.round) radius = BorderRadius.circular(26);
    if (med.pillShape == PillShape.capsule) radius = BorderRadius.circular(14);
    if (med.pillShape == PillShape.diamond) radius = BorderRadius.circular(6);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: radius,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(40),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          getMedicationIcon(med.iconName),
          color: color,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDateState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'No Medications Scheduled',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'No medications planned for ${DateFormat('EEE, MMM d').format(_selectedDate)} in the "$_timeSlotFilter" window.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
