import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/one_ui_widgets.dart';
import '../../core/theme.dart';

class EmergencyMedicalIdScreen extends StatelessWidget {
  const EmergencyMedicalIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Medical ID'),
        backgroundColor: MediMindTheme.alertRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Emergency ID',
            onPressed: () => _shareEmergencyId(context),
          ),
        ],
      ),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final profile = repo.userProfile;
          final meds = repo.medications;

          final patientName = profile?.name ?? 'Patient (Name Not Set)';
          final bloodGroup = profile?.bloodGroup ?? 'Unknown';
          final allergies = profile?.allergies ?? 'None Reported';
          final conditions = profile?.medicalConditions ?? 'None Reported';
          final doctorName = profile?.primaryDoctorName ?? 'None on file';
          final doctorPhone = profile?.primaryDoctorPhone ?? '';
          final emergencyName = profile?.emergencyContactName ?? 'None on file';
          final emergencyPhone = profile?.emergencyContactPhone ?? '';

          // Format standardized Emergency QR Payload
          final qrPayload = '''
[EMERGENCY MEDICAL ID]
Patient: $patientName
Blood Group: $bloodGroup
Allergies: $allergies
Conditions: $conditions
Emergency Contact: $emergencyName ($emergencyPhone)
Doctor: $doctorName ($doctorPhone)
Active Medications (${meds.length}):
${meds.map((m) => "• ${m.name} ${m.strength} (${m.frequency})").join("\n")}
— MediMind Pro Offline Medical Card
''';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Emergency Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MediMindTheme.alertRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MediMindTheme.alertRed.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emergency_rounded, color: MediMindTheme.alertRed, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FIRST RESPONDER FAST-PASS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: MediMindTheme.alertRed,
                              letterSpacing: 1.1,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Paramedics & emergency staff can scan this offline QR code or read critical health data immediately.',
                            style: TextStyle(fontSize: 11, color: MediMindTheme.alertRed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Patient Demographics & Blood Group Card
              OneUiWidgets.squircleCard(
                context: context,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: MediMindTheme.alertRed.withAlpha(26),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'BLOOD',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: MediMindTheme.alertRed),
                            ),
                            Text(
                              bloodGroup,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MediMindTheme.alertRed),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          if (profile?.dateOfBirth != null)
                            Text(
                              'DOB: ${profile!.dateOfBirth!.day}/${profile.dateOfBirth!.month}/${profile.dateOfBirth!.year}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.withAlpha(200)),
                            ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: MediMindTheme.successGreen.withAlpha(26),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ORGAN DONOR',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: MediMindTheme.successGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Offline QR Code Display Card
              OneUiWidgets.squircleCard(
                context: context,
                child: Column(
                  children: [
                    const Text(
                      'OFFLINE SCANNABLE MEDICAL QR',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contains allergies, emergency contacts & active prescriptions',
                      style: TextStyle(fontSize: 11, color: Colors.grey.withAlpha(200)),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: QrImageView(
                          data: qrPayload,
                          version: QrVersions.auto,
                          size: 190.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Works 100% offline without cellular or Wi-Fi data',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Critical Medical Information: Allergies & Conditions
              OneUiWidgets.squircleCard(
                context: context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: MediMindTheme.alertRed, size: 20),
                        SizedBox(width: 8),
                        Text('CRITICAL ALLERGIES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MediMindTheme.alertRed)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      allergies,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.local_hospital_outlined, color: MediMindTheme.primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text('CHRONIC MEDICAL CONDITIONS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MediMindTheme.primaryBlue)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      conditions,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Emergency Contact Speed-Dial
              OneUiWidgets.squircleCard(
                context: context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EMERGENCY CONTACTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFDC2626),
                        child: Icon(Icons.emergency, color: Colors.white),
                      ),
                      title: Text(emergencyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Next of Kin: $emergencyPhone'),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone, color: MediMindTheme.successGreen),
                        onPressed: () => _shareContact(emergencyName, emergencyPhone),
                      ),
                    ),
                    const Divider(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF0284C7),
                        child: Icon(Icons.medical_services, color: Colors.white),
                      ),
                      title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Primary Physician: $doctorPhone'),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone, color: MediMindTheme.successGreen),
                        onPressed: () => _shareContact(doctorName, doctorPhone),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active Medications List
              OneUiWidgets.squircleCard(
                context: context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACTIVE MEDICATIONS (${meds.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    const SizedBox(height: 12),
                    if (meds.isEmpty)
                      const Text('No active prescriptions logged.', style: TextStyle(color: Colors.grey))
                    else
                      ...meds.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 8, color: MediMindTheme.primaryBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${m.name} ${m.strength} (${m.dosageAmount.toInt()} ${m.dosageUnit.name})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  m.frequency,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.withAlpha(200)),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _shareEmergencyId(BuildContext context) {
    AppleGlassDecorations.mediumHaptic();
    final repo = context.read<MedicationRepository>();
    final profile = repo.userProfile;
    final meds = repo.medications;

    final text = '''
🚨 *EMERGENCY MEDICAL CARD (ICE)*
Patient: ${profile?.name ?? 'Patient'}
Blood Group: ${profile?.bloodGroup ?? 'Unknown'}
Allergies: ${profile?.allergies ?? 'None'}
Conditions: ${profile?.medicalConditions ?? 'None'}

Emergency Contact: ${profile?.emergencyContactName ?? 'N/A'} (${profile?.emergencyContactPhone ?? 'N/A'})
Primary Doctor: ${profile?.primaryDoctorName ?? 'N/A'} (${profile?.primaryDoctorPhone ?? 'N/A'})

Active Medications:
${meds.map((m) => "• ${m.name} ${m.strength} (${m.frequency})").join("\n")}

— Verified by MediMind Pro Emergency Fast-Pass
''';

    SharePlus.instance.share(ShareParams(
      text: text,
      subject: 'EMERGENCY MEDICAL ID: ${profile?.name ?? "Patient"}',
    ));
  }

  void _shareContact(String name, String phone) {
    SharePlus.instance.share(ShareParams(
      text: 'Contact $name: $phone',
      subject: 'Emergency Contact',
    ));
  }
}
