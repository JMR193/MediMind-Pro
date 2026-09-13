import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/tasker_event.dart';
import '../../core/theme.dart';

class TaskerScreen extends StatelessWidget {
  const TaskerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBanner(context),
              const SizedBox(height: 16),
              Text('Smart Automation Rules', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...repo.taskerRules.map((rule) => _buildTaskerRuleCard(context, rule, repo)),
              const SizedBox(height: 16),
              _buildInteractionCheatsheet(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF0284C7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withAlpha(51), shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Automation Engine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 4),
                Text('Configure Tasker, MacroDroid & Home Assistant integrations for context-aware medication management.',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskerRuleCard(BuildContext context, TaskerRule rule, MedicationRepository repo) {
    final actionColor = _getActionColor(rule.action);
    final actionIcon = _getActionIcon(rule.action);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: actionColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(actionIcon, color: actionColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(rule.description, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withAlpha(153))),
                    ],
                  ),
                ),
                Switch(
                  value: rule.isEnabled,
                  onChanged: (v) => repo.toggleTaskerRule(rule.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Intent action name code badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.code_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(rule.intentActionName, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey)),
                ],
              ),
            ),
            if (rule.lastTriggered != null) ...[
              const SizedBox(height: 8),
              Text('Last fired: ${DateFormat('MMM dd, HH:mm').format(rule.lastTriggered!)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: rule.isEnabled ? () => _simulateTrigger(context, rule, repo) : null,
                    icon: const Icon(Icons.play_arrow_outlined, size: 16),
                    label: const Text('Test Trigger', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionCheatsheet(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary.withAlpha(13),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.developer_board_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Tasker / MacroDroid Integration Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 12),
            _guideItem('📱 Tasker Profile', 'Create a Profile → State → Network Access = Home WiFi → Task → Send Intent with action name listed above'),
            const SizedBox(height: 8),
            _guideItem('🤖 MacroDroid', 'Add Macro → Trigger: WiFi Connected → Action: Send Intent → Package: com.medimind.reminder'),
            const SizedBox(height: 8),
            _guideItem('🏠 Home Assistant', 'Use REST API webhook to POST to app → Pipe through Android companion app intent'),
            const SizedBox(height: 8),
            _guideItem('💊 Smart Dispenser', 'Configure dispenser webhook URL to post to the local API endpoint on device port 8080'),
          ],
        ),
      ),
    );
  }

  Widget _guideItem(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 3),
        Text(body, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Color _getActionColor(TaskerAction action) {
    switch (action) {
      case TaskerAction.snoozeAllUntilHome:
        return MediMindTheme.warningOrange;
      case TaskerAction.nightQuietModeOverride:
        return const Color(0xFF7C3AED);
      case TaskerAction.triggerCriticalAlarm:
        return MediMindTheme.alertRed;
      case TaskerAction.logDoseExternal:
        return MediMindTheme.successGreen;
      case TaskerAction.requestRefillWebhook:
        return MediMindTheme.primaryBlue;
    }
  }

  IconData _getActionIcon(TaskerAction action) {
    switch (action) {
      case TaskerAction.snoozeAllUntilHome:
        return Icons.home_outlined;
      case TaskerAction.nightQuietModeOverride:
        return Icons.nights_stay_outlined;
      case TaskerAction.triggerCriticalAlarm:
        return Icons.notification_important_outlined;
      case TaskerAction.logDoseExternal:
        return Icons.sensors_outlined;
      case TaskerAction.requestRefillWebhook:
        return Icons.local_pharmacy_outlined;
    }
  }

  Future<void> _simulateTrigger(BuildContext context, TaskerRule rule, MedicationRepository repo) async {
    await repo.triggerTaskerRuleSimulated(rule.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🤖 Tasker Trigger Simulated: "${rule.title}"'),
          backgroundColor: MediMindTheme.primaryBlue,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
