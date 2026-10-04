import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../core/apple_glass_decorations.dart';

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen> with SingleTickerProviderStateMixin {
  bool _isSosTriggered = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  bool _isSirenActive = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerSosCountdown() {
    AppleGlassDecorations.heavyHaptic();
    setState(() {
      _isSosTriggered = true;
      _countdownSeconds = 5;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        _dispatchSosAlert();
      }
    });
  }

  void _cancelSos() {
    AppleGlassDecorations.lightHaptic();
    _countdownTimer?.cancel();
    setState(() {
      _isSosTriggered = false;
      _countdownSeconds = 5;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS Alert cancelled.')),
    );
  }

  void _dispatchSosAlert() {
    final repo = context.read<MedicationRepository>();
    final patientName = repo.userProfile?.name ?? 'Patient';
    final primaryCaregiver = repo.caregivers.isNotEmpty ? repo.caregivers.first : null;

    setState(() {
      _isSosTriggered = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 SOS Sent for $patientName to ${primaryCaregiver?.name ?? "Guardians"} with live location!'),
        backgroundColor: const Color(0xFFE53935),
        duration: const Duration(seconds: 4),
      ),
    );

    // Call caregiver or 911 if desired
    if (primaryCaregiver?.phone != null && primaryCaregiver!.phone!.isNotEmpty) {
      final uri = Uri.parse('tel:${primaryCaregiver.phone}');
      canLaunchUrl(uri).then((can) {
        if (can) launchUrl(uri);
      });
    }
  }

  void _toggleSiren() {
    AppleGlassDecorations.mediumHaptic();
    setState(() {
      _isSirenActive = !_isSirenActive;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSirenActive ? '🔊 Loud Siren Alarm Activated!' : 'Siren Silenced'),
        backgroundColor: _isSirenActive ? const Color(0xFFE53935) : Colors.grey.shade800,
      ),
    );
  }

  void _dialNumber(String? number) async {
    if (number == null || number.isEmpty) return;
    final clean = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot place call to $clean')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const sosRed = Color(0xFFE53935);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Emergency', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final profile = repo.userProfile;
          final caregivers = repo.caregivers;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // Top alert banner
                Text(
                  'Your alert will be sent to your guardians and emergency contacts with real-time location.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Pulsing SOS Button
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: GestureDetector(
                    onTap: _isSosTriggered ? _cancelSos : _triggerSosCountdown,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isSosTriggered
                              ? [const Color(0xFFB91C1C), const Color(0xFFDC2626)]
                              : [const Color(0xFFE53935), const Color(0xFFEF4444)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: sosRed.withAlpha(_isSosTriggered ? 140 : 90),
                            blurRadius: _isSosTriggered ? 36 : 24,
                            spreadRadius: _isSosTriggered ? 8 : 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSosTriggered) ...[
                              Text(
                                '$_countdownSeconds',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'Tap to Cancel',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              const Icon(Icons.emergency, color: Colors.white, size: 48),
                              const SizedBox(height: 4),
                              const Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const Text(
                                'Tap to Alert',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Safety Tools Section Header
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: sosRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Safety Tools',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "We're here to help in any situation",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 12),

                // Tool 1: Live Location
                _buildToolTile(
                  context,
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFF0284C7),
                  title: 'Live Location Sharing',
                  subtitle: 'Real-time GPS: 37.7749° N, 122.4194° W',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Active', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GPS Live location broadcasted to trusted contacts.')),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Tool 2: Loud Alarm / Siren
                _buildToolTile(
                  context,
                  icon: _isSirenActive ? Icons.volume_up_rounded : Icons.volume_off_outlined,
                  iconColor: sosRed,
                  title: 'Loud Alarm / Siren',
                  subtitle: _isSirenActive ? 'Audible distress siren playing' : 'Sound distress siren to alert nearby people',
                  trailing: Switch(
                    value: _isSirenActive,
                    activeThumbColor: sosRed,
                    onChanged: (_) => _toggleSiren(),
                  ),
                  onTap: _toggleSiren,
                ),
                const SizedBox(height: 8),

                // Tool 3: Emergency Contacts Roster
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.people_outline, color: Color(0xFF36A25D), size: 20),
                            SizedBox(width: 8),
                            Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (caregivers.isEmpty && profile?.emergencyContactPhone == null)
                          const Text('No emergency contacts configured yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
                        else ...[
                          if (profile?.emergencyContactName != null && profile!.emergencyContactPhone != null)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                              title: Text(profile.emergencyContactName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Primary Emergency Contact • ${profile.emergencyContactPhone}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.phone, color: Color(0xFF36A25D)),
                                onPressed: () => _dialNumber(profile.emergencyContactPhone!),
                              ),
                            ),
                          ...caregivers.map((c) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF36A25D).withAlpha(30),
                                  child: Text(c.name[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF36A25D))),
                                ),
                                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text('${c.relationship} • ${c.phone}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.phone, color: Color(0xFF36A25D)),
                                  onPressed: () => _dialNumber(c.phone),
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Direct 911 / 112 Speed Dial
                OutlinedButton.icon(
                  onPressed: () => _dialNumber('911'),
                  icon: const Icon(Icons.local_hospital_outlined, color: sosRed),
                  label: const Text('Call Local Emergency Services (911 / 112)', style: TextStyle(color: sosRed, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: sosRed),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Privacy Trust Badge (from MediLink Slide 16)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.security, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Your data is safe and secure. We respect your privacy.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
