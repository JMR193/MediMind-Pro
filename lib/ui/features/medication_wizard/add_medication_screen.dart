import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../core/utils.dart';
import '../../core/theme.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? editMedication;

  const AddMedicationScreen({super.key, this.editMedication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _rxCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  MedCategory _category = MedCategory.oral;
  DosageUnit _dosageUnit = DosageUnit.tablets;
  double _dosageAmount = 1.0;
  AdminInstruction _instruction = AdminInstruction.withMeal;
  String _frequency = 'Once daily';
  List<TimeOfDay> _scheduleTimes = [const TimeOfDay(hour: 8, minute: 0)];
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _expiryDate;
  DateTime? _openedDate;
  int _afterOpeningDays = 28;
  int _inventory = 30;
  int _refillThreshold = 5;
  String _colorHex = '#0284C7';
  String _iconName = 'pill';
  bool _isHighPriority = false;
  bool _isEyeDrop = false;
  bool _isOintment = false;
  String? _eyeTarget;
  int _eyeGapMinutes = 5;
  bool _contactLensWarning = false;

  static const _colorOptions = [
    '#0284C7', '#059669', '#D97706', '#DC2626',
    '#7C3AED', '#0D9488', '#DB2777', '#65A30D',
  ];

  @override
  void initState() {
    super.initState();
    final med = widget.editMedication;
    if (med != null) {
      _nameCtrl.text = med.name;
      _strengthCtrl.text = med.strength;
      _doctorCtrl.text = med.prescribingDoctor ?? '';
      _rxCtrl.text = med.rxNumber ?? '';
      _notesCtrl.text = med.clinicalNotes ?? '';
      _category = med.category;
      _dosageUnit = med.dosageUnit;
      _dosageAmount = med.dosageAmount;
      _instruction = med.instruction;
      _frequency = med.frequency;
      _scheduleTimes = med.scheduleTimes.map((t) {
        final parts = t.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
      _startDate = med.startDate;
      _endDate = med.endDate;
      _expiryDate = med.expiryDate;
      _openedDate = med.openedDate;
      _afterOpeningDays = med.afterOpeningDays ?? 28;
      _inventory = med.totalInventoryCount;
      _refillThreshold = med.refillThreshold;
      _colorHex = med.colorHex;
      _iconName = med.iconName;
      _isHighPriority = med.isHighPriorityAlarm;
      _isEyeDrop = med.requiresEyeDropProtocol || med.category == MedCategory.eyeDrop || med.category == MedCategory.eyeOintment;
      _isOintment = med.isOintment || med.category == MedCategory.eyeOintment;
      _eyeTarget = med.eyeTarget;
      _eyeGapMinutes = med.eyeDropGapMinutes;
      _contactLensWarning = med.contactLensWarning;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _strengthCtrl.dispose();
    _doctorCtrl.dispose();
    _rxCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editMedication == null ? 'Add Medication' : 'Edit Medication'),
        actions: [
          TextButton.icon(
            onPressed: _saveMedication,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Medication Identity', _buildIdentitySection()),
              _buildSection('Dosage, Frequency & Dates', _buildDosageSection()),
              _buildSection('Eye Medication Protocol & Timing', _buildEyeDropSection()),
              _buildSection('Inventory & Expiry Tracking', _buildInventorySection()),
              _buildSection('Clinical Details & Prescriber', _buildClinicalSection()),
              _buildSection('Appearance & Priority', _buildAppearanceSection()),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saveMedication,
                icon: const Icon(Icons.medication_outlined),
                label: const Text('Save Medication Schedule'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        ),
        content,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildIdentitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Medication Name *', hintText: 'e.g. Latanoprost, Timolol, Atorvastatin', prefixIcon: Icon(Icons.medication_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _strengthCtrl,
              decoration: const InputDecoration(labelText: 'Strength / Concentration *', hintText: 'e.g. 500 mg, 0.005%, 100 mcg/dose', prefixIcon: Icon(Icons.science_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Strength is required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MedCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Medication Category', prefixIcon: Icon(Icons.category_outlined)),
              items: MedCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(medCategoryLabel(c)))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _category = v;
                    if (v == MedCategory.eyeDrop) {
                      _iconName = 'eye_drop';
                      _isEyeDrop = true;
                      _isOintment = false;
                      _dosageUnit = DosageUnit.drops;
                    } else if (v == MedCategory.eyeOintment) {
                      _iconName = 'eye_drop';
                      _isEyeDrop = true;
                      _isOintment = true;
                      _dosageUnit = DosageUnit.applyTopical;
                    } else if (v == MedCategory.inhaler) {
                      _iconName = 'inhaler';
                      _dosageUnit = DosageUnit.puffs;
                    } else if (v == MedCategory.injectable) {
                      _iconName = 'syringe';
                      _dosageUnit = DosageUnit.units;
                    } else {
                      _isEyeDrop = false;
                      _isOintment = false;
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: _dosageAmount.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Dose Amount'),
                    onChanged: (v) => _dosageAmount = double.tryParse(v) ?? 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<DosageUnit>(
                    initialValue: _dosageUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: DosageUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(dosageUnitLabel(u)))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _dosageUnit = v); },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency', prefixIcon: Icon(Icons.repeat)),
              items: ['Once daily', 'Twice daily', 'Three times daily', 'Four times daily', 'At bedtime', 'As needed (PRN)', 'Custom']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _frequency = v;
                    if (v == 'Twice daily' && _scheduleTimes.length < 2) {
                      _scheduleTimes = [const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 20, minute: 0)];
                    } else if (v == 'Three times daily' && _scheduleTimes.length < 3) {
                      _scheduleTimes = [const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 14, minute: 0), const TimeOfDay(hour: 20, minute: 0)];
                    } else if (v == 'At bedtime') {
                      _scheduleTimes = [const TimeOfDay(hour: 21, minute: 30)];
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AdminInstruction>(
              initialValue: _instruction,
              decoration: const InputDecoration(labelText: 'Instructions', prefixIcon: Icon(Icons.restaurant_outlined)),
              items: AdminInstruction.values.map((i) => DropdownMenuItem(value: i, child: Text(adminInstructionLabel(i)))).toList(),
              onChanged: (v) { if (v != null) setState(() => _instruction = v); },
            ),
            const SizedBox(height: 16),
            // Start Date and End Date Pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Start Date', prefixIcon: Icon(Icons.event)),
                      child: Text(_startDate != null ? DateFormat('MMM dd, yyyy').format(_startDate!) : 'Today'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickEndDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'End Date', prefixIcon: Icon(Icons.event_busy)),
                      child: Text(_endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Ongoing'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Specific Reminder Times', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                TextButton.icon(
                  onPressed: _addScheduleTime,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Time'),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_scheduleTimes.length, (i) {
                final t = _scheduleTimes[i];
                return Chip(
                  avatar: const Icon(Icons.access_time, size: 16),
                  label: Text('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'),
                  deleteIcon: _scheduleTimes.length > 1 ? const Icon(Icons.close, size: 14) : null,
                  onDeleted: _scheduleTimes.length > 1 ? () => setState(() => _scheduleTimes.removeAt(i)) : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEyeDropSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Eye Medication Protocol'),
              subtitle: const Text('Enables ophthalmic timing assistant, gap countdown & contact lens warning'),
              secondary: const Icon(Icons.remove_red_eye_outlined),
              value: _isEyeDrop,
              onChanged: (v) => setState(() => _isEyeDrop = v),
            ),
            if (_isEyeDrop) ...[
              const Divider(),
              SwitchListTile(
                title: const Text('Eye Ointment Form'),
                subtitle: const Text('Ointments must be applied LAST, after all liquid drops'),
                value: _isOintment,
                onChanged: (v) => setState(() => _isOintment = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _eyeTarget ?? 'Both Eyes (OU)',
                decoration: const InputDecoration(labelText: 'Target Eye', prefixIcon: Icon(Icons.visibility_outlined)),
                items: ['Left Eye (OS)', 'Right Eye (OD)', 'Both Eyes (OU)']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _eyeTarget = v),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Required Gap to Other Drops:'),
                  DropdownButton<int>(
                    value: _eyeGapMinutes,
                    items: [5, 10, 15, 20, 30].map((m) => DropdownMenuItem(value: m, child: Text('$m min'))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _eyeGapMinutes = v); },
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Remove Contact Lenses'),
                subtitle: const Text('Warn to remove lenses and wait 15 min before re-inserting'),
                value: _contactLensWarning,
                onChanged: (v) => setState(() => _contactLensWarning = v),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _inventory.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Bottle/Pack Quantity', prefixIcon: Icon(Icons.inventory_2_outlined)),
                    onChanged: (v) => _inventory = int.tryParse(v) ?? 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _refillThreshold.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Refill Alert Threshold', prefixIcon: Icon(Icons.warning_outlined)),
                    onChanged: (v) => _refillThreshold = int.tryParse(v) ?? 5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickExpiryDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Medication Expiry Date', prefixIcon: Icon(Icons.event_busy_outlined)),
                      child: Text(_expiryDate != null ? DateFormat('MMM dd, yyyy').format(_expiryDate!) : 'Not set'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickOpenedDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date Opened', prefixIcon: Icon(Icons.hourglass_top_outlined)),
                      child: Text(_openedDate != null ? DateFormat('MMM dd, yyyy').format(_openedDate!) : 'Unopened'),
                    ),
                  ),
                ),
              ],
            ),
            if (_openedDate != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discard after opening (days):'),
                  DropdownButton<int>(
                    value: _afterOpeningDays,
                    items: [14, 28, 30, 60, 90].map((d) => DropdownMenuItem(value: d, child: Text('$d days'))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _afterOpeningDays = v); },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _doctorCtrl,
              decoration: const InputDecoration(labelText: 'Prescribing Doctor', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rxCtrl,
              decoration: const InputDecoration(labelText: 'Rx Number / Pharmacy Ref', prefixIcon: Icon(Icons.tag)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Doctor Clinical Notes & Warnings', prefixIcon: Icon(Icons.note_alt_outlined)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('High Priority Critical Alarm'),
              subtitle: const Text('Bypasses Do Not Disturb; persistent full-screen alarm'),
              secondary: const Icon(Icons.notification_important_outlined, color: MediMindTheme.alertRed),
              value: _isHighPriority,
              onChanged: (v) => setState(() => _isHighPriority = v),
            ),
            const SizedBox(height: 12),
            const Text('Color Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colorOptions.map((c) {
                final isSel = _colorHex == c;
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = c),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: hexToColor(c),
                      shape: BoxShape.circle,
                      border: Border.all(color: isSel ? Colors.black : Colors.transparent, width: 2.5),
                    ),
                    child: isSel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _pickOpenedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _openedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _openedDate = picked);
  }

  Future<void> _addScheduleTime() async {
    final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (picked != null && !_scheduleTimes.contains(picked)) {
      setState(() => _scheduleTimes.add(picked));
    }
  }

  void _saveMedication() {
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<MedicationRepository>();
    final times = _scheduleTimes.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList();

    final med = Medication(
      id: widget.editMedication?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      strength: _strengthCtrl.text.trim(),
      category: _category,
      dosageUnit: _dosageUnit,
      dosageAmount: _dosageAmount,
      instruction: _instruction,
      frequency: _frequency,
      scheduleTimes: times,
      startDate: _startDate ?? DateTime.now(),
      endDate: _endDate,
      expiryDate: _expiryDate,
      openedDate: _openedDate,
      afterOpeningDays: _afterOpeningDays,
      totalInventoryCount: _inventory,
      refillThreshold: _refillThreshold,
      prescribingDoctor: _doctorCtrl.text.trim().isEmpty ? null : _doctorCtrl.text.trim(),
      rxNumber: _rxCtrl.text.trim().isEmpty ? null : _rxCtrl.text.trim(),
      clinicalNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      colorHex: _colorHex,
      iconName: _iconName,
      isHighPriorityAlarm: _isHighPriority,
      requiresEyeDropProtocol: _isEyeDrop,
      eyeTarget: _eyeTarget,
      eyeDropGapMinutes: _eyeGapMinutes,
      contactLensWarning: _contactLensWarning,
      isOintment: _isOintment,
    );

    if (widget.editMedication == null) {
      repo.addMedication(med);
    } else {
      repo.updateMedication(med);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ ${med.name} saved successfully!'), backgroundColor: MediMindTheme.successGreen),
    );
  }
}
