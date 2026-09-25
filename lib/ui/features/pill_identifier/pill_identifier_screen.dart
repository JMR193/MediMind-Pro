import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/medication.dart';
import '../../core/theme.dart';

class PillReferenceItem {
  final String name;
  final String strength;
  final PillShape shape;
  final String colorName;
  final Color visualColor;
  final String imprint;
  final PillScoring scoring;
  final MedCategory category;
  final String indications;

  const PillReferenceItem({
    required this.name,
    required this.strength,
    required this.shape,
    required this.colorName,
    required this.visualColor,
    required this.imprint,
    required this.scoring,
    required this.category,
    required this.indications,
  });
}

class PillIdentifierScreen extends StatefulWidget {
  const PillIdentifierScreen({super.key});

  @override
  State<PillIdentifierScreen> createState() => _PillIdentifierScreenState();
}

class _PillIdentifierScreenState extends State<PillIdentifierScreen> {
  final _searchCtrl = TextEditingController();
  final _imprintCtrl = TextEditingController();

  PillShape? _selectedShape;
  String? _selectedColorName;
  PillScoring? _selectedScoring;
  bool _onlyMyCabinet = false;

  static const List<String> _colorNames = [
    'All',
    'White',
    'Blue',
    'Yellow',
    'Red',
    'Green',
    'Orange',
    'Pink',
    'Clear/Teal',
  ];

  static final List<PillReferenceItem> _referenceLibrary = [
    const PillReferenceItem(
      name: 'Atorvastatin',
      strength: '20 mg',
      shape: PillShape.oval,
      colorName: 'White',
      visualColor: Color(0xFFF8FAFC),
      imprint: 'ATV 20',
      scoring: PillScoring.unscored,
      category: MedCategory.oral,
      indications: 'Cholesterol & cardiovascular risk reduction',
    ),
    const PillReferenceItem(
      name: 'Metformin HCl',
      strength: '500 mg',
      shape: PillShape.round,
      colorName: 'White',
      visualColor: Color(0xFFFFFFFF),
      imprint: 'M 500',
      scoring: PillScoring.singleScored,
      category: MedCategory.oral,
      indications: 'Type 2 Diabetes Mellitus glycemic control',
    ),
    const PillReferenceItem(
      name: 'Lisinopril',
      strength: '10 mg',
      shape: PillShape.diamond,
      colorName: 'Pink',
      visualColor: Color(0xFFF472B6),
      imprint: 'L 10',
      scoring: PillScoring.unscored,
      category: MedCategory.oral,
      indications: 'Hypertension and heart failure management',
    ),
    const PillReferenceItem(
      name: 'Amlodipine Besylate',
      strength: '5 mg',
      shape: PillShape.round,
      colorName: 'White',
      visualColor: Color(0xFFFFFFFF),
      imprint: 'AML 5',
      scoring: PillScoring.unscored,
      category: MedCategory.oral,
      indications: 'Calcium channel blocker for hypertension & angina',
    ),
    const PillReferenceItem(
      name: 'Amoxicillin Trihydrate',
      strength: '500 mg',
      shape: PillShape.capsule,
      colorName: 'Red',
      visualColor: Color(0xFFEF4444),
      imprint: 'AMX 500',
      scoring: PillScoring.unscored,
      category: MedCategory.oral,
      indications: 'Broad-spectrum penicillin antibiotic',
    ),
    const PillReferenceItem(
      name: 'Levothyroxine Sodium',
      strength: '100 mcg',
      shape: PillShape.round,
      colorName: 'Yellow',
      visualColor: Color(0xFFFBBF24),
      imprint: 'LV 100',
      scoring: PillScoring.singleScored,
      category: MedCategory.oral,
      indications: 'Thyroid hormone replacement (empty stomach)',
    ),
    const PillReferenceItem(
      name: 'Omeprazole',
      strength: '20 mg',
      shape: PillShape.capsule,
      colorName: 'Orange',
      visualColor: Color(0xFFF97316),
      imprint: 'OMEP 20',
      scoring: PillScoring.unscored,
      category: MedCategory.oral,
      indications: 'Proton-pump inhibitor for acid reflux & GERD',
    ),
    const PillReferenceItem(
      name: 'Latanoprost 0.005%',
      strength: '1 drop OS',
      shape: PillShape.dropperBottle,
      colorName: 'Clear/Teal',
      visualColor: Color(0xFF14B8A6),
      imprint: 'Teal Cap',
      scoring: PillScoring.unscored,
      category: MedCategory.eyeDrop,
      indications: 'Prostaglandin analogue for ocular hypertension & glaucoma',
    ),
    const PillReferenceItem(
      name: 'Timolol Maleate 0.5%',
      strength: '1 drop OD',
      shape: PillShape.dropperBottle,
      colorName: 'Yellow',
      visualColor: Color(0xFFEAB308),
      imprint: 'Yellow Cap',
      scoring: PillScoring.unscored,
      category: MedCategory.eyeDrop,
      indications: 'Beta-blocker eye drop (requires 60s punctal occlusion)',
    ),
    const PillReferenceItem(
      name: 'Prednisolone Acetate 1%',
      strength: '1 drop OU',
      shape: PillShape.dropperBottle,
      colorName: 'Pink',
      visualColor: Color(0xFFEC4899),
      imprint: 'Pink Cap',
      scoring: PillScoring.unscored,
      category: MedCategory.eyeDrop,
      indications: 'Ophthalmic corticosteroid suspension (shake well)',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _imprintCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _imprintCtrl.clear();
      _selectedShape = null;
      _selectedColorName = null;
      _selectedScoring = null;
      _onlyMyCabinet = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Pill & Drug Identifier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Filters',
            onPressed: _resetFilters,
          ),
        ],
      ),
      body: Consumer<MedicationRepository>(
        builder: (context, repo, _) {
          final activeMeds = repo.activeMedications;
          final filtered = _getFilteredResults(activeMeds);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search and Imprint Bars
                      _buildSearchInputs(),
                      const SizedBox(height: 16),
                      // Shape Selector Chips
                      _buildShapeFilter(),
                      const SizedBox(height: 12),
                      // Color Selector Chips
                      _buildColorFilter(),
                      const SizedBox(height: 12),
                      // Scoring & Cabinet Filters
                      _buildScoringAndCabinetToggles(),
                      const Divider(height: 28),
                      // Header Results
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Matches (${filtered.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_hasActiveFilters)
                            TextButton.icon(
                              onPressed: _resetFilters,
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear Filters'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildResultCard(context, filtered[index]),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  bool get _hasActiveFilters =>
      _searchCtrl.text.isNotEmpty ||
      _imprintCtrl.text.isNotEmpty ||
      _selectedShape != null ||
      (_selectedColorName != null && _selectedColorName != 'All') ||
      _selectedScoring != null ||
      _onlyMyCabinet;

  Widget _buildSearchInputs() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              labelText: 'Search Drug Name',
              hintText: 'e.g. Metformin, Latanoprost',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: _imprintCtrl,
            decoration: InputDecoration(
              labelText: 'Imprint / Text',
              hintText: 'e.g. ATV 20',
              prefixIcon: const Icon(Icons.text_fields),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildShapeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pill / Delivery Shape',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: PillShape.values.map((shape) {
              final isSel = _selectedShape == shape;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getShapeIcon(shape), size: 14),
                      const SizedBox(width: 4),
                      Text(_getShapeLabel(shape)),
                    ],
                  ),
                  selected: isSel,
                  onSelected: (val) {
                    setState(() {
                      _selectedShape = val ? shape : null;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visual Color',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _colorNames.map((colorName) {
              final isSel = (_selectedColorName ?? 'All') == colorName;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(colorName),
                  selected: isSel,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedColorName = colorName == 'All' ? null : colorName;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScoringAndCabinetToggles() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<PillScoring?>(
            value: _selectedScoring,
            decoration: InputDecoration(
              labelText: 'Scoring',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any Scoring')),
              DropdownMenuItem(value: PillScoring.unscored, child: Text('Unscored')),
              DropdownMenuItem(value: PillScoring.singleScored, child: Text('Single Scored (-)')),
              DropdownMenuItem(value: PillScoring.doubleScored, child: Text('Cross/Double (+)')),
            ],
            onChanged: (val) => setState(() => _selectedScoring = val),
          ),
        ),
        const SizedBox(width: 12),
        FilterChip(
          label: const Text('My Cabinet Only'),
          selected: _onlyMyCabinet,
          avatar: const Icon(Icons.medication, size: 16),
          onSelected: (val) => setState(() => _onlyMyCabinet = val),
        ),
      ],
    );
  }

  List<dynamic> _getFilteredResults(List<Medication> activeMeds) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final imprintQuery = _imprintCtrl.text.trim().toLowerCase();

    final List<dynamic> results = [];

    // Search active cabinet meds
    for (final med in activeMeds) {
      if (query.isNotEmpty && !med.name.toLowerCase().contains(query)) continue;
      if (imprintQuery.isNotEmpty &&
          (med.pillImprint == null ||
              !med.pillImprint!.toLowerCase().contains(imprintQuery))) {
        continue;
      }
      if (_selectedShape != null && med.pillShape != _selectedShape) continue;
      if (_selectedColorName != null &&
          _selectedColorName != 'All' &&
          med.pillColorName.toLowerCase() != _selectedColorName!.toLowerCase()) {
        continue;
      }
      if (_selectedScoring != null && med.pillScoring != _selectedScoring) continue;

      results.add(med);
    }

    // Search clinical reference catalog (if not onlyMyCabinet)
    if (!_onlyMyCabinet) {
      for (final ref in _referenceLibrary) {
        if (query.isNotEmpty && !ref.name.toLowerCase().contains(query)) continue;
        if (imprintQuery.isNotEmpty && !ref.imprint.toLowerCase().contains(imprintQuery)) {
          continue;
        }
        if (_selectedShape != null && ref.shape != _selectedShape) continue;
        if (_selectedColorName != null &&
            _selectedColorName != 'All' &&
            ref.colorName.toLowerCase() != _selectedColorName!.toLowerCase()) {
          continue;
        }
        if (_selectedScoring != null && ref.scoring != _selectedScoring) continue;

        results.add(ref);
      }
    }

    return results;
  }

  Widget _buildResultCard(BuildContext context, dynamic item) {
    final bool isCabinetMed = item is Medication;
    final String name = isCabinetMed ? item.name : (item as PillReferenceItem).name;
    final String strength = isCabinetMed ? item.strength : (item as PillReferenceItem).strength;
    final PillShape shape = isCabinetMed ? item.pillShape : (item as PillReferenceItem).shape;
    final String colorName = isCabinetMed ? item.pillColorName : (item as PillReferenceItem).colorName;
    final String imprint = isCabinetMed
        ? (item.pillImprint ?? 'None')
        : (item as PillReferenceItem).imprint;
    final PillScoring scoring = isCabinetMed ? item.pillScoring : (item as PillReferenceItem).scoring;
    final String subtitle = isCabinetMed
        ? 'Active in Cabinet (${item.frequency})'
        : (item as PillReferenceItem).indications;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual Pill Simulation Icon
            _buildVisualPillSim(shape, colorName, scoring),
            const SizedBox(width: 14),
            // Information Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$name $strength',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCabinetMed
                              ? MediMindTheme.successGreen.withAlpha(30)
                              : Colors.blue.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCabinetMed ? 'MY MED' : 'CLINICAL REF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCabinetMed
                                ? MediMindTheme.successGreen
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildPillTag('Shape', _getShapeLabel(shape)),
                      _buildPillTag('Color', colorName),
                      _buildPillTag('Imprint', imprint),
                      _buildPillTag('Score', _getScoringLabel(scoring)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualPillSim(PillShape shape, String colorName, PillScoring scoring) {
    Color bg = Colors.grey.shade200;
    if (colorName.toLowerCase().contains('white')) bg = Colors.white;
    if (colorName.toLowerCase().contains('blue')) bg = Colors.blue.shade300;
    if (colorName.toLowerCase().contains('yellow')) bg = Colors.amber.shade300;
    if (colorName.toLowerCase().contains('red')) bg = Colors.red.shade400;
    if (colorName.toLowerCase().contains('green')) bg = Colors.green.shade400;
    if (colorName.toLowerCase().contains('orange')) bg = Colors.orange.shade400;
    if (colorName.toLowerCase().contains('pink')) bg = Colors.pink.shade300;
    if (colorName.toLowerCase().contains('teal') || colorName.toLowerCase().contains('clear')) {
      bg = Colors.teal.shade300;
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _getShapeBorderRadius(shape),
        border: Border.all(color: Colors.black26, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: scoring == PillScoring.singleScored
            ? Container(height: 1.5, width: 34, color: Colors.black38)
            : scoring == PillScoring.doubleScored
                ? const Icon(Icons.add, size: 24, color: Colors.black38)
                : Icon(_getShapeIcon(shape), size: 20, color: Colors.black45),
      ),
    );
  }

  BorderRadius _getShapeBorderRadius(PillShape shape) {
    switch (shape) {
      case PillShape.round:
        return BorderRadius.circular(29);
      case PillShape.oval:
      case PillShape.oblong:
        return BorderRadius.circular(16);
      case PillShape.capsule:
        return BorderRadius.circular(20);
      case PillShape.dropperBottle:
        return const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        );
      case PillShape.diamond:
        return BorderRadius.circular(6);
      default:
        return BorderRadius.circular(10);
    }
  }

  Widget _buildPillTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No Matching Medications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Try clearing some filters, imprint letters, or color constraints.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _resetFilters,
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getShapeIcon(PillShape shape) {
    switch (shape) {
      case PillShape.round:
        return Icons.circle;
      case PillShape.oval:
      case PillShape.oblong:
        return Icons.crop_16_9;
      case PillShape.capsule:
        return Icons.medication;
      case PillShape.diamond:
        return Icons.change_history;
      case PillShape.dropperBottle:
        return Icons.water_drop;
      case PillShape.inhaler:
        return Icons.air;
      case PillShape.patch:
        return Icons.crop_square;
      default:
        return Icons.grain;
    }
  }

  String _getShapeLabel(PillShape shape) {
    switch (shape) {
      case PillShape.round:
        return 'Round';
      case PillShape.oval:
        return 'Oval';
      case PillShape.capsule:
        return 'Capsule';
      case PillShape.oblong:
        return 'Oblong';
      case PillShape.diamond:
        return 'Diamond';
      case PillShape.dropperBottle:
        return 'Eye Dropper';
      case PillShape.inhaler:
        return 'Inhaler';
      case PillShape.patch:
        return 'Patch';
      case PillShape.other:
        return 'Other';
    }
  }

  String _getScoringLabel(PillScoring scoring) {
    switch (scoring) {
      case PillScoring.unscored:
        return 'Unscored';
      case PillScoring.singleScored:
        return 'Single-score';
      case PillScoring.doubleScored:
        return 'Double-score';
    }
  }
}
