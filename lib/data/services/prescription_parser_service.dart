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
  String frequencyPattern; // e.g., '1-0-1', 'TDS', 'OD', 'Q12H'
  String frequencyLabel; // e.g., 'Twice daily', 'Three times daily'
  List<String> scheduleTimes; // e.g., ['08:00', '20:00']
  int? durationDays; // e.g., 5, 7, 10, 14, 30 days
  AdminInstruction instruction;
  bool isEyeMedication;
  bool isOintment;
  String? eyeTarget; // 'Both Eyes (OU)', 'Left Eye (OS)', 'Right Eye (OD)'
  String? route; // 'Oral (PO)', 'Inhalation (INH)', 'Topical', etc.
  int totalQuantity; // Calculated or prescribed quantity
  String? clinicalNotes;
  String? safetyWarning; // DDI risk, narrow therapeutic index, or Beers criteria
  String? chronotherapyAdvice; // Circadian timing rationale
  bool isNarrowTherapeuticIndex; // Critical drugs needing tight adherence
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
    this.route,
    this.totalQuantity = 30,
    this.clinicalNotes,
    this.safetyWarning,
    this.chronotherapyAdvice,
    this.isNarrowTherapeuticIndex = false,
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
    String? route,
    int? totalQuantity,
    String? clinicalNotes,
    String? safetyWarning,
    String? chronotherapyAdvice,
    bool? isNarrowTherapeuticIndex,
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
      route: route ?? this.route,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      safetyWarning: safetyWarning ?? this.safetyWarning,
      chronotherapyAdvice: chronotherapyAdvice ?? this.chronotherapyAdvice,
      isNarrowTherapeuticIndex: isNarrowTherapeuticIndex ?? this.isNarrowTherapeuticIndex,
      confidence: confidence ?? this.confidence,
      isSelected: isSelected ?? this.isSelected,
      correctedFrom: correctedFrom ?? this.correctedFrom,
    );
  }

  /// Converts this draft to a ready-to-save production Medication model.
  Medication toMedication({String? doctorName}) {
    final now = DateTime.now();
    final calculatedEndDate = durationDays != null ? now.add(Duration(days: durationDays!)) : null;

    String colorHex = '#2D6A4F'; // Calming green for oral
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
    } else if (isNarrowTherapeuticIndex) {
      colorHex = '#D97706'; // Warning Amber for NTI drugs
    }

    final StringBuffer notesBuffer = StringBuffer();
    if (clinicalNotes != null && clinicalNotes!.isNotEmpty) {
      notesBuffer.write(clinicalNotes);
    }
    if (chronotherapyAdvice != null && chronotherapyAdvice!.isNotEmpty) {
      if (notesBuffer.isNotEmpty) notesBuffer.write(' • ');
      notesBuffer.write(chronotherapyAdvice);
    }
    if (safetyWarning != null && safetyWarning!.isNotEmpty) {
      if (notesBuffer.isNotEmpty) notesBuffer.write(' • ');
      notesBuffer.write('⚠️ ${safetyWarning!}');
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
      clinicalNotes: notesBuffer.isNotEmpty ? notesBuffer.toString() : null,
      colorHex: colorHex,
      iconName: iconName,
      isHighPriorityAlarm: isNarrowTherapeuticIndex || isEyeMedication,
      requiresEyeDropProtocol: isEyeMedication,
      eyeTarget: isEyeMedication ? (eyeTarget ?? 'Both Eyes (OU)') : null,
      eyeDropGapMinutes: isEyeMedication ? 5 : 0,
      contactLensWarning: isEyeMedication,
      isOintment: isOintment,
    );
  }
}

/// Clinical AI Prescription Parser Service (RxNLP 2.0)
/// Runs 100% on-device without cloud transmission (HIPAA / GDPR compliant).
/// Supports Latin medical shorthand, Indian matrix notation, US/UK NHS sig parsing,
/// OCR noise de-mangling, Levenshtein fuzzy matching, and prescription safety radar.
class PrescriptionParserService {
  static final PrescriptionParserService _instance = PrescriptionParserService._internal();
  factory PrescriptionParserService() => _instance;
  PrescriptionParserService._internal();

  // ──────────────────────────────────────────────────────────
  // Clinical Drug Dictionary (180+ Generic APIs & Global Brands)
  // ──────────────────────────────────────────────────────────
  static const Map<String, ({
    MedCategory category,
    DosageUnit unit,
    bool isEye,
    bool isOintment,
    bool isNti,
    String? chrono,
  })> _drugDictionary = {
    // 👁️ Ophthalmic Glaucoma, Antibiotic, NSAID, Steroid & Dry Eye Drops
    'latanoprost': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Instill at bedtime (21:30) for peak IOP lowering.'),
    'xalatan': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Instill at bedtime.'),
    'bimatoprost': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Instill at bedtime.'),
    'lumigan': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Instill at bedtime.'),
    'travoprost': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Instill at bedtime.'),
    'travatan': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Instill at bedtime.'),
    'tafluprost': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Instill at bedtime.'),
    'timolol': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Instill in morning. Apply 60s punctal occlusion.'),
    'timoptic': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Instill in morning. Apply 60s punctal occlusion.'),
    'brimonidine': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Space 8-12 hours apart.'),
    'alphagan': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Space 8-12 hours apart.'),
    'dorzolamide': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Space 8 hours apart.'),
    'trusopt': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Space 8 hours apart.'),
    'brinzolamide': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Shake well before instillation.'),
    'azopt': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Shake well before instillation.'),
    'combigan': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Brimonidine/Timolol: Space 12 hours apart.'),
    'cosopt': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Dorzolamide/Timolol: Twice daily.'),
    'simbrinza': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Brinzolamide/Brimonidine: Shake well.'),
    'rocklatan': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Netarsudil/Latanoprost: Evening dosing.'),
    'rhopressa': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Netarsudil: Once daily in evening.'),
    'moxifloxacin': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Complete full antibiotic course.'),
    'vigamox': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Complete full course.'),
    'moxicip': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Complete full course.'),
    'ciplox': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Complete full course.'),
    'ciprofloxacin': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Keep refrigerated if specified.'),
    'tobramycin': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Space evenly.'),
    'tobrex': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Space evenly.'),
    'tobradex': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Tobramycin/Dexamethasone: Shake well.'),
    'prednisolone': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Vigorously shake suspension 10 seconds.'),
    'pred forte': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Shake bottle vigorously.'),
    'dexamethasone': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Shake well before instillation.'),
    'maxidex': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Shake well before instillation.'),
    'loteprednol': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Lotemax: Shake suspension.'),
    'lotemax': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Shake suspension.'),
    'difluprednate': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Durezol: Do not shake emulsion.'),
    'durezol': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Ophthalmic emulsion: Do not shake.'),
    'erythromycin': (category: MedCategory.eyeOintment, unit: DosageUnit.applyTopical, isEye: true, isOintment: true, isNti: false, chrono: 'Apply at bedtime. Blurs vision temporarily.'),
    'ketorolac': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Acular: Space 5 min from other drops.'),
    'nepafenac': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Nevanac: Shake bottle.'),
    'nevanac': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Shake bottle.'),
    'bromfenac': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Prolensa: Once daily.'),
    'cyclosporine': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Restasis: Invert vial 4-5 times.'),
    'restasis': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Invert single-use vial.'),
    'cequa': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Cyclosporine 0.09%: Twice daily.'),
    'lifitegrast': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Xiidra: Space 15 min from contact lenses.'),
    'xiidra': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Space 15 min from contact lenses.'),
    'olopatadine': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Pataday: Once daily.'),
    'patanol': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Twice daily.'),
    'pataday': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Once daily morning.'),
    'carboxymethylcellulose': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Artificial tears: Use as needed PRN.'),
    'refresh tears': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Use PRN throughout day.'),
    'systane': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: false, chrono: 'Shake well. Use PRN.'),
    'atropine': (category: MedCategory.eyeDrop, unit: DosageUnit.drops, isEye: true, isOintment: false, isNti: true, chrono: 'Apply 2-3 min punctal occlusion.'),

    // ❤️ Anticoagulation & Antiplatelets (Narrow Therapeutic Index)
    'warfarin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Take at 18:00 (evening) consistently. Maintain stable Vitamin K intake.'),
    'coumadin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Take at 18:00 consistently.'),
    'apixaban': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Eliquis: Strict 12h spacing (08:00 & 20:00).'),
    'eliquis': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Strict 12h spacing (08:00 & 20:00).'),
    'rivaroxaban': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Xarelto: Take with evening meal for full absorption.'),
    'xarelto': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Take with evening meal for absorption.'),
    'dabigatran': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: true, chrono: 'Pradaxa: Swallow whole with full water glass. Do not chew.'),
    'pradaxa': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: true, chrono: 'Swallow whole with full glass of water.'),
    'clopidogrel': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Plavix: Once daily with or without food.'),
    'plavix': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Once daily with or without food.'),
    'ticagrelor': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Brilinta: Twice daily (08:00 & 20:00).'),
    'brilinta': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Twice daily with low-dose aspirin.'),
    'aspirin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take after meal with full glass of water.'),
    'ecosprin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take after food.'),

    // 🫀 Blood Pressure, Heart Failure & Statins
    'atorvastatin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take at bedtime (21:30) for peak hepatic HMG-CoA reductase inhibition.'),
    'atorva': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take at bedtime.'),
    'lipitor': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take at bedtime (21:30).'),
    'rosuvastatin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Crestor: Once daily any time, bedtime preferred.'),
    'crestor': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Once daily in evening.'),
    'simvastatin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Strict bedtime administration required.'),
    'zocor': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take strictly at bedtime.'),
    'amlodipine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Norvasc: Take morning or bedtime (night reduces ankle edema).'),
    'norvasc': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Once daily.'),
    'amlong': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Once daily.'),
    'telmisartan': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Micardis: Morning or bedtime (bedtime restores nocturnal dip).'),
    'telma': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Once daily after breakfast.'),
    'losartan': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Cozaar: Morning or divided BD.'),
    'valsartan': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Diovan: Morning or twice daily.'),
    'entresto': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Sacubitril/Valsartan: Strict twice daily (08:00 & 20:00).'),
    'metoprolol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Toprol: Take with or immediately after food.'),
    'toprol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take with or immediately after food.'),
    'carvedilol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Coreg: Always take with food to minimize orthostatic hypotension.'),
    'coreg': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Always take with food.'),
    'bisoprolol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Zebeta: Once daily morning.'),
    'ramipril': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Altace: Morning or bedtime.'),
    'lisinopril': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Zestril: Morning.'),
    'spironolactone': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Aldactone: Morning with meal. Avoid extra potassium.'),
    'aldactone': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Take with morning breakfast.'),
    'furosemide': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Lasix: Morning (08:00) to prevent sleep-disrupting nocturia.'),
    'lasix': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take in morning (08:00) to prevent nighttime urination.'),
    'torsemide': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take in morning.'),
    'hydrochlorothiazide': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'HCTZ: Morning with breakfast.'),
    'hctz': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Morning with food.'),
    'digoxin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Lanoxin: Strict NTI. Same time daily.'),
    'lanoxin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Narrow therapeutic index. Do not miss.'),

    // 🩸 Diabetes & GLP-1 / SGLT2 Incretins
    'semaglutide': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Rybelsus: Take first thing upon waking with <=120ml water, wait 30m before food.'),
    'rybelsus': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take first thing in morning with sip of plain water only. Wait 30 min before eating.'),
    'ozempic': (category: MedCategory.injectable, unit: DosageUnit.units, isEye: false, isOintment: false, isNti: false, chrono: 'Inject subcutaneously once weekly on the same day.'),
    'wegovy': (category: MedCategory.injectable, unit: DosageUnit.units, isEye: false, isOintment: false, isNti: false, chrono: 'Once weekly subcutaneous injection.'),
    'tirzepatide': (category: MedCategory.injectable, unit: DosageUnit.units, isEye: false, isOintment: false, isNti: false, chrono: 'Mounjaro: Once weekly subcutaneous.'),
    'mounjaro': (category: MedCategory.injectable, unit: DosageUnit.units, isEye: false, isOintment: false, isNti: false, chrono: 'Once weekly.'),
    'metformin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Always take with meals to reduce GI upset.'),
    'glycomet': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take with meals.'),
    'glucophage': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take with food.'),
    'empagliflozin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Jardiance: Morning with or without food. Stay hydrated.'),
    'jardiance': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take in morning with plenty of water.'),
    'dapagliflozin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Farxiga: Morning with water.'),
    'forxiga': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Morning with water.'),
    'farxiga': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Morning with water.'),
    'sitagliptin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Januvia: Once daily with or without food.'),
    'januvia': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Once daily.'),
    'glimepiride': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Amaryl: Take immediately before breakfast.'),
    'amaryl': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take with first main meal.'),
    'insulin glargine': (category: MedCategory.injectable, unit: DosageUnit.units, isEye: false, isOintment: false, isNti: true, chrono: 'Lantus: Basal insulin. Inject at same hour every night.'),
    'lantus': (category: MedCategory.injectable, unit: DosageUnit.units, isEye: false, isOintment: false, isNti: true, chrono: 'Inject at same hour every night.'),

    // 🧪 Thyroid & Endocrine
    'levothyroxine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Take at 07:00 on empty stomach with water 60m before breakfast. Space 4h from calcium/iron.'),
    'synthroid': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Take 60 min before breakfast with plain water.'),
    'thyronorm': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Empty stomach early morning with water.'),
    'eltroxin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: true, chrono: 'Empty stomach morning.'),

    // 🧬 Gastroenterology & Acid Suppression
    'pantoprazole': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Protonix: Take 30-60 min before breakfast for maximal H+/K+ ATPase inhibition.'),
    'pan': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: '30 min before breakfast.'),
    'pantocid': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: '30 min before breakfast.'),
    'omeprazole': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Prilosec: 30-60 min before first meal.'),
    'omez': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: '30 min before food.'),
    'esomeprazole': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Nexium: 30-60 min before breakfast.'),
    'nexium': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: '30 min before food.'),
    'rabeprazole': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: '30 min before breakfast.'),
    'famotidine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Pepcid: Bedtime or 30 min before trigger meal.'),
    'pepcid': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take before meal or at bedtime.'),
    'ondansetron': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Zofran: 30 min before chemotherapy or as needed.'),
    'zofran': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take as needed for nausea.'),
    'emset': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take as needed.'),

    // 💊 Antibiotics, Antivirals & Antifungals
    'amoxicillin': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Space every 8 or 12 hours. Complete full course.'),
    'augmentin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Amoxicillin/Clavulanate: Take at start of meal to minimize diarrhea.'),
    'azithromycin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Zithromax: Once daily. 1h before or 2h after food.'),
    'zithromax': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Once daily. Complete 3-5 day pack.'),
    'cefixime': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take with or after food.'),
    'doxycycline': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Take with full glass of water. Do NOT lie down for 30m (prevents pill esophagitis).'),
    'metronidazole': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Flagyl: STRICTLY NO ALCOHOL during therapy + 48h after (disulfiram reaction).'),
    'flagyl': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Avoid all alcohol.'),
    'cipro': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Space 2h before or 6h after dairy/calcium/antacids.'),
    'levofloxacin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Levaquin: Take with plenty of fluids. Space from minerals.'),
    'nitrofurantoin': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Macrobid: Always take with meals or milk.'),
    'macrobid': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Take twice daily with food.'),
    'fluconazole': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Diflucan: With or without food.'),
    'acyclovir': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Maintain good hydration.'),
    'valacyclovir': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Valtrex: Drink plenty of water.'),

    // 🩹 Pain, Anti-inflammatory & Corticosteroids
    'paracetamol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Max 4000mg/day (2000-3000mg in seniors). Space min 4-6h.'),
    'acetaminophen': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Tylenol: Max 4g daily. Space 4-6 hours.'),
    'tylenol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Max 4g daily.'),
    'dolo': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take as needed for pain/fever. Max 4 tablets daily.'),
    'calpol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take after meals for fever/pain.'),
    'crocin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take as needed.'),
    'ibuprofen': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Advil/Motrin: Always take with food or milk.'),
    'advil': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take with food.'),
    'motrin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take with food.'),
    'combiflam': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Ibuprofen + Paracetamol: Take strictly after food.'),
    'naproxen': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Aleve: Take with food and full glass of water.'),
    'aleve': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take with food.'),
    'celecoxib': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Celebrex: With food.'),
    'diclofenac': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Voltaren: Take after food.'),
    'voveran': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take with or after meals.'),
    'aceclofenac': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take after food.'),
    'zerodol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take after food.'),
    'prednisone': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take in morning (08:00) with food to mimic diurnal cortisol rhythm and prevent insomnia.'),
    'methylprednisolone': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Medrol Dosepak: Take morning with food.'),
    'tramadol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Controlled pain agent: Causes drowsiness.'),

    // 🧠 Neurology, Mental Health & Sleep
    'gabapentin': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Neurontin: Nighttime titration to avoid daytime sedation.'),
    'neurontin': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Take at bedtime.'),
    'pregabalin': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Lyrica: Bedtime or divided BD.'),
    'lyrica': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Evening or bedtime.'),
    'sertraline': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Zoloft: Morning with breakfast (avoids insomnia).'),
    'zoloft': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Morning with food.'),
    'escitalopram': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Lexapro: Morning with or without food.'),
    'lexapro': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Morning with water.'),
    'duloxetine': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Cymbalta: Morning with breakfast.'),
    'cymbalta': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Morning with food.'),
    'bupropion': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Wellbutrin: Morning. Never take at bedtime (seizure risk / insomnia).'),
    'wellbutrin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Morning only. Do not take at night.'),
    'alprazolam': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Xanax: Short-term PRN. Caution: sedation.'),
    'clonazepam': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Klonopin: Bedtime administration.'),
    'zolpidem': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Ambien: Take immediately before getting into bed. Allow 7-8h sleep.'),
    'ambien': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take right before sleep.'),
    'melatonin': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take 30-60 min before planned sleep time.'),

    // 🌬️ Pulmonology & Allergy
    'albuterol': (category: MedCategory.inhaler, unit: DosageUnit.puffs, isEye: false, isOintment: false, isNti: false, chrono: 'ProAir/Ventolin: Rapid rescue inhaler. Rinse mouth after use.'),
    'ventolin': (category: MedCategory.inhaler, unit: DosageUnit.puffs, isEye: false, isOintment: false, isNti: false, chrono: 'Rescue inhaler. 1-2 puffs as needed.'),
    'salbutamol': (category: MedCategory.inhaler, unit: DosageUnit.puffs, isEye: false, isOintment: false, isNti: false, chrono: 'Rescue inhaler. Rinse mouth.'),
    'asthalin': (category: MedCategory.inhaler, unit: DosageUnit.puffs, isEye: false, isOintment: false, isNti: false, chrono: 'Rescue inhaler.'),
    'symbicort': (category: MedCategory.inhaler, unit: DosageUnit.puffs, isEye: false, isOintment: false, isNti: false, chrono: 'Budesonide/Formoterol: Rinse and spit with water after each use to prevent thrush.'),
    'foracort': (category: MedCategory.inhaler, unit: DosageUnit.puffs, isEye: false, isOintment: false, isNti: false, chrono: 'Rinse mouth with water and spit.'),
    'advair': (category: MedCategory.inhaler, unit: DosageUnit.puffs, isEye: false, isOintment: false, isNti: false, chrono: 'Fluticasone/Salmeterol: Rinse and spit.'),
    'montelukast': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Singulair: Take in the evening (asthma chronotherapy).'),
    'singulair': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take in the evening.'),
    'montek': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take in the evening.'),
    'levocetirizine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take at bedtime (mild drowsiness).'),
    'levocet': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take at bedtime.'),
    'cetirizine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Zyrtec: Evening or bedtime.'),
    'allegra': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Fexofenadine: Take with water only. Avoid fruit juices.'),
    'fexofenadine': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Avoid taking with grapefruit or orange juice.'),

    // 🦴 Minerals, Vitamins & Supplements
    'calcium': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take with meals for optimal absorption. Space from iron and thyroid meds.'),
    'shelcal': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Take with food.'),
    'vitamin d3': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Take with main fat-containing meal for absorption.'),
    'cholecalciferol': (category: MedCategory.oral, unit: DosageUnit.capsules, isEye: false, isOintment: false, isNti: false, chrono: 'Take with meal containing dietary fat.'),
    'neurobion': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'B-complex: Take after breakfast.'),
    'allopurinol': (category: MedCategory.oral, unit: DosageUnit.tablets, isEye: false, isOintment: false, isNti: false, chrono: 'Zyloprim: Take after meals with lots of water to prevent kidney stones.'),
  };

  // ──────────────────────────────────────────────────────────
  // OCR Noise De-mangler & Preprocessor
  // ──────────────────────────────────────────────────────────
  String cleanOcrDeMangle(String rawText) {
    if (rawText.isEmpty) return rawText;
    String text = rawText;

    // Common OCR character substitution fixes in medical contexts
    // 1. Matrix notation fixes: 1-O-1 -> 1-0-1, 1-O-O -> 1-0-0, O-O-1 -> 0-0-1
    text = text.replaceAllMapped(RegExp(r'\b([01Ool])\s*[-/]\s*([01Ool])\s*[-/]\s*([01Ool])\b', caseSensitive: false), (m) {
      String cleanChar(String c) {
        c = c.toLowerCase();
        if (c == 'o') return '0';
        if (c == 'l') return '1';
        return c;
      }
      return '${cleanChar(m.group(1)!)} - ${cleanChar(m.group(2)!)} - ${cleanChar(m.group(3)!)}';
    });

    // 2. Dosage strength fixes: "S00mg" -> "500mg", "l0mg" -> "10mg", "2.Smg" -> "2.5mg"
    text = text.replaceAllMapped(RegExp(r'\b([SsoOlI\d]+)\s*(mg|mcg|ml|g|gm|%)\b', caseSensitive: false), (m) {
      String num = m.group(1)!
          .replaceAll(RegExp(r'[S]'), '5')
          .replaceAll(RegExp(r'[s]'), '5')
          .replaceAll(RegExp(r'[oO]'), '0')
          .replaceAll(RegExp(r'[lI]'), '1');
      return '$num ${m.group(2)!}';
    });

    // 3. Common abbreviations: "8D" -> "BD", "T1D" -> "TID", "Q1D" -> "QID"
    text = text.replaceAll(RegExp(r'\b8[Dd]\b'), 'BD');
    text = text.replaceAll(RegExp(r'\bT1[Dd]\b'), 'TID');
    text = text.replaceAll(RegExp(r'\bQ1[Dd]\b'), 'QID');
    text = text.replaceAll(RegExp(r'\bP\.?O\.?\b', caseSensitive: false), 'PO');
    text = text.replaceAll(RegExp(r'\bB\.?I\.?D\.?\b', caseSensitive: false), 'BID');
    text = text.replaceAll(RegExp(r'\bT\.?I\.?D\.?\b', caseSensitive: false), 'TID');
    text = text.replaceAll(RegExp(r'\bQ\.?I\.?D\.?\b', caseSensitive: false), 'QID');

    return text;
  }

  // ──────────────────────────────────────────────────────────
  // Main Parsing Entry Point
  // ──────────────────────────────────────────────────────────
  List<ParsedMedicationDraft> parsePrescription(String rawOcrText) {
    if (rawOcrText.trim().isEmpty) return [];

    final cleanText = cleanOcrDeMangle(rawOcrText);
    final lines = cleanText.split(RegExp(r'[\r\n]+'));
    final List<String> candidateBlocks = [];
    final StringBuffer currentBlock = StringBuffer();

    // 1. Filter out clinic headers, doctor bio, patient demographics, vitals
    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (_isHeaderOrDemographicNoise(line)) continue;

      // Check if line starts with a medication index e.g., "1.", "2)", "•", "Rx", "R/"
      final isNewMedicationEntry = RegExp(r'^(\d+[\.\)]\s*|[•\-\*]\s*|(Rx|R/|Tab|Cap|Syr|Gutt|Eye\s+Drop)\s+)', caseSensitive: false).hasMatch(line);

      if (isNewMedicationEntry && currentBlock.isNotEmpty) {
        candidateBlocks.add(currentBlock.toString().trim());
        currentBlock.clear();
      }

      currentBlock.write(' $line');
    }

    if (currentBlock.isNotEmpty) {
      candidateBlocks.add(currentBlock.toString().trim());
    }

    // Fallback: If blocks yielded nothing or only 1 single line, inspect line-by-line
    final effectiveCandidates = candidateBlocks.isNotEmpty ? candidateBlocks : lines;

    final List<ParsedMedicationDraft> results = [];

    for (final cand in effectiveCandidates) {
      final parsed = _parseSingleCandidate(cand);
      if (parsed != null) {
        // Prevent duplicate names in result set
        if (!results.any((r) => r.name.toLowerCase() == parsed.name.toLowerCase())) {
          results.add(parsed);
        }
      }
    }

    // Fallback generic line search if dictionary didn't trigger
    if (results.isEmpty) {
      for (final line in lines) {
        if (!_isHeaderOrDemographicNoise(line) && line.length > 5) {
          final fallback = _parseGenericLine(line);
          if (fallback != null && !results.any((r) => r.name.toLowerCase() == fallback.name.toLowerCase())) {
            results.add(fallback);
          }
        }
      }
    }

    // ──────────────────────────────────────────────────────────
    // Prescription Safety Radar (Cohort-Wide Safety Analysis)
    // ──────────────────────────────────────────────────────────
    _applyPrescriptionSafetyRadar(results);

    return results;
  }

  // ──────────────────────────────────────────────────────────
  // Candidate Analysis & Entity Extraction
  // ──────────────────────────────────────────────────────────
  ParsedMedicationDraft? _parseSingleCandidate(String text) {
    final lower = text.toLowerCase();
    String detectedName = '';
    String detectedStrength = '';
    MedCategory detectedCategory = MedCategory.oral;
    DosageUnit detectedUnit = DosageUnit.tablets;
    bool isEyeMed = false;
    bool isOint = false;
    bool isNti = false;
    String? chronoAdvice;
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
        isNti = entry.value.isNti;
        chronoAdvice = entry.value.chrono;
        confidence = 0.98;
        break;
      }
    }

    // 1b. AI Fuzzy Typo Correction (Levenshtein Distance) for messy handwriting & OCR typos
    if (detectedName.isEmpty) {
      final words = lower.replaceAll(RegExp(r'[^a-z0-9\s\-]'), ' ').split(RegExp(r'\s+'));
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
            isNti = entry.value.isNti;
            chronoAdvice = entry.value.chrono;
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

    // 3. Extract Strength (e.g., 500mg, 0.5%, 2.5mcg, 10ml, 100iu)
    final strengthMatch = RegExp(r'(\d+(?:\.\d+)?\s*(?:mg|mcg|ml|%|g|iu|IU|gm))', caseSensitive: false).firstMatch(text);
    if (strengthMatch != null) {
      detectedStrength = strengthMatch.group(0)!.trim();
    }

    // 4. Extract Frequency, Timing & Chrono Alignment
    final frequencyInfo = _extractFrequency(text, detectedName);

    // 5. Extract Duration in Days
    final durationDays = _extractDuration(text);

    // 6. Extract Food / Administration Instruction
    final instruction = _extractInstruction(text, isEyeMed);

    // 7. Extract Eye Target & Route
    String? eyeTarget;
    String route = 'Oral (PO)';
    if (isEyeMed) {
      route = isOint ? 'Ophthalmic Ointment' : 'Ophthalmic (GTT)';
      if (lower.contains('left eye') || lower.contains('(os)') || RegExp(r'\bos\b').hasMatch(lower)) {
        eyeTarget = 'Left Eye (OS)';
      } else if (lower.contains('right eye') || lower.contains('(od)') || (RegExp(r'\bod\b').hasMatch(lower) && !frequencyInfo.raw.contains('OD'))) {
        eyeTarget = 'Right Eye (OD)';
      } else {
        eyeTarget = 'Both Eyes (OU)';
      }
    } else if (detectedCategory == MedCategory.inhaler) {
      route = 'Inhalation (INH)';
    } else if (detectedCategory == MedCategory.injectable) {
      route = 'Subcutaneous / Injectable (SC)';
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
      route: route,
      totalQuantity: calculatedQty,
      clinicalNotes: _extractClinicalNotes(text),
      chronotherapyAdvice: chronoAdvice,
      isNarrowTherapeuticIndex: isNti,
      confidence: confidence,
      correctedFrom: typoCorrectedFrom,
    );
  }

  // ──────────────────────────────────────────────────────────
  // Heuristic Frequency & Timing Extractor (Latin & Matrix)
  // ──────────────────────────────────────────────────────────
  ({String raw, String label, List<String> scheduleTimes}) _extractFrequency(String text, String drugName) {
    final lower = text.toLowerCase();
    final drugLower = drugName.toLowerCase();

    // 1. Matrix pattern: 1-0-1, 1-1-1, 1-0-0, 0-1-0, 0-0-1, 1-1-1-1, 0.5-0-0.5, 1/2-0-1/2
    final matrixMatch = RegExp(r'\b([01](?:\.5|\/2)?)\s*[-/]\s*([01](?:\.5|\/2)?)\s*[-/]\s*([01](?:\.5|\/2)?)(?:\s*[-/]\s*([01](?:\.5|\/2)?))?\b').firstMatch(text);
    if (matrixMatch != null) {
      final m = matrixMatch.group(1)!;
      final a = matrixMatch.group(2)!;
      final n = matrixMatch.group(3)!;
      final fourth = matrixMatch.group(4);

      if (fourth != null && fourth != '0') {
        return (raw: '$m-$a-$n-$fourth', label: 'Four times daily (QID)', scheduleTimes: ['08:00', '12:00', '16:00', '20:00']);
      }
      if (m != '0' && a != '0' && n != '0') {
        return (raw: '$m-$a-$n', label: 'Three times daily (TDS)', scheduleTimes: ['08:00', '14:00', '20:00']);
      }
      if (m != '0' && n != '0') {
        return (raw: '$m-0-$n', label: 'Twice daily (BD / 12h)', scheduleTimes: ['08:00', '20:00']);
      }
      if (m != '0') {
        final time = (drugLower == 'pan' || drugLower.startsWith('pan ') || drugLower.contains('panto') || drugLower.contains('thyroid') || drugLower.contains('levothyroxine') || drugLower.contains('omeprazole'))
            ? ['07:00']
            : ['08:00'];
        return (raw: '$m-0-0', label: 'Once daily (Morning)', scheduleTimes: time);
      }
      if (a != '0') {
        return (raw: '0-$a-0', label: 'Once daily (Afternoon)', scheduleTimes: ['13:00']);
      }
      if (n != '0') {
        return (raw: '0-0-$n', label: 'Once daily (Bedtime)', scheduleTimes: ['21:30']);
      }
    }

    // 2. Specific Interval Sigs: Q4H, Q6H, Q8H, Q12H
    if (RegExp(r'\bq4h\b').hasMatch(lower)) {
      return (raw: 'Q4H', label: 'Every 4 hours', scheduleTimes: ['06:00', '10:00', '14:00', '18:00', '22:00', '02:00']);
    }
    if (RegExp(r'\bq6h\b').hasMatch(lower)) {
      return (raw: 'Q6H', label: 'Every 6 hours (4x daily)', scheduleTimes: ['06:00', '12:00', '18:00', '24:00']);
    }
    if (RegExp(r'\bq8h\b').hasMatch(lower)) {
      return (raw: 'Q8H', label: 'Every 8 hours (3x daily)', scheduleTimes: ['08:00', '16:00', '24:00']);
    }
    if (RegExp(r'\bq12h\b').hasMatch(lower)) {
      return (raw: 'Q12H', label: 'Every 12 hours (Twice daily)', scheduleTimes: ['08:00', '20:00']);
    }

    // 3. Standard Medical Abbreviations
    if (RegExp(r'\b(qid|four times daily|4 times daily|4 times a day)\b').hasMatch(lower)) {
      return (raw: 'QID', label: 'Four times daily', scheduleTimes: ['08:00', '12:00', '16:00', '20:00']);
    }
    if (RegExp(r'\b(tid|tds|three times daily|3 times daily|3 times a day)\b').hasMatch(lower)) {
      return (raw: 'TDS / TID', label: 'Three times daily', scheduleTimes: ['08:00', '14:00', '20:00']);
    }
    if (RegExp(r'\b(bid|bd|twice daily|2 times daily|2 times a day)\b').hasMatch(lower)) {
      return (raw: 'BD / BID', label: 'Twice daily', scheduleTimes: ['08:00', '20:00']);
    }
    if (RegExp(r'\b(hs|qhs|at bedtime|bedtime|night only|on)\b').hasMatch(lower)) {
      return (raw: 'HS', label: 'At bedtime', scheduleTimes: ['21:30']);
    }
    if (RegExp(r'\b(od|once daily|1 time daily|once a day|daily|qd|qam|om)\b').hasMatch(lower)) {
      // Smart chronobiology time resolution based on molecule type
      if (drugLower.contains('statin') || drugLower.contains('latanoprost') || drugLower.contains('bimatoprost') || drugLower.contains('montelukast')) {
        return (raw: 'OD (Bedtime)', label: 'Once daily (Night)', scheduleTimes: ['21:30']);
      }
      if (drugLower.contains('thyroid') || drugLower.contains('levothyroxine') || drugLower.contains('panto') || drugLower.contains('omeprazole')) {
        return (raw: 'OD (Morning Fasting)', label: 'Once daily (Fasting)', scheduleTimes: ['07:00']);
      }
      return (raw: 'OD', label: 'Once daily', scheduleTimes: ['08:00']);
    }
    if (RegExp(r'\b(qod|every other day)\b').hasMatch(lower)) {
      return (raw: 'QOD', label: 'Every other day', scheduleTimes: ['08:00']);
    }
    if (RegExp(r'\b(qweek|once weekly|qwk)\b').hasMatch(lower)) {
      return (raw: 'QWK', label: 'Once weekly', scheduleTimes: ['09:00']);
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

    // Match "x 2 weeks", "for 1 week", "2 wks", "2w"
    final weeksMatch = RegExp(r'(?:x|for|\*|\/)?\s*(\d+)\s*(?:weeks?|wks?|wk\b|w\b)', caseSensitive: false).firstMatch(lower);
    if (weeksMatch != null) {
      final w = int.tryParse(weeksMatch.group(1)!);
      if (w != null) return w * 7;
    }

    // Match "1 month", "x 1 month", "3 months", "1m"
    final monthMatch = RegExp(r'(?:x|for|\*|\/)?\s*(\d+)\s*(?:months?|mths?|m\b)', caseSensitive: false).firstMatch(lower);
    if (monthMatch != null) {
      final m = int.tryParse(monthMatch.group(1)!);
      if (m != null) return m * 30;
    }

    // Match "till next visit" or "continue"
    if (lower.contains('till next visit') || lower.contains('review after')) {
      return 30;
    }

    return null;
  }

  // ──────────────────────────────────────────────────────────
  // Food & Administration Instruction Extractor
  // ──────────────────────────────────────────────────────────
  AdminInstruction _extractInstruction(String text, bool isEyeMed) {
    if (isEyeMed) return AdminInstruction.asNeeded;
    final lower = text.toLowerCase();

    if (RegExp(r'\b(b\/f|bbf|ac|before food|before meal|before breakfast|empty stomach)\b').hasMatch(lower)) {
      return AdminInstruction.beforeMeal;
    }
    if (RegExp(r'\b(a\/f|abf|pc|after food|after meal|with food|post meal|after meals)\b').hasMatch(lower)) {
      return AdminInstruction.afterMeal;
    }
    if (RegExp(r'\b(with meals|during meal|with food|cc)\b').hasMatch(lower)) {
      return AdminInstruction.withMeal;
    }
    if (RegExp(r'\b(hs|qhs|at bedtime|bedtime)\b').hasMatch(lower)) {
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
      return 'Shake bottle well before administration.';
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
      'follow up', 'next visit',
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

  // ──────────────────────────────────────────────────────────
  // Prescription Safety Radar (Cohort-Wide Safety Pre-screening)
  // ──────────────────────────────────────────────────────────
  void _applyPrescriptionSafetyRadar(List<ParsedMedicationDraft> drafts) {
    if (drafts.isEmpty) return;

    final names = drafts.map((d) => d.name.toLowerCase()).toList();

    // 1. Dual Ophthalmic Spacing Warning (Washout Prevention)
    final eyeDrops = drafts.where((d) => d.isEyeMedication).toList();
    if (eyeDrops.length >= 2) {
      for (final ed in eyeDrops) {
        ed.safetyWarning = 'OPHTHALMIC SPACING: Wait at least 5 minutes before administering the next eye drop to prevent tear-film washout.';
      }
    }

    // 2. High Bleed Risk: Anticoagulant + NSAID / Aspirin
    final hasAnticoagulant = names.any((n) => n.contains('warfarin') || n.contains('apixaban') || n.contains('rivaroxaban') || n.contains('dabigatran') || n.contains('eliquis') || n.contains('xarelto'));
    final hasNsaid = names.any((n) => n.contains('aspirin') || n.contains('ibuprofen') || n.contains('naproxen') || n.contains('diclofenac') || n.contains('combiflam') || n.contains('aceclofenac'));

    if (hasAnticoagulant && hasNsaid) {
      for (final d in drafts) {
        final n = d.name.toLowerCase();
        if (n.contains('warfarin') || n.contains('apixaban') || n.contains('rivaroxaban') || n.contains('aspirin') || n.contains('ibuprofen') || n.contains('diclofenac')) {
          d.safetyWarning = 'MAJOR DDI BLEED HAZARD: Concurrent Anticoagulant + NSAID significantly increases severe GI bleeding risk. Confirm with your doctor.';
        }
      }
    }

    // 3. Statin + Grapefruit / CYP3A4 Notice
    for (final d in drafts) {
      if (d.name.toLowerCase().contains('atorvastatin') || d.name.toLowerCase().contains('simvastatin')) {
        d.clinicalNotes = (d.clinicalNotes != null ? '${d.clinicalNotes!} • ' : '') + 'Avoid grapefruit juice (inhibits CYP3A4 metabolism).';
      }
    }
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
        confidence: 0.65,
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
      subtitle: 'Oral medications with Indian matrix (1-0-1, 1-0-0) & days',
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
      subtitle: 'Maintenance medications with statin & metformin timing',
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
    (
      title: '⚡ Complex Polypharmacy & High Bleed Risk',
      subtitle: 'Warfarin + Aspirin DDI & Thyroxine Fasting Schedule',
      text: '''
ROYAL HEALTHCARE ADVANCED GERIATRIC WARD
Dr. Amanda Brooks, MD (Cardiology & Geriatrics)
Patient: Evelyn Wright | Age: 72

Rx:
1. Tab Warfarin 2.5mg 0-0-1 at 18:00 evening with water x 30 days
2. Tab Aspirin 81mg 1-0-0 morning after food x 30 days
3. Tab Levothyroxine 50mcg 1-0-0 empty stomach 60 min before breakfast x 30 days
4. Tab Lasix 40mg 1-0-0 morning 08:00 x 30 days
'''
    ),
  ];
}
