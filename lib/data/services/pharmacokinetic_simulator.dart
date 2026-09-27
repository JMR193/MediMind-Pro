import 'dart:math' as math;

/// Clinical status of the simulated plasma concentration relative to the therapeutic window.
enum PlasmaSafetyStatus {
  subtherapeutic,
  optimalTherapeutic,
  approachingToxic,
  toxicOverdose,
}

/// Pharmacokinetic parameters for a specific medication.
class DrugPkProfile {
  final String drugName;
  final String drugClass;
  final double halfLifeHours; // t1/2
  final double timeToPeakHours; // Tmax
  final double volumeOfDistributionLiters; // Vd
  final double bioavailability; // F (0.0 to 1.0)
  final double minimumEffectiveConc; // MEC in ng/mL or arbitrary therapeutic units
  final double minimumToxicConc; // MTC in same units
  final int typicalDosingIntervalHours; // tau (e.g. 24 for OD, 12 for BID, 8 for TID)
  final String clinicalGuidance;

  const DrugPkProfile({
    required this.drugName,
    required this.drugClass,
    required this.halfLifeHours,
    required this.timeToPeakHours,
    required this.volumeOfDistributionLiters,
    required this.bioavailability,
    required this.minimumEffectiveConc,
    required this.minimumToxicConc,
    required this.typicalDosingIntervalHours,
    required this.clinicalGuidance,
  });

  /// Elimination rate constant ke = ln(2) / t1/2
  double get eliminationRateKe => math.ln2 / halfLifeHours;

  /// Approximate absorption rate constant ka derived from Tmax and ke:
  /// Tmax = ln(ka/ke) / (ka - ke). We approximate ka based on typical absorption kinetics.
  double get absorptionRateKa {
    // If ka is very fast relative to ke, ka ≈ 2.5 / Tmax
    final kaApprox = 2.5 / (timeToPeakHours <= 0 ? 1.0 : timeToPeakHours);
    // Ensure ka > ke for classic Bateman function
    return math.max(kaApprox, eliminationRateKe * 2.0);
  }

  /// Therapeutic Index = MTC / MEC
  double get therapeuticIndex => minimumToxicConc / minimumEffectiveConc;

  /// Narrow Therapeutic Index (NTI) indicator (TI <= 2.0)
  bool get isNarrowTherapeuticIndex => therapeuticIndex <= 2.2;
}

/// Individual coordinate on the simulated plasma concentration-time curve.
class PkDataPoint {
  final double hourOffset; // Hours from baseline (e.g. 0.0 to 48.0)
  final DateTime timestamp;
  final double concentration; // Simulated plasma level
  final PlasmaSafetyStatus status;

  const PkDataPoint({
    required this.hourOffset,
    required this.timestamp,
    required this.concentration,
    required this.status,
  });
}

/// Comprehensive simulation result containing curve data, current level, and risk flags.
class PkSimulationResult {
  final DrugPkProfile profile;
  final double currentConcentration;
  final PlasmaSafetyStatus currentStatus;
  final double peakConcentrationCssMax;
  final double troughConcentrationCssMin;
  final double timeAboveMecPercent; // Fraction of cycle in therapeutic zone
  final List<PkDataPoint> curvePoints;
  final List<String> clinicalWarnings;
  final String recommendation;

  const PkSimulationResult({
    required this.profile,
    required this.currentConcentration,
    required this.currentStatus,
    required this.peakConcentrationCssMax,
    required this.troughConcentrationCssMin,
    required this.timeAboveMecPercent,
    required this.curvePoints,
    required this.clinicalWarnings,
    required this.recommendation,
  });
}

/// On-Device Digital Twin Pharmacokinetic (PK) Simulation Engine.
///
/// Implements 1-Compartment extravascular Bateman calculus and linear superposition
/// to mathematically simulate plasma concentrations, steady-state fluctuation,
/// and missed-dose toxicity or failure risks.
class PharmacokineticSimulatorService {
  /// Curated Reference Database of Pharmacokinetic Drug Constants.
  static final Map<String, DrugPkProfile> _referenceProfiles = {
    'atorvastatin': const DrugPkProfile(
      drugName: 'Atorvastatin',
      drugClass: 'HMG-CoA Reductase Inhibitor',
      halfLifeHours: 14.0,
      timeToPeakHours: 1.5,
      volumeOfDistributionLiters: 381.0,
      bioavailability: 0.14,
      minimumEffectiveConc: 10.0,
      minimumToxicConc: 80.0,
      typicalDosingIntervalHours: 24,
      clinicalGuidance:
          'Long biological effect due to active ortho/para-hydroxy metabolites. Once-daily evening dosing aligns with hepatic cholesterol synthesis.',
    ),
    'amlodipine': const DrugPkProfile(
      drugName: 'Amlodipine',
      drugClass: 'Dihydropyridine Calcium Channel Blocker',
      halfLifeHours: 40.0,
      timeToPeakHours: 6.0,
      volumeOfDistributionLiters: 1470.0,
      bioavailability: 0.64,
      minimumEffectiveConc: 5.0,
      minimumToxicConc: 25.0,
      typicalDosingIntervalHours: 24,
      clinicalGuidance:
          'Prolonged terminal half-life provides smooth 24h blood pressure buffering even if a dose is slightly delayed.',
    ),
    'metoprolol': const DrugPkProfile(
      drugName: 'Metoprolol Tartrate',
      drugClass: 'Cardioselective Beta-1 Blocker',
      halfLifeHours: 3.5,
      timeToPeakHours: 1.5,
      volumeOfDistributionLiters: 290.0,
      bioavailability: 0.50,
      minimumEffectiveConc: 20.0,
      minimumToxicConc: 150.0,
      typicalDosingIntervalHours: 12,
      clinicalGuidance:
          'Rapid clearance necessitates BID dosing for immediate-release formulation to avoid severe subtherapeutic rebound tachycardia.',
    ),
    'metformin': const DrugPkProfile(
      drugName: 'Metformin',
      drugClass: 'Biguanide Antihyperglycemic',
      halfLifeHours: 6.2,
      timeToPeakHours: 2.5,
      volumeOfDistributionLiters: 654.0,
      bioavailability: 0.55,
      minimumEffectiveConc: 0.5,
      minimumToxicConc: 5.0,
      typicalDosingIntervalHours: 12,
      clinicalGuidance:
          'Renally eliminated without hepatic metabolism. Troughs must remain sufficient to maintain hepatic gluconeogenesis suppression.',
    ),
    'warfarin': const DrugPkProfile(
      drugName: 'Warfarin',
      drugClass: 'Vitamin K Antagonist (Anticoagulant)',
      halfLifeHours: 40.0,
      timeToPeakHours: 4.0,
      volumeOfDistributionLiters: 10.0,
      bioavailability: 0.99,
      minimumEffectiveConc: 1.0,
      minimumToxicConc: 2.5,
      typicalDosingIntervalHours: 24,
      clinicalGuidance:
          'CRITICAL NARROW THERAPEUTIC INDEX (NTI). Minor concentration shifts drastically alter INR, causing either thrombosis or major hemorrhage.',
    ),
    'levothyroxine': const DrugPkProfile(
      drugName: 'Levothyroxine',
      drugClass: 'Synthetic Thyroid Hormone (T4)',
      halfLifeHours: 168.0, // 7 days
      timeToPeakHours: 3.0,
      volumeOfDistributionLiters: 12.0,
      bioavailability: 0.80,
      minimumEffectiveConc: 5.0,
      minimumToxicConc: 12.0,
      typicalDosingIntervalHours: 24,
      clinicalGuidance:
          '7-day half-life dampens acute fluctuations; steady state requires 4-6 weeks of uninterrupted daily adherence.',
    ),
    'ciprofloxacin': const DrugPkProfile(
      drugName: 'Ciprofloxacin',
      drugClass: 'Fluoroquinolone Antibacterial',
      halfLifeHours: 4.0,
      timeToPeakHours: 1.5,
      volumeOfDistributionLiters: 150.0,
      bioavailability: 0.70,
      minimumEffectiveConc: 1.0,
      minimumToxicConc: 6.0,
      typicalDosingIntervalHours: 12,
      clinicalGuidance:
          'Concentration-dependent bacterial killing (AUC/MIC driven). Subtherapeutic troughs risk antibiotic resistance emergence.',
    ),
    'timolol': const DrugPkProfile(
      drugName: 'Timolol Maleate',
      drugClass: 'Non-Selective Beta Blocker (Ophthalmic/Systemic)',
      halfLifeHours: 4.0,
      timeToPeakHours: 2.0,
      volumeOfDistributionLiters: 140.0,
      bioavailability: 0.60,
      minimumEffectiveConc: 2.0,
      minimumToxicConc: 15.0,
      typicalDosingIntervalHours: 12,
      clinicalGuidance:
          'Punctal occlusion recommended during ocular instillation to restrict systemic beta-blocker absorption and bradycardia.',
    ),
    'lisinopril': const DrugPkProfile(
      drugName: 'Lisinopril',
      drugClass: 'ACE Inhibitor',
      halfLifeHours: 12.0,
      timeToPeakHours: 7.0,
      volumeOfDistributionLiters: 124.0,
      bioavailability: 0.25,
      minimumEffectiveConc: 15.0,
      minimumToxicConc: 120.0,
      typicalDosingIntervalHours: 24,
      clinicalGuidance:
          'Slow absorption (Tmax 6-8h) and sustained 24-hour hemodynamic control with once-daily dosing.',
    ),
  };

  /// Find matching PK profile or construct an intelligent heuristic fallback.
  static DrugPkProfile getProfileForMedication(String medicationName,
      {int? customIntervalHours}) {
    final clean = medicationName.toLowerCase().trim();

    for (final entry in _referenceProfiles.entries) {
      if (clean.contains(entry.key) || entry.value.drugName.toLowerCase().contains(clean)) {
        return entry.value;
      }
    }

    // Heuristic Fallback based on typical pharmaceutical averages
    final interval = customIntervalHours ?? 24;
    final halfLife = interval == 8
        ? 4.0
        : interval == 12
            ? 7.0
            : 16.0;

    return DrugPkProfile(
      drugName: medicationName,
      drugClass: 'Standard Pharmaceutical Agent',
      halfLifeHours: halfLife,
      timeToPeakHours: 2.0,
      volumeOfDistributionLiters: 200.0,
      bioavailability: 0.60,
      minimumEffectiveConc: 10.0,
      minimumToxicConc: 50.0,
      typicalDosingIntervalHours: interval,
      clinicalGuidance:
          'Simulated via generalized one-compartment pharmacokinetic model based on $interval-hour dosing frequency.',
    );
  }

  /// Single Dose Bateman function:
  /// C(t) = [ (F * Dose * ka) / (Vd * (ka - ke)) ] * [ exp(-ke * t) - exp(-ka * t) ]
  static double calculateSingleDoseConcentration({
    required DrugPkProfile profile,
    required double doseMg,
    required double hoursPostDose,
  }) {
    if (hoursPostDose <= 0.0) return 0.0;

    final ke = profile.eliminationRateKe;
    final ka = profile.absorptionRateKa;
    final f = profile.bioavailability;
    final vd = profile.volumeOfDistributionLiters;

    if ((ka - ke).abs() < 1e-6) {
      // In unlikely event ka == ke
      return (f * doseMg / vd) * ke * hoursPostDose * math.exp(-ke * hoursPostDose);
    }

    final coefficient = (f * doseMg * ka) / (vd * (ka - ke));
    final conc = coefficient * (math.exp(-ke * hoursPostDose) - math.exp(-ka * hoursPostDose));
    // Normalize to drug therapeutic scale if needed
    final normalized = (conc / 0.005) * (profile.minimumEffectiveConc * 1.5);
    return math.max(0.0, normalized);
  }

  /// Simulates steady-state multi-dose curve using superposition across dose history.
  /// Generates a high-resolution time series curve for chart plotting.
  static PkSimulationResult simulateRegimen({
    required DrugPkProfile profile,
    required double doseMg,
    required List<DateTime> pastDoseTimestamps,
    required DateTime now,
    int hoursToSimulateAhead = 24,
    double timeStepHours = 0.5,
  }) {
    // Generate timestamps from 24h in past to hoursToSimulateAhead in future
    final startTime = now.subtract(const Duration(hours: 24));
    final totalHours = 24 + hoursToSimulateAhead;
    final points = <PkDataPoint>[];

    final sortedDoses = List<DateTime>.from(pastDoseTimestamps)..sort();

    // If no past doses recorded, assume patient is on regular steady-state schedule
    final doses = sortedDoses.isNotEmpty
        ? sortedDoses
        : _generateIdealPastDoses(now, profile.typicalDosingIntervalHours, 7);

    double currentConcentration = 0.0;
    double maxConcentration = 0.0;
    double minConcentration = double.infinity;
    int pointsAboveMec = 0;

    for (double h = 0.0; h <= totalHours; h += timeStepHours) {
      final sampleTime = startTime.add(Duration(minutes: (h * 60).round()));

      // Superposition: Sum contributions from all previous doses
      double totalC = 0.0;
      for (final doseTime in doses) {
        if (sampleTime.isAfter(doseTime)) {
          final elapsedHours = sampleTime.difference(doseTime).inMinutes / 60.0;
          totalC += calculateSingleDoseConcentration(
            profile: profile,
            doseMg: doseMg,
            hoursPostDose: elapsedHours,
          );
        }
      }

      // Determine safety status
      final status = _determineStatus(totalC, profile);

      // Check current time point
      if ((sampleTime.difference(now).inMinutes).abs() <= (timeStepHours * 30)) {
        currentConcentration = totalC;
      }

      // Track statistics in the 24h steady-state observation window
      if (sampleTime.isAfter(now.subtract(Duration(hours: profile.typicalDosingIntervalHours))) &&
          sampleTime.isBefore(now.add(Duration(hours: profile.typicalDosingIntervalHours)))) {
        if (totalC > maxConcentration) maxConcentration = totalC;
        if (totalC < minConcentration) minConcentration = totalC;
        if (totalC >= profile.minimumEffectiveConc) pointsAboveMec++;
      }

      points.add(PkDataPoint(
        hourOffset: h - 24.0, // negative = past, positive = future
        timestamp: sampleTime,
        concentration: totalC,
        status: status,
      ));
    }

    if (minConcentration == double.infinity) minConcentration = 0.0;

    final totalWindowPoints = (profile.typicalDosingIntervalHours * 2 / timeStepHours).round();
    final timeAboveMecPercent = totalWindowPoints > 0
        ? (pointsAboveMec / totalWindowPoints * 100).clamp(0.0, 100.0)
        : 100.0;

    // Safety warnings and clinical advice
    final warnings = <String>[];
    String recommendation;

    final currentStatus = _determineStatus(currentConcentration, profile);

    if (currentStatus == PlasmaSafetyStatus.toxicOverdose) {
      warnings.add(
          'CRITICAL ALERT: Simulated blood plasma concentration exceeds Minimum Toxic Concentration (${profile.minimumToxicConc.toStringAsFixed(1)}).');
      warnings.add('Do NOT take any additional doses until contacting your physician or poison control.');
      recommendation = 'Hold next dose. Monitor for acute side effects or toxicity symptoms.';
    } else if (currentStatus == PlasmaSafetyStatus.approachingToxic) {
      warnings.add(
          'Elevated plasma levels near upper safety threshold. Double-dosing or CYP-inhibitor interactions risk toxicity.');
      recommendation = 'Adhere strictly to scheduled timing. Do not take doses early.';
    } else if (currentStatus == PlasmaSafetyStatus.subtherapeutic) {
      warnings.add(
          'Subtherapeutic plasma level (< MEC of ${profile.minimumEffectiveConc.toStringAsFixed(1)}). Medication is currently ineffective.');
      recommendation = 'Take scheduled dose immediately to restore therapeutic drug coverage.';
    } else {
      recommendation =
          'Plasma concentrations are well-maintained within the optimal therapeutic window ($timeAboveMecPercent% time in target range).';
    }

    if (profile.isNarrowTherapeuticIndex) {
      warnings.add(
          'Narrow Therapeutic Index drug: small timing shifts cause significant volatility between clotting and bleeding risks.');
    }

    return PkSimulationResult(
      profile: profile,
      currentConcentration: currentConcentration,
      currentStatus: currentStatus,
      peakConcentrationCssMax: maxConcentration,
      troughConcentrationCssMin: minConcentration,
      timeAboveMecPercent: timeAboveMecPercent,
      curvePoints: points,
      clinicalWarnings: warnings,
      recommendation: recommendation,
    );
  }

  /// Simulate a "What-If" scenario (e.g. Taking 4 hours late vs Accidentally taking 2 pills).
  static PkSimulationResult simulateWhatIfScenario({
    required DrugPkProfile profile,
    required double baseDoseMg,
    required DateTime now,
    required String scenarioType, // 'on_time', 'delayed_4h', 'double_dose', 'missed'
  }) {
    final regularInterval = profile.typicalDosingIntervalHours;
    final baseDoses = _generateIdealPastDoses(now, regularInterval, 5);

    final modifiedDoses = List<DateTime>.from(baseDoses);
    double testDoseMg = baseDoseMg;

    if (scenarioType == 'delayed_4h') {
      // Last scheduled dose was delayed by 4 hours
      if (modifiedDoses.isNotEmpty) {
        final last = modifiedDoses.removeLast();
        modifiedDoses.add(last.add(const Duration(hours: 4)));
      }
    } else if (scenarioType == 'double_dose') {
      testDoseMg = baseDoseMg * 2.0; // Two pills taken simultaneously
    } else if (scenarioType == 'missed') {
      if (modifiedDoses.isNotEmpty) {
        modifiedDoses.removeLast(); // Skipped last dose entirely
      }
    }

    return simulateRegimen(
      profile: profile,
      doseMg: testDoseMg,
      pastDoseTimestamps: modifiedDoses,
      now: now,
      hoursToSimulateAhead: 24,
    );
  }

  static PlasmaSafetyStatus _determineStatus(double c, DrugPkProfile p) {
    if (c < p.minimumEffectiveConc) {
      return PlasmaSafetyStatus.subtherapeutic;
    } else if (c > p.minimumToxicConc) {
      return PlasmaSafetyStatus.toxicOverdose;
    } else if (c > p.minimumToxicConc * 0.85) {
      return PlasmaSafetyStatus.approachingToxic;
    } else {
      return PlasmaSafetyStatus.optimalTherapeutic;
    }
  }

  static List<DateTime> _generateIdealPastDoses(
      DateTime now, int intervalHours, int count) {
    final doses = <DateTime>[];
    for (int i = count; i >= 1; i--) {
      doses.add(now.subtract(Duration(hours: i * intervalHours)));
    }
    return doses;
  }
}
