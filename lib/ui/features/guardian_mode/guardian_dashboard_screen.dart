import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../../domain/models/medication_log.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../medication_wizard/add_medication_screen.dart';
import '../ocr_scanner/ocr_scanner_screen.dart';
import '../emergency/sos_emergency_screen.dart';
import '../medications/stock_out_alert_screen.dart';
import '../reports/adherence_report_screen.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  State<GuardianDashboardScreen> createState() => _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  String _selectedPharmacy = 'Apollo Pharmacy';
  bool _orderDispatched = false;
  String _orderStep = 'Delivered to Doorstep';

  static const _pharmacies = [
    {
      'name': 'Apollo Pharmacy',
      'deliveryTime': '20 - 30 min delivery',
      'rating': '4.8 ★',
      'tag': 'Fastest Delivery',
      'discount': '20% OFF',
    },
    {
      'name': 'Netmeds Express',
      'deliveryTime': '30 - 45 min delivery',
      'rating': '4.7 ★',
      'tag': 'Free Delivery',
      'discount': '15% OFF',
    },
    {
      'name': '1mg Pharmacy',
      'deliveryTime': '35 - 50 min delivery',
      'rating': '4.9 ★',
      'tag': 'Best Prices',
      'discount': '25% OFF',
    },
    {
      'name': 'MedPlus Mart',
      'deliveryTime': '40 min delivery',
      'rating': '4.6 ★',
      'tag': '100% Genuine',
      'discount': '10% OFF',
    },
  ];

  void _callPatient(String phone) async {
    AppleGlassDecorations.lightHaptic();
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot place call to $phone')),
        );
      }
    }
  }

  void _dispatchPharmacyOrder(BuildContext context, List<Medication> lowMeds) {
    AppleGlassDecorations.heavyHaptic();
    setState(() {
      _orderDispatched = true;
      _orderStep = 'Order Placed & Confirmed';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📦 Pharmacy refill order placed via $_selectedPharmacy!'),
        backgroundColor: const Color(0xFF36A25D),
        duration: const Duration(seconds: 3),
      ),
    );

    // Simulate delivery progress updates
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _orderStep = 'Packed by Licensed Pharmacist');
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _orderStep = 'Out for Doorstep Delivery 🛵');
    });
  }

  @override
  Widget build(BuildContext context) {
    const guardianGreen = Color(0xFF36A25D);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: guardianGreen.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: guardianGreen, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guardian Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Remote Healthcare & Delivery', style: TextStyle(fontSize: 10, color: guardianGreen, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'AI Prescription Scanner',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OcrScannerScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Exit Guardian Mode',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final profile = repo.userProfile;
          final patientName = profile?.name ?? 'Loved One';
          final lowMeds = repo.medicationsNeedingRefill;
          final today = DateTime.now();
          final adherenceRate = repo.calculateAdherenceRate();
          final takenLogs = repo.logs.where((l) => l.status == LogStatus.taken).length;
          final missedLogs = repo.logs.where((l) => l.status == LogStatus.missed).length;
          final skippedLogs = repo.logs.where((l) => l.status == LogStatus.skipped).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Connection Header Card (MediLink Slide 3 & 17)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [guardianGreen.withAlpha(25), const Color(0xFF0D9488).withAlpha(15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: guardianGreen.withAlpha(60), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: guardianGreen.withAlpha(35),
                        child: const Icon(Icons.elderly_woman_rounded, color: guardianGreen, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  patientName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Active Now', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Last sync: Today, ${DateFormat('hh:mm a').format(today)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            if (profile?.primaryDoctorPhone != null)
                              Text(
                                'Doctor: ${profile?.primaryDoctorName ?? "Assigned"}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          if (profile?.emergencyContactPhone != null) {
                            _callPatient(profile!.emergencyContactPhone!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Calling patient direct dial...')),
                            );
                          }
                        },
                        icon: const Icon(Icons.phone_in_talk, color: guardianGreen),
                        style: IconButton.styleFrom(backgroundColor: guardianGreen.withAlpha(30)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Live Adherence & Intake Monitor (MediLink Slide 4 & 17)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.analytics_outlined, color: guardianGreen, size: 20),
                                SizedBox(width: 8),
                                Text('Adherence & Intake Monitor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdherenceReportScreen())),
                              child: const Text('Detailed Report →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: guardianGreen)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Progress Circle
                            SizedBox(
                              width: 68,
                              height: 68,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: adherenceRate / 100,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey.withAlpha(35),
                                    valueColor: const AlwaysStoppedAnimation<Color>(guardianGreen),
                                  ),
                                  Center(
                                    child: Text(
                                      '${adherenceRate.toInt()}%',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: guardianGreen),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildStatRow('Taken Doses', '$takenLogs', Colors.green),
                                  const SizedBox(height: 6),
                                  _buildStatRow('Missed Doses', '$missedLogs', Colors.red),
                                  const SizedBox(height: 6),
                                  _buildStatRow('Skipped Doses', '$skippedLogs', Colors.orange),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Low Stock Alerts & Fast Refill (MediLink Slide 16 & 17)
                if (lowMeds.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, color: Color(0xFFE53935), size: 20),
                          SizedBox(width: 8),
                          Text('Low-Stock Warnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOutAlertScreen())),
                        child: const Text('View All Alerts →', style: TextStyle(fontSize: 11, color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...lowMeds.take(2).map((m) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFCECE),
                            child: Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 20),
                          ),
                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('${m.totalInventoryCount} left • Refill threshold: ${m.refillThreshold}'),
                          trailing: FilledButton.tonal(
                            onPressed: () => _dispatchPharmacyOrder(context, [m]),
                            style: FilledButton.styleFrom(
                              backgroundColor: guardianGreen.withAlpha(25),
                              foregroundColor: guardianGreen,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Reorder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // Remote Pharmacy Ordering Hub (MediLink Slide 4 & 17 Signature Feature)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.local_shipping_outlined, color: guardianGreen, size: 22),
                                SizedBox(width: 8),
                                Text('Doorstep Medicine Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: guardianGreen.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('FLAT 20% OFF', style: TextStyle(color: guardianGreen, fontWeight: FontWeight.bold, fontSize: 9)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Order prescription refills remotely and have them delivered directly to $patientName’s home.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),

                        // Delivery address row
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.home_outlined, color: guardianGreen, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Deliver to: Patient Residence (Primary Address)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Pharmacy Selection List
                        const Text('Choose Verified Pharmacy Partner:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        ..._pharmacies.map((p) {
                          final isSelected = _selectedPharmacy == p['name'];
                          return InkWell(
                            onTap: () {
                              AppleGlassDecorations.lightHaptic();
                              setState(() => _selectedPharmacy = p['name'] as String);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? guardianGreen.withAlpha(25) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? guardianGreen : Theme.of(context).dividerColor.withAlpha(60),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                    color: isSelected ? guardianGreen : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        Text('${p['deliveryTime']} • ${p['tag']}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  Text(p['rating'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: guardianGreen)),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),

                        // Order Status Banner if active
                        if (_orderDispatched) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: guardianGreen.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: guardianGreen),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.two_wheeler_rounded, color: guardianGreen, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Live Dispatch Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: guardianGreen)),
                                      Text(_orderStep, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Order Button
                        FilledButton.icon(
                          onPressed: () => _dispatchPharmacyOrder(context, lowMeds),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: Text(_orderDispatched ? 'Order Another Refill Pack' : 'Order Refill via $_selectedPharmacy'),
                          style: FilledButton.styleFrom(
                            backgroundColor: guardianGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Remote Reminder Management Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remote Schedule Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        AppleGlassDecorations.mediumHaptic();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMedicationScreen()));
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Med', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: guardianGreen.withAlpha(25),
                        foregroundColor: guardianGreen,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Active Medications Schedule
                ...repo.medications.map((m) {
                  final color = hexToColor(m.colorHex);
                  final icon = getMedicationIcon(m.iconName);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Times: ${m.scheduleTimes.join(", ")} • Stock: ${m.totalInventoryCount} left'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_calendar_outlined, size: 20, color: guardianGreen),
                            tooltip: 'Modify Schedule',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Editing schedule for ${m.name}...')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}
