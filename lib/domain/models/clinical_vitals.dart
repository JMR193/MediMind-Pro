enum GlucoseMealTiming {
  fasting,
  preMeal,
  postMeal2h,
  bedtime,
  random,
}

enum BpCategory {
  normal,
  elevated,
  stage1Hypertension,
  stage2Hypertension,
  hypertensiveCrisis,
  hypotension,
}

enum IopRiskCategory {
  normal, // 10-21 mmHg
  borderline, // 22-24 mmHg
  highSpike, // >= 25 mmHg
  hypotony, // < 6 mmHg
}

class ClinicalVitalRecord {
  final String id;
  final String profileId;
  final DateTime timestamp;
  
  // Blood Pressure & Heart Rate
  final int? systolicBp; // mmHg (e.g. 120)
  final int? diastolicBp; // mmHg (e.g. 80)
  final int? heartRateBpm; // bpm (e.g. 72)
  
  // Blood Glucose
  final double? bloodGlucoseMgDl; // mg/dL (e.g. 110.0)
  final GlucoseMealTiming? glucoseTiming;
  
  // Ophthalmic Intraocular Pressure (IOP)
  final double? iopRightEyeOd; // mmHg (e.g. 15.0)
  final double? iopLeftEyeOs; // mmHg (e.g. 16.5)
  
  // Weight & Renal
  final double? weightKg; // kg
  final double? serumCreatinineMgDl; // mg/dL (e.g. 1.1)
  final double? estimatedEgfr; // mL/min/1.73m²
  
  final String? notes;

  const ClinicalVitalRecord({
    required this.id,
    required this.profileId,
    required this.timestamp,
    this.systolicBp,
    this.diastolicBp,
    this.heartRateBpm,
    this.bloodGlucoseMgDl,
    this.glucoseTiming,
    this.iopRightEyeOd,
    this.iopLeftEyeOs,
    this.weightKg,
    this.serumCreatinineMgDl,
    this.estimatedEgfr,
    this.notes,
  });

  BpCategory? get bpCategory {
    if (systolicBp == null || diastolicBp == null) return null;
    final sys = systolicBp!;
    final dia = diastolicBp!;

    if (sys > 180 || dia > 120) return BpCategory.hypertensiveCrisis;
    if (sys >= 140 || dia >= 90) return BpCategory.stage2Hypertension;
    if (sys >= 130 || dia >= 80) return BpCategory.stage1Hypertension;
    if (sys >= 120 && dia < 80) return BpCategory.elevated;
    if (sys < 90 || dia < 60) return BpCategory.hypotension;
    return BpCategory.normal;
  }

  String get bpCategoryLabel {
    switch (bpCategory) {
      case BpCategory.normal:
        return 'Normal BP (<120/80)';
      case BpCategory.elevated:
        return 'Elevated (120-129/<80)';
      case BpCategory.stage1Hypertension:
        return 'Stage 1 Hypertension (130-139/80-89)';
      case BpCategory.stage2Hypertension:
        return 'Stage 2 Hypertension (≥140/90)';
      case BpCategory.hypertensiveCrisis:
        return '🚨 Hypertensive Crisis (>180/>120)';
      case BpCategory.hypotension:
        return 'Hypotension (<90/60)';
      case null:
        return 'Not recorded';
    }
  }

  IopRiskCategory? get iopCategory {
    final maxIop = [iopRightEyeOd, iopLeftEyeOs].whereType<double>().fold(0.0, (a, b) => a > b ? a : b);
    if (maxIop <= 0) return null;
    if (maxIop >= 25.0) return IopRiskCategory.highSpike;
    if (maxIop >= 22.0) return IopRiskCategory.borderline;
    if (maxIop < 6.0) return IopRiskCategory.hypotony;
    return IopRiskCategory.normal;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'timestamp': timestamp.toIso8601String(),
    'systolicBp': systolicBp,
    'diastolicBp': diastolicBp,
    'heartRateBpm': heartRateBpm,
    'bloodGlucoseMgDl': bloodGlucoseMgDl,
    'glucoseTiming': glucoseTiming?.index,
    'iopRightEyeOd': iopRightEyeOd,
    'iopLeftEyeOs': iopLeftEyeOs,
    'weightKg': weightKg,
    'serumCreatinineMgDl': serumCreatinineMgDl,
    'estimatedEgfr': estimatedEgfr,
    'notes': notes,
  };

  factory ClinicalVitalRecord.fromJson(Map<String, dynamic> json) => ClinicalVitalRecord(
    id: json['id'] as String,
    profileId: json['profileId'] as String? ?? 'default_profile',
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    systolicBp: json['systolicBp'] as int?,
    diastolicBp: json['diastolicBp'] as int?,
    heartRateBpm: json['heartRateBpm'] as int?,
    bloodGlucoseMgDl: (json['bloodGlucoseMgDl'] as num?)?.toDouble(),
    glucoseTiming: json['glucoseTiming'] != null ? GlucoseMealTiming.values[json['glucoseTiming'] as int] : null,
    iopRightEyeOd: (json['iopRightEyeOd'] as num?)?.toDouble(),
    iopLeftEyeOs: (json['iopLeftEyeOs'] as num?)?.toDouble(),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    serumCreatinineMgDl: (json['serumCreatinineMgDl'] as num?)?.toDouble(),
    estimatedEgfr: (json['estimatedEgfr'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
  );
}
