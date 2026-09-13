import 'package:uuid/uuid.dart';
import '../../domain/models/medication.dart';

/// Draft representation of an extracted medication from a prescription.
/// Allows the user to review, edit, confirm, and customize before scheduling.
class ParsedMedicationDraft {
  final String id;
  final String rawLine;
  String name;
  String strength;
  MedCategory category;
  DosageUnit dosageUnit;
  double dosageAmount;
  String frequencyPattern; // e.g., '1-0-1', 'TDS', 'OD', 'Once daily'
  String frequencyLabel; // e.g., 'Twice daily', 'Three times daily'
  List<String> scheduleTimes; // e.g., ['08:00', '20:00']
  int? durationDays; // e.g., 5, 7, 10, 14, 30 days
  AdminInstruction instruction;
  bool isEyeMedication;
  bool isOintment;
  String? eyeTarget; // 'Both Eyes (OU)', 'Left Eye (OS)', 'Right Eye (OD)'
  int totalQuantity; // Calculated or prescribed quantity
  String? clinicalNotes;
  double confidence; // 0.0 to 1.0 heuristic score
  bool isSelected; // For multi-select batch import
  String? correctedFrom; // If autocorrected from an OCR typo

  ParsedMedicationDraft({
    String? id,
    required this.rawLine,
    required this.name,
    this.strength = '',
    this.category = MedCategory.oral,
    this.dosageUnit = DosageUnit.tablets,
    this.dosageAmount = 1.0,
    this.frequencyPattern = '1-0-0',
    this.frequencyLabel = 'Once daily',
    this.scheduleTimes = const ['08:00'],
    this.durationDays,
    this.instruction = AdminInstruction.afterMeal,
    this.isEyeMedication = false,
    this.isOintment = false,
    this.eyeTarget,
    this.totalQuantity = 30,
    this.clinicalNotes,
    this.confidence = 0.85,
    this.isSelected = true,
    this.correctedFrom,
  }) : id = id ?? const Uuid().v4();

  ParsedMedicationDraft copyWith({
    String? name,
    String? strength,
    MedCategory? category,
    DosageUnit? dosageUnit,
    double? dosageAmount,
    String? frequencyPattern,
    String? frequencyLabel,
    List<String>? scheduleTimes,
    int? durationDays,
    AdminInstruction? instruction,
    bool? isEyeMedication,
    bool? isOintment,
    String? eyeTarget,
    int? totalQuantity,
    String? clinicalNotes,
    double? confidence,
    bool? isSelected,
    String? correctedFrom,
  }) {
    return ParsedMedicationDraft(
      id: id,
      rawLine: rawLine,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      category: category ?? this.category,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      frequencyPattern: frequencyPattern ?? this.frequencyPattern,
      frequencyLabel: frequencyLabel ?? this.frequencyLabel,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      durationDays: durationDays ?? this.durationDays,
      instruction: instruction ?? this.instruction,
      isEyeMedication: isEyeMedication ?? this.isEyeMedication,
      isOintment: isOintment ?? this.isOintment,
      eyeTarget: eyeTarget ?? this.eyeTarget,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      confidence: confidence ?? this.confidence,
      isSelected: isSelected ?? this.isSelected,
      correctedFrom: correctedFrom ?? this.correctedFrom,
    );
  }

  /// Converts this draft to a ready-to-save production Medication model.
  Medication toMedication({String? doctorName}) {
    final now = DateTime.now();
    final calculatedEndDate = durationDays != null ? now.add(Duration(days: durationDays!)) : null;

    String colorHex = '#059669'; // Default green for oral
    String iconName = 'pill';

    if (isEyeMedication) {
      if (isOintment) {
        colorHex = '#0D9488'; // Teal
        iconName = 'eye_drop';
      } else {
        colorHex = '#0284C7'; // Blue
        iconName = 'eye_drop';
      }
    } else if (category == MedCategory.inhaler) {
      colorHex = '#7C3AED';
      iconName = 'inhaler';
    } else if (category == MedCategory.injectable) {
      colorHex = '#DC2626';
      iconName = 'syringe';
    }

    return Medication(
      id: id,
      name: name,
      strength: strength.isEmpty ? 'Standard Dose' : strength,
      category: isEyeMedication
          ? (isOintment ? MedCategory.eyeOintment : MedCategory.eyeDrop)
          : category,
      dosageUnit: dosageUnit,
      dosageAmount: dosageAmount,
      instruction: instruction,
      frequency: frequencyLabel,
      scheduleTimes: scheduleTimes,
      startDate: now,
      endDate: calculatedEndDate,
      expiryDate: now.add(const Duration(days: 180)),
      openedDate: isEyeMedication ? now : null,
      afterOpeningDays: isEyeMedication ? 28 : null,
      totalInventoryCount: totalQuantity > 0 ? totalQuantity : 30,
      refillThreshold: (totalQuantity * 0.25).ceil().clamp(3, 10),
      prescribingDoctor: doctorName ?? 'Scanned Prescription',
      clinicalNotes: clinicalNotes ?? (durationDays != null ? 'Prescribed for $durationDays days.' : null),
      colorHex: colorHex,
      iconName: iconName,
      requiresEyeDropProtocol: isEyeMedication,
      eyeTarget: isEyeMedication ? (eyeTarget ?? 'Both Eyes (OU)') : null,
      eyeDropGapMinutes: isEyeMedication ? 5 : 0,
      contactLensWarning: isEyeMedication,
      isOintment: isOintment,
    );
  }
}

/// Clinical AI Prescription Parser Service
/// Runs 100% on-device using heuristic NLP, medical dictionaries, and matrix pattern extractors.
class PrescriptionParserService {
  static final PrescriptionParserService _instance = PrescriptionParserService._internal();
  factory PrescriptionParserService() => _instance;
  PrescriptionParserService._internal();

  // ──────────────────────────────────────────────────────────
  // Clinical Drug Dictionary (Brand Names + Active Ingredients)
  // ──────────────────────────────────────────────────────────
  static const Map<String, ({MedCategory category, DosageUnit unit, bool isEye, bool isOintment})> _drugDictionary = {
    // 👁️ Ophthalmic Drops & Ointments
    'latanoprost': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'timolol': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'bimatoprost': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'travoprost': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'brimonidine': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'dorzolamide': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'brinzolamide': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'moxifloxacin': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'vigamox': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'moxicip': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'ciplox': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'ciprofloxacin': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'tobramycin': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'tobrex': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'tobradex': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'prednisolone': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'pred forte': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'dexamethasone': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'erythromycin': (category: MedCategory.eyeOintment, unit: DosageUnit.applyTopical, isEye: true, isOintment: true),
    'ketorolac': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'nepafenac': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'nevanac': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'carboxymethylcellulose': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'refresh tears': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'systane': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'cyclosporine': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'restasis': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'olopatadine': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'patanol': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'loteprednol': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'lotemax': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'atropine': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'homatropine': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),
    'tropicamide': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false),

    // 💊 Antibiotics / Antivirals
    'amoxicillin': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false),
    'augmentin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'azithromycin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'azithral': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'cefixime': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'cefpodoxime': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'doxycycline': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false),
    'metronidazole': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'flagyl': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'levofloxacin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'ofloxacin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'acyclovir': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),

    // ❤️ Cardiovascular / Blood Pressure / Lipids
    'atorvastatin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'atorva': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'rosuvastatin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'amlodipine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'amlong': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'telmisartan': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'telma': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'losartan': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'metoprolol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'atenolol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'ramipril': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'lisinopril': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'furosemide': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'lasix': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'aspirin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'ecosprin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'clopidogrel': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),

    // 🩸 Diabetes & Metabolism
    'metformin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'glycomet': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'glimepiride': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'amaryl': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'sitagliptin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'januvia': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'dapagliflozin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'forxiga': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'empagliflozin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'jardiance': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'thyroxine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'thyronorm': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'levothyroxine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),

    // 🧪 Gastrointestinal
    'pantoprazole': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'pan': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'pantocid': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'omeprazole': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false),
    'omez': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false),
    'rabeprazole': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'rabicip': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'domperidone': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'ondansetron': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'emset': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),

    // 🩹 Pain / Anti-inflammatory
    'paracetamol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'crocin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'dolo': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'calpol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'ibuprofen': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'combiflam': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'diclofenac': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'voveran': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'aceclofenac': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'zerodol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'tramadol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),

    // 🌬️ Respiratory & Allergy
    'montelukast': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'montek': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'levocetirizine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'levocet': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'cetirizine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'cetzine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'fexofenadine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'allegra': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'salbutamol': (category: MedCategory.inhaler, unit: DosageUnit.puffs, isEye: false, isOintment: false),
    'asthalin': (category: MedCategory.inhaler, unit: DosageUnit.puffs, isEye: false, isOintment: false),
    'budesonide': (category: MedCategory.inhaler, unit: DosageUnit.puffs, isEye: false, isOintment: false),
    'foracort': (category: MedCategory.inhaler, unit: DosageUnit.puffs, isEye: false, isOintment: false),

    // 🌿 Vitamins / Supplements
    'calcium': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'shelcal': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
    'vitamin d3': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false),
    'cholecalciferol': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false),
    'neurobion': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false),
  };

  // ──────────────────────────────────────────────────────────
  // Main Parsing Entry Point
  // ──────────────────────────────────────────────────────────
  List<ParsedMedicationDraft> parsePrescription(String rawOcrText) {
    if (rawOcrText.trim().isEmpty) return [];

    final lines = rawOcrText.split(RegExp(r'[\r\n]+'));
    final List<String> candidateLines = [];
    final StringBuffer currentBlock = StringBuffer();

    // 1. Filter out clinic headers, doctor bio, patient demographics, vitals
    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (_isHeaderOrDemographicNoise(line)) continue;

      // Check if line starts with a medication index e.g., "1.", "2)", "•", "Rx", "R/"
      final isNewMedicationEntry = RegExp(r'^(\d+[\.\)]\s*|[•\-\*]\s*|(Rx|R/)\s+)', caseSensitive: false).hasMatch(line);

      if (isNewMedicationEntry && currentBlock.isNotEmpty) {
        candidateLines.add(currentBlock.toString().trim());
        currentBlock.clear();
      }

      currentBlock.write(' $line');
    }

    if (currentBlock.isNotEmpty) {
      candidateLines.add(currentBlock.toString().trim());
    }

    // If block-splitting yielded nothing or only 1 line, fallback to line-by-line inspection
    final effectiveLines = candidateLines.isNotEmpty ? candidateLines : lines;

    final List<ParsedMedicationDraft> results = [];

    for (final cand in effectiveLines) {
      final parsed = _parseSingleCandidate(cand);
      if (parsed != null) {
        // Prevent duplicate names
        if (!results.any((r) => r.name.toLowerCase() == parsed.name.toLowerCase())) {
          results.add(parsed);
        }
      }
    }

    // If dictionary matched nothing, attempt heuristic line search
    if (results.isEmpty) {
      for (final line in lines) {
        if (!_isHeaderOrDemographicNoise(line) && line.length > 5) {
          final fallback = _parseGenericLine(line);
          if (fallback != null) {
            results.add(fallback);
          }
        }
      }
    }

    return results;
  }

  // ──────────────────────────────────────────────────────────
  // Candidate Analysis & Extraction
  // ──────────────────────────────────────────────────────────
  ParsedMedicationDraft? _parseSingleCandidate(String text) {
    final lower = text.toLowerCase();
    String detectedName = '';
    String detectedStrength = '';
    MedCategory detectedCategory = MedCategory.oral;
    DosageUnit detectedUnit = DosageUnit.tablets;
    bool isEyeMed = false;
    bool isOint = false;
    double confidence = 0.70;

    String? typoCorrectedFrom;

    // 1. Scan for known drug names
    for (final entry in _drugDictionary.entries) {
      final drugKey = entry.key;
      // Match whole word or exact term
      final regex = RegExp(r'\b' + RegExp.escape(drugKey) + r'\b', caseSensitive: false);
      if (regex.hasMatch(lower)) {
        detectedName = _capitalize(drugKey);
        detectedCategory = entry.value.category;
        detectedUnit = entry.value.unit;
        isEyeMed = entry.value.isEye;
        isOint = entry.value.isOintment;
        confidence = 0.95;
        break;
      }
    }

    // 1b. AI Fuzzy Typo Correction (Levenshtein Distance) for messy handwriting & OCR typos
    if (detectedName.isEmpty) {
      final words = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length < 4) continue;
        for (final entry in _drugDictionary.entries) {
          final drugKey = entry.key;
          if ((word.length - drugKey.length).abs() > 3) continue;

          final distance = _levenshtein(word, drugKey);
          final maxLen = word.length > drugKey.length ? word.length : drugKey.length;
          final similarity = 1.0 - (distance / maxLen);

          if (distance <= 2 && similarity >= 0.72) {
            detectedName = _capitalize(drugKey);
            detectedCategory = entry.value.category;
            detectedUnit = entry.value.unit;
            isEyeMed = entry.value.isEye;
            isOint = entry.value.isOintment;
            confidence = similarity * 0.95;
            typoCorrectedFrom = word;
            break;
          }
        }
        if (detectedName.isNotEmpty) break;
      }
    }

    // 2. Check for form indicators if name was not in dictionary
    if (detectedName.isEmpty) {
      final formMatch = RegExp(r'\b(tab|tablet|cap|capsule|syr|syrup|drop|drops|eye drop|eye drops|gutt|ointment|oint|inj|injection|inhaler|gel|cream)\b\s+([A-Za-z0-9\-]+)', caseSensitive: false).firstMatch(text);
      if (formMatch != null) {
        final formType = formMatch.group(1)!.toLowerCase();
        final rawName = formMatch.group(2)!;
        detectedName = _capitalize(rawName);

        if (formType.contains('drop') || formType.contains('gutt')) {
          isEyeMed = true;
          detectedCategory = MedCategory.eyeDrop;
          detectedUnit = DosageUnit.drops;
        } else if (formType.contains('oint')) {
          isEyeMed = true;
          isOint = true;
          detectedCategory = MedCategory.eyeOintment;
          detectedUnit = DosageUnit.applyTopical;
        } else if (formType.contains('cap')) {
          detectedCategory = MedCategory.oral;
          detectedUnit = DosageUnit.capsules;
        } else if (formType.contains('syr')) {
          detectedCategory = MedCategory.oral;
          detectedUnit = DosageUnit.ml;
        } else if (formType.contains('inhal')) {
          detectedCategory = MedCategory.inhaler;
          detectedUnit = DosageUnit.puffs;
        } else {
          detectedCategory = MedCategory.oral;
          detectedUnit = DosageUnit.tablets;
        }
        confidence = 0.85;
      }
    }

    if (detectedName.isEmpty) {
      return null;
    }

    // 3. Extract Strength
    final strengthMatch = RegExp(r'(\d+(?:\.\d+)?\s*(?:mg|mcg|ml|%|g|iu|IU|gm))', caseSensitive: false).firstMatch(text);
    if (strengthMatch != null) {
      detectedStrength = strengthMatch.group(0)!.trim();
    }

    // 4. Extract Frequency & Timing
    final frequencyInfo = _extractFrequency(text);

    // 5. Extract Duration in Days
    final durationDays = _extractDuration(text);

    // 6. Extract Food / Administration Instruction
    final instruction = _extractInstruction(text, isEyeMed);

    // 7. Extract Eye Target
    String? eyeTarget;
    if (isEyeMed) {
      if (lower.contains('left eye') || lower.contains('(os)') || RegExp(r'\bos\b').hasMatch(lower)) {
        eyeTarget = 'Left Eye (OS)';
      } else if (lower.contains('right eye') || lower.contains('(od)') || (RegExp(r'\bod\b').hasMatch(lower) && isEyeMed && !frequencyInfo.raw.contains('OD'))) {
        eyeTarget = 'Right Eye (OD)';
      } else {
        eyeTarget = 'Both Eyes (OU)';
      }
    }

    // 8. Calculate total quantity needed
    final dosesPerDay = frequencyInfo.scheduleTimes.length;
    final days = durationDays ?? 30;
    int calculatedQty;
    if (isEyeMed) {
      calculatedQty = isOint ? 1 : 1; // 1 bottle / tube
    } else {
      calculatedQty = (dosesPerDay * days).clamp(5, 500);
    }

    return ParsedMedicationDraft(
      rawLine: text,
      name: detectedName,
      strength: detectedStrength,
      category: detectedCategory,
      dosageUnit: detectedUnit,
      dosageAmount: isEyeMed ? 1.0 : 1.0,
      frequencyPattern: frequencyInfo.raw,
      frequencyLabel: frequencyInfo.label,
      scheduleTimes: frequencyInfo.scheduleTimes,
      durationDays: durationDays,
      instruction: instruction,
      isEyeMedication: isEyeMed,
      isOintment: isOint,
      eyeTarget: eyeTarget,
      totalQuantity: calculatedQty,
      clinicalNotes: _extractClinicalNotes(text),
      confidence: confidence,
      correctedFrom: typoCorrectedFrom,
    );
  }

  // ──────────────────────────────────────────────────────────
  // Heuristic Frequency & Timing Extractor
  // ──────────────────────────────────────────────────────────
  ({String raw, String label, List<String> scheduleTimes}) _extractFrequency(String text) {
    final lower = text.toLowerCase();

    // 1. Matrix pattern: 1-0-1, 1-1-1, 1-0-0, 0-1-0, 0-0-1, 1-1-1-1, 0.5-0-0.5
    final matrixMatch = RegExp(r'\b([01](?:\.5)?)\s*[-/]\s*([01](?:\.5)?)\s*[-/]\s*([01](?:\.5)?)(?:\s*[-/]\s*([01](?:\.5)?))?\b').firstMatch(text);
    if (matrixMatch != null) {
      final m = matrixMatch.group(1)!;
      final a = matrixMatch.group(2)!;
      final n = matrixMatch.group(3)!;
      final fourth = matrixMatch.group(4);

      if (fourth != null && fourth != '0') {
        return (raw: '$m-$a-$n-$fourth', label: 'Four times daily', scheduleTimes: ['08:00', '12:00', '16:00', '20:00']);
      }
      if (m != '0' && a != '0' && n != '0') {
        return (raw: '$m-$a-$n', label: 'Three times daily', scheduleTimes: ['08:00', '14:00', '20:00']);
      }
      if (m != '0' && n != '0') {
        return (raw: '$m-0-$n', label: 'Twice daily', scheduleTimes: ['08:00', '20:00']);
      }
      if (m != '0') {
        return (raw: '$m-0-0', label: 'Once daily (Morning)', scheduleTimes: ['08:00']);
      }
      if (a != '0') {
        return (raw: '0-$a-0', label: 'Once daily (Afternoon)', scheduleTimes: ['13:00']);
      }
      if (n != '0') {
        return (raw: '0-0-$n', label: 'Once daily (Night)', scheduleTimes: ['21:00']);
      }
    }

    // 2. Standard Medical Abbreviations
    if (RegExp(r'\b(qid|four times daily|4 times daily|4 times a day|q6h)\b').hasMatch(lower)) {
      return (raw: 'QID', label: 'Four times daily', scheduleTimes: ['08:00', '12:00', '16:00', '20:00']);
    }
    if (RegExp(r'\b(tid|tds|three times daily|3 times daily|3 times a day|q8h)\b').hasMatch(lower)) {
      return (raw: 'TDS / TID', label: 'Three times daily', scheduleTimes: ['08:00', '14:00', '20:00']);
    }
    if (RegExp(r'\b(bid|bd|twice daily|2 times daily|2 times a day|q12h)\b').hasMatch(lower)) {
      return (raw: 'BD / BID', label: 'Twice daily', scheduleTimes: ['08:00', '20:00']);
    }
    if (RegExp(r'\b(hs|at bedtime|bedtime|night only|qhs)\b').hasMatch(lower)) {
      return (raw: 'HS', label: 'At bedtime', scheduleTimes: ['21:30']);
    }
    if (RegExp(r'\b(od|once daily|1 time daily|once a day|daily|qd)\b').hasMatch(lower)) {
      return (raw: 'OD', label: 'Once daily', scheduleTimes: ['08:00']);
    }
    if (RegExp(r'\b(prn|sos|as needed)\b').hasMatch(lower)) {
      return (raw: 'SOS / PRN', label: 'As needed', scheduleTimes: ['08:00']);
    }

    return (raw: 'Once daily', label: 'Once daily', scheduleTimes: ['08:00']);
  }

  // ──────────────────────────────────────────────────────────
  // Duration Extractor
  // ──────────────────────────────────────────────────────────
  int? _extractDuration(String text) {
    final lower = text.toLowerCase();

    // Match "x 5 days", "for 7 days", "10 days", "5d", "x 5d"
    final daysMatch = RegExp(r'(?:x|for|\*|\/)?\s*(\d+)\s*(?:days?|d\b)', caseSensitive: false).firstMatch(lower);
    if (daysMatch != null) {
      return int.tryParse(daysMatch.group(1)!);
    }

    // Match "x 2 weeks", "for 1 week", "2 wks"
    final weeksMatch = RegExp(r'(?:x|for|\*|\/)?\s*(\d+)\s*(?:weeks?|wks?|wk\b)', caseSensitive: false).firstMatch(lower);
    if (weeksMatch != null) {
      final w = int.tryParse(weeksMatch.group(1)!);
      if (w != null) return w * 7;
    }

    // Match "1 month", "x 1 month", "3 months"
    final monthMatch = RegExp(r'(?:x|for|\*|\/)?\s*(\d+)\s*(?:months?|mths?|m\b)', caseSensitive: false).firstMatch(lower);
    if (monthMatch != null) {
      final m = int.tryParse(monthMatch.group(1)!);
      if (m != null) return m * 30;
    }

    return null;
  }

  // ──────────────────────────────────────────────────────────
  // Food & Administration Instruction Extractor
  // ──────────────────────────────────────────────────────────
  AdminInstruction _extractInstruction(String text, bool isEyeMed) {
    if (isEyeMed) return AdminInstruction.asNeeded;
    final lower = text.toLowerCase();

    if (RegExp(r'\b(b\/f|bbf|ac|before food|before meal|empty stomach)\b').hasMatch(lower)) {
      return AdminInstruction.beforeMeal;
    }
    if (RegExp(r'\b(a\/f|abf|pc|after food|after meal|with food|post meal)\b').hasMatch(lower)) {
      return AdminInstruction.afterMeal;
    }
    if (RegExp(r'\b(with meals|during meal)\b').hasMatch(lower)) {
      return AdminInstruction.withMeal;
    }
    if (RegExp(r'\b(hs|at bedtime|bedtime)\b').hasMatch(lower)) {
      return AdminInstruction.atBedtime;
    }

    return AdminInstruction.afterMeal; // Safe standard default
  }

  String? _extractClinicalNotes(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('sos') || lower.contains('prn')) {
      return 'Take only when necessary / as needed.';
    }
    if (lower.contains('water') || lower.contains('glass')) {
      return 'Take with a full glass of water.';
    }
    if (lower.contains('shake')) {
      return 'Shake well before administration.';
    }
    return null;
  }

  bool _isHeaderOrDemographicNoise(String line) {
    final lower = line.toLowerCase();
    final noiseKeywords = [
      'hospital', 'clinic', 'dr.', 'doctor', 'mbbs', 'md', 'ms', 'frcs',
      'patient name', 'age:', 'sex:', 'gender:', 'weight:', 'wt:', 'bp:',
      'pulse:', 'spo2:', 'date:', 'reg no', 'registration', 'opd', 'ipd',
      'signature', 'rx', 'r/', 'phone:', 'ph:', 'address', 'tel:',
      'consultant', 'department', 'investigations', 'diagnosis', 'chief complaint',
      'follow up', 'review after', 'next visit',
    ];
    for (final kw in noiseKeywords) {
      if (lower.startsWith(kw) || (lower.contains(kw) && line.length < 35)) {
        // If line contains a known medication name from dictionary, do not filter out!
        final containsKnownDrug = _drugDictionary.keys.any((k) => lower.contains(k));
        if (!containsKnownDrug) return true;
      }
    }
    return false;
  }

  ParsedMedicationDraft? _parseGenericLine(String line) {
    // Look for a line with capitalized medication candidate and dosage or numbers
    final match = RegExp(r'^([A-Z][a-zA-Z0-9\s\-]{3,20})(?:\s+(\d+(?:\.\d+)?\s*(?:mg|mcg|ml|%|g)))?').firstMatch(line.trim());
    if (match != null) {
      final name = match.group(1)!.trim();
      final strength = match.group(2)?.trim() ?? '';
      final isEye = name.toLowerCase().contains('drop') || line.toLowerCase().contains('eye');

      return ParsedMedicationDraft(
        rawLine: line,
        name: name,
        strength: strength,
        category: isEye ? MedCategory.eyeDrop : MedCategory.oral,
        dosageUnit: isEye ? DosageUnit.drops : DosageUnit.tablets,
        isEyeMedication: isEye,
        frequencyPattern: '1-0-0',
        frequencyLabel: 'Once daily',
        scheduleTimes: ['08:00'],
        confidence: 0.60,
      );
    }
    return null;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  int _levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  // ──────────────────────────────────────────────────────────
  // Pre-loaded Sample Prescriptions for Instant Testing
  // ──────────────────────────────────────────────────────────
  static const List<({String title, String subtitle, String text})> samplePrescriptions = [
    (
      title: '👁️ Ophthalmic & Post-Cataract Surgery Rx',
      subtitle: '4 eye drops & ointment with 5-10m wash-out warning',
      text: '''
DR. SARAH LIN, MD, FRCS (Ophthalmology)
ST. MARY EYE HOSPITAL & RETINA CENTER
Patient: Robert Vance | Age: 64 | Eye: Right Eye (OD)

Rx:
1. Moxifloxacin 0.5% Eye Drops (Vigamox) - 1 drop 4 times daily (OD) x 14 days
2. Pred Forte 1% Ophthalmic Suspension - 1 drop TID (OD) x 2 weeks
3. Latanoprost 0.005% Eye Drops - 1 drop at bedtime (OU) continue 30 days
4. Erythromycin 0.5% Eye Ointment - Apply thin ribbon at bedtime (OD) x 10 days
(Wait 10 minutes after liquid drops before applying ointment)
'''
    ),
    (
      title: '🩺 Outpatient General Clinic Prescription',
      subtitle: '3 oral medications with Indian matrix (1-0-1, 1-0-0) & days',
      text: '''
METRO HEALTH CLINIC & DIAGNOSTICS
Dr. Rajesh Sharma, MBBS, MD (Internal Medicine)
Patient: Anita Patel | Date: Today | BP: 128/82

Rx:
1. Tab Augmentin 625mg 1-0-1 after food x 5 days
2. Cap Pan 40mg 1-0-0 before breakfast x 7 days
3. Tab Dolo 650mg 1-1-1 SOS for fever x 3 days
4. Tab Levocet 5mg 0-0-1 at bedtime x 5 days
'''
    ),
    (
      title: '❤️ Chronic Cardio-Diabetic Routine',
      subtitle: 'Long-term maintenance medications with timing & refill',
      text: '''
CARDIO-ENDOCRINE SPECIALTY CARE
Dr. David Miller, MD
Patient: Thomas Reed | Age: 58

Prescription:
1. Tab Metformin 500mg 1-0-1 after meals x 30 days
2. Tab Telmisartan 40mg 1-0-0 morning after food x 30 days
3. Tab Atorvastatin 20mg 0-0-1 at bedtime x 30 days
(Avoid grapefruit juice with Atorvastatin)
'''
    ),
  ];
}
