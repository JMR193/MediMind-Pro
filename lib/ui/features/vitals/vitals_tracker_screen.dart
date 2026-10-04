import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/clinical_vitals.dart';
import '../../core/one_ui_widgets.dart';
import '../../core/apple_glass_decorations.dart';

class VitalsTrackerScreen extends StatefulWidget {
  const VitalsTrackerScreen({super.key});

  @override
  State<VitalsTrackerScreen> createState() => _VitalsTrackerScreenState();
}

class _VitalsTrackerScreenState extends State<VitalsTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Clinical Vitals & IOP'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.favorite_rounded, size: 20), text: 'BP & Heart'),
            Tab(icon: Icon(Icons.remove_red_eye_rounded, size: 20), text: 'Glaucoma IOP'),
            Tab(icon: Icon(Icons.bloodtype_rounded, size: 20), text: 'Blood Glucose'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVitalModal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Vitals'),
      ),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final vitals = repo.activeVitals;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBpTab(context, vitals, repo),
              _buildIopTab(context, vitals, repo),
              _buildGlucoseTab(context, vitals, repo),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBpTab(BuildContext context, List<ClinicalVitalRecord> vitals, MedicationRepository repo) {
    final bpRecords = vitals.where((v) => v.systolicBp != null && v.diastolicBp != null).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OneUiWidgets.squircleCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('LATEST BLOOD PRESSURE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  Icon(Icons.favorite_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              if (bpRecords.isEmpty)
                const Text('No blood pressure readings recorded yet. Tap "Log Vitals" below.', style: TextStyle(color: Colors.grey))
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${bpRecords.first.systolicBp}/${bpRecords.first.diastolicBp}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Text('mmHg', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const Spacer(),
                    if (bpRecords.first.heartRateBpm != null)
                      Text('❤️ ${bpRecords.first.heartRateBpm} BPM', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBpColor(bpRecords.first.bpCategory).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bpRecords.first.bpCategoryLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getBpColor(bpRecords.first.bpCategory)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Blood Pressure History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (bpRecords.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No BP history available.')))
        else
          ...bpRecords.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getBpColor(r.bpCategory).withAlpha(30),
                    child: Icon(Icons.favorite_rounded, color: _getBpColor(r.bpCategory), size: 20),
                  ),
                  title: Text('${r.systolicBp}/${r.diastolicBp} mmHg  •  ${r.heartRateBpm ?? "--"} BPM', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('MMM dd, yyyy  •  hh:mm a').format(r.timestamp)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => repo.deleteVitalRecord(r.id),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildIopTab(BuildContext context, List<ClinicalVitalRecord> vitals, MedicationRepository repo) {
    final iopRecords = vitals.where((v) => v.iopRightEyeOd != null || v.iopLeftEyeOs != null).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OneUiWidgets.squircleCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GLAUCOMA INTRAOCULAR PRESSURE (IOP)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  Icon(Icons.remove_red_eye_rounded, color: Color(0xFF0284C7), size: 20),
                ],
              ),
              const SizedBox(height: 12),
              if (iopRecords.isEmpty)
                const Text('No eye pressure readings logged. Normal target is 10–21 mmHg.', style: TextStyle(color: Colors.grey))
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('RIGHT EYE (OD)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${iopRecords.first.iopRightEyeOd ?? "--"} mmHg', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(height: 36, width: 1, color: Colors.grey.withAlpha(50)),
                    Column(
                      children: [
                        const Text('LEFT EYE (OS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${iopRecords.first.iopLeftEyeOs ?? "--"} mmHg', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Diurnal IOP Pressure Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (iopRecords.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No IOP measurements recorded.')))
        else
          ...iopRecords.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.remove_red_eye_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                  title: Text('OD: ${r.iopRightEyeOd ?? "--"} mmHg  |  OS: ${r.iopLeftEyeOs ?? "--"} mmHg', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('MMM dd, yyyy  •  hh:mm a').format(r.timestamp)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => repo.deleteVitalRecord(r.id),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildGlucoseTab(BuildContext context, List<ClinicalVitalRecord> vitals, MedicationRepository repo) {
    final glucoseRecords = vitals.where((v) => v.bloodGlucoseMgDl != null).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OneUiWidgets.squircleCard(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LATEST BLOOD GLUCOSE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  Icon(Icons.bloodtype_rounded, color: Color(0xFFE11D48), size: 20),
                ],
              ),
              const SizedBox(height: 12),
              if (glucoseRecords.isEmpty)
                const Text('No blood glucose records logged.', style: TextStyle(color: Colors.grey))
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${glucoseRecords.first.bloodGlucoseMgDl?.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Text('mg/dL', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const Spacer(),
                    Text(
                      glucoseRecords.first.glucoseTiming?.name.toUpperCase() ?? 'RANDOM',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Blood Sugar History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (glucoseRecords.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No glucose logs recorded.')))
        else
          ...glucoseRecords.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFE4E6),
                    child: Icon(Icons.bloodtype_rounded, color: Color(0xFFE11D48), size: 20),
                  ),
                  title: Text('${r.bloodGlucoseMgDl?.toStringAsFixed(0)} mg/dL (${r.glucoseTiming?.name ?? "Random"})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('MMM dd, yyyy  •  hh:mm a').format(r.timestamp)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => repo.deleteVitalRecord(r.id),
                  ),
                ),
              )),
      ],
    );
  }

  Color _getBpColor(BpCategory? category) {
    switch (category) {
      case BpCategory.normal:
        return Colors.green;
      case BpCategory.elevated:
        return Colors.amber.shade700;
      case BpCategory.stage1Hypertension:
        return Colors.orange;
      case BpCategory.stage2Hypertension:
      case BpCategory.hypertensiveCrisis:
        return Colors.red;
      case BpCategory.hypotension:
        return Colors.purple;
      case null:
        return Colors.grey;
    }
  }

  void _showAddVitalModal(BuildContext context) {
    AppleGlassDecorations.lightHaptic();
    final sysCtrl = TextEditingController();
    final diaCtrl = TextEditingController();
    final hrCtrl = TextEditingController();
    final iopOdCtrl = TextEditingController();
    final iopOsCtrl = TextEditingController();
    final glucoseCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Record Clinical Measurements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Systolic BP', suffixText: 'mmHg', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: diaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Diastolic BP', suffixText: 'mmHg', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hrCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Heart Rate (BPM)', suffixText: 'bpm', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: iopOdCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Right Eye IOP (OD)', suffixText: 'mmHg', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: iopOsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Left Eye IOP (OS)', suffixText: 'mmHg', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: glucoseCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Blood Glucose', suffixText: 'mg/dL', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final sys = int.tryParse(sysCtrl.text.trim());
                  final dia = int.tryParse(diaCtrl.text.trim());
                  final hr = int.tryParse(hrCtrl.text.trim());
                  final od = double.tryParse(iopOdCtrl.text.trim());
                  final os = double.tryParse(iopOsCtrl.text.trim());
                  final glu = double.tryParse(glucoseCtrl.text.trim());

                  if (sys != null || dia != null || hr != null || od != null || os != null || glu != null) {
                    final repo = context.read<MedicationRepository>();
                    final record = ClinicalVitalRecord(
                      id: const Uuid().v4(),
                      profileId: repo.activeProfileId,
                      timestamp: DateTime.now(),
                      systolicBp: sys,
                      diastolicBp: dia,
                      heartRateBpm: hr,
                      iopRightEyeOd: od,
                      iopLeftEyeOs: os,
                      bloodGlucoseMgDl: glu,
                      glucoseTiming: GlucoseMealTiming.random,
                    );
                    repo.addVitalRecord(record);
                    Navigator.pop(ctx);
                    AppleGlassDecorations.mediumHaptic();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vital signs saved successfully')));
                  }
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
