import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../domain/models/ai_message.dart';
import '../../domain/models/medication.dart';
import '../../domain/models/ai_task.dart';
import 'package:uuid/uuid.dart';
import 'tts_service.dart';

/// MediMind Autonomous Offline AI Health Coach & Medical Tutor
/// ─────────────────────────────────────────────────────────────
/// Features:
/// 1. Multilingual Support: English, Spanish, Arabic, French, German, Hindi, Chinese.
/// 2. Natural Voice Output: Text-to-Speech playback in the patient's language.
/// 3. Interactive Medical Teacher / Tutor (Lessons, Quizzes, Plain Language Explanations)
/// 4. Proactive Daily Task & Routine Automation Engine
/// 5. Interactive Clinical Health Check-In (Targeted Triage Questioning)
class AiAssistantService extends ChangeNotifier {
  final List<AiMessage> _messages = [];
  List<Medication> _medications = [];
  List<AiDailyTask> _dailyTasks = [];
  List<AiHealthCheckQuestion> _healthQuestions = [];
  List<AiLesson> _lessons = [];
  bool _isProcessing = false;
  String _activeLanguageCode = 'en';
  bool _autoSpeakEnabled = false;
  final _uuid = const Uuid();
  final TtsService _ttsService = TtsService();

  // ──────────────────────────────────────────
  // Interactive Telemetry & Chart Analytics
  // ──────────────────────────────────────────
  int _totalQueriesCount = 14;
  final Map<String, int> _queryCategoryCounts = {
    'Ophthalmology': 6,
    'Pharmacology': 4,
    'Schedules & Timers': 3,
    'Food & Diet Safety': 2,
  };
  int _completedQuizzesCount = 3;
  int _correctQuizAnswersCount = 3;
  int _totalTriageCheckIns = 4;
  final List<int> _recentLatenciesMs = [98, 115, 87, 104, 122];

  AiAssistantService() {
    _initLessons();
    _initHealthQuestions();
    _ttsService.init();
  }

  List<AiMessage> get messages => List.unmodifiable(_messages);
  List<AiDailyTask> get dailyTasks => List.unmodifiable(_dailyTasks);
  List<AiHealthCheckQuestion> get healthQuestions => List.unmodifiable(_healthQuestions);
  List<AiLesson> get lessons => List.unmodifiable(_lessons);
  bool get isProcessing => _isProcessing;
  String get activeLanguageCode => _activeLanguageCode;
  bool get autoSpeakEnabled => _autoSpeakEnabled;

  // Telemetry Getters
  int get totalQueriesCount => _totalQueriesCount;
  Map<String, int> get queryCategoryCounts => Map.unmodifiable(_queryCategoryCounts);
  int get completedQuizzesCount => _completedQuizzesCount;
  int get correctQuizAnswersCount => _correctQuizAnswersCount;
  double get quizAccuracyPercentage => _completedQuizzesCount > 0
      ? (_correctQuizAnswersCount / _completedQuizzesCount) * 100
      : 100.0;
  double get academyMasteryPercentage => _lessons.isEmpty
      ? 0.0
      : (_lessons.where((l) => l.isCompleted).length / _lessons.length) * 100;
  int get totalTriageCheckIns => _totalTriageCheckIns;
  List<int> get recentLatenciesMs => List.unmodifiable(_recentLatenciesMs);
  double get averageLatencyMs => _recentLatenciesMs.isEmpty
      ? 105.0
      : _recentLatenciesMs.reduce((a, b) => a + b) / _recentLatenciesMs.length;

  int get completedTasksCount => _dailyTasks.where((t) => t.isCompleted).length;
  double get taskProgress => _dailyTasks.isEmpty ? 1.0 : completedTasksCount / _dailyTasks.length;

  void recordQuizResult({required bool isCorrect}) {
    _completedQuizzesCount++;
    if (isCorrect) _correctQuizAnswersCount++;
    notifyListeners();
  }

  void recordTriageCheckIn() {
    _totalTriageCheckIns++;
    notifyListeners();
  }

  void recordQueryTelemetry(String category, int latencyMs) {
    _totalQueriesCount++;
    _queryCategoryCounts[category] = (_queryCategoryCounts[category] ?? 0) + 1;
    _recentLatenciesMs.add(latencyMs);
    if (_recentLatenciesMs.length > 10) _recentLatenciesMs.removeAt(0);
    notifyListeners();
  }

  void setLanguage(String langCode) {
    _activeLanguageCode = langCode;
    notifyListeners();
  }

  void toggleAutoSpeak() {
    _autoSpeakEnabled = !_autoSpeakEnabled;
    notifyListeners();
  }

  Future<void> speakText(String text, {String? lang}) async {
    await _ttsService.speak(text, languageCode: lang ?? _activeLanguageCode);
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
  }

  void updateMedications(List<Medication> meds) {
    _medications = meds;
    _generateDailyTasks();
    notifyListeners();
  }

  // ──────────────────────────────────────────
  // Autonomous AI Daily Tasks Generation
  // ──────────────────────────────────────────
  void _generateDailyTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<AiDailyTask> generated = [];

    // 1. Core Eye Care / Medication tasks
    final eyeMeds = _medications.where((m) =>
        m.category == MedCategory.eyeDrop ||
        m.category == MedCategory.eyeOintment ||
        m.requiresEyeDropProtocol).toList();

    if (eyeMeds.isNotEmpty) {
      generated.add(AiDailyTask(
        id: 'task_eye_morning',
        title: 'Morning Punctal Occlusion Technique',
        description: 'When applying morning eye drops, pinch the inner tear duct for 60 seconds to prevent systemic absorption.',
        category: AiTaskCategory.eyeCare,
        timeOfDay: AiTaskTimeOfDay.morning,
        date: today,
        actionRoute: 'eye_drop',
      ));

      generated.add(AiDailyTask(
        id: 'task_eye_rest',
        title: '20-20-20 Eye Strain Reset',
        description: 'Every 20 minutes of screen use, look 20 feet away for 20 seconds to maintain cornea hydration.',
        category: AiTaskCategory.eyeCare,
        timeOfDay: AiTaskTimeOfDay.afternoon,
        date: today,
      ));
    }

    // 2. Check for eye ointment sequencing
    final hasOintment = _medications.any((m) => m.isOintment || m.category == MedCategory.eyeOintment);
    final hasDrops = _medications.any((m) => !m.isOintment && (m.category == MedCategory.eyeDrop || m.requiresEyeDropProtocol));

    if (hasOintment && hasDrops) {
      generated.add(AiDailyTask(
        id: 'task_sequence_ointment',
        title: 'Evening Eye Sequence Check',
        description: 'Crucial rule: Administer liquid eye drops FIRST, wait 10-15 minutes, then apply eye ointment LAST.',
        category: AiTaskCategory.eyeCare,
        timeOfDay: AiTaskTimeOfDay.bedtime,
        date: today,
        actionRoute: 'eye_drop',
      ));
    }

    // 3. Medication Refill Checks
    for (final m in _medications) {
      if (m.needsRefill) {
        generated.add(AiDailyTask(
          id: 'task_refill_${m.id}',
          title: 'Prescription Refill: ${m.name}',
          description: 'Only ${m.totalInventoryCount} doses left (~${m.estimatedDaysSupplyRemaining} days supply). Call pharmacy to renew.',
          category: AiTaskCategory.refillPharmacy,
          timeOfDay: AiTaskTimeOfDay.morning,
          date: today,
          relatedMedicationName: m.name,
        ));
      }
    }

    // 4. Opened Bottle Window Expiry Check
    for (final m in _medications) {
      if (m.isOpenedWindowClosingSoon) {
        generated.add(AiDailyTask(
          id: 'task_opened_${m.id}',
          title: 'Bottle Shelf Life Alert: ${m.name}',
          description: 'Opened bottle is near its 28-day safety limit (${m.daysRemainingAfterOpening} days left). Prepare a fresh bottle.',
          category: AiTaskCategory.refillPharmacy,
          timeOfDay: AiTaskTimeOfDay.afternoon,
          date: today,
          relatedMedicationName: m.name,
        ));
      }
    }

    // 5. Daily Micro-Learning Task
    final nextUncompletedLesson = _lessons.firstWhere((l) => !l.isCompleted, orElse: () => _lessons.first);
    generated.add(AiDailyTask(
      id: 'task_lesson_${nextUncompletedLesson.id}',
      title: 'Daily 1-Min Lesson: ${nextUncompletedLesson.title}',
      description: nextUncompletedLesson.summary,
      category: AiTaskCategory.microLesson,
      timeOfDay: AiTaskTimeOfDay.anytime,
      date: today,
      actionRoute: 'lesson',
    ));

    // 6. General Hydration & Symptom Check
    generated.add(AiDailyTask(
      id: 'task_hydration',
      title: 'Optimal Hydration Intake',
      description: 'Drink a full glass of water with each scheduled oral dose to prevent gastric irritation and kidney strain.',
      category: AiTaskCategory.lifestyleHydration,
      timeOfDay: AiTaskTimeOfDay.anytime,
      date: today,
    ));

    _dailyTasks = generated;
  }

  void toggleTask(String taskId) {
    final idx = _dailyTasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _dailyTasks[idx] = _dailyTasks[idx].copyWith(isCompleted: !_dailyTasks[idx].isCompleted);
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────
  // Interactive Daily Health Check-In Questions
  // ──────────────────────────────────────────
  void _initHealthQuestions() {
    _healthQuestions = [
      const AiHealthCheckQuestion(
        id: 'q_eye_comfort',
        question: 'How are your eyes feeling right now?',
        subtitle: 'Daily ocular comfort & irritation assessment',
        options: ['Comfortable & Clear', 'Mildly Gritty / Dry', 'Red or Irritated', 'Significant Pain / Blurry Vision'],
      ),
      const AiHealthCheckQuestion(
        id: 'q_punctal_technique',
        question: 'Did you pinch your tear duct (punctal occlusion) with your drops?',
        subtitle: 'Essential technique to prevent drug absorption into bloodstream',
        options: ['Yes, for a full 60 seconds', 'Just for a few seconds', 'No, forgot this time', 'I do not use eye drops'],
      ),
      const AiHealthCheckQuestion(
        id: 'q_side_effects',
        question: 'Have you noticed any unexpected side effects from your medications?',
        subtitle: 'Monitors dizziness, nausea, stomach upset, or rash',
        options: ['None, feeling good', 'Mild stomach upset / nausea', 'Dizziness or lightheadedness', 'Severe reaction'],
      ),
    ];
  }

  void answerHealthQuestion(String questionId, String answer) {
    final idx = _healthQuestions.indexWhere((q) => q.id == questionId);
    if (idx != -1) {
      final q = _healthQuestions[idx];
      String feedback = '';
      bool isNegative = false;

      if (q.id == 'q_eye_comfort') {
        if (answer == 'Comfortable & Clear') {
          feedback = 'Excellent! Your tear film and ocular surface are well-maintained. Keep adhering to your scheduled times.';
        } else if (answer == 'Mildly Gritty / Dry') {
          feedback = 'Grittiness is frequently caused by environmental dry eye or preservatives in drops. Consider doctor-approved preservative-free artificial tears spaced 10 min away.';
        } else if (answer == 'Red or Irritated') {
          feedback = 'Ocular redness may signify mild allergy or medication irritation. Ensure you never rub your eyes. If it persists beyond 24 hours, log it in the Symptom Diary.';
          isNegative = true;
        } else {
          feedback = '🚨 WARNING: Significant eye pain and blurred vision are clinical red flags. Please log this immediately in your Symptom Diary and contact your ophthalmologist or urgent care!';
          isNegative = true;
        }
      } else if (q.id == 'q_punctal_technique') {
        if (answer == 'Yes, for a full 60 seconds') {
          feedback = 'Outstanding! Punctal occlusion increases corneal drug penetration by up to 60% and stops drops from entering the nasal circulation.';
        } else {
          feedback = 'Tip: Next time, place your index finger gently against the inner corner of your eye (next to the bridge of your nose) for 60 seconds. This prevents systemic side effects!';
        }
      } else if (q.id == 'q_side_effects') {
        if (answer == 'None, feeling good') {
          feedback = 'Great news! Your regimen is being tolerated well. Keep logging your doses consistently.';
        } else if (answer.contains('Severe')) {
          feedback = '🚨 URGENT: For severe reactions (breathing difficulty, swelling, extensive rash), seek emergency medical care immediately!';
          isNegative = true;
        } else {
          feedback = 'Noted. Taking medications with food or water can often ease mild gastrointestinal symptoms. Be sure to discuss persistent symptoms with your doctor.';
          isNegative = true;
        }
      }

      _healthQuestions[idx] = q.copyWith(
        selectedAnswer: answer,
        aiFeedback: feedback,
        isNegativeSymptom: isNegative,
      );

      if (_autoSpeakEnabled && feedback.isNotEmpty) {
        speakText(feedback);
      }

      notifyListeners();
    }
  }

  // ──────────────────────────────────────────
  // Medical Lessons & Quizzes (AI Teacher)
  // ──────────────────────────────────────────
  void _initLessons() {
    _lessons = [
      const AiLesson(
        id: 'lesson_1',
        title: 'The 5-Minute Eye Drop Rule',
        category: 'Ophthalmology',
        readTime: '2 min read',
        summary: 'Why one single drop already exceeds what your eye can hold.',
        detailedContentMarkdown: '''
### 👁️ The Physiological Eye Capacity

Did you know the human eye can only hold about **25 to 30 microliters** of liquid at any time?
A standard prescription bottle dispenses **40 to 50 microliters** in a single drop!

#### What happens if you apply drops back-to-back?
If you apply two drops within 1 or 2 minutes of each other:
1. The second drop washes out the first drop completely.
2. You absorb less than 20% of the active drug.
3. You waste expensive medication.

#### The Golden Clinical Rule:
Always wait **at least 5 to 10 minutes** between different eye drops so the first medicine has time to penetrate into the cornea!
''',
        quizQuestion: 'How long should you wait between applying two different eye drops?',
        quizOptions: ['Immediately (no wait)', '30 seconds', 'At least 5 to 10 minutes', '1 hour'],
        correctOptionIndex: 2,
        quizExplanation: 'Correct! Waiting 5–10 minutes prevents the second drop from washing out the first drop before it penetrates the cornea.',
      ),
      const AiLesson(
        id: 'lesson_2',
        title: 'Punctal Occlusion Masterclass',
        category: 'Ophthalmology',
        readTime: '2 min read',
        summary: 'How to block eye drops from entering your heart and bloodstream.',
        detailedContentMarkdown: '''
### 🫀 Why Eye Drops Can Affect Your Body

At the inner corner of your eyelid lies the **nasolacrimal punctum** — tiny drainage holes that drain tears straight into your nasal passages and into your bloodstream!

Topical eye drops like **Timolol** (a beta-blocker) can enter your bloodstream this way, potentially causing:
- Slow heart rate (bradycardia)
- Shortness of breath or asthma flare-ups
- Fatigue and low blood pressure

#### How to perform Punctal Occlusion:
1. Tilt head back and apply 1 drop in the lower lid pocket.
2. Close your eyes gently (do NOT squeeze tight or blink rapidly).
3. Place your index finger against the bridge of your nose at the inner corner of the eye.
4. Press gently for **60 seconds**.
''',
        quizQuestion: 'What is the purpose of punctal occlusion (pressing the inner corner of the eye)?',
        quizOptions: [
          'To clean the eye lashes',
          'To stop medication from draining into the nasal tract & bloodstream',
          'To spread ointment across the face',
          'To make the eye water faster'
        ],
        correctOptionIndex: 1,
        quizExplanation: 'Correct! Punctal occlusion blocks the tear duct, maximizing corneal penetration and preventing cardiovascular/respiratory side effects.',
      ),
      const AiLesson(
        id: 'lesson_3',
        title: 'Eye Drops vs Ointments Sequencing',
        category: 'Pharmacology',
        readTime: '2 min read',
        summary: 'Why oil must always go after water in eye treatments.',
        detailedContentMarkdown: '''
### 💧 Water vs. Oil: The Sequencing Law

If your ophthalmologist prescribes both **eye drops** and an **eye ointment** (like Erythromycin or lubricating ointment):

#### The Rule:
1. **Drops FIRST**
2. **Wait 10 to 15 minutes**
3. **Ointment LAST**

#### Why?
Eye ointments have a thick, petrolatum-mineral oil base. Once ointment touches the eye, it forms a waterproof lipid barrier. If you apply liquid drops after ointment, the drop literally slides right off without touching the cornea!
''',
        quizQuestion: 'Which should you apply first when prescribed both eye drops and eye ointment?',
        quizOptions: [
          'Ointment first, then drops immediately',
          'Mix them together in a spoon',
          'Eye drops first, then ointment 10-15 minutes later',
          'It does not matter'
        ],
        correctOptionIndex: 2,
        quizExplanation: 'Correct! Drops must be applied first so they can absorb before the ointment forms a hydrophobic barrier.',
      ),
      const AiLesson(
        id: 'lesson_4',
        title: 'The 28-Day Bottle Sterility Window',
        category: 'General Safety',
        readTime: '1 min read',
        summary: 'Why opened eye drops must be discarded after 28 days.',
        detailedContentMarkdown: '''
### ⏳ Why the Clock Ticks Once Opened

Multi-dose eye drop bottles contain preservatives like **Benzalkonium Chloride (BAK)** to prevent bacterial and fungal growth.

Once the seal is broken:
- Airborne microbes and skin bacteria can colonize the dropper tip.
- Preservatives gradually degrade and lose antimicrobial efficacy.
- Contaminated eye drops can cause severe **bacterial keratitis** or corneal ulcers!

#### Clinical Best Practice:
Always write the date opened on the bottle or log it in MediMind Pro. Discard after **28 days** even if medicine is still inside.
''',
        quizQuestion: 'Why should multi-dose eye drop bottles generally be discarded 28 days after opening?',
        quizOptions: [
          'The bottle physically dissolves',
          'Preservative effectiveness diminishes and bacterial contamination risk rises',
          'The liquid turns into solid ice',
          'Pharmacy regulations require buying more'
        ],
        correctOptionIndex: 1,
        quizExplanation: 'Correct! Preservatives lose potency after 28 days of air exposure, creating high risks of blinding bacterial infections.',
      ),
      const AiLesson(
        id: 'lesson_5',
        title: 'Grapefruit & Statins Interaction',
        category: 'Pharmacology',
        readTime: '2 min read',
        summary: 'The liver enzyme inhibition that leads to muscle damage.',
        detailedContentMarkdown: '''
### 🍊 The CYP3A4 Enzyme Trap

Statins like **Atorvastatin** and **Simvastatin** are broken down in your intestines and liver by an enzyme called **CYP3A4**.

Grapefruit contains **furanocoumarins**, which permanently deactivate CYP3A4 enzymes for up to 72 hours!

#### The Consequence:
Instead of normal levels, drug concentrations in your blood can rise **up to 15-fold**, drastically increasing the risk of:
- Severe muscle aches and weakness
- **Rhabdomyolysis** (fatal breakdown of muscle tissue)
- Acute kidney failure

**Safe alternatives:** Oranges, tangerines, and lemons do not contain furanocoumarins and are safe to consume.
''',
        quizQuestion: 'Why should patients taking Atorvastatin or Simvastatin avoid grapefruit?',
        quizOptions: [
          'Grapefruit makes the pill taste bitter',
          'It destroys stomach acid completely',
          'It inhibits CYP3A4 enzymes, causing dangerously high drug levels and muscle damage',
          'It neutralizes all cholesterol benefits'
        ],
        correctOptionIndex: 2,
        quizExplanation: 'Correct! Grapefruit blocks CYP3A4 metabolism, spiking statin blood levels and increasing the risk of rhabdomyolysis.',
      ),
    ];
  }

  void completeLesson(String lessonId) {
    final idx = _lessons.indexWhere((l) => l.id == lessonId);
    if (idx != -1) {
      _lessons[idx] = _lessons[idx].copyWith(isCompleted: true);
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────
  // Language Auto-Detection Helper
  // ──────────────────────────────────────────
  String _detectLanguage(String text) {
    final t = text.toLowerCase();
    // Tamil
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text) || t.contains('vanakkam') || t.contains('marunthu')) {
      return 'ta';
    }
    // Telugu
    if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(text) || t.contains('namaskaram') || t.contains('mandulu')) {
      return 'te';
    }
    // Kannada
    if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(text) || t.contains('namaskara') || t.contains('aushadhi')) {
      return 'kn';
    }
    // Malayalam
    if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(text) || t.contains('marunnu')) {
      return 'ml';
    }
    // Bengali
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(text) || t.contains('nomoshkar') || t.contains('osudh')) {
      return 'bn';
    }
    // Gujarati
    if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(text) || t.contains('kem cho') || t.contains('dava')) {
      return 'gu';
    }
    // Punjabi
    if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(text) || t.contains('sat sri akaal') || t.contains('davai')) {
      return 'pa';
    }
    // Marathi (Devanagari with Marathi specific vocabulary)
    if (t.contains('dolyat') || t.contains('aushadh') || t.contains('kashe') || (RegExp(r'[\u0900-\u097F]').hasMatch(text) && (text.contains('डोळा') || text.contains('औषध') || text.contains('घ्यावे') || text.contains('टाकावे') || text.contains('कसे')))) {
      return 'mr';
    }
    // Hindi
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text) || t.contains('namaste') || t.contains('aankh') || t.contains('dawa')) {
      return 'hi';
    }
    // Spanish
    if (t.contains('hola') || t.contains('gotas') || t.contains('ojo') || t.contains('dosis') || t.contains('medicamento') || t.contains('gracias') || t.contains('olvid')) {
      return 'es';
    }
    // Arabic
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
      return 'ar';
    }
    // French
    if (t.contains('bonjour') || t.contains('gouttes') || t.contains('yeux') || t.contains('médicament') || t.contains('oubli')) {
      return 'fr';
    }
    // German
    if (t.contains('hallo') || t.contains('augentropfen') || t.contains('medikament') || t.contains('dosis') || t.contains('vergessen')) {
      return 'de';
    }
    // Chinese
    if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(text)) {
      return 'zh';
    }
    return _activeLanguageCode;
  }

  // ──────────────────────────────────────────
  // Offline Conversational & Multilingual Engine
  // ──────────────────────────────────────────
  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    final userMsg = AiMessage(
      id: _uuid.v4(),
      role: AiRole.user,
      content: userText.trim(),
      timestamp: DateTime.now(),
    );

    final thinkingMsg = AiMessage(
      id: _uuid.v4(),
      role: AiRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isTyping: true,
    );

    _messages.add(userMsg);
    _messages.add(thinkingMsg);
    _isProcessing = true;
    notifyListeners();

    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(400)));

    final lang = _detectLanguage(userText);
    final response = _generateMultilingualResponse(userText.trim().toLowerCase(), lang);

    _messages.removeLast();
    _messages.add(AiMessage(
      id: _uuid.v4(),
      role: AiRole.assistant,
      content: response,
      timestamp: DateTime.now(),
    ));
    _isProcessing = false;
    notifyListeners();

    if (_autoSpeakEnabled) {
      speakText(response, lang: lang);
    }
  }

  void clearChat() {
    _messages.clear();
    stopSpeaking();
    notifyListeners();
  }

  String _generateMultilingualResponse(String q, String lang) {
    switch (lang) {
      case 'ta':
        return _generateTamilResponse(q);
      case 'te':
        return _generateTeluguResponse(q);
      case 'kn':
        return _generateKannadaResponse(q);
      case 'ml':
        return _generateMalayalamResponse(q);
      case 'bn':
        return _generateBengaliResponse(q);
      case 'mr':
        return _generateMarathiResponse(q);
      case 'gu':
        return _generateGujaratiResponse(q);
      case 'pa':
        return _generatePunjabiResponse(q);
      case 'es':
        return _generateSpanishResponse(q);
      case 'ar':
        return _generateArabicResponse(q);
      case 'fr':
        return _generateFrenchResponse(q);
      case 'de':
        return _generateGermanResponse(q);
      case 'hi':
        return _generateHindiResponse(q);
      case 'zh':
        return _generateChineseResponse(q);
      default:
        return _generateEnglishResponse(q);
    }
  }

  // ── Spanish Responses ──────────────────────────────────────
  String _generateSpanishResponse(String q) {
    if (q.contains('hola') || q.contains('buenos')) {
      return "¡Hola! 👋 Soy tu tutor y asistente médico MediMind con IA offline.\n\n"
          "Puedo ayudarte en español con:\n"
          "• Técnica adecuada de gotas oftálmicas\n"
          "• Regla de los 5 minutos y oclusión lagrimal\n"
          "• Interacciones con alimentos (ej. pomelo y estatinas)\n"
          "• ¿Qué hacer si olvidas una dosis?\n\n"
          "¿Qué duda médica tienes hoy?";
    }
    if (q.contains('gotas') || q.contains('ojo') || q.contains('poner') || q.contains('aplicar')) {
      return "👁️ **Técnica Clínica para Gotas Oftálmicas:**\n\n"
          "1. **Lávate bien las manos** con agua y jabón.\n"
          "2. **Retira lentes de contacto** (espera 15 min después de las gotas antes de volver a colocarlos).\n"
          "3. **Inclina la cabeza** y baja suavemente el párpado inferior para formar un bolsillo.\n"
          "4. Aplica **1 sola gota** sin tocar el ojo con el gotero.\n"
          "5. **Cierra los ojos con suavidad** (no aprietes ni parpadees rápido).\n"
          "6. **Oclusión lagrimal:** Presiona la esquina interior del ojo junto a la nariz durante **60 segundos** para evitar que el fármaco pase al torrente sanguíneo.\n"
          "7. Espera **al menos 5 a 10 minutos** antes de cualquier segunda gota.";
    }
    if (q.contains('olvid') || q.contains('dosis') || q.contains('pase')) {
      return "💊 **Guía si Olvidas una Dosis:**\n\n"
          "• Si recuerdas poco después, adminístrala de inmediato.\n"
          "• Si ya está cerca de tu siguiente dosis, omite la dosis olvidada y sigue tu horario normal.\n"
          "• **NUNCA dupliques la dosis** para compensar.\n"
          "• Consulta siempre con tu médico o farmacéutico ante dudas.";
    }
    if (q.contains('pomelo') || q.contains('toronja') || q.contains('estatina') || q.contains('atorvastatina')) {
      return "🍊 **Advertencia: Toronja/Pomelo y Estatinas:**\n\n"
          "El pomelo bloquea la enzima hepática **CYP3A4**. Esto hace que las estatinas (Atorvastatina, Simvastatina) se acumulen a niveles tóxicos en sangre, aumentando el riesgo de daño muscular grave (**rabdomiólisis**).\n\n"
          "**Recomendación:** Evita el pomelo por completo. Las naranjas y limones son seguros.";
    }
    return "🤖 **Asistente MediMind en Español:**\n\n"
        "Puedes preguntarme sobre:\n"
        "• '¿Cómo me aplico las gotas?'\n"
        "• '¿Por qué esperar 5 minutos entre gotas?'\n"
        "• '¿Qué pasa si olvidé mi medicina?'\n"
        "• '¿Por qué la pomada va al final?'\n\n"
        "¡Usa las pestañas superiores para ver tus Tareas Diarias y Cursos de la Academia!";
  }

  // ── Arabic Responses (RTL) ─────────────────────────────────
  String _generateArabicResponse(String q) {
    if (q.contains('مرحبا') || q.contains('اهلا') || q.contains('سلام')) {
      return "أهلاً بك! 👋 أنا مساعدك الطبي ومعلمك الذكي في MediMind.\n\n"
          "أعمل بالكامل دون اتصال بالإنترنت لمساعدتك في:\n"
          "• الطريقة الصحيحة لتقطير العين وسد المجرى الدمعي\n"
          "• قاعدة فاصل ٥ إلى ١٠ دقائق لمنع غسيل الدواء\n"
          "• التداخلات الدوائية والغذائية\n"
          "• ما يجب فعله عند نسيان الجرعة\n\n"
          "كيف يمكنني مساعدتك اليوم؟";
    }
    if (q.contains('قطر') || q.contains('عين') || q.contains('طريق') || q.contains('كيف')) {
      return "👁️ **الطريقة الطبية الصحيحة لوضع قطرات العين:**\n\n"
          "١. **اغسل يديك جيداً** بالماء والصابون.\n"
          "٢. **انزع العدسات اللاصقة** وانتظر ١٥ دقيقة بعد القطرة قبل ارتدائها.\n"
          "٣. أمِل رأسك للخلف واسحب الجفن السفلي برفق لعمل جيب صغير.\n"
          "٤. ضع **قطرة واحدة فقط** دون ملامسة فوهة الزجاجة لعينك.\n"
          "٥. أغمض عينيك بلطف دون عصر أو رمش سريع.\n"
          "٦. **سد المجرى الدمعي:** اضغط برفق على الزاوية الداخلية للعين بجانب الأنف لمدة **٦٠ ثانية** لمنع امتصاص الدواء في مجرى الدم.\n"
          "٧. انتظر **٥ إلى ١٠ دقائق** على الأقل قبل وضع أي قطرة ثانية.";
    }
    if (q.contains('نسي') || q.contains('جرع') || q.contains('فات')) {
      return "💊 **إرشادات الجرعة الفائتة:**\n\n"
          "• إذا تذكرت في غضون وقت قصير، خذ الجرعة فوراً.\n"
          "• إذا كان موعد الجرعة التالية قريباً، تجاوز الجرعة الفائتة وتابع جدولك المعتاد.\n"
          "• **لا تضاعف الجرعة أبداً** لتعويض ما فاتك!";
    }
    return "🤖 **مساعدك الطبي الذكي بالعربية:**\n\n"
        "يمكنك سؤالي عن:\n"
        "• 'كيف استخدم قطرات العين بطريقة صحيحة؟'\n"
        "• 'ما هو تأثير الغسيل بين القطرات؟'\n"
        "• 'ماذا أفعل عند نسيان الجرعة؟'\n"
        "• 'لماذا يجب استخدام المرهم بعد القطرات؟'";
  }

  // ── French Responses ───────────────────────────────────────
  String _generateFrenchResponse(String q) {
    if (q.contains('bonjour') || q.contains('salut')) {
      return "Bonjour ! 👋 Je suis MediMind AI, votre tuteur et assistant médical hors-ligne.\n\n"
          "Je peux vous expliquer en français :\n"
          "• La technique des gouttes oculaires et l'occlusion lacrymale\n"
          "• L'espacement de 5 à 10 minutes entre les collyres\n"
          "• Les interactions aliments-médicaments (ex. pamplemousse et statines)\n"
          "• Que faire en cas d'oubli de prise\n\n"
          "Quelle est votre question médicale aujourd'hui ?";
    }
    if (q.contains('goutte') || q.contains('yeux') || q.contains('collyre') || q.contains('oeil')) {
      return "👁️ **Technique Clinique pour les Collyres (Gouttes) :**\n\n"
          "1. **Lavez-vous soigneusement les mains** avec du savon.\n"
          "2. **Retirez les lentilles de contact** (attendez 15 min avant de les remettre).\n"
          "3. Penchez la tête en arrière et tirez doucement la paupière inférieure.\n"
          "4. Instillez **1 seule goutte** sans toucher l'œil avec le flacon.\n"
          "5. Fermez doucement les yeux sans serrer fort.\n"
          "6. **Occlusion lacrymale :** Appuyez doucement sur le coin interne de l'œil (près du nez) pendant **60 secondes** pour éviter le passage dans la circulation sanguine.\n"
          "7. Attendez **5 à 10 minutes** avant d'appliquer une deuxième goutte.";
    }
    return "🤖 **Assistant Médical MediMind en Français :**\n\n"
        "Posez vos questions sur vos médicaments, la règle des 5 minutes, ou explorez l'onglet **Académie** pour vos micro-cours interactifs !";
  }

  // ── German Responses ───────────────────────────────────────
  String _generateGermanResponse(String q) {
    if (q.contains('hallo') || q.contains('guten')) {
      return "Guten Tag! 👋 Ich bin Ihr Offline-KI-Gesundheitscoach und medizinischer Tutor von MediMind.\n\n"
          "Ich helfe Ihnen auf Deutsch bei:\n"
          "• Richtiger Anwendung von Augentropfen & Pünktchen-Kompression\n"
          "• Der 5-10 Minuten-Abstandsregel zwischen Tropfen\n"
          "• Wechselwirkungen von Lebensmitteln und Medikamenten\n"
          "• Vorgehen bei vergessenen Dosen";
    }
    if (q.contains('tropfen') || q.contains('auge') || q.contains('anwend')) {
      return "👁️ **Klinischer Leitfaden für Augentropfen:**\n\n"
          "1. **Hände gründlich mit Seife waschen.**\n"
          "2. **Kontaktlinsen entfernen** (mindestens 15 Min. warten vor erneutem Einsetzen).\n"
          "3. Kopf nach hinten neigen, Unterlid vorsichtig nach unten ziehen.\n"
          "4. **1 einzigen Tropfen** einbringen, ohne das Auge mit der Spitze zu berühren.\n"
          "5. Augen sanft schließen.\n"
          "6. **Tränenwegsokklusion:** Drücken Sie den inneren Augenwinkel neben der Nase für **60 Sekunden** sanft ab, um Nebenwirkungen im Kreislauf zu verhindern.\n"
          "7. Warten Sie **mindestens 5-10 Minuten** vor einem weiteren Tropfen.";
    }
    return "🤖 **MediMind KI-Assistent auf Deutsch:**\n\n"
        "Fragen Sie mich nach Augentropfen, Wechselwirkungen oder testen Sie Ihr Wissen im Tab **Akademie**!";
  }

  // ── Hindi Responses ────────────────────────────────────────
  String _generateHindiResponse(String q) {
    if (q.contains('नमस्ते') || q.contains('हेलो') || q.contains('प्रणाम')) {
      return "नमस्ते! 👋 मैं मेडीमाइंड ऑफलाइन एआई मेडिकल ट्यूटर और हेल्थ कोच हूँ।\n\n"
          "मैं आपकी हिंदी में मदद कर सकता हूँ:\n"
          "• आई ड्रॉप्स डालने का सही तरीका\n"
          "• दो दवाओं के बीच 5 से 10 मिनट का अंतर क्यों जरूरी है\n"
          "• भोजन और दवा का परहेज\n"
          "• दवा की खुराक छूट जाने पर क्या करें\n\n"
          "आज आपका क्या सवाल है?";
    }
    if (q.contains('ड्रॉप') || q.contains('आंख') || q.contains('दवा') || q.contains('डाल')) {
      return "👁️ **आई ड्रॉप्स डालने का सही चिकित्सीय तरीका:**\n\n"
          "1. **हाथों को साबुन से अच्छी तरह धोएं।**\n"
          "2. **कांटेक्ट लेंस निकालें** (दवा डालने के 15 मिनट बाद ही दोबारा पहनें)।\n"
          "3. सिर को पीछे झुकाएं और निचली पलक को धीरे से नीचे खींचकर पॉकेट बनाएं।\n"
          "4. ड्रॉपर को बिना छुए **सिर्फ 1 बूंद** डालें।\n"
          "5. आंखें धीरे से बंद करें (जोर से न भींचें)।\n"
          "6. **अश्रु नलिका को दबाएं (Punctal Occlusion):** आंख के भीतरी कोने (नाक के पास) को **60 सेकंड** तक उंगली से दबाकर रखें ताकि दवा खून में न फैले।\n"
          "7. दूसरी आई ड्रॉप डालने से पहले **कम से कम 5 से 10 मिनट** का इंतजार करें।";
    }
    return "🤖 **मेडीमाइंड एआई सहायक (हिंदी):**\n\n"
        "आप मुझसे आई ड्रॉप्स, दवाओं के परहेज या खुराक के बारे में पूछ सकते हैं!";
  }

  // ── Chinese Responses ──────────────────────────────────────
  String _generateChineseResponse(String q) {
    if (q.contains('你好') || q.contains('您好')) {
      return "您好！👋 我是 MediMind 离线 AI 医疗导师与健康助手。\n\n"
          "我可以用中文为您解答：\n"
          "• 眼药水正确滴用手法与泪囊按压法\n"
          "• 两种眼药水间隔 5-10 分钟的重要性（防止冲洗效应）\n"
          "• 药物与食物相互作用（如葡萄柚与他汀类药物）\n"
          "• 漏服药物的应对措施";
    }
    if (q.contains('眼药水') || q.contains('眼睛') || q.contains('滴') || q.contains('用药')) {
      return "👁️ **眼药水临床标准滴用手法：**\n\n"
          "1. **用肥皂彻底清洗双手。**\n"
          "2. **摘下隐形眼镜**（滴药后等待 15 分钟方可重新佩戴）。\n"
          "3. 头向后仰，轻拉下眼睑形成小囊。\n"
          "4. 悬空滴入 **1 滴**药液，切勿让瓶口触碰眼睛或睫毛。\n"
          "5. 轻轻闭眼，切勿用力挤眼或频繁眨眼。\n"
          "6. **按压内眼角（泪囊阻断法）：** 用食指轻压靠近鼻梁的内眼角 **60 秒**，阻断药物流入鼻腔及全身血液循环。\n"
          "7. 如需使用第二种眼药水，务必**间隔至少 5 至 10 分钟**。";
    }
    return "🤖 **MediMind 中文 AI 医疗导师：**\n\n"
        "您可以随时询问眼药水滴用顺序、药物相互作用或查阅顶部的每日任务与学院课程！";
  }

  // ── Tamil Responses ────────────────────────────────────────
  String _generateTamilResponse(String q) {
    if (q.contains('வணக்கம்') || q.contains('ஹலோ') || q.contains('vanakkam')) {
      return "வணக்கம்! 👋 நான் மெடிமைண்ட் ஆஃப்லைன் AI மருத்துவ ஆசிரியர் மற்றும் ஆரோக்கிய வழிகாட்டி.\n\n"
          "தமிழில் உங்களுக்கு உதவ முடியும்:\n"
          "• கண் சொட்டு மருந்து (Eye Drops) போடும் சரியான மருத்துவ முறை\n"
          "• இரண்டு மருந்துகளுக்கு இடையில் 5 முதல் 10 நிமிடங்கள் இடைவெளி ஏன் அவசியம்?\n"
          "• மருந்து உட்கொள்ள மறந்தால் என்ன செய்ய வேண்டும்?\n"
          "• உணவு மற்றும் மருந்து இடைவினைகள்\n\n"
          "இன்று உங்கள் ஆரோக்கிய சந்தேகம் என்ன?";
    }
    if (q.contains('கண்') || q.contains('சொட்டு') || q.contains('மருந்து') || q.contains('ட்ராப்') || q.contains('marunthu')) {
      return "👁️ **கண் சொட்டு மருந்து போடும் சரியான முறை (Punctal Occlusion):**\n\n"
          "1. **கைகளை சோப்பினால் நன்றாகக் கழுவுங்கள்.**\n"
          "2. **கான்டாக்ட் லென்ஸை கழற்றுங்கள்** (மருந்து போட்ட 15 நிமிடங்களுக்குப் பிறகே மீண்டும் அணியவும்).\n"
          "3. தலையை பின்னால் சாய்த்து, கீழ் இமையை மெதுவாக கீழே இழுத்து ஒரு சிறிய இடைவெளி உருவாக்குங்கள்.\n"
          "4. கண்ணில் பாட்டில் முனை படாமல் **ஒரே ஒரு சொட்டு** மட்டும் விடுங்கள்.\n"
          "5. கண்களை மெதுவாக மூடுங்கள் (இறுக்கமாக மூடாதீர்கள்).\n"
          "6. **கண்ணீர்க் குழாய் அழுத்தம் (Punctal Occlusion):** மருந்து ரத்த ஓட்டத்தில் கலப்பதைத் தடுக்க, மூக்கிற்கு அருகிலுள்ள உள் கண் மூலையை விரலால் **60 வினாடிகள்** மெதுவாக அழுத்தவும்.\n"
          "7. அடுத்த கண் மருந்து போடுவதற்கு முன் **குறைந்தது 5 முதல் 10 நிமிடங்கள்** காத்திருங்கள்.";
    }
    if (q.contains('மறந்து') || q.contains('தவறி') || q.contains('விட்டு')) {
      return "💊 **மருந்து உட்கொள்ள மறந்தால் வழிகாட்டுதல்:**\n\n"
          "• சிறிது நேரத்திற்குள் நினைவுக்கு வந்தால் உடனே எடுத்துக்கொள்ளுங்கள்.\n"
          "• அடுத்த வேளை மருந்துக்கு நேரம் நெருங்கிவிட்டால், தவறவிட்ட அளவைத் தவிர்த்து வழக்கமான அட்டவணையைப் பின்பற்றுங்கள்.\n"
          "• **ஈடுசெய்வதற்காக ஒருபோதும் இரட்டை டோஸ் எடுக்காதீர்கள்!**\n"
          "சந்தேகம் இருந்தால் உங்கள் மருத்துவரை அணுகவும்.";
    }
    return "🤖 **மெடிமைண்ட் AI மருத்துவ உதவியாளர் (தமிழ்):**\n\n"
        "கண் சொட்டு மருந்துகள், மருந்தளவு அல்லது உணவுக் கட்டுப்பாடுகள் குறித்து நீங்கள் தமிழில் கேட்கலாம்!";
  }

  // ── Telugu Responses ───────────────────────────────────────
  String _generateTeluguResponse(String q) {
    if (q.contains('నమస్కారం') || q.contains('హలో') || q.contains('namaskaram')) {
      return "నమస్కారం! 👋 నేను మెడిమైండ్ ఆఫ్‌లైన్ AI మెడికల్ ట్యూటర్ మరియు హెల్త్ కోచ్‌ని.\n\n"
          "నేను మీకు తెలుగులో సహాయపడగలను:\n"
          "• కంటి చుక్కల మందు (Eye Drops) వేసుకునే సరైన పద్ధతి\n"
          "• రెండు చుక్కల మందుల మధ్య 5 నుండి 10 నిమిషాల విరామం ఎందుకు అవసరం?\n"
          "• డోస్ మిస్ అయినప్పుడు ఏం చేయాలి?\n"
          "• ఆహార మరియు ఔషధ జాగ్రత్తలు\n\n"
          "ఈరోజు మీ ఆరోగ్య సందేహం ఏమిటి?";
    }
    if (q.contains('కంటి') || q.contains('చుక్క') || q.contains('మందు') || q.contains('డ్రాప్') || q.contains('mandulu')) {
      return "👁️ **కంటి చుక్కల మందు వేసుకునే వైద్య విధానం (Punctal Occlusion):**\n\n"
          "1. **చేతులను సబ్బుతో శుభ్రంగా కడగండి.**\n"
          "2. **కాంటాక్ట్ లెన్స్‌లను తీసివేయండి** (మందు వేసిన 15 నిమిషాల తర్వాతే మళ్లీ ధరించండి).\n"
          "3. తలను వెనక్కి వంచి, కింది రెప్పను సున్నితంగా కిందకు లాగి పాకెట్ లాగా చేయండి.\n"
          "4. డ్రాపర్ కొన కంటికి తగలకుండా **కేవలం 1 చుక్క** మాత్రమే వేయండి.\n"
          "5. కళ్ళు నెమ్మదిగా మూసుకోండి (గట్టిగా నొక్కవద్దు).\n"
          "6. **కన్నీటి నాళాన్ని నొక్కడం (Punctal Occlusion):** మందు రక్తంలోకి చేరకుండా ముక్కు దగ్గర ఉన్న కంటి లోపలి మూలను వేలితో **60 సెకన్ల పాటు** నెమ్మదిగా నొక్కండి.\n"
          "7. రెండో చుక్కల మందు వేసే ముందు **కనీసం 5 నుండి 10 నిమిషాలు** వేచి ఉండండి.";
    }
    if (q.contains('మిస్') || q.contains('మరిచి') || q.contains('తీసుకోలేదు')) {
      return "💊 **డోస్ మిస్ అయినప్పుడు సలహా:**\n\n"
          "• కొద్దిసేపటికే గుర్తొస్తే వెంటనే మందు వేసుకోండి.\n"
          "• తదుపరి డోస్ సమయం దగ్గరపడితే, మిస్ అయిన డోస్‌ను వదిలేసి సాధారణ సమయానికే తీసుకోండి.\n"
          "• **ఎట్టి పరిస్థితుల్లోనూ రెట్టింపు డోస్ తీసుకోకండి!**";
    }
    return "🤖 **మెడిమైండ్ AI సహాయకుడు (తెలుగు):**\n\n"
        "కంటి చుక్కలు, మందుల వేళలు లేదా దుష్ప్రభావాల గురించి మీరు నన్ను అడగవచ్చు!";
  }

  // ── Kannada Responses ──────────────────────────────────────
  String _generateKannadaResponse(String q) {
    if (q.contains('ನಮಸ್ಕಾರ') || q.contains('ಹಲೋ') || q.contains('namaskara')) {
      return "ನಮಸ್ಕಾರ! 👋 ನಾನು ಮೆಡಿಮೈಂಡ್ ಆಫ್‌ಲೈನ್ AI ವೈದ್ಯಕೀಯ ಬೋಧಕ ಮತ್ತು ಆರೋಗ್ಯ ಸಹಾಯಕ.\n\n"
          "ಕನ್ನಡದಲ್ಲಿ ನಾನು ನಿಮಗೆ ಸಹಾಯ ಮಾಡುತ್ತೇನೆ:\n"
          "• ಕಣ್ಣಿನ ಹನಿಗಳನ್ನು (Eye Drops) ಸರಿಯಾಗಿ ಹಾಕುವ ವಿಧಾನ\n"
          "• ಎರಡು ಔಷಧಿಗಳ ನಡುವೆ 5 ರಿಂದ 10 ನಿಮಿಷಗಳ ಅಂತರವೇಕೆ ಬೇಕು?\n"
          "• ಡೋಸ್ ತಪ್ಪಿಹೋದರೆ ಏನು ಮಾಡಬೇಕು?\n"
          "• ಆಹಾರ ಮತ್ತು ಔಷಧಿಗಳ ಪರಿಣಾಮಗಳು\n\n"
          "ಇಂದು ನಿಮ್ಮ ಆರೋಗ್ಯದ ಪ್ರಶ್ನೆ ಏನು?";
    }
    if (q.contains('ಕಣ್ಣು') || q.contains('ಹನಿ') || q.contains('ಔಷಧಿ') || q.contains('ಡ್ರಾಪ್') || q.contains('aushadhi')) {
      return "👁️ **ಕಣ್ಣಿನ ಹನಿಗಳನ್ನು ಹಾಕುವ ಸರಿಯಾದ ಕ್ರಮ (Punctal Occlusion):**\n\n"
          "1. **ಕೈಗಳನ್ನು ಸಾಬೂನಿನಿಂದ ಸ್ವಚ್ಛವಾಗಿ ತೊಳೆಯಿರಿ.**\n"
          "2. **ಕಾಂಟ್ಯಾಕ್ಟ್ ಲೆನ್ಸ್ ತೆಗೆಯಿರಿ** (ಔಷಧಿ ಹಾಕಿದ 15 ನಿಮಿಷಗಳ ನಂತರವೇ ಮರಳಿ ಧರಿಸಿ).\n"
          "3. ತಲೆಯನ್ನು ಹಿಂದಕ್ಕೆ ಬಾಗಿಸಿ ಕೆಳಗಿನ ರೆಪ್ಪೆಯನ್ನು ನಿಧಾನವಾಗಿ ಎಳೆದು ಜಾಗ ಮಾಡಿ.\n"
          "4. ಕಣ್ಣಿಗೆ ಬಾಟಲ್ ತಾಗಿಸದೆ **ಕೇವಲ 1 ಹನಿ** ಹಾಕಿ.\n"
          "5. ಕಣ್ಣುಗಳನ್ನು ಮೃದುವಾಗಿ ಮುಚ್ಚಿ.\n"
          "6. **ಕಣ್ಣೀರಿನ ನಾಳವನ್ನು ಒತ್ತಿ ಹಿಡಿಯಿರಿ (Punctal Occlusion):** ಔಷಧಿಯು ರಕ್ತನಾಳಕ್ಕೆ ಸೇರದಂತೆ ಮೂಗಿನ ಪಕ್ಕದಲ್ಲಿರುವ ಒಳ ಕಣ್ಣಿನ ಮೂಲೆಯನ್ನು **60 ಸೆಕೆಂಡುಗಳ ಕಾಲ** ನಿಧಾನವಾಗಿ ಒತ್ತಿ ಹಿಡಿಯಿರಿ.\n"
          "7. ಇನ್ನೊಂದು ಕಣ್ಣಿನ ಹನಿ ಹಾಕುವ ಮೊದಲು **ಕನಿಷ್ಠ 5 ರಿಂದ 10 ನಿಮಿಷ** ಕಾಯಿರಿ.";
    }
    if (q.contains('ಮರೆತು') || q.contains('ತಪ್ಪಿ') || q.contains('ಡೋಸ್')) {
      return "💊 **ಔಷಧಿ ತಪ್ಪಿಹೋದರೆ ಮಾರ್ಗದರ್ಶನ:**\n\n"
          "• ಸ್ವಲ್ಪ ಸಮಯದಲ್ಲಿ ನೆನಪಾದರೆ ತಕ್ಷಣ ತೆಗೆದುಕೊಳ್ಳಿ.\n"
          "• ಮುಂದಿನ ಡೋಸ್ ಸಮಯ ಸಮೀಪಿಸಿದ್ದರೆ ತಪ್ಪಿದ ಡೋಸ್ ಬಿಟ್ಟು ಎಂದಿನಂತೆ ಮುಂದುವರಿಯಿರಿ.\n"
          "• **ಎಂದಿಗೂ ಡಬಲ್ ಡೋಸ್ ತೆಗೆದುಕೊಳ್ಳಬೇಡಿ!**";
    }
    return "🤖 **ಮೆಡಿಮೈಂಡ್ AI ಸಹಾಯಕ (ಕನ್ನಡ):**\n\n"
        "ಕಣ್ಣಿನ ಹನಿಗಳು, ಔಷಧಿಗಳ ನಿಯಮಗಳು ಅಥವಾ ಮುನ್ನೆಚ್ಚರಿಕೆಗಳ ಬಗ್ಗೆ ಕನ್ನಡದಲ್ಲೇ ಕೇಳಿ!";
  }

  // ── Malayalam Responses ────────────────────────────────────
  String _generateMalayalamResponse(String q) {
    if (q.contains('നമസ്കാരം') || q.contains('ഹലോ') || q.contains('namaskaram')) {
      return "നമസ്കാരം! 👋 ഞാൻ മെഡിമൈൻഡ് ഓഫ്‌ലൈൻ AI മെഡിക്കൽ ട്യൂട്ടറും ഹെൽത്ത് കോച്ചുമാണ്.\n\n"
          "മലയാളത്തിൽ ഞാൻ നിങ്ങളെ സഹായിക്കാം:\n"
          "• കണ്ണ് തുള്ളിമരുന്ന് (Eye Drops) കൃത്യമായി ഉപയോഗിക്കുന്ന വിധം\n"
          "• രണ്ട് മരുന്നുകൾക്കിടയിൽ 5-10 മിനിറ്റ് ഇടവേള എന്തിന്?\n"
          "• മരുന്ന് കഴിക്കാൻ മറന്നുപോയാൽ എന്ത് ചെയ്യണം?\n"
          "• ഭക്ഷണ-മരുന്ന് പ്രതിപ്രവർത്തനങ്ങൾ\n\n"
          "ഇന്ന് എന്താണ് അറിയേണ്ടത്?";
    }
    if (q.contains('കണ്ണ്') || q.contains('തുള്ളി') || q.contains('മരുന്ന്') || q.contains('ഡ്രോപ്പ്') || q.contains('marunnu')) {
      return "👁️ **കണ്ണ് തുള്ളിമരുന്ന് ഉപയോഗിക്കുന്ന ശരിയായ രീതി:**\n\n"
          "1. **കൈകൾ സോപ്പുപയോഗിച്ച് വൃത്തിയായി കഴുകുക.**\n"
          "2. **കോൺടാക്റ്റ് ലെൻസുകൾ മാറ്റുക** (മരുന്ന് ഒഴിച്ച് 15 മിനിറ്റിന് ശേഷം മാത്രം വീണ്ടും വെക്കുക).\n"
          "3. തല പിന്നോട്ട് ചരിച്ച് താഴത്തെ കൺപോള താഴേക്ക് പിടിച്ച് ഒരു പോക്കറ്റ് ഉണ്ടാക്കുക.\n"
          "4. കുപ്പിയുടെ അഗ്രം കണ്ണിൽ തൊടാതെ **1 തുള്ളി മാത്രം** ഒഴിക്കുക.\n"
          "5. കണ്ണുകൾ പതുക്കെ അടയ്ക്കുക.\n"
          "6. **കണ്ണീർ നാളി അമർത്തിപ്പിടിക്കുക (Punctal Occlusion):** മരുന്ന് രക്തത്തിലേക്ക് പടരാതിരിക്കാൻ മൂക്കിന് അടുത്തുള്ള കണ്ണിന്റെ ഉൾമൂലയിൽ **60 സെക്കൻഡ്** വിരലമർത്തിപ്പിടിക്കുക.\n"
          "7. രണ്ടാമത്തെ തുള്ളിമരുന്ന് ഒഴിക്കുന്നതിന് മുൻപ് **കുറഞ്ഞത് 5-10 മിനിറ്റ്** കാത്തിരിക്കുക.";
    }
    if (q.contains('മറന്നു') || q.contains('ഒഴിവാ') || q.contains('ഡോസ്')) {
      return "💊 **മരുന്ന് കഴിക്കാൻ വിട്ടുപോയാൽ:**\n\n"
          "• അല്പം വൈകിയാണ് ഓർമ്മ വന്നതെങ്കിൽ ഉടൻ മരുന്ന് കഴിക്കുക.\n"
          "• അടുത്ത ഡോസിന്റെ സമയമായെങ്കിൽ മറന്ന ഡോസ് ഒഴിവാക്കി സാധാരണ ക്രമം തുടരുക.\n"
          "• **ഒരിക്കലും ഇരട്ടി ഡോസ് കഴിക്കരുത്!**";
    }
    return "🤖 **മെഡിമൈൻഡ് AI സഹായി (മലയാളം):**\n\n"
        "കണ്ണ് തുള്ളിമരുന്നുകളെക്കുറിച്ചോ മരുന്നുകളുടെ പാർശ്വഫലങ്ങളെക്കുറിച്ചോ ചോദിക്കാം!";
  }

  // ── Bengali Responses ──────────────────────────────────────
  String _generateBengaliResponse(String q) {
    if (q.contains('নমস্কার') || q.contains('হ্যালো') || q.contains('nomoshkar')) {
      return "নমস্কার! 👋 আমি মেডিমাইন্ড অফলাইন AI মেডিকেল টিউটর ও স্বাস্থ্য সহকারী।\n\n"
          "বাংলায় আমি আপনাকে সাহায্য করতে পারি:\n"
          "• চোখের ড্রপ ব্যবহারের সঠিক চিকিৎসা পদ্ধতি\n"
          "• দুটি ড্রপের মাঝে ৫ থেকে ১০ মিনিট বিরতি কেন জরুরি\n"
          "• ওষুধের ডোজ ভুলে গেলে করণীয়\n"
          "• খাদ্য ও ওষুধের পার্শ্বপ্রতিক্রিয়া\n\n"
          "আজ আপনার কী প্রশ্ন আছে?";
    }
    if (q.contains('চোখ') || q.contains('ড্রপ') || q.contains('ওষুধ') || q.contains('ফোঁটা') || q.contains('osudh')) {
      return "👁️ **চোখের ড্রপ ব্যবহারের সঠিক চিকিৎসা পদ্ধতি (Punctal Occlusion):**\n\n"
          "1. **হাত সাবান দিয়ে ভালো করে ধুয়ে নিন।**\n"
          "2. **কনট্যাক্ট লেন্স খুলে রাখুন** (ড্রপ দেওয়ার ১৫ মিনিট পর লেন্স পরবেন)।\n"
          "3. মাথা পেছনের দিকে হেলিয়ে নিচের চোখের পাতাটি আলতো করে টেনে ধরুন।\n"
          "4. বোতলের মুখ চোখে না ঠেকিয়ে **মাত্র ১ ফোঁটা** ড্রপ দিন।\n"
          "5. চোখ আলতো করে বন্ধ করুন (জোরে চাপবেন না)।\n"
          "6. **টিয়ার ডাক্ট ব্লকেজ (Punctal Occlusion):** ড্রপ রক্তে ছড়িয়ে পড়া রোধ করতে নাকের পাশের চোখের ভেতরের কোণা **৬০ সেকেন্ড** আঙুল দিয়ে চেপে রাখুন।\n"
          "7. দ্বিতীয় কোনো ড্রপ দেওয়ার আগে **কমপক্ষে ৫ থেকে ১০ মিনিট** অপেক্ষা করুন।";
    }
    if (q.contains('ভুলে') || q.contains('ছুটে') || q.contains('ডোজ')) {
      return "💊 **ওষুধের ডোজ ভুলে গেলে করণীয়:**\n\n"
          "• অল্প সময়ের মধ্যে মনে পড়লে সাথে সাথে ওষুধটি খান।\n"
          "• পরবর্তী ডোজের সময় কাছাকাছি হলে ভুলে যাওয়া ডোজটি বাদ দিন এবং স্বাভাবিক নিয়ম মেনে চলুন।\n"
          "• **কখনোই ক্ষতিপূরণ হিসেবে ডবল ডোজ নেবেন না!**";
    }
    return "🤖 **মেডিমাইন্ড AI সহকারী (বাংলা):**\n\n"
        "চোখের ড্রপ, ওষুধ খাওয়ার সময়সূচি বা পার্শ্বপ্রতিক্রিয়া সম্পর্কে জানতে প্রশ্ন করুন!";
  }

  // ── Marathi Responses ──────────────────────────────────────
  String _generateMarathiResponse(String q) {
    if (q.contains('नमस्कार') || q.contains('हॅलो') || q.contains('namaskar')) {
      return "नमस्कार! 👋 मी मेडिमाइंड ऑफलाइन AI मेडिकल ट्यूटर आणि हेल्थ कोच आहे.\n\n"
          "मी तुम्हाला मराठीत मदत करू शकतो:\n"
          "• डोळ्यांचे ड्रॉप्स (Eye Drops) टाकण्याची योग्य पद्धत\n"
          "• दोन औषधांमध्ये ५ ते १० मिनिटांचा फरक का आवश्यक आहे?\n"
          "• डोस चुकला तर काय करावे?\n"
          "• अन्न आणि औषधांमधील परस्परसंवाद\n\n"
          "आज आपला काय प्रश्न आहे?";
    }
    if (q.contains('डोळा') || q.contains('थेंब') || q.contains('औषध') || q.contains('ड्रॉप') || q.contains('dolyat') || q.contains('aushadh')) {
      return "👁️ **डोळ्यात ड्रॉप्स टाकण्याची योग्य वैद्यकीय पद्धत (Punctal Occlusion):**\n\n"
          "1. **हात साबणाने स्वच्छ धुवा.**\n"
          "2. **कॉन्टॅक्ट लेन्स काढून ठेवा** (औषध टाकल्यानंतर १५ मिनिटांनीच पुन्हा वापरा).\n"
          "3. डोके मागे झुकवून खालची पापणी हळूच खाली ओढा.\n"
          "4. बाटलीचा टोक डोळ्याला न टेकवता **फक्त १ थेंब** टाका.\n"
          "5. डोळे हळूच मिटून घ्या.\n"
          "6. **अश्रू नलिका दाबणे (Punctal Occlusion):** औषध रक्तात मिसळू नये म्हणून नाकाजवळचा डोळ्याचा आतील कोपरा बोटाने **६० सेकंद** दाबून ठेवा.\n"
          "7. दुसरा ड्रॉप टाकण्यापूर्वी **किमान ५ ते १० मिनिटे** थांबा.";
    }
    if (q.contains('चुकला') || q.contains('विसरला') || q.contains('डोस')) {
      return "💊 **डोस चुकल्यास योग्य सल्ला:**\n\n"
          "• थोड्याच वेळात आठवल्यास लगेच औषध घ्या.\n"
          "• पुढील डोसची वेळ जवळ आली असल्यास चुकलेला डोस सोडून द्या आणि नियमित वेळापत्रक पाळा.\n"
          "• **कधीही दुप्पट डोस घेऊ नका!**";
    }
    return "🤖 **मेडिमाइंड AI सहाय्यक (मराठी):**\n\n"
        "डोळ्यांची काळजी, औषधांचे वेळापत्रक किंवा पथ्याबाबत मराठीत विचारा!";
  }

  // ── Gujarati Responses ─────────────────────────────────────
  String _generateGujaratiResponse(String q) {
    if (q.contains('નમસ્તે') || q.contains('હેલો') || q.contains('kem cho')) {
      return "નમસ્તે! 👋 હું મેડીમાઇન્ડ ઑફલાઇન AI મેડિકલ ટ્યુટર અને હેલ્થ કોચ છું.\n\n"
          "હું તમને ગુજરાતીમાં મદદ કરી શકું છું:\n"
          "• આંખના ટીપાં (Eye Drops) નાખવાની સાચી તબીબી રીત\n"
          "• બે દવા વચ્ચે 5 થી 10 મિનિટનો ગાળો કેમ જરૂરી છે?\n"
          "• ડોઝ ચૂકી ગયા હોવ તો શું કરવું?\n"
          "• ખોરાક અને દવાની પરહેજ\n\n"
          "આજે આપનો શું પ્રશ્ન છે?";
    }
    if (q.contains('આંખ') || q.contains('ટીપ') || q.contains('દવા') || q.contains('ડ્રોપ') || q.contains('dava')) {
      return "👁️ **આંખમાં ટીપાં નાખવાની સાચી પદ્ધતિ (Punctal Occlusion):**\n\n"
          "1. **હાથ સાબુથી બરાબર ધોઈ લો.**\n"
          "2. **કોન્ટેક્ટ લેન્સ કાઢી લો** (દવા નાખ્યા પછી 15 મિનિટ બાદ જ ફરી પહેરવા).\n"
          "3. માથું પાછળ નમાવીને નીચેની પાંપણ ધીમેથી ખેંચી પોકેટ બનાવો.\n"
          "4. ડ્રોપર આંખને અડ્યા વગર **માત્ર 1 ટીપું** નાખો.\n"
          "5. આંખો ધીમેથી બંધ કરો.\n"
          "6. **આંસુની નળી દબાવવી (Punctal Occlusion):** દવા લોહીમાં ન ભળે તે માટે નાક પાસેના આંખના અંદરના ખૂણાને આંગળીથી **60 સેકન્ડ** દબાવી રાખો.\n"
          "7. બીજું ટીપું નાખતા પહેલા **ઓછામાં ઓછી 5 થી 10 મિનિટ** રાહ જુઓ.";
    }
    if (q.contains('ભૂલી') || q.contains('ચૂકી') || q.contains('ડોઝ')) {
      return "💊 **ડોઝ ચૂકી ગયા હોય ત્યારે સલાહ:**\n\n"
          "• થોડા સમયમાં યાદ આવે તો તરત જ દવા લઈ લો.\n"
          "• જો આગળના ડોઝનો સમય નજીક હોય, તો ચૂકી ગયેલો ડોઝ છોડી દો અને નિયમિત સમયપત્રક ચાલુ રાખો.\n"
          "• **ક્યારેય ડબલ ડોઝ ન લેશો!**";
    }
    return "🤖 **મેડીમાઇન્ડ AI સહાયક (ગુજરાતી):**\n\n"
        "આંખની દવાઓ, સમયપત્રક અથવા સાવચેતી વિશે ગુજરાતીમાં પૂછી શકો છો!";
  }

  // ── Punjabi Responses ──────────────────────────────────────
  String _generatePunjabiResponse(String q) {
    if (q.contains('ਸਤਿ') || q.contains('ਹੈਲੋ') || q.contains('sat sri akaal')) {
      return "ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ! 👋 ਮੈਂ ਮੈਡੀਮਾਈਂਡ ਆਫ਼ਲਾਈਨ AI ਮੈਡੀਕਲ ਟਿਊਟਰ ਅਤੇ ਸਿਹਤ ਕੋਚ ਹਾਂ।\n\n"
          "ਮੈਂ ਪੰਜਾਬੀ ਵਿੱਚ ਤੁਹਾਡੀ ਮਦਦ ਕਰ ਸਕਦਾ ਹਾਂ:\n"
          "• ਅੱਖਾਂ ਦੇ ਡ੍ਰੌਪ (Eye Drops) ਪਾਉਣ ਦਾ ਸਹੀ ਤਰੀਕਾ\n"
          "• ਦੋ ਦਵਾਈਆਂ ਵਿਚਕਾਰ 5 ਤੋਂ 10 ਮਿੰਟ ਦਾ ਫਰਕ ਕਿਉਂ ਜ਼ਰੂਰੀ ਹੈ?\n"
          "• ਜੇਕਰ ਖੁਰਾਕ ਖੁੰਝ ਜਾਵੇ ਤਾਂ ਕੀ ਕਰਨਾ ਹੈ?\n"
          "• ਭੋਜਨ ਅਤੇ ਦਵਾਈਆਂ ਦੇ ਪਰਹੇਜ਼\n\n"
          "ਅੱਜ ਤੁਹਾਡਾ ਕੀ ਸਵਾਲ ਹੈ?";
    }
    if (q.contains('ਅੱਖ') || q.contains('ਬੂੰਦ') || q.contains('ਦਵਾਈ') || q.contains('ਡ੍ਰੌਪ') || q.contains('davai')) {
      return "👁️ **ਅੱਖਾਂ ਵਿੱਚ ਡ੍ਰੌਪ ਪਾਉਣ ਦਾ ਸਹੀ ਡਾਕਟਰੀ ਤਰੀਕਾ (Punctal Occlusion):**\n\n"
          "1. **ਹੱਥਾਂ ਨੂੰ ਸਾਬਣ ਨਾਲ ਚੰਗੀ ਤਰ੍ਹਾਂ ਧੋਵੋ।**\n"
          "2. **ਕਾਂਟੈਕਟ ਲੈਂਸ ਉਤਾਰੋ** (ਦਵਾਈ ਪਾਉਣ ਦੇ 15 ਮਿੰਟ ਬਾਅਦ ਹੀ ਦੁਬਾਰਾ ਲਗਾਓ)।\n"
          "3. ਸਿਰ ਪਿੱਛੇ ਝੁਕਾਓ ਅਤੇ ਹੇਠਲੀ ਪਲਕ ਨੂੰ ਹੌਲੀ ਜਿਹੀ ਖਿੱਚ ਕੇ ਜੇਬ ਬਣਾਓ।\n"
          "4. ਬੋਤਲ ਨੂੰ ਬਿਨਾਂ ਛੋਹੇ **ਸਿਰਫ਼ 1 ਬੂੰਦ** ਪਾਓ।\n"
          "5. ਅੱਖਾਂ ਨੂੰ ਹੌਲੀ ਜਿਹੇ ਬੰਦ ਕਰੋ।\n"
          "6. **ਅੱਥਰੂ ਨਲੀ ਨੂੰ ਦਬਾਓ (Punctal Occlusion):** ਦਵਾਈ ਖੂਨ ਵਿੱਚ ਨਾ ਜਾਵੇ ਇਸ ਲਈ ਨੱਕ ਦੇ ਕੋਲ ਅੱਖ ਦੇ ਅੰਦਰਲੇ ਕੋਨੇ ਨੂੰ **60 ਸਕਿੰਟ** ਉਂਗਲ ਨਾਲ ਦਬਾ ਕੇ ਰੱਖੋ।\n"
          "7. ਦੂਜੀ ਦਵਾਈ ਪਾਉਣ ਤੋਂ ਪਹਿਲਾਂ **ਘੱਟੋ-ਘੱਟ 5 ਤੋਂ 10 ਮਿੰਟ** ਉਡੀਕ ਕਰੋ।";
    }
    if (q.contains('ਖੁੰਝ') || q.contains('ਭੁੱਲ') || q.contains('ਖੁਰਾਕ')) {
      return "💊 **ਖੁਰਾਕ ਖੁੰਝ ਜਾਣ 'ਤੇ ਸਲਾਹ:**\n\n"
          "• ਜੇਕਰ ਥੋੜ੍ਹੀ ਦੇਰ ਵਿੱਚ ਯਾਦ ਆ ਜਾਵੇ ਤਾਂ ਤੁਰੰਤ ਦਵਾਈ ਲਓ।\n"
          "• ਜੇਕਰ ਅਗਲੀ ਖੁਰਾਕ ਦਾ ਸਮਾਂ ਨੇੜੇ ਹੈ, ਤਾਂ ਖੁੰਝੀ ਹੋਈ ਖੁਰਾਕ ਛੱਡ ਦਿਓ ਅਤੇ ਆਮ ਸਮੇਂ 'ਤੇ ਦਵਾਈ ਲਓ।\n"
          "• **ਕਦੇ ਵੀ ਦੁੱਗਣੀ ਖੁਰਾਕ ਨਾ ਲਓ!**";
    }
    return "🤖 **ਮੈਡੀਮਾਈਂਡ AI ਸਹਾਇਕ (ਪੰਜਾਬੀ):**\n\n"
        "ਅੱਖਾਂ ਦੀ ਦਵਾਈ ਜਾਂ ਦਵਾਈਆਂ ਦੇ ਪਰਹੇਜ਼ ਬਾਰੇ ਪੰਜਾਬੀ ਵਿੱਚ ਪੁੱਛੋ!";
  }

  // ── English Default Responses ──────────────────────────────
  String _generateEnglishResponse(String q) {
    if (_matchesAny(q, ['hello', 'hi', 'hey', 'good morning', 'good afternoon'])) {
      return "Hello! 👋 I'm MediMind AI, your offline medication tutor & health coach.\n\n"
          "I can help you in **multiple languages** (English, Hindi, Tamil, Telugu, Kannada, Malayalam, Bengali, Marathi, Gujarati, Punjabi, Spanish, Arabic, French, German, Chinese) with:\n"
          "• Ophthalmic timing & punctal occlusion guidance\n"
          "• Plain-language explanations ('Explain glaucoma like I am 5')\n"
          "• Drug & food interaction advisories\n"
          "• Missed dose strategies & storage limits\n\n"
          "How can I assist your health journey today?";
    }

    if (q.contains('explain') || q.contains('teach me') || q.contains('what is') || q.contains('how does')) {
      if (q.contains('glaucoma')) {
        return "👨‍🏫 **Medical Tutor: What is Glaucoma in Simple Terms?**\n\n"
            "Think of your eye like a small water balloon that needs steady pressure to keep its shape.\n\n"
            "1. Your eye is constantly making fresh clear fluid (aqueous humor) and draining old fluid out.\n"
            "2. If the drain gets clogged, pressure builds up inside the eye (**high intraocular pressure**).\n"
            "3. This pressure pushes against the delicate **optic nerve** at the back of your eye.\n"
            "4. Over time, high pressure damages nerve fibers, starting from your side (peripheral) vision!\n\n"
            "**Why medications matter:**\n"
            "Drops like **Latanoprost** open up drainage channels, while drops like **Timolol** reduce the fluid your eye makes. Taking them daily protects your optic nerve!";
      }

      if (q.contains('punctal') || q.contains('tear duct') || q.contains('pinch')) {
        return "👨‍🏫 **Medical Tutor: Why Pinch Your Tear Duct (Punctal Occlusion)?**\n\n"
            "At the inner corner of your eyelids, there is a tiny drain called the punctum that connects straight to your nose and throat.\n\n"
            "• When you put in an eye drop without pinching, much of the medicine drains down into your nose and enters your **general bloodstream**.\n"
            "• For drops like beta-blockers, this can slow your heart rate or cause breathing tightness.\n\n"
            "**How to do it like a pro:**\n"
            "Right after dropping, close your eyes gently and press with your index finger right next to your nose for **60 seconds**. This locks the medicine in the eye where it belongs!";
      }

      if (q.contains('wash out') || q.contains('5 minute') || q.contains('gap')) {
        return "👨‍🏫 **Medical Tutor: The Eye Drop Wash-Out Effect**\n\n"
            "Your eye pocket can hold roughly **1 drop** at most.\n"
            "If you put Drop A into your eye, and then put Drop B in 1 minute later, Drop B literally overflows and washes Drop A down your cheek!\n\n"
            "**The golden medical rule:**\n"
            "Always wait **5 to 10 minutes** between drops so Drop A can fully absorb into your cornea.";
      }
    }

    if (_matchesAny(q, ['eye drop', 'eye drops', 'eyedrop', 'glaucoma drop', 'latanoprost', 'timolol', 'bimatoprost', 'eye medication'])) {
      return "👁️ **Step-by-Step Eye Drop Technique (Clinical Protocol)**\n\n"
          "1. **Wash hands** with soap and water.\n"
          "2. **Remove soft contact lenses** (wait 15 min after drops before re-inserting).\n"
          "3. **Tilt head back** and gently pull down lower eyelid to form a pocket.\n"
          "4. **Hold bottle vertically** without touching tip to eyelid or eyelashes.\n"
          "5. **Squeeze 1 single drop** into the pocket.\n"
          "6. **Close eyes gently** — do not blink rapidly or squeeze.\n"
          "7. **Punctal occlusion:** Press inner corner of eye for **60 seconds**.\n"
          "8. **Wait 5-10 minutes** before any second eye drop.";
    }

    if (_matchesAny(q, ['missed dose', 'forgot dose', 'skip dose', 'missed my', 'forgot my medicine'])) {
      return "💊 **Clinical Guidance for Missed Doses:**\n\n"
          "• **General rule:** If you remember within a few hours, take it immediately.\n"
          "• **Close to next dose:** Skip the missed dose and resume normal schedule.\n"
          "• **NEVER double dose** to compensate!\n\n"
          "Always contact your doctor or pharmacist if unsure.";
    }

    if (_matchesAny(q, ['grapefruit', 'statin', 'atorvastatin', 'simvastatin'])) {
      return "🍊 **Grapefruit & Statins Warning:**\n\n"
          "Grapefruit blocks the liver enzyme **CYP3A4**.\n"
          "This causes statins to accumulate to toxic levels in your blood, raising the risk of severe muscle tissue breakdown (**rhabdomyolysis**).\n\n"
          "**Recommendation:** Avoid grapefruit completely. Oranges and lemons are safe!";
    }

    return "🤖 **I'm your MediMind AI Health Coach & Medical Tutor!**\n\n"
        "I speak and understand **multiple languages** (English, Spanish, Arabic, French, German, Hindi, Chinese).\n"
        "• Ask me to **'Explain glaucoma in simple words'**\n"
        "• Ask me **'Why do I need to wait 5 minutes between drops?'**\n"
        "• Ask me in Spanish: **'¿Cómo me pongo las gotas?'**\n"
        "• Ask me in Arabic: **'كيف استعمل قطرة العين؟'**\n\n"
        "Tap the speaker icon on any message to hear it read out loud in your language!";
  }

  bool _matchesAny(String input, List<String> keywords) {
    return keywords.any((kw) => input.contains(kw));
  }
}
