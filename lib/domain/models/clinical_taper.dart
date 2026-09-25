class TitrationStep {
  final int stepNumber;
  final double dosageAmount;
  final String frequencyDescription; // e.g. "4 times daily", "3 drops 3x/day"
  final List<String> timesOfDay; // e.g. ["08:00", "12:00", "16:00", "20:00"]
  final int durationDays; // e.g. 7 days
  final String clinicalInstruction; // e.g. "Post-op Week 1: Anti-inflammatory suppression"

  const TitrationStep({
    required this.stepNumber,
    required this.dosageAmount,
    required this.frequencyDescription,
    required this.timesOfDay,
    required this.durationDays,
    required this.clinicalInstruction,
  });

  Map<String, dynamic> toJson() => {
    'stepNumber': stepNumber,
    'dosageAmount': dosageAmount,
    'frequencyDescription': frequencyDescription,
    'timesOfDay': timesOfDay,
    'durationDays': durationDays,
    'clinicalInstruction': clinicalInstruction,
  };

  factory TitrationStep.fromJson(Map<String, dynamic> json) => TitrationStep(
    stepNumber: json['stepNumber'] as int? ?? 1,
    dosageAmount: (json['dosageAmount'] as num?)?.toDouble() ?? 1.0,
    frequencyDescription: json['frequencyDescription'] as String? ?? 'Once daily',
    timesOfDay: (json['timesOfDay'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['08:00'],
    durationDays: json['durationDays'] as int? ?? 7,
    clinicalInstruction: json['clinicalInstruction'] as String? ?? '',
  );
}

class ClinicalTaperPlan {
  final String id;
  final String medicationName;
  final String indication; // e.g., "Post-Cataract Steroid Protocol", "Oral Prednisone Taper"
  final List<TitrationStep> steps;
  final DateTime startDate;
  final int currentStepIndex; // 0-based
  final int daysCompletedInCurrentStep;
  final bool isCompleted;

  const ClinicalTaperPlan({
    required this.id,
    required this.medicationName,
    required this.indication,
    required this.steps,
    required this.startDate,
    this.currentStepIndex = 0,
    this.daysCompletedInCurrentStep = 0,
    this.isCompleted = false,
  });

  TitrationStep get currentStep => steps.isNotEmpty && currentStepIndex < steps.length
      ? steps[currentStepIndex]
      : (steps.isNotEmpty ? steps.last : const TitrationStep(
          stepNumber: 1,
          dosageAmount: 1,
          frequencyDescription: 'Completed',
          timesOfDay: [],
          durationDays: 0,
          clinicalInstruction: 'Taper complete',
        ));

  int get totalPlanDays => steps.fold(0, (sum, step) => sum + step.durationDays);

  int get totalDaysCompletedSoFar {
    int total = 0;
    for (int i = 0; i < currentStepIndex && i < steps.length; i++) {
      total += steps[i].durationDays;
    }
    total += daysCompletedInCurrentStep;
    return total;
  }

  double get overallProgressPercentage {
    if (totalPlanDays <= 0) return 1.0;
    return (totalDaysCompletedSoFar / totalPlanDays).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicationName': medicationName,
    'indication': indication,
    'steps': steps.map((s) => s.toJson()).toList(),
    'startDate': startDate.toIso8601String(),
    'currentStepIndex': currentStepIndex,
    'daysCompletedInCurrentStep': daysCompletedInCurrentStep,
    'isCompleted': isCompleted,
  };

  factory ClinicalTaperPlan.fromJson(Map<String, dynamic> json) => ClinicalTaperPlan(
    id: json['id'] as String,
    medicationName: json['medicationName'] as String,
    indication: json['indication'] as String? ?? 'Clinical Titration',
    steps: (json['steps'] as List<dynamic>?)
            ?.map((s) => TitrationStep.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [],
    startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
    currentStepIndex: json['currentStepIndex'] as int? ?? 0,
    daysCompletedInCurrentStep: json['daysCompletedInCurrentStep'] as int? ?? 0,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );

  ClinicalTaperPlan copyWith({
    String? id,
    String? medicationName,
    String? indication,
    List<TitrationStep>? steps,
    DateTime? startDate,
    int? currentStepIndex,
    int? daysCompletedInCurrentStep,
    bool? isCompleted,
  }) {
    return ClinicalTaperPlan(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      indication: indication ?? this.indication,
      steps: steps ?? this.steps,
      startDate: startDate ?? this.startDate,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      daysCompletedInCurrentStep: daysCompletedInCurrentStep ?? this.daysCompletedInCurrentStep,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
