import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/medication_log.dart';
import '../alarm/medicine_alarm_dialog.dart';

class IntakeHistoryScreen extends StatefulWidget {
  const IntakeHistoryScreen({super.key});

  @override
  State<IntakeHistoryScreen> createState() => _IntakeHistoryScreenState();
}

class _IntakeHistoryScreenState extends State<IntakeHistoryScreen> {
  late DateTime _selectedDate;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    // Align to Monday of current week
    _weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    final medications = repo.medications;
    final logs = repo.logs;

    final weekEnd = _weekStart.add(const Duration(days: 6));
    final dateRangeStr =
        '${DateFormat('d').format(_weekStart)} - ${DateFormat('d MMMM').format(weekEnd)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Intake History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
            ),
            Text(
              dateRangeStr,
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF2D6A4F)),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = DateTime(picked.year, picked.month, picked.day);
                  _weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
                });
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 7-Day Horizontal Calendar Strip (Matching Image 2 Screen 1)
          _buildWeeklyCalendarStrip(),
          const SizedBox(height: 24),

          // Grouped Sections: Today
          _buildGroupHeader('Today, ${DateFormat('d MMMM').format(_selectedDate)}'),
          const SizedBox(height: 10),
          _buildDoseListForDay(medications, logs, _selectedDate),

          const SizedBox(height: 20),

          // Grouped Sections: Yesterday
          _buildGroupHeader('Yesterday, ${DateFormat('d MMMM').format(_selectedDate.subtract(const Duration(days: 1)))}'),
          const SizedBox(height: 10),
          _buildDoseListForDay(medications, logs, _selectedDate.subtract(const Duration(days: 1))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendarStrip() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final day = _weekStart.add(Duration(days: i));
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = day;
              });
            },
            child: Column(
              children: [
                Text(
                  weekdays[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? const Color(0xFF2D6A4F) : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2D6A4F) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1B4332),
      ),
    );
  }

  Widget _buildDoseListForDay(
    List<Medication> medications,
    List<MedicationLog> logs,
    DateTime day,
  ) {
    if (medications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No medications scheduled',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: medications.map((med) {
        final scheduledTimeStr =
            med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : '09:00';

        // Find if taken on that day
        final log = logs.firstWhere(
          (l) =>
              l.medicationId == med.id &&
              l.timestamp.year == day.year &&
              l.timestamp.month == day.month &&
              l.timestamp.day == day.day,
          orElse: () => MedicationLog(
            id: '',
            medicationId: med.id,
            medicationName: med.name,
            scheduledTime: scheduledTimeStr,
            timestamp: day,
            status: LogStatus.missed,
          ),
        );

        final isTaken = log.status == LogStatus.taken;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Circular status checkbox (Matching Image 2 Screen 1)
              GestureDetector(
                onTap: () {
                  context.read<MedicationRepository>().logDose(
                        medication: med,
                        scheduledTime: scheduledTimeStr,
                        status: isTaken ? LogStatus.skipped : LogStatus.taken,
                      );
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTaken ? const Color(0xFF2D6A4F) : Colors.transparent,
                    border: Border.all(
                      color: isTaken ? const Color(0xFF2D6A4F) : Colors.grey.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: isTaken
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Clean Medicine Icon Thumbnail
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3DC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  med.category == MedCategory.eyeDrop || med.category == MedCategory.eyeOintment
                      ? Icons.remove_red_eye_outlined
                      : med.category == MedCategory.inhaler
                          ? Icons.air_outlined
                          : med.category == MedCategory.injectable
                              ? Icons.vaccines_outlined
                              : Icons.medication_outlined,
                  color: const Color(0xFF2D6A4F),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Dose Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isTaken ? Colors.grey : const Color(0xFF1E293B),
                        decoration: isTaken ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$scheduledTimeStr • ${med.dosageAmount.toInt()} ${med.dosageUnit.name}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Chevron for interactive Reminder or Specs
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                onPressed: () {
                  MedicineAlarmDialog.show(
                    context,
                    medication: med,
                    scheduledTime: scheduledTimeStr,
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
