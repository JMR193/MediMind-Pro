import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/clinical_taper.dart';
import '../../../domain/models/medication.dart';
import '../../core/theme.dart';
import 'punctal_occlusion_screen.dart';

/// Comprehensive Eye Hospital & Post-Operative Clinical Care Hub
/// Built for Cataract, LASIK, Glaucoma, and Keratoplasty post-op patients.
/// Provides 1-tap clinical regimens, formulation sequencing ladder,
/// 5-minute washout spacing timer, steroid taper tracker, and RSVP emergency triage.
class EyeHospitalPostOpHub extends StatefulWidget {
  const EyeHospitalPostOpHub({super.key});

  @override
  State<EyeHospitalPostOpHub> createState() => _EyeHospitalPostOpHubState();
}

class _EyeHospitalPostOpHubState extends State<EyeHospitalPostOpHub> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Active spacing timer state
  Timer? _spacingTimer;
  int _spacingSecondsRemaining = 0;
  bool _isSpacingActive = false;

  // Selected Operative Eye
  String _selectedEye = 'Left Eye (OS)';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _spacingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startSpacingTimer(int minutes) {
    _spacingTimer?.cancel();
    setState(() {
      _spacingSecondsRemaining = minutes * 60;
      _isSpacingActive = true;
    });

    _spacingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_spacingSecondsRemaining > 1) {
        setState(() {
          _spacingSecondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _spacingSecondsRemaining = 0;
          _isSpacingActive = false;
        });
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2D6A4F),
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Safe to administer next eye drop! Tear film restored.')),
              ],
            ),
          ),
        );
      }
    });
  }

  void _cancelSpacingTimer() {
    _spacingTimer?.cancel();
    setState(() {
      _spacingSecondsRemaining = 0;
      _isSpacingActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        final ophthalmicMeds = repo.activeMedications
            .where((m) => m.isOphthalmic)
            .toList();

        // Sort by formulation hierarchy: Solution -> Suspension -> Emulsion -> Gel -> Ointment
        ophthalmicMeds.sort((a, b) => a.ophthalmicFormulation.index.compareTo(b.ophthalmicFormulation.index));

        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ophthalmic Specialty & Post-Op Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Glaucoma • Retina • Cornea • Orbit Care', style: TextStyle(fontSize: 11, color: Color(0xFF52B788))),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFF2D6A4F),
              labelColor: const Color(0xFF2D6A4F),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.medication_outlined, size: 20), text: 'Drop Ladder'),
                Tab(icon: Icon(Icons.local_hospital_outlined, size: 20), text: 'Hospital Presets'),
                Tab(icon: Icon(Icons.trending_down, size: 20), text: 'Steroid Taper'),
                Tab(icon: Icon(Icons.shield_outlined, size: 20), text: 'Post-Op Rules & RSVP'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDropLadderTab(context, ophthalmicMeds, repo, isDark),
              _buildHospitalPresetsTab(context, repo),
              _buildTaperTrackerTab(context, ophthalmicMeds, repo),
              _buildPostOpRulesTab(context),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────
  // Tab 1: Clinical Formulation Ladder & Washout Spacing
  // ──────────────────────────────────────────────────────────
  Widget _buildDropLadderTab(BuildContext context, List<Medication> meds, MedicationRepository repo, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Spacing timer active banner
        if (_isSpacingActive) _buildActiveTimerCard(),
        const SizedBox(height: 12),

        // Operative Eye Selector
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye, color: Color(0xFF2D6A4F)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Operative Eye', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Target Eye for Drops', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedEye,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'Right Eye (OD)', child: Text('Right Eye (OD)')),
                    DropdownMenuItem(value: 'Left Eye (OS)', child: Text('Left Eye (OS)')),
                    DropdownMenuItem(value: 'Both Eyes (OU)', child: Text('Both Eyes (OU)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedEye = v);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Spacing & Punctal Occlusion Action Bar
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.timer_outlined, size: 18),
                label: const Text('Start 5m Gap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => _startSpacingTimer(5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D6A4F),
                  side: const BorderSide(color: Color(0xFF2D6A4F)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.touch_app_outlined, size: 18),
                label: const Text('60s Occlusion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PunctalOcclusionScreen()));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Formulation Hierarchy Guide Header
        Row(
          children: [
            const Icon(Icons.format_list_numbered, color: Color(0xFF2D6A4F), size: 18),
            const SizedBox(width: 8),
            const Text('Clinical Administration Hierarchy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF2D6A4F).withAlpha(26), borderRadius: BorderRadius.circular(8)),
              child: const Text('5-min gap between each', style: TextStyle(fontSize: 10, color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (meds.isEmpty)
          _buildEmptyMedsPrompt(context)
        else
          ...meds.asMap().entries.map((entry) => _buildLadderItem(entry.key + 1, entry.value, repo, isDark)),
      ],
    );
  }

  Widget _buildActiveTimerCard() {
    final mins = _spacingSecondsRemaining ~/ 60;
    final secs = _spacingSecondsRemaining % 60;
    final progress = 1.0 - (_spacingSecondsRemaining / (5 * 60));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withAlpha(77),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Washout Prevention Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Tear film requires 5 minutes to absorb medication.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: _cancelSpacingTimer,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF74C69D)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLadderItem(int stepNumber, Medication med, MedicationRepository repo, bool isDark) {
    final stepInfo = _getFormulationStepInfo(med.ophthalmicFormulation);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Step Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: stepInfo.badgeColor.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$stepNumber', style: TextStyle(fontWeight: FontWeight.bold, color: stepInfo.badgeColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              med.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: stepInfo.badgeColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(stepInfo.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stepInfo.badgeColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${med.strength} • ${med.frequency} • Target: ${med.eyeTarget ?? _selectedEye}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Icon(stepInfo.actionIcon, size: 16, color: stepInfo.badgeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stepInfo.instruction,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (med.ophthalmicFormulation == OphthalmicFormulation.suspension)
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.vibration, size: 14, color: Color(0xFF2D6A4F)),
                    label: const Text('Shake 15s', style: TextStyle(fontSize: 11, color: Color(0xFF2D6A4F))),
                    onPressed: () {
                      HapticFeedback.vibrate();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(duration: Duration(seconds: 2), content: Text('Suspension agitated. Drug particles uniformly resuspended!')));
                    },
                  ),
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.timer, size: 14, color: Color(0xFF2D6A4F)),
                  label: const Text('Start 5m Gap', style: TextStyle(fontSize: 11, color: Color(0xFF2D6A4F))),
                  onPressed: () => _startSpacingTimer(5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMedsPrompt(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.remove_red_eye_outlined, size: 48, color: Colors.grey.withAlpha(120)),
            const SizedBox(height: 12),
            const Text('No Active Ophthalmic Medications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
              'Load an authentic eye hospital regimen from the presets tab or scan your discharge prescription.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.local_hospital_outlined),
              label: const Text('Browse Hospital Presets'),
              onPressed: () => _tabController.animateTo(1),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Tab 2: Authentic Clinical Subspecialty Preset Regimens
  // ──────────────────────────────────────────────────────────
  Widget _buildHospitalPresetsTab(BuildContext context, MedicationRepository repo) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHospitalPresetCard(
          context: context,
          repo: repo,
          hospitalName: 'Cornea & Anterior Segment Protocol',
          procedure: 'Phacoemulsification with Foldable IOL (Post-Cataract)',
          description: 'Standard 4-drug clinical regimen: Antibiotic + 4-Week Steroid Taper + CME NSAID + Lubricant.',
          medications: [
            _PresetMed(name: 'Moxifloxacin 0.5% (Vigamox)', strength: '0.5%', form: OphthalmicFormulation.solution, freq: 'QID (4 times daily)', times: ['08:00', '12:00', '16:00', '20:00'], days: 14),
            _PresetMed(name: 'Pred Forte 1% (Prednisolone Acetate)', strength: '1%', form: OphthalmicFormulation.suspension, freq: '4-3-2-1 Weekly Taper', times: ['08:00', '12:00', '16:00', '20:00'], days: 28, hasTaper: true),
            _PresetMed(name: 'Nevanac 0.1% (Nepafenac)', strength: '0.1%', form: OphthalmicFormulation.suspension, freq: 'TID (3 times daily)', times: ['08:00', '14:00', '20:00'], days: 30),
            _PresetMed(name: 'Refresh Tears (CMC 0.5%)', strength: '0.5%', form: OphthalmicFormulation.solution, freq: 'QID (As needed)', times: ['09:00', '13:00', '17:00', '21:00'], days: 30),
          ],
        ),
        const SizedBox(height: 16),
        _buildHospitalPresetCard(
          context: context,
          repo: repo,
          hospitalName: 'Post-Cataract Fixed-Dose Combination',
          procedure: 'Post-Phacoemulsification Reduced-Bottle Regimen',
          description: 'Combines Fluoroquinolone + Dexamethasone into a single bottle, reducing instillation error.',
          medications: [
            _PresetMed(name: 'Moxicip D (Moxifloxacin + Dexamethasone)', strength: '0.5% + 0.1%', form: OphthalmicFormulation.solution, freq: 'QID (4 times daily)', times: ['08:00', '12:00', '16:00', '20:00'], days: 14),
            _PresetMed(name: 'Nevanac 0.1% (Nepafenac)', strength: '0.1%', form: OphthalmicFormulation.suspension, freq: 'TID (3 times daily)', times: ['08:00', '14:00', '20:00'], days: 30),
            _PresetMed(name: 'Vismed (Sodium Hyaluronate 0.18%)', strength: '0.18%', form: OphthalmicFormulation.solution, freq: 'QID (4 times daily)', times: ['09:00', '13:00', '17:00', '21:00'], days: 30),
          ],
        ),
        const SizedBox(height: 16),
        _buildHospitalPresetCard(
          context: context,
          repo: repo,
          hospitalName: 'Glaucoma Service Target-IOP Protocol',
          procedure: 'Triple Therapy for Primary Open-Angle Glaucoma',
          description: 'Target IOP lowering with nocturnal prostaglandin, daytime CAI/beta-blocker & alpha-2 agonist.',
          medications: [
            _PresetMed(name: 'Cosopt (Dorzolamide 2% + Timolol 0.5%)', strength: '2% / 0.5%', form: OphthalmicFormulation.solution, freq: 'BD (Twice daily)', times: ['08:00', '20:00'], days: 60),
            _PresetMed(name: 'Alphagan 0.2% (Brimonidine)', strength: '0.2%', form: OphthalmicFormulation.solution, freq: 'BD (Twice daily)', times: ['08:00', '20:00'], days: 60),
            _PresetMed(name: 'Xalatan 0.005% (Latanoprost)', strength: '0.005%', form: OphthalmicFormulation.solution, freq: 'QHS (Strictly at Bedtime)', times: ['21:30'], days: 60),
          ],
        ),
        const SizedBox(height: 16),
        _buildHospitalPresetCard(
          context: context,
          repo: repo,
          hospitalName: 'Corneal Refractive (LASIK/PRK) Surface Protocol',
          procedure: 'Post-LASIK & PRK Surface Healing Regimen',
          description: 'Prevents flap infection, controls haze with low-potency surface steroid, and heals epithelium.',
          medications: [
            _PresetMed(name: 'Moxifloxacin 0.5%', strength: '0.5%', form: OphthalmicFormulation.solution, freq: 'QID (4 times daily)', times: ['08:00', '12:00', '16:00', '20:00'], days: 7),
            _PresetMed(name: 'FML 0.1% (Fluorometholone)', strength: '0.1%', form: OphthalmicFormulation.suspension, freq: 'QID (4 times daily)', times: ['08:00', '12:00', '16:00', '20:00'], days: 14),
            _PresetMed(name: 'Hylo-Tear (Preservative-Free Tear)', strength: '0.1%', form: OphthalmicFormulation.solution, freq: 'Every 2 Hours (PRN)', times: ['08:00', '10:00', '12:00', '14:00', '16:00', '18:00', '20:00'], days: 30),
          ],
        ),
        const SizedBox(height: 16),
        _buildHospitalPresetCard(
          context: context,
          repo: repo,
          hospitalName: 'Retina & Vitreoretinal Post-Vitrectomy Protocol',
          procedure: 'Pars Plana Vitrectomy with Gas Tamponade Post-Op',
          description: 'Infection prophylaxis, steroid inflammation control, cycloplegic stabilization, and macular carotenoid nutrition.',
          medications: [
            _PresetMed(name: 'Moxifloxacin 0.5%', strength: '0.5%', form: OphthalmicFormulation.solution, freq: 'QID (4 times daily)', times: ['08:00', '12:00', '16:00', '20:00'], days: 14),
            _PresetMed(name: 'Pred Forte 1% (Prednisolone)', strength: '1%', form: OphthalmicFormulation.suspension, freq: 'QID (4 times daily)', times: ['08:00', '12:00', '16:00', '20:00'], days: 21),
            _PresetMed(name: 'Atropine 1% Eye Drops', strength: '1%', form: OphthalmicFormulation.solution, freq: 'BD (Twice daily)', times: ['08:00', '20:00'], days: 14),
            _PresetMed(name: 'PreserVision AREDS 2 Formula', strength: 'Standard', form: OphthalmicFormulation.solution, freq: 'BD with Meals', times: ['08:00', '20:00'], days: 90, isOral: true),
          ],
        ),
        const SizedBox(height: 16),
        _buildHospitalPresetCard(
          context: context,
          repo: repo,
          hospitalName: 'Orbit & Oculoplastics Eyelid Care Protocol',
          procedure: 'Blepharoplasty, Ptosis & Periorbital Suture Care',
          description: 'Suture line antibiotic ointment, Meibomian lipid barrier maintenance, and ocular surface hydration.',
          medications: [
            _PresetMed(name: 'Bacitracin Ophthalmic Ointment', strength: '500 units/g', form: OphthalmicFormulation.ointment, freq: 'At Bedtime', times: ['21:30'], days: 10),
            _PresetMed(name: 'AzaSite (Azithromycin 1%)', strength: '1%', form: OphthalmicFormulation.solution, freq: 'BD (Twice daily)', times: ['08:00', '20:00'], days: 7),
            _PresetMed(name: 'Systane Ultra Lubricant', strength: 'Standard', form: OphthalmicFormulation.solution, freq: 'QID PRN', times: ['09:00', '13:00', '17:00', '21:00'], days: 30),
          ],
        ),
      ],
    );
  }

  Widget _buildHospitalPresetCard({
    required BuildContext context,
    required MedicationRepository repo,
    required String hospitalName,
    required String procedure,
    required String description,
    required List<_PresetMed> medications,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF2D6A4F).withAlpha(26), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.healing_outlined, color: Color(0xFF2D6A4F), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hospitalName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D6A4F))),
                      Text(procedure, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 18),
            ...medications.map((m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: m.isOral ? const Color(0xFF2D6A4F) : _getFormulationStepInfo(m.form).badgeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${m.name} (${m.freq})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  Text(m.isOral ? 'Oral' : _getFormulationStepInfo(m.form).label, style: TextStyle(fontSize: 10, color: m.isOral ? const Color(0xFF2D6A4F) : _getFormulationStepInfo(m.form).badgeColor, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text('Apply Protocol to Active Cabinet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => _applyPresetToRepo(context, repo, procedure, medications),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyPresetToRepo(BuildContext context, MedicationRepository repo, String procedure, List<_PresetMed> presetMeds) {
    final now = DateTime.now();

    for (final pm in presetMeds) {
      ClinicalTaperPlan? taperPlan;
      if (pm.hasTaper) {
        taperPlan = ClinicalTaperPlan(
          id: const Uuid().v4(),
          medicationName: pm.name,
          indication: 'Post-Cataract Steroid Step-Down Protocol',
          startDate: now,
          steps: const [
            TitrationStep(stepNumber: 1, dosageAmount: 1.0, frequencyDescription: '4 times daily (QID)', timesOfDay: ['08:00', '12:00', '16:00', '20:00'], durationDays: 7, clinicalInstruction: 'Week 1: High anti-inflammatory suppression'),
            TitrationStep(stepNumber: 2, dosageAmount: 1.0, frequencyDescription: '3 times daily (TID)', timesOfDay: ['08:00', '14:00', '20:00'], durationDays: 7, clinicalInstruction: 'Week 2: Initial step-down taper'),
            TitrationStep(stepNumber: 3, dosageAmount: 1.0, frequencyDescription: 'Twice daily (BID)', timesOfDay: ['08:00', '20:00'], durationDays: 7, clinicalInstruction: 'Week 3: Maintenance taper'),
            TitrationStep(stepNumber: 4, dosageAmount: 1.0, frequencyDescription: 'Once daily (OD)', timesOfDay: ['08:00'], durationDays: 7, clinicalInstruction: 'Week 4: Final taper before cessation'),
          ],
        );
      }

      final med = Medication(
        id: const Uuid().v4(),
        name: pm.name,
        strength: pm.strength,
        category: pm.isOral
            ? MedCategory.oral
            : (pm.form == OphthalmicFormulation.ointment ? MedCategory.eyeOintment : MedCategory.eyeDrop),
        dosageUnit: pm.isOral ? DosageUnit.tablets : DosageUnit.drops,
        dosageAmount: 1.0,
        instruction: AdminInstruction.asNeeded,
        frequency: pm.freq,
        scheduleTimes: pm.times,
        startDate: now,
        endDate: now.add(Duration(days: pm.days)),
        expiryDate: now.add(const Duration(days: 180)),
        openedDate: pm.isOral ? null : now,
        afterOpeningDays: pm.isOral ? null : 28,
        totalInventoryCount: pm.hasTaper ? 2 : (pm.isOral ? 60 : 1),
        refillThreshold: pm.isOral ? 10 : 1,
        prescribingDoctor: 'Ophthalmic Specialty Protocol',
        colorHex: pm.isOral ? '#2D6A4F' : '#0284C7',
        iconName: pm.isOral ? 'pill' : 'eye_drop',
        requiresEyeDropProtocol: !pm.isOral,
        eyeTarget: pm.isOral ? null : _selectedEye,
        eyeDropGapMinutes: pm.isOral ? 0 : 5,
        contactLensWarning: !pm.isOral,
        isOintment: !pm.isOral && pm.form == OphthalmicFormulation.ointment,
        ophthalmicFormulation: pm.form,
        taperPlan: taperPlan,
      );

      repo.addMedication(med);
    }

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2D6A4F),
        content: Text('✅ $procedure applied successfully (${presetMeds.length} items scheduled)!'),
      ),
    );
    _tabController.animateTo(0);
  }

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2D6A4F),
        content: Text('✅ $procedure applied successfully (${presetMeds.length} drops scheduled)!'),
      ),
    );
    _tabController.animateTo(0);
  }

  // ──────────────────────────────────────────────────────────
  // Tab 3: Steroid Step-Down Taper Tracker
  // ──────────────────────────────────────────────────────────
  Widget _buildTaperTrackerTab(BuildContext context, List<Medication> meds, MedicationRepository repo) {
    final taperingMeds = meds.where((m) => m.taperPlan != null).toList();

    if (taperingMeds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_down, size: 64, color: Colors.grey.withAlpha(100)),
              const SizedBox(height: 12),
              const Text('No Active Tapering Drops', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              const Text(
                'Post-cataract steroid drops (e.g., Pred Forte) follow a 4-week step-down schedule (4x -> 3x -> 2x -> 1x daily).\nApply a preset or scan a prescription to track.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F), foregroundColor: Colors.white),
                onPressed: () => _tabController.animateTo(1),
                child: const Text('View Cataract Preset'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: taperingMeds.map((m) {
        final plan = m.taperPlan!;
        final currentStep = plan.currentStep;
        final progress = plan.overallProgressPercentage;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_down, color: Color(0xFF2D6A4F)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF2D6A4F).withAlpha(26), borderRadius: BorderRadius.circular(8)),
                      child: Text('Step ${currentStep.stepNumber} of ${plan.steps.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2D6A4F))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Current Schedule: ${currentStep.frequencyDescription}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(currentStep.clinicalInstruction, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.withAlpha(50),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D6A4F)),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Overall Protocol Progress: ${(progress * 100).toInt()}% completed', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const Divider(height: 20),
                ...plan.steps.map((s) {
                  final isCurrent = s.stepNumber == currentStep.stepNumber;
                  final isPast = s.stepNumber < currentStep.stepNumber;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isPast ? Icons.check_circle : (isCurrent ? Icons.play_circle_fill : Icons.radio_button_unchecked),
                          size: 16,
                          color: isPast ? const Color(0xFF52B788) : (isCurrent ? const Color(0xFF2D6A4F) : Colors.grey),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Week ${s.stepNumber}: ${s.frequencyDescription}', style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 12))),
                        Text('${s.durationDays} days', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Tab 4: Post-Op Care Rules & RSVP Emergency Triage
  // ──────────────────────────────────────────────────────────
  Widget _buildPostOpRulesTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // RSVP Red-Flag Emergency Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MediMindTheme.alertRed.withAlpha(26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MediMindTheme.alertRed, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: MediMindTheme.alertRed, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('EMERGENCY "RSVP" RED FLAGS', style: TextStyle(fontWeight: FontWeight.bold, color: MediMindTheme.alertRed, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Contact your eye surgeon immediately or visit urgent ophthalmic care if you experience any of these 4 symptoms:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MediMindTheme.alertRed),
              ),
              const SizedBox(height: 10),
              _buildRsvpItem('R', 'Redness', 'Severe or worsening eye redness spreading across the sclera.'),
              _buildRsvpItem('S', 'Sensitivity', 'Extreme photophobia (pain when looking at room light).'),
              _buildRsvpItem('V', 'Vision Loss', 'Sudden cloudiness, curtain shadow, or flashes of light.'),
              _buildRsvpItem('P', 'Pain', 'Deep throbbing ache not relieved by prescribed eye drops.'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MediMindTheme.alertRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.phone_in_talk, size: 18),
                  label: const Text('Call Eye Emergency Clinic (Speed-Dial)'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling Eye Emergency Dispatch (911 / 112 / Clinic)...')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Surgical Care Rules Checklist
        const Text('Crucial Post-Operative Rules (Weeks 1 to 4)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        _buildCareRuleCard(
          icon: Icons.nightlight_round,
          title: 'Wear Eye Shield at Night',
          description: 'Tape the clear plastic shield over your operative eye while sleeping for at least 7-14 nights to prevent accidental rubbing or pillow pressure.',
        ),
        _buildCareRuleCard(
          icon: Icons.do_not_touch,
          title: 'NEVER Rub the Operative Eye',
          description: 'Rubbing can dislodge a post-cataract corneal incision or post-LASIK corneal flap, risking severe astigmatism, dehiscence, or infection.',
        ),
        _buildCareRuleCard(
          icon: Icons.shower_outlined,
          title: 'Keep Tap Water Away from Eyes',
          description: 'Do not wash face with tap water or shampoo hair with water running down face for 7-10 days. Tap water harbors Acanthamoeba and bacterial pathogens.',
        ),
        _buildCareRuleCard(
          icon: Icons.fitness_center,
          title: 'No Straining or Heavy Lifting',
          description: 'Do not lift weights over 5 kg (10 lbs) or bend forward below the waist for 2 weeks to avoid sudden dangerous spikes in intraocular pressure (IOP).',
        ),
        _buildCareRuleCard(
          icon: Icons.soap,
          title: 'Strict Hand Hygiene',
          description: 'Always wash hands thoroughly with soap for 20 seconds before touching eye drops or eye area. Never let dropper tip touch lashes or fingers.',
        ),
      ],
    );
  }

  Widget _buildRsvpItem(String letter, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: MediMindTheme.alertRed, shape: BoxShape.circle),
            child: Center(
              child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: MediMindTheme.alertRed)),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareRuleCard({required IconData icon, required String title, required String description}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF2D6A4F).withAlpha(26), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFF2D6A4F), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Helper: Formulation Information Hierarchy
  // ──────────────────────────────────────────────────────────
  ({String label, Color badgeColor, IconData actionIcon, String instruction}) _getFormulationStepInfo(OphthalmicFormulation f) {
    switch (f) {
      case OphthalmicFormulation.solution:
        return (
          label: '1. Clear Solution',
          badgeColor: const Color(0xFF0284C7),
          actionIcon: Icons.water_drop_outlined,
          instruction: 'Instill first. Absorbs fastest through cornea without barrier.',
        );
      case OphthalmicFormulation.suspension:
        return (
          label: '2. Suspension',
          badgeColor: const Color(0xFF2D6A4F),
          actionIcon: Icons.vibration,
          instruction: 'SHAKE VIGOROUSLY for 10-15 seconds. Active particles settle at bottom.',
        );
      case OphthalmicFormulation.emulsion:
        return (
          label: '3. Emulsion',
          badgeColor: const Color(0xFF7C3AED),
          actionIcon: Icons.blur_on,
          instruction: 'Milky drop. Do not shake vigorously unless specified.',
        );
      case OphthalmicFormulation.gel:
        return (
          label: '4. Gel / Viscous',
          badgeColor: const Color(0xFFD97706),
          actionIcon: Icons.gradient,
          instruction: 'Viscous formulation. Blurs vision for 5-10 minutes.',
        );
      case OphthalmicFormulation.ointment:
        return (
          label: '5. Ointment',
          badgeColor: const Color(0xFFDC2626),
          actionIcon: Icons.nightlight_round,
          instruction: 'APPLY LAST AT BEDTIME. Creates oily barrier; blurs vision for 30m.',
        );
    }
  }
}

class _PresetMed {
  final String name;
  final String strength;
  final OphthalmicFormulation form;
  final String freq;
  final List<String> times;
  final int days;
  final bool hasTaper;
  final bool isOral;

  const _PresetMed({
    required this.name,
    required this.strength,
    required this.form,
    required this.freq,
    required this.times,
    required this.days,
    this.hasTaper = false,
    this.isOral = false,
  });
}
