import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _doctorCtrl;
  late TextEditingController _doctorPhoneCtrl;
  late TextEditingController _emergencyCtrl;
  late TextEditingController _emergencyPhoneCtrl;
  late TextEditingController _allergiesCtrl;
  late TextEditingController _conditionsCtrl;
  String? _bloodGroup;
  DateTime? _dob;

  static const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'];

  @override
  void initState() {
    super.initState();
    final profile = context.read<MedicationRepository>().userProfile;
    _nameCtrl = TextEditingController(text: profile?.name ?? '');
    _doctorCtrl = TextEditingController(text: profile?.primaryDoctorName ?? '');
    _doctorPhoneCtrl = TextEditingController(text: profile?.primaryDoctorPhone ?? '');
    _emergencyCtrl = TextEditingController(text: profile?.emergencyContactName ?? '');
    _emergencyPhoneCtrl = TextEditingController(text: profile?.emergencyContactPhone ?? '');
    _allergiesCtrl = TextEditingController(text: profile?.allergies ?? '');
    _conditionsCtrl = TextEditingController(text: profile?.medicalConditions ?? '');
    _bloodGroup = profile?.bloodGroup;
    _dob = profile?.dateOfBirth;
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _doctorCtrl, _doctorPhoneCtrl, _emergencyCtrl, _emergencyPhoneCtrl, _allergiesCtrl, _conditionsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildAvatarSection(context),
              const SizedBox(height: 20),
              _buildCard('Personal Information', [
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outlined)), validator: (v) => v == null || v.isEmpty ? 'Name required' : null),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDob,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.cake_outlined)),
                    child: Text(_dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Tap to select', style: TextStyle(color: _dob != null ? null : Colors.grey)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _bloodGroup,
                  decoration: const InputDecoration(labelText: 'Blood Group', prefixIcon: Icon(Icons.bloodtype_outlined)),
                  hint: const Text('Select'),
                  items: _bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _bloodGroup = v),
                ),
              ]),
              const SizedBox(height: 12),
              _buildCard('Medical Information', [
                TextFormField(controller: _allergiesCtrl, decoration: const InputDecoration(labelText: 'Known Allergies', prefixIcon: Icon(Icons.warning_outlined), hintText: 'e.g. Penicillin, NSAIDs'), maxLines: 2),
                const SizedBox(height: 12),
                TextFormField(controller: _conditionsCtrl, decoration: const InputDecoration(labelText: 'Medical Conditions', prefixIcon: Icon(Icons.local_hospital_outlined), hintText: 'e.g. Glaucoma, Hypertension, Diabetes'), maxLines: 2),
              ]),
              const SizedBox(height: 12),
              _buildCard('Doctor Contact', [
                TextFormField(controller: _doctorCtrl, decoration: const InputDecoration(labelText: 'Primary Doctor Name', prefixIcon: Icon(Icons.medical_services_outlined))),
                const SizedBox(height: 12),
                TextFormField(controller: _doctorPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Doctor Phone', prefixIcon: Icon(Icons.phone_outlined))),
              ]),
              const SizedBox(height: 12),
              _buildCard('Emergency Contact', [
                TextFormField(controller: _emergencyCtrl, decoration: const InputDecoration(labelText: 'Emergency Contact Name', prefixIcon: Icon(Icons.emergency_outlined))),
                const SizedBox(height: 12),
                TextFormField(controller: _emergencyPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Emergency Phone', prefixIcon: Icon(Icons.phone_outlined))),
              ]),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Profile'),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
            child: Icon(Icons.person_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
          ),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1980),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<MedicationRepository>();
    final profile = UserProfile(
      id: repo.userProfile?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      dateOfBirth: _dob,
      bloodGroup: _bloodGroup,
      primaryDoctorName: _doctorCtrl.text.trim().isEmpty ? null : _doctorCtrl.text.trim(),
      primaryDoctorPhone: _doctorPhoneCtrl.text.trim().isEmpty ? null : _doctorPhoneCtrl.text.trim(),
      emergencyContactName: _emergencyCtrl.text.trim().isEmpty ? null : _emergencyCtrl.text.trim(),
      emergencyContactPhone: _emergencyPhoneCtrl.text.trim().isEmpty ? null : _emergencyPhoneCtrl.text.trim(),
      allergies: _allergiesCtrl.text.trim().isEmpty ? null : _allergiesCtrl.text.trim(),
      medicalConditions: _conditionsCtrl.text.trim().isEmpty ? null : _conditionsCtrl.text.trim(),
    );
    repo.updateUserProfile(profile);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Profile saved!')));
  }
}
