import 'clinical_taper.dart';

enum DosageUnit {
  mg,
  ml,
  drops,
  puffs,
  units,
  spray,
  tablets,
  capsules,
  applyTopical,
}

enum AdminInstruction {
  beforeMeal,
  withMeal,
  afterMeal,
  emptyStomach,
  atBedtime,
  asNeeded,
  withFullGlassOfWater,
}

enum MedCategory {
  oral,
  eyeDrop,
  eyeOintment,
  inhaler,
  injectable,
  topical,
  nasalSpray,
  other,
}

enum OphthalmicFormulation {
  solution,
  suspension,
  emulsion,
  gel,
  ointment,
}

enum PillShape {
  round,
  oval,
  capsule,
  oblong,
  diamond,
  dropperBottle,
  inhaler,
  patch,
  other,
}

enum PillScoring {
  unscored,
  singleScored,
  doubleScored,
}

class Medication {
  final String id;
  final String name;
  final String strength; // e.g. "500 mg", "0.05%"
  final MedCategory category;
  final DosageUnit dosageUnit;
  final double dosageAmount;
  final AdminInstruction instruction;
  final String frequency; // e.g. "Once daily", "Twice daily", "Three times daily", "As needed"
  final List<String> scheduleTimes; // Format: "HH:mm" e.g., "08:00", "20:00"
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? expiryDate;
  final DateTime? openedDate;
  final int? afterOpeningDays; // e.g. 28 days for opened eye drops
  final int totalInventoryCount;
  final int refillThreshold;
  final String? prescribingDoctor;
  final String? rxNumber;
  final String? clinicalNotes;
  final String colorHex; // e.g., "#0066FF"
  final String iconName; // e.g., "pill", "eye_drop", "inhaler", "syringe"
  final bool isHighPriorityAlarm;
  final bool requiresEyeDropProtocol;
  final String? eyeTarget; // "Left Eye (OS)", "Right Eye (OD)", "Both Eyes (OU)"
  final int eyeDropGapMinutes; // Default 5 to 10 min between drops
  final bool contactLensWarning;
  final bool isOintment;
  final OphthalmicFormulation ophthalmicFormulation;
  final String profileId; // Multi-patient profile isolation
  final ClinicalTaperPlan? taperPlan; // Optional titration/tapering plan
  final double? halfLifeHours; // Pharmacological half-life for missed dose calculus

  // Advanced Multi-Regimen Scheduling (Days of week & Cycle)
  final List<int> scheduledDaysOfWeek; // 1 = Monday ... 7 = Sunday. Empty = every day
  final int? cycleDaysOn; // e.g. 21 days
  final int? cycleDaysOff; // e.g. 7 days

  // Visual Pill Identification Characteristics
  final PillShape pillShape;
  final PillScoring pillScoring;
  final String? pillImprint;
  final String pillColorName;

  Medication({
    required this.id,
    required this.name,
    required this.strength,
    required this.category,
    required this.dosageUnit,
    required this.dosageAmount,
    required this.instruction,
    this.frequency = 'Once daily',
    required this.scheduleTimes,
    this.startDate,
    this.endDate,
    this.expiryDate,
    this.openedDate,
    this.afterOpeningDays,
    required this.totalInventoryCount,
    required this.refillThreshold,
    this.prescribingDoctor,
    this.rxNumber,
    this.clinicalNotes,
    required this.colorHex,
    required this.iconName,
    this.isHighPriorityAlarm = false,
    this.requiresEyeDropProtocol = false,
    this.eyeTarget,
    this.eyeDropGapMinutes = 5,
    this.contactLensWarning = false,
    this.isOintment = false,
    this.ophthalmicFormulation = OphthalmicFormulation.solution,
    this.profileId = 'default_profile',
    this.taperPlan,
    this.halfLifeHours,
    this.scheduledDaysOfWeek = const [],
    this.cycleDaysOn,
    this.cycleDaysOff,
    this.pillShape = PillShape.round,
    this.pillScoring = PillScoring.unscored,
    this.pillImprint,
    this.pillColorName = 'White',
  });

  bool get needsRefill => totalInventoryCount <= refillThreshold;

  // Convenience & compatibility getters
  bool get isOphthalmic => requiresEyeDropProtocol || category == MedCategory.eyeDrop || category == MedCategory.eyeOintment;
  String get dosage => '$dosageAmount ${dosageUnit.name}';
  int get currentSupply => totalInventoryCount;
  List<String> get scheduledTimes => scheduleTimes;

  // Estimated days of supply remaining based on doses per day
  int get estimatedDaysSupplyRemaining {
    final dailyDoses = scheduleTimes.isNotEmpty ? scheduleTimes.length * dosageAmount : dosageAmount;
    if (dailyDoses <= 0) return 999;
    return (totalInventoryCount / dailyDoses).floor();
  }

  DateTime? get estimatedExhaustionDate {
    final days = estimatedDaysSupplyRemaining;
    if (days >= 999) return null;
    return DateTime.now().add(Duration(days: days));
  }

  double get supplyPercentage {
    if (totalInventoryCount <= 0) return 0.0;
    final maxNorm = (refillThreshold * 3).clamp(30, 300);
    return (totalInventoryCount / maxNorm).clamp(0.0, 1.0);
  }

  // Expiration check
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final diff = expiryDate!.difference(DateTime.now()).inDays;
    return diff <= 30 && diff >= 0;
  }

  // 28-day opened eye drop rule
  bool get isOpenedWindowExpired {
    if (openedDate == null || afterOpeningDays == null) return false;
    final diff = DateTime.now().difference(openedDate!).inDays;
    return diff >= afterOpeningDays!;
  }

  int? get openedDaysRemaining {
    if (openedDate == null || afterOpeningDays == null) return null;
    final elapsed = DateTime.now().difference(openedDate!).inDays;
    return (afterOpeningDays! - elapsed).clamp(0, 999);
  }

  int? get daysRemainingAfterOpening => openedDaysRemaining;

  bool get isOpenedWindowClosingSoon {
    final remaining = openedDaysRemaining;
    if (remaining == null) return false;
    return remaining <= 3 && remaining > 0;
  }

  /// Determines whether this medication is scheduled to be taken on a specific calendar date
  bool isScheduledForDay(DateTime date) {
    // 1. Date boundaries check
    if (startDate != null) {
      final startOnly = DateTime(startDate!.year, startDate!.month, startDate!.day);
      final targetOnly = DateTime(date.year, date.month, date.day);
      if (targetOnly.isBefore(startOnly)) return false;
    }
    if (endDate != null) {
      final endOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
      final targetOnly = DateTime(date.year, date.month, date.day);
      if (targetOnly.isAfter(endOnly)) return false;
    }

    // 2. Day of week check (e.g. Mon/Wed/Fri)
    if (scheduledDaysOfWeek.isNotEmpty) {
      if (!scheduledDaysOfWeek.contains(date.weekday)) {
        return false;
      }
    }

    // 3. Cyclic / intermittent regimen check (e.g. 21 days on, 7 days off)
    if (cycleDaysOn != null && cycleDaysOff != null && cycleDaysOn! > 0 && cycleDaysOff! > 0) {
      final start = startDate ?? DateTime(2026, 1, 1);
      final daysSinceStart = date.difference(start).inDays;
      if (daysSinceStart >= 0) {
        final cycleLength = cycleDaysOn! + cycleDaysOff!;
        final dayInCycle = daysSinceStart % cycleLength;
        if (dayInCycle >= cycleDaysOn!) {
          return false; // In "off" period of the cycle
        }
      }
    }

    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'strength': strength,
      'category': category.index,
      'dosageUnit': dosageUnit.index,
      'dosageAmount': dosageAmount,
      'instruction': instruction.index,
      'frequency': frequency,
      'scheduleTimes': scheduleTimes,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'openedDate': openedDate?.toIso8601String(),
      'afterOpeningDays': afterOpeningDays,
      'totalInventoryCount': totalInventoryCount,
      'refillThreshold': refillThreshold,
      'prescribingDoctor': prescribingDoctor,
      'rxNumber': rxNumber,
      'clinicalNotes': clinicalNotes,
      'colorHex': colorHex,
      'iconName': iconName,
      'isHighPriorityAlarm': isHighPriorityAlarm,
      'requiresEyeDropProtocol': requiresEyeDropProtocol,
      'eyeTarget': eyeTarget,
      'eyeDropGapMinutes': eyeDropGapMinutes,
      'contactLensWarning': contactLensWarning,
      'isOintment': isOintment,
      'ophthalmicFormulation': ophthalmicFormulation.index,
      'profileId': profileId,
      'taperPlan': taperPlan?.toJson(),
      'halfLifeHours': halfLifeHours,
      'scheduledDaysOfWeek': scheduledDaysOfWeek,
      'cycleDaysOn': cycleDaysOn,
      'cycleDaysOff': cycleDaysOff,
      'pillShape': pillShape.index,
      'pillScoring': pillScoring.index,
      'pillImprint': pillImprint,
      'pillColorName': pillColorName,
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      strength: json['strength'] as String? ?? '',
      category: MedCategory.values[(json['category'] as int? ?? 0).clamp(0, MedCategory.values.length - 1)],
      dosageUnit: DosageUnit.values[(json['dosageUnit'] as int? ?? 0).clamp(0, DosageUnit.values.length - 1)],
      dosageAmount: (json['dosageAmount'] as num? ?? 1.0).toDouble(),
      instruction: AdminInstruction.values[(json['instruction'] as int? ?? 0).clamp(0, AdminInstruction.values.length - 1)],
      frequency: json['frequency'] as String? ?? 'Once daily',
      scheduleTimes: List<String>.from(json['scheduleTimes'] as List? ?? []),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) : null,
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'] as String) : null,
      openedDate: json['openedDate'] != null ? DateTime.tryParse(json['openedDate'] as String) : null,
      afterOpeningDays: json['afterOpeningDays'] as int?,
      totalInventoryCount: json['totalInventoryCount'] as int? ?? 30,
      refillThreshold: json['refillThreshold'] as int? ?? 5,
      prescribingDoctor: json['prescribingDoctor'] as String?,
      rxNumber: json['rxNumber'] as String?,
      clinicalNotes: json['clinicalNotes'] as String?,
      colorHex: json['colorHex'] as String? ?? '#0284C7',
      iconName: json['iconName'] as String? ?? 'pill',
      isHighPriorityAlarm: json['isHighPriorityAlarm'] as bool? ?? false,
      requiresEyeDropProtocol: json['requiresEyeDropProtocol'] as bool? ?? false,
      eyeTarget: json['eyeTarget'] as String?,
      eyeDropGapMinutes: json['eyeDropGapMinutes'] as int? ?? 5,
      contactLensWarning: json['contactLensWarning'] as bool? ?? false,
      isOintment: json['isOintment'] as bool? ?? false,
      ophthalmicFormulation: OphthalmicFormulation.values[(json['ophthalmicFormulation'] as int? ?? 0).clamp(0, OphthalmicFormulation.values.length - 1)],
      profileId: json['profileId'] as String? ?? 'default_profile',
      taperPlan: json['taperPlan'] != null ? ClinicalTaperPlan.fromJson(json['taperPlan'] as Map<String, dynamic>) : null,
      halfLifeHours: (json['halfLifeHours'] as num?)?.toDouble(),
      scheduledDaysOfWeek: (json['scheduledDaysOfWeek'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [],
      cycleDaysOn: json['cycleDaysOn'] as int?,
      cycleDaysOff: json['cycleDaysOff'] as int?,
      pillShape: PillShape.values[(json['pillShape'] as int? ?? 0).clamp(0, PillShape.values.length - 1)],
      pillScoring: PillScoring.values[(json['pillScoring'] as int? ?? 0).clamp(0, PillScoring.values.length - 1)],
      pillImprint: json['pillImprint'] as String?,
      pillColorName: json['pillColorName'] as String? ?? 'White',
    );
  }

  Medication copyWith({
    String? id,
    String? name,
    String? strength,
    MedCategory? category,
    DosageUnit? dosageUnit,
    double? dosageAmount,
    AdminInstruction? instruction,
    String? frequency,
    List<String>? scheduleTimes,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? expiryDate,
    DateTime? openedDate,
    int? afterOpeningDays,
    int? totalInventoryCount,
    int? refillThreshold,
    String? prescribingDoctor,
    String? rxNumber,
    String? clinicalNotes,
    String? colorHex,
    String? iconName,
    bool? isHighPriorityAlarm,
    bool? requiresEyeDropProtocol,
    String? eyeTarget,
    int? eyeDropGapMinutes,
    bool? contactLensWarning,
    bool? isOintment,
    OphthalmicFormulation? ophthalmicFormulation,
    String? profileId,
    ClinicalTaperPlan? taperPlan,
    double? halfLifeHours,
    List<int>? scheduledDaysOfWeek,
    int? cycleDaysOn,
    int? cycleDaysOff,
    PillShape? pillShape,
    PillScoring? pillScoring,
    String? pillImprint,
    String? pillColorName,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      category: category ?? this.category,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      instruction: instruction ?? this.instruction,
      frequency: frequency ?? this.frequency,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      expiryDate: expiryDate ?? this.expiryDate,
      openedDate: openedDate ?? this.openedDate,
      afterOpeningDays: afterOpeningDays ?? this.afterOpeningDays,
      totalInventoryCount: totalInventoryCount ?? this.totalInventoryCount,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      prescribingDoctor: prescribingDoctor ?? this.prescribingDoctor,
      rxNumber: rxNumber ?? this.rxNumber,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      isHighPriorityAlarm: isHighPriorityAlarm ?? this.isHighPriorityAlarm,
      requiresEyeDropProtocol: requiresEyeDropProtocol ?? this.requiresEyeDropProtocol,
      eyeTarget: eyeTarget ?? this.eyeTarget,
      eyeDropGapMinutes: eyeDropGapMinutes ?? this.eyeDropGapMinutes,
      contactLensWarning: contactLensWarning ?? this.contactLensWarning,
      isOintment: isOintment ?? this.isOintment,
      ophthalmicFormulation: ophthalmicFormulation ?? this.ophthalmicFormulation,
      profileId: profileId ?? this.profileId,
      taperPlan: taperPlan ?? this.taperPlan,
      halfLifeHours: halfLifeHours ?? this.halfLifeHours,
      scheduledDaysOfWeek: scheduledDaysOfWeek ?? this.scheduledDaysOfWeek,
      cycleDaysOn: cycleDaysOn ?? this.cycleDaysOn,
      cycleDaysOff: cycleDaysOff ?? this.cycleDaysOff,
      pillShape: pillShape ?? this.pillShape,
      pillScoring: pillScoring ?? this.pillScoring,
      pillImprint: pillImprint ?? this.pillImprint,
      pillColorName: pillColorName ?? this.pillColorName,
    );
  }
}
