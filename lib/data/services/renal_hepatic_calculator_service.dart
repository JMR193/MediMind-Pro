import 'dart:math';
import '../../domain/models/medication.dart';

class RenalDoseGuideline {
  final String medicationName;
  final String normalDosage;
  final String recommendedRenalDose;
  final String rationale;
  final bool isContraindicated;
  final double thresholdCrCl;

  const RenalDoseGuideline({
    required this.medicationName,
    required this.normalDosage,
    required this.recommendedRenalDose,
    required this.rationale,
    required this.isContraindicated,
    required this.thresholdCrCl,
  });
}

class RenalHepaticCalculatorService {
  /// Calculates Cockcroft-Gault Creatinine Clearance (CrCl in mL/min)
  /// CrCl = [ (140 - Age) * Weight(kg) ] / [ 72 * SerumCr(mg/dL) ] (* 0.85 if female)
  static double calculateCockcroftGaultCrCl({
    required int age,
    required double weightKg,
    required double serumCreatinineMgDl,
    required bool isFemale,
  }) {
    if (age <= 0 || weightKg <= 0 || serumCreatinineMgDl <= 0) return 100.0;
    
    double crCl = ((140.0 - age) * weightKg) / (72.0 * serumCreatinineMgDl);
    if (isFemale) {
      crCl *= 0.85;
    }
    return double.parse(crCl.toStringAsFixed(1));
  }

  /// Calculates CKD-EPI 2021 (race-free) Estimated Glomerular Filtration Rate (eGFR in mL/min/1.73m²)
  static double calculateCkdEpiEgfr({
    required int age,
    required double serumCreatinineMgDl,
    required bool isFemale,
  }) {
    if (age <= 0 || serumCreatinineMgDl <= 0) return 90.0;

    final k = isFemale ? 0.7 : 0.9;
    final a = isFemale ? -0.241 : -0.302;
    final genderCoeff = isFemale ? 1.012 : 1.0;

    final scrOverK = serumCreatinineMgDl / k;
    final minPart = pow(min(scrOverK, 1.0), a);
    final maxPart = pow(max(scrOverK, 1.0), -1.200);
    final agePart = pow(0.9938, age);

    final egfr = 142.0 * minPart * maxPart * agePart * genderCoeff;
    return double.parse(egfr.clamp(0.0, 150.0).toStringAsFixed(1));
  }

  /// Evaluates active medications against clinical nephrology dose adjustment thresholds
  static List<RenalDoseGuideline> evaluateRenalAdjustments({
    required List<Medication> medications,
    required double crCl,
  }) {
    final List<RenalDoseGuideline> guidelines = [];

    for (final med in medications) {
      final nameLower = med.name.toLowerCase();

      // 1. Metformin
      if (nameLower.contains('metformin') || nameLower.contains('glycomet') || nameLower.contains('janumet')) {
        if (crCl < 30.0) {
          guidelines.add(RenalDoseGuideline(
            medicationName: med.name,
            normalDosage: '500mg - 2000mg daily',
            recommendedRenalDose: '🚫 CONTRAINDICATED (Stop Metformin)',
            rationale: 'Severe risk of fatal lactic acidosis when eGFR/CrCl < 30 mL/min.',
            isContraindicated: true,
            thresholdCrCl: 30.0,
          ));
        } else if (crCl < 45.0) {
          guidelines.add(RenalDoseGuideline(
            medicationName: med.name,
            normalDosage: '1500mg - 2000mg daily',
            recommendedRenalDose: 'Max 1000mg/day (Reduce dose by 50%)',
            rationale: 'Moderate renal impairment requires maximum 1000mg/day to prevent accumulation.',
            isContraindicated: false,
            thresholdCrCl: 45.0,
          ));
        }
      }

      // 2. Gabapentin
      if (nameLower.contains('gabapentin') || nameLower.contains('neurontin')) {
        if (crCl < 15.0) {
          guidelines.add(RenalDoseGuideline(
            medicationName: med.name,
            normalDosage: '300mg - 600mg TID',
            recommendedRenalDose: '100mg - 300mg every other day',
            rationale: 'Gabapentin is 100% renally cleared. Failure to reduce leads to severe myoclonus, sedation, and coma.',
            isContraindicated: false,
            thresholdCrCl: 15.0,
          ));
        } else if (crCl < 30.0) {
          guidelines.add(RenalDoseGuideline(
            medicationName: med.name,
            normalDosage: '300mg - 600mg TID',
            recommendedRenalDose: '200mg - 300mg Once Daily (OD)',
            rationale: 'CrCl 15-29 mL/min requires dose reduction to once daily.',
            isContraindicated: false,
            thresholdCrCl: 30.0,
          ));
        } else if (crCl < 60.0) {
          guidelines.add(RenalDoseGuideline(
            medicationName: med.name,
            normalDosage: '300mg - 600mg TID',
            recommendedRenalDose: '200mg - 300mg Twice Daily (BID)',
            rationale: 'CrCl 30-59 mL/min requires dose reduction to twice daily.',
            isContraindicated: false,
            thresholdCrCl: 60.0,
          ));
        }
      }

      // 3. Ciprofloxacin
      if (nameLower.contains('ciprofloxacin') || nameLower.contains('ciplox')) {
        if (crCl < 30.0) {
          guidelines.add(RenalDoseGuideline(
            medicationName: med.name,
            normalDosage: '500mg - 750mg BID',
            recommendedRenalDose: '250mg - 500mg Once Daily or every 18-24h',
            rationale: 'Reduced clearance can cause CNS toxicity, QT prolongation, and neurotoxicity.',
            isContraindicated: false,
            thresholdCrCl: 30.0,
          ));
        }
      }

      // 4. Apixaban / Eliquis
      if (nameLower.contains('apixaban') || nameLower.contains('eliquis')) {
        if (crCl < 15.0) {
          guidelines.add(RenalDoseGuideline(
            medicationName: med.name,
            normalDosage: '5mg BID',
            recommendedRenalDose: '🚫 Not Recommended (Severe hemorrhage risk)',
            rationale: 'End-stage renal disease significantly elevates plasma factor Xa inhibitor levels.',
            isContraindicated: true,
            thresholdCrCl: 15.0,
          ));
        } else if (crCl < 30.0) {
          guidelines.add(RenalDoseGuideline(
            medicationName: med.name,
            normalDosage: '5mg BID',
            recommendedRenalDose: 'Reduce to 2.5mg Twice Daily (BID)',
            rationale: 'Renal impairment warrants dose reduction to minimize major bleed risk.',
            isContraindicated: false,
            thresholdCrCl: 30.0,
          ));
        }
      }

      // 5. Allopurinol
      if (nameLower.contains('allopurinol') || nameLower.contains('zyloric')) {
        if (crCl < 20.0) {
          guidelines.add(RenalDoseGuideline(
            medicationName: med.name,
            normalDosage: '300mg Daily',
            recommendedRenalDose: 'Max 100mg Daily or 100mg QOD',
            rationale: 'Oxypurinol metabolite accumulation causes severe Allopurinol Hypersensitivity Syndrome (AHS/DRESS).',
            isContraindicated: false,
            thresholdCrCl: 20.0,
          ));
        }
      }
    }

    return guidelines;
  }
}
