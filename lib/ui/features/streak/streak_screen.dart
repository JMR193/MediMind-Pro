import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication_log.dart';
import '../../core/theme.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adherence Streaks & Badges')),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final streak = repo.streakData;
          final logs = repo.logs;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Flame & Current Streak Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFF97316), Color(0xFFFBBF24)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withAlpha(102),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 64),
                      const SizedBox(height: 8),
                      Text(
                        '${streak.currentStreak} DAYS',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        streak.streakBadge,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Personal Record: ${streak.bestStreak} Days 🔥',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Monthly Calendar View with Dots for Taken/Skipped
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text('Medication Adherence Calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        TableCalendar(
                          firstDay: DateTime.now().subtract(const Duration(days: 365)),
                          lastDay: DateTime.now().add(const Duration(days: 30)),
                          focusedDay: _focusedDay,
                          calendarFormat: CalendarFormat.month,
                          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                          onPageChanged: (focused) => setState(() => _focusedDay = focused),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              final dayLogs = logs.where((l) =>
                                  l.timestamp.year == date.year &&
                                  l.timestamp.month == date.month &&
                                  l.timestamp.day == date.day).toList();
                              if (dayLogs.isEmpty) return null;
                              final allTaken = dayLogs.every((l) => l.status == LogStatus.taken);
                              final hasSkipped = dayLogs.any((l) => l.status == LogStatus.skipped || l.status == LogStatus.missed);

                              return Positioned(
                                bottom: 1,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: allTaken
                                        ? MediMindTheme.successGreen
                                        : hasSkipped
                                            ? MediMindTheme.alertRed
                                            : MediMindTheme.warningOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.circle, color: MediMindTheme.successGreen, size: 8),
                            SizedBox(width: 4),
                            Text('All Taken', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 16),
                            Icon(Icons.circle, color: MediMindTheme.alertRed, size: 8),
                            SizedBox(width: 4),
                            Text('Missed/Skipped', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 16),
                            Icon(Icons.circle, color: MediMindTheme.warningOrange, size: 8),
                            SizedBox(width: 4),
                            Text('Partial', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Achievement Badges
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Milestones & Badges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                const SizedBox(height: 10),
                _buildBadgeTile(
                  icon: '💪',
                  title: '3-Day Strong',
                  subtitle: 'Take all doses consistently for 3 straight days',
                  unlocked: streak.bestStreak >= 3,
                ),
                _buildBadgeTile(
                  icon: '🔥',
                  title: 'Week Warrior',
                  subtitle: '7 days of uninterrupted clinical adherence',
                  unlocked: streak.bestStreak >= 7,
                ),
                _buildBadgeTile(
                  icon: '⭐',
                  title: '2-Week Star',
                  subtitle: '14 days of proper medication timing',
                  unlocked: streak.bestStreak >= 14,
                ),
                _buildBadgeTile(
                  icon: '🏆',
                  title: '30-Day Champion',
                  subtitle: 'A full month of optimal disease management',
                  unlocked: streak.bestStreak >= 30,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeTile({required String icon, required String title, required String subtitle, required bool unlocked}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: unlocked ? null : Colors.grey.withAlpha(20),
      child: ListTile(
        leading: Text(icon, style: TextStyle(fontSize: 28, color: unlocked ? null : Colors.grey)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: unlocked ? null : Colors.grey)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Icon(
          unlocked ? Icons.check_circle : Icons.lock_outline,
          color: unlocked ? MediMindTheme.successGreen : Colors.grey,
        ),
      ),
    );
  }
}
