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
  });

  bool get needsRefill => totalInventoryCount <= refillThreshold;

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
    return diff >= 0 && diff <= 30;
  }

  // After-opening expiry for eye drops / eye ointments (typically 28 days)
  int? get daysRemainingAfterOpening {
    if (openedDate == null || afterOpeningDays == null) return null;
    final openedLimit = openedDate!.add(Duration(days: afterOpeningDays!));
    final remaining = openedLimit.difference(DateTime.now()).inDays;
    return remaining;
  }

  bool get isOpenedWindowClosingSoon {
    final remaining = daysRemainingAfterOpening;
    if (remaining == null) return false;
    return remaining <= 7 && remaining >= 0;
  }

  bool get isOpenedWindowExpired {
    final remaining = daysRemainingAfterOpening;
    if (remaining == null) return false;
    return remaining < 0;
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
    );
  }

  Medication copyWith({
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
  }) {
    return Medication(
      id: id,
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
    );
  }
}
