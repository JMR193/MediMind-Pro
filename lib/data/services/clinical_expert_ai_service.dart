import '../../domain/models/medication.dart';

enum CircadianWindow {
  morningAwakening, // 06:00 - 08:30 (Cortisol peak, thyroid, PPIs)
  midDay,            // 11:30 - 13:30 (Lunchtime, sustained release)
  lateAfternoon,     // 16:00 - 18:00 (Pre-dinner)
  bedtimeNocturnal,  // 20:30 - 23:00 (Statins, glaucoma drops, sedatives, evening BP)
  flexible,          // Any consistent timing
}

class CircadianRule {
  final String drugPattern;
  final CircadianWindow optimalWindow;
  final String targetHourString; // e.g. "07:30", "21:30"
  final AdminInstruction targetInstruction;
  final String clinicalRationale;
  final String biologicalMechanism;

  const CircadianRule({
    required this.drugPattern,
    required this.optimalWindow,
    required this.targetHourString,
    required this.targetInstruction,
    required this.clinicalRationale,
    required this.biologicalMechanism,
  });
}

class ChronotherapyEvaluation {
  final Medication medication;
  final bool isOptimallyAligned;
  final CircadianRule rule;
  final String currentScheduledTime;
  final String recommendedTime;
  final String recommendationText;

  const ChronotherapyEvaluation({
    required this.medication,
    required this.isOptimallyAligned,
    required this.rule,
    required this.currentScheduledTime,
    required this.recommendedTime,
    required this.recommendationText,
  });
}

class MissedDoseSafetyAssessment {
  final bool canTakeImmediately;
  final String safetyRecommendation;
  final double elapsedIntervalFraction; // 0.0 to 1.0+
  final String clinicalRationale;
  final bool isNarrowTherapeuticIndex;

  const MissedDoseSafetyAssessment({
    required this.canTakeImmediately,
    required this.safetyRecommendation,
    required this.elapsedIntervalFraction,
    required this.clinicalRationale,
    required this.isNarrowTherapeuticIndex,
  });
}

class ParsedMedicalSig {
  final String rawInput;
  final String medicationName;
  final String strength;
  final MedCategory category;
  final DosageUnit dosageUnit;
  final double dosageAmount;
  final AdminInstruction instruction;
  final String frequency;
  final List<String> scheduleTimes;
  final String englishTranslation;

  const ParsedMedicalSig({
    required this.rawInput,
    required this.medicationName,
    required this.strength,
    required this.category,
    required this.dosageUnit,
    required this.dosageAmount,
    required this.instruction,
    required this.frequency,
    required this.scheduleTimes,
    required this.englishTranslation,
  });
}

/// Pre-Configured Clinical AI Decision Support System (CDSS)
/// Deterministic Expert Engines grounded in pharmacokinetics, chronotherapy, and geriatric pharmacovigilance.
class ClinicalExpertAiService {
  // Pre-configured chronobiological drug rules grounded in clinical evidence
  static final List<CircadianRule> _circadianRules = [
    // 1. Statins (HMG-CoA Reductase Inhibitors)
    const CircadianRule(
      drugPattern: 'statin|atorvastatin|simvastatin|rosuvastatin|pravastatin|lovastatin',
      optimalWindow: CircadianWindow.bedtimeNocturnal,
      targetHourString: '21:30',
      targetInstruction: AdminInstruction.atBedtime,
      clinicalRationale: 'Hepatic HMG-CoA reductase and physiological cholesterol synthesis peak between midnight and 04:00 AM.',
      biologicalMechanism: 'Bedtime dosing guarantees peak plasma concentration coincides with nocturnal endogenous lipogenesis.',
    ),
    // 2. Proton Pump Inhibitors (PPIs)
    const CircadianRule(
      drugPattern: 'prazole|omeprazole|pantoprazole|esomeprazole|lansoprazole|rabeprazole',
      optimalWindow: CircadianWindow.morningAwakening,
      targetHourString: '07:00',
      targetInstruction: AdminInstruction.beforeMeal,
      clinicalRationale: 'Inactivates newly synthesized H+/K+-ATPase gastric proton pumps activated by morning breakfast.',
      biologicalMechanism: 'Administer 30-60 minutes prior to first meal; food is required to stimulate pumps for covalent blockade.',
    ),
    // 3. Glaucoma Prostaglandin Analogues
    const CircadianRule(
      drugPattern: 'prost|latanoprost|bimatoprost|travoprost|tafluprost',
      optimalWindow: CircadianWindow.bedtimeNocturnal,
      targetHourString: '21:00',
      targetInstruction: AdminInstruction.atBedtime,
      clinicalRationale: 'Reduces early morning diurnal Intraocular Pressure (IOP) spike while conjunctival hyperemia clears overnight.',
      biologicalMechanism: 'Up-regulates matrix metalloproteinases in the ciliary muscle, optimizing uveoscleral aqueous outflow during nocturnal supine posture.',
    ),
    // 4. Glaucoma Beta-Blockers
    const CircadianRule(
      drugPattern: 'timolol|betaxolol|levobunolol|carteolol',
      optimalWindow: CircadianWindow.morningAwakening,
      targetHourString: '08:00',
      targetInstruction: AdminInstruction.asNeeded,
      clinicalRationale: 'Aqueous humor production is high during wakefulness and minimal during sleep.',
      biologicalMechanism: 'Beta-blockers suppress active diurnal aqueous secretion; nocturnal administration causes excessive nighttime bradycardia with zero added IOP reduction.',
    ),
    // 5. Corticosteroids
    const CircadianRule(
      drugPattern: 'prednisone|prednisolone|methylprednisolone|dexamethasone|hydrocortisone',
      optimalWindow: CircadianWindow.morningAwakening,
      targetHourString: '08:00',
      targetInstruction: AdminInstruction.withMeal,
      clinicalRationale: 'Matches endogenous ACTH and cortisol circadian rhythm, minimizing adrenal atrophy and insomnia.',
      biologicalMechanism: 'Suppresses inflammatory cascades when daily cortisol naturally spikes, preserving the hypothalamic-pituitary-adrenal (HPA) axis.',
    ),
    // 6. Thyroid Hormone Replacement
    const CircadianRule(
      drugPattern: 'levothyroxine|synthroid|eltroxin|euthyrox',
      optimalWindow: CircadianWindow.morningAwakening,
      targetHourString: '06:30',
      targetInstruction: AdminInstruction.emptyStomach,
      clinicalRationale: 'Requires acidic gastric pH for optimal ileal absorption; food, coffee, calcium, and iron bind T4.',
      biologicalMechanism: 'Administer on empty stomach with a full glass of water 30-60 min before breakfast or calcium/iron supplements.',
    ),
    // 7. Antihypertensives (ACEi / ARB / CCB)
    const CircadianRule(
      drugPattern: 'pril|sartan|dipine|lisinopril|ramipril|losartan|telmisartan|valsartan|amlodipine',
      optimalWindow: CircadianWindow.bedtimeNocturnal,
      targetHourString: '21:00',
      targetInstruction: AdminInstruction.atBedtime,
      clinicalRationale: 'Converts dangerous nocturnal "non-dipper" hypertension into a protective dipping curve, lowering stroke risk.',
      biologicalMechanism: 'Renin-angiotensin-aldosterone system (RAAS) and sympathetic tone surge in pre-waking hours; nocturnal blockade protects morning vascular integrity.',
    ),
    // 8. Diuretics (Loop & Thiazide)
    const CircadianRule(
      drugPattern: 'furosemide|lasix|torsemide|hydrochlorothiazide|hctz|chlorthalidone|indapamide',
      optimalWindow: CircadianWindow.morningAwakening,
      targetHourString: '08:00',
      targetInstruction: AdminInstruction.afterMeal,
      clinicalRationale: 'Prevents nocturnal enuresis and frequent nighttime awakenings that disrupt restorative sleep.',
      biologicalMechanism: 'Peak natriuresis and diuresis occur over 4-6 hours post-dose; completing before evening prevents sleep fragmentation and fall hazards.',
    ),
  ];

  /// Evaluates an entire medication regimen for chronotherapeutic optimization
  static List<ChronotherapyEvaluation> evaluateRegimen(List<Medication> medications) {
    final evaluations = <ChronotherapyEvaluation>[];

    for (final med in medications) {
      final nameLower = med.name.toLowerCase();
      CircadianRule? matchedRule;

      for (final rule in _circadianRules) {
        final regex = RegExp(rule.drugPattern, caseSensitive: false);
        if (regex.hasMatch(nameLower)) {
          matchedRule = rule;
          break;
        }
      }

      if (matchedRule != null) {
        final currentTimes = med.scheduleTimes;
        final currentTime = currentTimes.isNotEmpty ? currentTimes.first : '08:00';
        final currentHour = int.tryParse(currentTime.split(':')[0]) ?? 8;

        bool isOptimal = false;
        switch (matchedRule.optimalWindow) {
          case CircadianWindow.morningAwakening:
            isOptimal = currentHour >= 5 && currentHour <= 9;
            break;
          case CircadianWindow.midDay:
            isOptimal = currentHour >= 11 && currentHour <= 14;
            break;
          case CircadianWindow.lateAfternoon:
            isOptimal = currentHour >= 16 && currentHour <= 18;
            break;
          case CircadianWindow.bedtimeNocturnal:
            isOptimal = currentHour >= 20 || currentHour <= 1;
            break;
          case CircadianWindow.flexible:
            isOptimal = true;
            break;
        }

        evaluations.add(
          ChronotherapyEvaluation(
            medication: med,
            isOptimallyAligned: isOptimal,
            rule: matchedRule,
            currentScheduledTime: currentTime,
            recommendedTime: matchedRule.targetHourString,
            recommendationText: isOptimal
                ? '✅ Perfectly aligned with human circadian rhythm.'
                : '⚠️ Chrono-Advisory: Reschedule to ${matchedRule.targetHourString} (${matchedRule.optimalWindow.name}). ${matchedRule.clinicalRationale}',
          ),
        );
      }
    }

    return evaluations;
  }

  /// Evaluates the mathematical safety of taking a missed dose based on Pharmacokinetic Half-Interval Rule
  static MissedDoseSafetyAssessment evaluateMissedDose({
    required Medication medication,
    required DateTime scheduledTime,
    required DateTime currentTime,
    required DateTime nextScheduledTime,
  }) {
    final totalIntervalMinutes = nextScheduledTime.difference(scheduledTime).inMinutes;
    final elapsedMinutes = currentTime.difference(scheduledTime).inMinutes;

    final elapsedFraction = totalIntervalMinutes > 0
        ? (elapsedMinutes / totalIntervalMinutes).clamp(0.0, 2.0)
        : 1.0;

    final nameLower = medication.name.toLowerCase();

    // 1. Narrow Therapeutic Index (NTI) Drugs - Special strict handling
    final isAnticoagulant = RegExp(r'warfarin|coumadin|apixaban|eliquis|rivaroxaban|xarelto|dabigatran').hasMatch(nameLower);
    final isGlaucoma = medication.category == MedCategory.eyeDrop || RegExp(r'latanoprost|timolol|brimonidine|dorzolamide').hasMatch(nameLower);
    final isThyroid = RegExp(r'levothyroxine|synthroid').hasMatch(nameLower);

    if (isAnticoagulant) {
      final elapsedHours = elapsedMinutes / 60.0;
      if (elapsedHours <= 6.0) {
        return MissedDoseSafetyAssessment(
          canTakeImmediately: true,
          safetyRecommendation: 'Safe to take now. Blood level remains within anticoagulant window.',
          elapsedIntervalFraction: elapsedFraction,
          clinicalRationale: 'Direct Oral Anticoagulants (DOACs) allow a strict 6-hour rescue grace period. Beyond 6 hours, skip to prevent double-anticoagulation bleed risks.',
          isNarrowTherapeuticIndex: true,
        );
      } else {
        return MissedDoseSafetyAssessment(
          canTakeImmediately: false,
          safetyRecommendation: 'DO NOT TAKE. Skip this dose and take next scheduled dose on time.',
          elapsedIntervalFraction: elapsedFraction,
          clinicalRationale: 'More than 6 hours have elapsed for an anticoagulant. Doubling or taking too close to next dose creates high hemorrhage risk.',
          isNarrowTherapeuticIndex: true,
        );
      }
    }

    if (isGlaucoma) {
      final elapsedHours = elapsedMinutes / 60.0;
      if (elapsedHours <= 3.0) {
        return MissedDoseSafetyAssessment(
          canTakeImmediately: true,
          safetyRecommendation: 'Instill 1 drop now. Gently press tear duct for 60 seconds.',
          elapsedIntervalFraction: elapsedFraction,
          clinicalRationale: 'Ophthalmic drop allowed up to 3 hours late. Beyond 3 hours, diurnal receptor saturation requires skipping to next cycle.',
          isNarrowTherapeuticIndex: true,
        );
      } else {
        return MissedDoseSafetyAssessment(
          canTakeImmediately: false,
          safetyRecommendation: 'Skip missed drop. Instill regular drop at next scheduled time.',
          elapsedIntervalFraction: elapsedFraction,
          clinicalRationale: 'Taking glaucoma drops too close together saturates the conjunctival sac without lowering eye pressure further.',
          isNarrowTherapeuticIndex: true,
        );
      }
    }

    if (isThyroid) {
      return MissedDoseSafetyAssessment(
        canTakeImmediately: true,
        safetyRecommendation: 'Take now ONLY if you have not eaten for at least 2 hours. Otherwise take tomorrow morning.',
        elapsedIntervalFraction: elapsedFraction,
        clinicalRationale: 'Levothyroxine has a long 7-day half-life. Maintaining an empty stomach is far more critical than exact timing.',
        isNarrowTherapeuticIndex: true,
      );
    }

    // Standard Pharmacokinetic Half-Interval Rule:
    // If <= 50% of interval elapsed: Take now.
    // If > 50% elapsed: Skip dose to prevent toxicity overlap.
    if (elapsedFraction <= 0.50) {
      return MissedDoseSafetyAssessment(
        canTakeImmediately: true,
        safetyRecommendation: 'Take missed dose now. Then resume your normal schedule.',
        elapsedIntervalFraction: elapsedFraction,
        clinicalRationale: 'Within 50% of the dose interval (Half-Interval Rule). Plasma therapeutic concentration can be restored safely.',
        isNarrowTherapeuticIndex: false,
      );
    } else {
      return MissedDoseSafetyAssessment(
        canTakeImmediately: false,
        safetyRecommendation: 'Skip this missed dose. Do NOT take double doses. Resume at next scheduled time.',
        elapsedIntervalFraction: elapsedFraction,
        clinicalRationale: 'More than 50% of the dosing interval has elapsed. Taking the dose now causes excessive peak plasma accumulation.',
        isNarrowTherapeuticIndex: false,
      );
    }
  }

  /// Parses medical prescription 'Sig' codes and Latin abbreviations into structured instructions
  static ParsedMedicalSig parseDoctorSig(String rawSig) {
    final clean = rawSig.trim().toUpperCase();

    // 1. Detect Category & Dosage Unit
    MedCategory category = MedCategory.oral;
    DosageUnit unit = DosageUnit.tablets;
    double amount = 1.0;

    if (RegExp(r'\b(GTT|GTTS|DROP|DROPS)\b').hasMatch(clean)) {
      category = MedCategory.eyeDrop;
      unit = DosageUnit.drops;
    } else if (RegExp(r'\b(PUFF|PUFFS|INH|INHALATION)\b').hasMatch(clean)) {
      category = MedCategory.inhaler;
      unit = DosageUnit.puffs;
    } else if (RegExp(r'\b(CAP|CAPS|CAPSULE)\b').hasMatch(clean)) {
      unit = DosageUnit.capsules;
    } else if (RegExp(r'\b(ML|MILLILITER)\b').hasMatch(clean)) {
      unit = DosageUnit.ml;
    } else if (RegExp(r'\b(MG|MILLIGRAM)\b').hasMatch(clean)) {
      unit = DosageUnit.mg;
    }

    // Extract numerical dose amount
    final amountMatch = RegExp(r'\b(\d+(\.\d+)?)\s*(TAB|CAP|GTT|PUFF|ML|MG)?\b').firstMatch(clean);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1) ?? '1') ?? 1.0;
    }

    // 2. Frequency & Schedule Times
    String frequency = 'Once daily';
    List<String> times = ['08:00'];

    if (RegExp(r'\b(QID|4X|FOUR TIMES)\b').hasMatch(clean)) {
      frequency = 'Four times daily';
      times = ['08:00', '12:00', '17:00', '21:00'];
    } else if (RegExp(r'\b(TID|3X|THREE TIMES)\b').hasMatch(clean)) {
      frequency = 'Three times daily';
      times = ['08:00', '14:00', '20:00'];
    } else if (RegExp(r'\b(BID|2X|TWICE DAILY)\b').hasMatch(clean)) {
      frequency = 'Twice daily';
      times = ['08:00', '20:00'];
    } else if (RegExp(r'\b(QHS|BEDTIME|AT NIGHT)\b').hasMatch(clean)) {
      frequency = 'Once daily at bedtime';
      times = ['21:30'];
    } else if (RegExp(r'\b(QAM|MORNING|IN THE MORNING)\b').hasMatch(clean)) {
      frequency = 'Once daily in the morning';
      times = ['08:00'];
    } else if (RegExp(r'\b(QOD|EVERY OTHER DAY)\b').hasMatch(clean)) {
      frequency = 'Every other day';
      times = ['08:00'];
    } else if (RegExp(r'\b(Q4H)\b').hasMatch(clean)) {
      frequency = 'Every 4 hours';
      times = ['06:00', '10:00', '14:00', '18:00', '22:00', '02:00'];
    } else if (RegExp(r'\b(PRN)\b').hasMatch(clean)) {
      frequency = 'As needed';
      times = ['08:00'];
    }

    // 3. Administration Instruction (Meals & Fasting)
    AdminInstruction instruction = AdminInstruction.withMeal;
    if (RegExp(r'\b(AC|BEFORE MEAL|EMPTY STOMACH)\b').hasMatch(clean)) {
      instruction = AdminInstruction.beforeMeal;
    } else if (RegExp(r'\b(PC|AFTER MEAL)\b').hasMatch(clean)) {
      instruction = AdminInstruction.afterMeal;
    } else if (RegExp(r'\b(QHS|BEDTIME)\b').hasMatch(clean)) {
      instruction = AdminInstruction.atBedtime;
    } else if (RegExp(r'\b(PRN|AS NEEDED)\b').hasMatch(clean)) {
      instruction = AdminInstruction.asNeeded;
    }

    // 4. Extract drug name & strength
    final words = rawSig.split(RegExp(r'\s+'));
    String drugName = words.isNotEmpty ? words.first : 'Prescribed Medicine';
    String strength = '';
    final strengthMatch = RegExp(r'(\d+(\.\d+)?\s*(MG|MCG|G|%|ML))', caseSensitive: false).firstMatch(rawSig);
    if (strengthMatch != null) {
      strength = strengthMatch.group(1) ?? '';
    }

    final translation = 'Take ${amount.toInt()} ${unit.name} of $drugName $strength, $frequency, ${_formatInstruction(instruction)}.';

    return ParsedMedicalSig(
      rawInput: rawSig,
      medicationName: drugName,
      strength: strength,
      category: category,
      dosageUnit: unit,
      dosageAmount: amount,
      instruction: instruction,
      frequency: frequency,
      scheduleTimes: times,
      englishTranslation: translation,
    );
  }

  static String _formatInstruction(AdminInstruction inst) {
    switch (inst) {
      case AdminInstruction.beforeMeal: return 'before meals (empty stomach)';
      case AdminInstruction.withMeal: return 'with meals';
      case AdminInstruction.afterMeal: return 'after meals';
      case AdminInstruction.emptyStomach: return 'on an empty stomach with a full glass of water';
      case AdminInstruction.atBedtime: return 'at bedtime';
      case AdminInstruction.asNeeded: return 'as needed';
      case AdminInstruction.withFullGlassOfWater: return 'with a full glass of water';
    }
  }
}
