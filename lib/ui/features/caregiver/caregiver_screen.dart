import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/caregiver.dart';
import '../../core/theme.dart';

class CaregiverScreen extends StatelessWidget {
  const CaregiverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCaregiverSheet(context),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Caregiver'),
      ),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final caregivers = repo.caregivers;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0369A1)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Caregiver Safety Net', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'If you repeatedly miss critical medications, your designated caregiver receives an instant notification or alert.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Caregiver Alert Settings Toggle
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.notification_important_outlined, color: MediMindTheme.alertRed),
                  title: const Text('Enable Caregiver Alerts'),
                  subtitle: const Text('Send alerts when critical doses are missed'),
                  value: repo.settings.caregiverAlertsEnabled,
                  onChanged: (val) {
                    repo.updateSettings(repo.settings.copyWith(caregiverAlertsEnabled: val));
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text('Designated Caregivers (${caregivers.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              if (caregivers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 56, color: Colors.grey.withAlpha(102)),
                        const SizedBox(height: 12),
                        const Text('No caregivers added yet', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Add a family member or doctor as a safety contact', style: TextStyle(fontSize: 12, color: Colors.grey.withAlpha(153))),
                      ],
                    ),
                  ),
                )
              else
                ...caregivers.map((c) => _buildCaregiverCard(context, c, repo)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCaregiverCard(BuildContext context, Caregiver c, MedicationRepository repo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(c.relationship, style: TextStyle(fontSize: 12, color: Colors.grey.withAlpha(204))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => repo.deleteCaregiver(c.id),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.alarm_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Alerts after ${c.missedDosesBeforeAlert} missed doses', style: const TextStyle(fontSize: 12)),
                const Spacer(),
                if (c.phone != null) ...[
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, size: 18, color: Colors.green),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling ${c.phone}...')));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.message_outlined, size: 18, color: Colors.blue),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sending SMS to ${c.phone}...')));
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCaregiverSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    int missedThreshold = 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Caregiver Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationCtrl,
                decoration: const InputDecoration(labelText: 'Relationship', prefixIcon: Icon(Icons.favorite_outline), hintText: 'e.g. Spouse, Son, Daughter, Nurse'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Alert after missed doses:'),
                  DropdownButton<int>(
                    value: missedThreshold,
                    items: [1, 2, 3, 4, 5].map((n) => DropdownMenuItem(value: n, child: Text('$n doses'))).toList(),
                    onChanged: (v) { if (v != null) setState(() => missedThreshold = v); },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final c = Caregiver(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    relationship: relationCtrl.text.trim().isEmpty ? 'Caregiver' : relationCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    missedDosesBeforeAlert: missedThreshold,
                    isActive: true,
                    addedAt: DateTime.now(),
                  );
                  context.read<MedicationRepository>().addCaregiver(c);
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Save Caregiver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
