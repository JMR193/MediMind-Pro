import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/theme.dart';

class MedicationRefillForecast {
  final Medication medication;
  final int currentStock;
  final double dailyBurnRate;
  final int daysRemaining;
  final DateTime depletionDate;
  final bool fallsOnWeekend;
  final bool isCriticalDepletion;

  const MedicationRefillForecast({
    required this.medication,
    required this.currentStock,
    required this.dailyBurnRate,
    required this.daysRemaining,
    required this.depletionDate,
    required this.fallsOnWeekend,
    required this.isCriticalDepletion,
  });
}

class RefillForecastScreen extends StatelessWidget {
  const RefillForecastScreen({super.key});

  List<MedicationRefillForecast> _computeForecasts(List<Medication> meds) {
    final now = DateTime.now();
    return meds.map((m) {
      final stock = m.currentSupply;
      final timesPerDay = m.scheduledTimes.isNotEmpty ? m.scheduledTimes.length : 1;
      final dosePerIntake = m.isOphthalmic ? 1.0 : (double.tryParse(m.dosage.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.0);
      final dailyBurn = (timesPerDay * dosePerIntake).clamp(1.0, 10.0);
      final days = stock <= 0 ? 0 : (stock / dailyBurn).floor();
      final depletion = now.add(Duration(days: days));
      final isWeekend = depletion.weekday == DateTime.saturday || depletion.weekday == DateTime.sunday;
      final isCritical = days <= 5;

      return MedicationRefillForecast(
        medication: m,
        currentStock: stock,
        dailyBurnRate: dailyBurn,
        daysRemaining: days,
        depletionDate: depletion,
        fallsOnWeekend: isWeekend,
        isCriticalDepletion: isCritical,
      );
    }).toList()
      ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    final meds = repo.activeMedications;
    final forecasts = _computeForecasts(meds);

    final weekendHazards = forecasts.where((f) => f.fallsOnWeekend && f.daysRemaining <= 14).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.teal),
            SizedBox(width: 8),
            Text('Refill & Desert Buffer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
      body: meds.isEmpty
          ? _buildEmptyState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(context),
                  const SizedBox(height: 16),
                  if (weekendHazards.isNotEmpty) ...[
                    _buildWeekendRefillCliffAlert(context, weekendHazards),
                    const SizedBox(height: 16),
                  ],
                  const Text('Supply Depletion Forecast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...forecasts.map((f) => _buildForecastCard(context, f, repo)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.analytics_rounded, color: Colors.white, size: 36),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pharmacy Desert & Weekend Buffer',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Predicts the exact day your cabinet runs out. Prevents dangerous weekend and holiday stock-outs.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekendRefillCliffAlert(BuildContext context, List<MedicationRefillForecast> hazards) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Weekend Refill Cliff Detected (${hazards.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'The following medication(s) will run out over a weekend when pharmacies, clinics, and delivery dispatch are closed! Refill before Friday.',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          ...hazards.map((h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${h.medication.name}: Depletes on ${DateFormat('EEEE, MMM d').format(h.depletionDate)}',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildForecastCard(BuildContext context, MedicationRefillForecast f, MedicationRepository repo) {
    final statusColor = f.daysRemaining <= 5
        ? Colors.redAccent
        : f.daysRemaining <= 12
            ? Colors.amber
            : Colors.green;

    final progressRatio = (f.daysRemaining / 30.0).clamp(0.0, 1.0);

    return AppleGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withAlpha(30),
                  child: Icon(
                    f.daysRemaining <= 5 ? Icons.battery_alert_rounded : Icons.battery_charging_full_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.medication.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${f.medication.dosage} • ${f.currentStock} units in stock', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${f.daysRemaining} Days',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor),
                    ),
                    Text(
                      DateFormat('MMM d').format(f.depletionDate),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressRatio,
                minHeight: 8,
                backgroundColor: Colors.grey.withAlpha(40),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (f.fallsOnWeekend)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                    child: const Text('⚠️ Weekend Exhaustion', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                  )
                else
                  Text('Weekday Exhaustion (${DateFormat('EEEE').format(f.depletionDate)})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                TextButton.icon(
                  onPressed: () {
                    final msg = 'Hello, I need to request a prescription refill for ${f.medication.name} (${f.medication.dosage}). Current remaining supply: ${f.currentStock} units. Expected exhaustion date: ${DateFormat('yyyy-MM-dd').format(f.depletionDate)}. Thank you!';
                    Share.share(msg, subject: 'Refill Request: ${f.medication.name}');
                  },
                  icon: const Icon(Icons.share, size: 14),
                  label: const Text('Send Refill Order', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.withAlpha(100)),
          const SizedBox(height: 16),
          const Text('No Medications in Cabinet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Add medications to track inventory runways and weekend refill cliffs.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
