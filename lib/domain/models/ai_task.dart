enum AiTaskCategory {
  eyeCare,
  medicationIntake,
  symptomCheck,
  refillPharmacy,
  lifestyleHydration,
  microLesson,
}

enum AiTaskTimeOfDay {
  morning,
  afternoon,
  evening,
  bedtime,
  anytime,
}

class AiDailyTask {
  final String id;
  final String title;
  final String description;
  final AiTaskCategory category;
  final AiTaskTimeOfDay timeOfDay;
  final bool isCompleted;
  final DateTime date;
  final String? relatedMedicationName;
  final String? actionRoute; // e.g. 'eye_drop', 'symptom_diary', 'refill', 'lesson'

  const AiDailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timeOfDay,
    this.isCompleted = false,
    required this.date,
    this.relatedMedicationName,
    this.actionRoute,
  });

  AiDailyTask copyWith({bool? isCompleted}) {
    return AiDailyTask(
      id: id,
      title: title,
      description: description,
      category: category,
      timeOfDay: timeOfDay,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date,
      relatedMedicationName: relatedMedicationName,
      actionRoute: actionRoute,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.index,
        'timeOfDay': timeOfDay.index,
        'isCompleted': isCompleted,
        'date': date.toIso8601String(),
        'relatedMedicationName': relatedMedicationName,
        'actionRoute': actionRoute,
      };

  factory AiDailyTask.fromJson(Map<String, dynamic> json) => AiDailyTask(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: AiTaskCategory.values[json['category'] as int? ?? 0],
        timeOfDay: AiTaskTimeOfDay.values[json['timeOfDay'] as int? ?? 0],
        isCompleted: json['isCompleted'] as bool? ?? false,
        date: DateTime.parse(json['date'] as String),
        relatedMedicationName: json['relatedMedicationName'] as String?,
        actionRoute: json['actionRoute'] as String?,
      );
}

/// Interactive Clinical Question asked by the AI Health Coach
class AiHealthCheckQuestion {
  final String id;
  final String question;
  final String subtitle;
  final List<String> options;
  final String? selectedAnswer;
  final String? aiFeedback;
  final bool isNegativeSymptom; // If true, triggers symptom diary recommendation

  const AiHealthCheckQuestion({
    required this.id,
    required this.question,
    required this.subtitle,
    required this.options,
    this.selectedAnswer,
    this.aiFeedback,
    this.isNegativeSymptom = false,
  });

  AiHealthCheckQuestion copyWith({
    String? selectedAnswer,
    String? aiFeedback,
    bool? isNegativeSymptom,
  }) {
    return AiHealthCheckQuestion(
      id: id,
      question: question,
      subtitle: subtitle,
      options: options,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      isNegativeSymptom: isNegativeSymptom ?? this.isNegativeSymptom,
    );
  }
}

/// Educational Micro-Lesson taught by the AI Teacher
class AiLesson {
  final String id;
  final String title;
  final String category; // e.g. "Ophthalmology", "Pharmacology", "General Safety"
  final String readTime; // e.g. "2 min read"
  final String summary;
  final String detailedContentMarkdown;
  final String quizQuestion;
  final List<String> quizOptions;
  final int correctOptionIndex;
  final String quizExplanation;
  final bool isCompleted;

  const AiLesson({
    required this.id,
    required this.title,
    required this.category,
    required this.readTime,
    required this.summary,
    required this.detailedContentMarkdown,
    required this.quizQuestion,
    required this.quizOptions,
    required this.correctOptionIndex,
    required this.quizExplanation,
    this.isCompleted = false,
  });

  AiLesson copyWith({bool? isCompleted}) {
    return AiLesson(
      id: id,
      title: title,
      category: category,
      readTime: readTime,
      summary: summary,
      detailedContentMarkdown: detailedContentMarkdown,
      quizQuestion: quizQuestion,
      quizOptions: quizOptions,
      correctOptionIndex: correctOptionIndex,
      quizExplanation: quizExplanation,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
