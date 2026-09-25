import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/user_profile.dart';
import '../../core/apple_glass_decorations.dart';
import '../../core/one_ui_widgets.dart';

class FamilyProfilesScreen extends StatelessWidget {
  const FamilyProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        final profiles = repo.profiles;
        final activeId = repo.activeProfileId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Family & Patient Profiles'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_rounded),
                tooltip: 'Add Dependent Profile',
                onPressed: () => _showAddProfileSheet(context, repo),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OneUiWidgets.bannerCard(
                  context: context,
                  title: 'Multi-Patient Caregiver Hub',
                  subtitle: 'Manage prescriptions for yourself, elderly parents, or children in one secure app.',
                  icon: Icons.family_restroom_rounded,
                  accentColor: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 16),

                const Text('Registered Profiles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                ...profiles.map((profile) {
                  final isActive = profile.id == activeId;
                  final color = Color(int.parse(profile.colorHex.replaceAll('#', '0xFF')));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? color : Colors.grey.withAlpha(50),
                        width: isActive ? 2.0 : 1.0,
                      ),
                      boxShadow: isActive
                          ? [BoxShadow(color: color.withAlpha(30), blurRadius: 10, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: color.withAlpha(30),
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'P',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 8),
                          if (profile.isPrimaryUser)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                              child: Text('Primary', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text('Relationship:  • Blood: ', style: const TextStyle(fontSize: 12)),
                          if (profile.medicalConditions != null && profile.medicalConditions!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('Conditions: ', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ],
                      ),
                      trailing: isActive
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            )
                          : OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                AppleGlassDecorations.mediumHaptic();
                                repo.switchProfile(profile.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Switched active profile to ')),
                                );
                              },
                              child: const Text('Switch'),
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddProfileSheet(BuildContext context, MedicationRepository repo) {
    final nameController = TextEditingController();
    final relationController = TextEditingController(text: 'Parent');
    final conditionsController = TextEditingController();
    final allergiesController = TextEditingController();
    final doctorController = TextEditingController();
    String selectedBlood = 'O+';
    String selectedColor = '#0284C7';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Dependent / Family Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: relationController,
                  decoration: InputDecoration(
                    labelText: 'Relationship (e.g. Mother, Father, Child, Spouse)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: conditionsController,
                  decoration: InputDecoration(
                    labelText: 'Chronic Conditions (e.g. Glaucoma, Hypertension)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allergiesController,
                  decoration: InputDecoration(
                    labelText: 'Allergies (e.g. Penicillin, Sulfa)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doctorController,
                  decoration: InputDecoration(
                    labelText: 'Primary Doctor Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) return;
                      final newProfile = UserProfile(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        relationship: relationController.text.trim().isEmpty ? 'Family' : relationController.text.trim(),
                        bloodGroup: selectedBlood,
                        colorHex: selectedColor,
                        medicalConditions: conditionsController.text.trim(),
                        allergies: allergiesController.text.trim(),
                        primaryDoctorName: doctorController.text.trim(),
                      );
                      repo.addProfile(newProfile);
                      Navigator.pop(ctx);
                      AppleGlassDecorations.mediumHaptic();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✓ Profile "" created.')),
                      );
                    },
                    child: const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
