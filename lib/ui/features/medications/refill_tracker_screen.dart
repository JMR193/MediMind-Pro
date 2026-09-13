import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/one_ui_widgets.dart';
import '../../core/theme.dart';
import '../medication_wizard/add_medication_screen.dart';

class RefillTrackerScreen extends StatelessWidget {
  const RefillTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Refill & Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Medication',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final meds = repo.medications;
          if (meds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey.withAlpha(120)),
                  const SizedBox(height: 16),
                  const Text('No Medications Tracked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Add prescriptions to monitor remaining pills & supply dates.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Sort by urgency: lowest days remaining first
          final sortedMeds = List<Medication>.from(meds)
            ..sort((a, b) => a.estimatedDaysSupplyRemaining.compareTo(b.estimatedDaysSupplyRemaining));

          final urgentCount = sortedMeds.where((m) => m.estimatedDaysSupplyRemaining <= 5).length;
          final warningCount = sortedMeds.where((m) => m.estimatedDaysSupplyRemaining > 5 && m.estimatedDaysSupplyRemaining <= 14).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Top Status Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Urgent Refills',
                      count: '$urgentCount',
                      subtitle: '< 5 Days Supply',
                      color: urgentCount > 0 ? MediMindTheme.alertRed : MediMindTheme.successGreen,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Order Soon',
                      count: '$warningCount',
                      subtitle: '5–14 Days Supply',
                      color: warningCount > 0 ? MediMindTheme.warningOrange : Colors.grey,
                      icon: Icons.access_time_filled_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active Inventory List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PRESCRIPTION INVENTORY (${sortedMeds.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Auto-calculated from doses',
                    style: TextStyle(fontSize: 11, color: Colors.grey.withAlpha(180)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Medication Inventory Cards
              ...sortedMeds.map((med) => _buildInventoryCard(context, med, repo)),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String count,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return OneUiWidgets.squircleCard(
      context: context,
      backgroundColor: color.withAlpha(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.withAlpha(200))),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, Medication med, MedicationRepository repo) {
    final daysRemaining = med.estimatedDaysSupplyRemaining;
    final exhaustionDate = med.estimatedExhaustionDate;
    final isUrgent = daysRemaining <= 5;
    final isModerate = daysRemaining > 5 && daysRemaining <= 14;

    final statusColor = isUrgent
        ? MediMindTheme.alertRed
        : isModerate
            ? MediMindTheme.warningOrange
            : MediMindTheme.successGreen;

    final supplyRatio = (daysRemaining / 30.0).clamp(0.0, 1.0);

    return OneUiWidgets.squircleCard(
      context: context,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    med.requiresEyeDropProtocol ? Icons.opacity_rounded : Icons.medication_rounded,
                    color: statusColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${med.strength} • ${med.dosageAmount.toInt()} ${med.dosageUnit.name} per dose (${med.scheduleTimes.length}x daily)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.withAlpha(200)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  daysRemaining <= 0 ? 'EMPTY' : '$daysRemaining DAYS LEFT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Battery Supply Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: supplyRatio,
              minHeight: 8,
              backgroundColor: Colors.grey.withAlpha(40),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock: ${med.totalInventoryCount} ${med.dosageUnit.name} remaining',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (exhaustionDate != null)
                Text(
                  'Depletes: ${DateFormat('MMM dd, yyyy').format(exhaustionDate)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.withAlpha(180)),
                ),
            ],
          ),
          const Divider(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRestockDialog(context, med, repo),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  label: const Text('Restock'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _dispatchRefillRequest(context, med, repo),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Order Refill'),
                  style: FilledButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(BuildContext context, Medication med, MedicationRepository repo) {
    final countCtrl = TextEditingController(text: '30');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restock ${med.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current inventory: ${med.totalInventoryCount} ${med.dosageUnit.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Units Added',
                suffixText: med.dosageUnit.name,
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [15, 30, 60, 90].map((units) {
                return ActionChip(
                  label: Text('+$units'),
                  onPressed: () => countCtrl.text = units.toString(),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(countCtrl.text.trim()) ?? 0;
              if (val > 0) {
                repo.restockMedication(med.id, val);
                Navigator.pop(ctx);
                AppleGlassDecorations.mediumHaptic();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added $val ${med.dosageUnit.name} to ${med.name}')),
                );
              }
            },
            child: const Text('Save Stock'),
          ),
        ],
      ),
    );
  }

  void _dispatchRefillRequest(BuildContext context, Medication med, MedicationRepository repo) {
    AppleGlassDecorations.lightHaptic();
    final patientName = repo.userProfile?.name ?? 'Patient';
    final doctor = med.prescribingDoctor ?? repo.userProfile?.primaryDoctorName ?? 'Attending Doctor';
    final rx = med.rxNumber ?? 'On File';

    final text = '''
🏥 *PRESCRIPTION REFILL REQUEST*
Patient: $patientName
Medication: ${med.name} (${med.strength})
Prescribed Dosage: ${med.dosageAmount.toInt()} ${med.dosageUnit.name} (${med.frequency})
Rx Number: $rx
Doctor: $doctor
Current Stock: ${med.totalInventoryCount} remaining (~${med.estimatedDaysSupplyRemaining} days left)

Please confirm refill availability and pickup / delivery timing. Thank you!
— Generated securely by MediMind Pro
''';

    SharePlus.instance.share(ShareParams(
      text: text,
      subject: 'Prescription Refill Request: ${med.name}',
    ));
  }
}
