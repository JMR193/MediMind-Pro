import 'package:flutter/material.dart';
import '../../../domain/models/medication.dart';
import '../../core/apple_glass_decorations.dart';
import '../companion/medi_buddy_character.dart';
import 'animated_water_wave_tracker.dart';
import 'interactive_3d_pill_viewer.dart';
import 'ophthalmic_3d_drop_simulator.dart';
import 'realistic_3d_medicine_card.dart';

class VisualLabScreen extends StatefulWidget {
  const VisualLabScreen({super.key});

  @override
  State<VisualLabScreen> createState() => _VisualLabScreenState();
}

class _VisualLabScreenState extends State<VisualLabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MediBuddyMood _selectedMood = MediBuddyMood.happy;
  MediBuddyOutfit _selectedOutfit = MediBuddyOutfit.doctor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.view_in_ar_rounded, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('3D Visual Studio & Pip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7C3AED),
          indicatorColor: const Color(0xFF7C3AED),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.medication_liquid_rounded, size: 20), text: '3D Pill Lab'),
            Tab(icon: Icon(Icons.face_rounded, size: 20), text: 'MediBuddy Pip'),
            Tab(icon: Icon(Icons.water_drop_rounded, size: 20), text: 'Fluid & Drops'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: 3D Pill & Capsule Inspector
          _build3dPillLab(),

          // Tab 2: MediBuddy Pip Character Studio
          _buildMediBuddyStudio(),

          // Tab 3: Hydration & Ophthalmic Drop Simulators
          _buildFluidSimulators(),
        ],
      ),
    );
  }

  Widget _build3dPillLab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Interactive 3D Medication Inspector',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Touch and drag anywhere on the 3D canvas to rotate medications in real-time space with realistic specular lighting.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Central 3D Pill Canvas
          const Interactive3dPillViewer(size: 230, autoRotate: true),
          const SizedBox(height: 24),

          // Educational Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF7C3AED), size: 20),
                      SizedBox(width: 8),
                      Text('Visual Pill Verification Benefit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Multi-attribute 3D visual verification reduces patient medication administration errors by over 47%, particularly for seniors managing multiple daily generic prescriptions.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Realistic 3D Pharmaceutical Cards Showcase
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Realistic 3D Medication Cards',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Interactive micro-tilt on drag, procedural 3D specular rendering & fluid dynamics:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),

          Realistic3dMedicineCard(
            medication: Medication(
              id: 'sample_tab',
              name: 'Atorvastatin Calcium',
              strength: '20 mg',
              category: MedCategory.oral,
              dosageUnit: DosageUnit.tablets,
              dosageAmount: 1,
              instruction: AdminInstruction.atBedtime,
              scheduleTimes: ['21:00'],
              totalInventoryCount: 28,
              refillThreshold: 7,
              colorHex: '#0284C7',
              iconName: 'tablet',
            ),
          ),
          Realistic3dMedicineCard(
            medication: Medication(
              id: 'sample_cap',
              name: 'Amoxicillin Trihydrate',
              strength: '500 mg',
              category: MedCategory.oral,
              dosageUnit: DosageUnit.capsules,
              dosageAmount: 1,
              instruction: AdminInstruction.withMeal,
              scheduleTimes: ['08:00', '14:00', '20:00'],
              totalInventoryCount: 14,
              refillThreshold: 5,
              colorHex: '#F43F5E',
              iconName: 'capsule',
            ),
          ),
          Realistic3dMedicineCard(
            medication: Medication(
              id: 'sample_drop',
              name: 'Timolol Maleate Ophthalmic',
              strength: '0.5%',
              category: MedCategory.eyeDrop,
              dosageUnit: DosageUnit.drops,
              dosageAmount: 1,
              instruction: AdminInstruction.beforeMeal,
              scheduleTimes: ['08:00', '20:00'],
              totalInventoryCount: 5,
              refillThreshold: 10,
              colorHex: '#7C3AED',
              iconName: 'eye_drop',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediBuddyStudio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Pip • Your Emotional Health Companion',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap Pip to hear his voice! Drag over Pip to have his pupils follow your touch.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Pip Character Centerpiece
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
                radius: 0.85,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: MediBuddyCharacter(
              size: 200,
              mood: _selectedMood,
              outfit: _selectedOutfit,
              interactive: true,
              enableVoiceOnTap: true,
            ),
          ),
          const SizedBox(height: 20),

          // Mood Selector
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Pip\'s Expressions & Moods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MediBuddyMood.values.map((m) {
                final isSelected = _selectedMood == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(m.name.toUpperCase(), style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF7C3AED).withAlpha(40),
                    side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent),
                    onSelected: (val) {
                      if (val) {
                        AppleGlassDecorations.lightHaptic();
                        setState(() => _selectedMood = m);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Outfit Wardrobe Selector
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Pip\'s Wardrobe & Roles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MediBuddyOutfit.values.map((o) {
                final isSelected = _selectedOutfit == o;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(o.name.toUpperCase(), style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0284C7).withAlpha(40),
                    side: BorderSide(color: isSelected ? const Color(0xFF0284C7) : Colors.transparent),
                    onSelected: (val) {
                      if (val) {
                        AppleGlassDecorations.lightHaptic();
                        setState(() => _selectedOutfit = o);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFluidSimulators() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Animated Water Wave Hydration Tracker
          const AnimatedWaterWaveTracker(),
          const SizedBox(height: 20),

          // 3D Ophthalmic Eye Drop Simulator
          const Ophthalmic3dDropSimulator(),
        ],
      ),
    );
  }
}
