import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/medication_log.dart';
import 'refill_tracker_screen.dart';
import '../medication_wizard/add_medication_screen.dart';

class MedicationDetailSpecsScreen extends StatelessWidget {
  final Medication medication;

  const MedicationDetailSpecsScreen({super.key, required this.medication});

  @override
  Widget build(BuildContext context) {
    final timesStr = medication.scheduleTimes.isNotEmpty
        ? medication.scheduleTimes.join(' / ')
        : '08:00 / 14:00';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      appBar: AppBar(
        title: Text(
          medication.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Centered Hero Medicine Display with Soft Radial Glow
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFD8F3DC), Color(0xFFB7E4C7)],
                  radius: 0.85,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withOpacity(0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  medication.category == MedCategory.eyeDrop || medication.category == MedCategory.eyeOintment
                      ? Icons.remove_red_eye_rounded
                      : medication.category == MedCategory.inhaler
                          ? Icons.air_rounded
                          : medication.category == MedCategory.injectable
                              ? Icons.vaccines_rounded
                              : Icons.medication_rounded,
                  size: 72,
                  color: const Color(0xFF2D6A4F),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Specifications Card Group (Matching Image 2 Screen 3)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSpecTile(
                  icon: Icons.medication_outlined,
                  title: 'Quantity',
                  value: '${medication.dosageAmount.toInt()} ${medication.dosageUnit.name}',
                ),
                const Divider(height: 1, indent: 56, endIndent: 20),
                _buildSpecTile(
                  icon: Icons.access_time_rounded,
                  title: 'Time',
                  value: timesStr,
                ),
                const Divider(height: 1, indent: 56, endIndent: 20),
                _buildSpecTile(
                  icon: Icons.repeat_rounded,
                  title: 'Repeat',
                  value: medication.frequency.toUpperCase(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Remaining Inventory Card (Matching Image 2 Screen 3)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2D6A4F), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Remaining Inventory',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '${medication.totalInventoryCount} ${medication.dosageUnit.name} left',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: Color(0xFFB7E4C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, color: Color(0xFF2D6A4F), size: 18),
                  label: const Text('+ Add pack', style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RefillTrackerScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Primary Action: Edit or Log Dose
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                context.read<MedicationRepository>().logDose(
                      medication: medication,
                      scheduledTime: medication.scheduleTimes.isNotEmpty ? medication.scheduleTimes.first : '08:00',
                      status: LogStatus.taken,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Logged ${medication.name} as taken!')),
                );
              },
              child: const Text('Log Dose Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D6A4F),
                side: const BorderSide(color: Color(0xFFB7E4C7), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMedicationScreen(editMedication: medication),
                  ),
                );
              },
              child: const Text('Edit Medication', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSpecTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2D6A4F)),
          const SizedBox(width: 14),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Medication'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddMedicationScreen(editMedication: medication)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Medication', style: TextStyle(color: Colors.red)),
              onTap: () {
                context.read<MedicationRepository>().deleteMedication(medication.id);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
