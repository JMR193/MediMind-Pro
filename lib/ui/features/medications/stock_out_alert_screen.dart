import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/utils.dart';
import '../qr_share/qr_code_share_screen.dart';

class StockOutAlertScreen extends StatelessWidget {
  const StockOutAlertScreen({super.key});

  void _notifyGuardianViaSms(BuildContext context, String phone, List<Medication> lowMeds) async {
    AppleGlassDecorations.mediumHaptic();
    final medNames = lowMeds.map((m) => '${m.name} (${m.totalInventoryCount} left)').join(', ');
    final message = 'Hi, my medication supply is running low: $medNames. Please help me reorder.';
    final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open SMS app for $phone')),
        );
      }
    }
  }

  void _callGuardian(BuildContext context, String phone) async {
    AppleGlassDecorations.lightHaptic();
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not place call to $phone')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const alertRed = Color(0xFFE53935);
    const primaryBlue = Color(0xFF4A90E2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock out Alert', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final lowMeds = repo.medicationsNeedingRefill;
          final caregivers = repo.caregivers;
          final profile = repo.userProfile;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Warning Card (MediLink Signature)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: alertRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: alertRed.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: alertRed.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: alertRed, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medicine Stock Low',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: alertRed),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lowMeds.isEmpty
                                  ? 'All medications are sufficiently stocked.'
                                  : 'The following ${lowMeds.length} medicine(s) are running out. Reorder soon to avoid missing doses.',
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(200)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Running Out Medicines List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Medicine Running Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (lowMeds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: alertRed.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${lowMeds.length} items',
                          style: const TextStyle(color: alertRed, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (lowMeds.isEmpty)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, color: Color(0xFF36A25D), size: 40),
                            SizedBox(height: 8),
                            Text('No Stock Out Warnings', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Your medicine inventory is well-stocked.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...lowMeds.map((med) {
                    final color = hexToColor(med.colorHex);
                    final icon = getMedicationIcon(med.iconName);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('${med.strength} • ${med.dosageUnit.name}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: alertRed.withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${med.totalInventoryCount} left (Threshold: ${med.refillThreshold})',
                                      style: const TextStyle(fontSize: 10, color: alertRed, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Quick Restock Button (+30)
                            FilledButton.tonal(
                              onPressed: () {
                                AppleGlassDecorations.mediumHaptic();
                                repo.restockMedication(med.id, 30);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Restocked 30 units of ${med.name}!')),
                                );
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('+ Restock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 20),

                // Notify Guardian Section
                const Text('Notify Guardian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'Let your Guardian know so they can reorder or arrange delivery.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),

                if (caregivers.isEmpty && profile?.primaryDoctorPhone == null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.person_add_alt, color: primaryBlue),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('No guardian contacts added yet. Add one in settings to send restock alerts.')),
                        ],
                      ),
                    ),
                  )
                else ...[
                  ...caregivers.map((c) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF36A25D).withAlpha(30),
                            child: Text(c.name[0], style: const TextStyle(color: Color(0xFF36A25D), fontWeight: FontWeight.bold)),
                          ),
                          title: Row(
                            children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF36A25D).withAlpha(25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Primary', style: TextStyle(fontSize: 9, color: Color(0xFF36A25D), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          subtitle: Text('${c.relationship} • ${c.phone}', style: const TextStyle(fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.message_outlined, color: primaryBlue, size: 20),
                                tooltip: 'Send SMS Restock Request',
                                onPressed: () => _notifyGuardianViaSms(context, c.phone, lowMeds),
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone_outlined, color: Color(0xFF36A25D), size: 20),
                                tooltip: 'Call Guardian',
                                onPressed: () => _callGuardian(context, c.phone),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
                const SizedBox(height: 16),

                // Send Prescription to Guardian Button (MediLink Signature)
                FilledButton.icon(
                  onPressed: () {
                    AppleGlassDecorations.mediumHaptic();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QrCodeShareScreen()));
                  },
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Send Prescription to Guardian via QR / Share'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
