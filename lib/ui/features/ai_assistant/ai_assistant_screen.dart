import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../data/services/ai_assistant_service.dart';
import '../../../data/services/prescription_parser_service.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../domain/models/ai_message.dart';
import '../../../domain/models/ai_task.dart';
import '../../../domain/models/medication.dart';
import '../../core/theme.dart';
import '../eye_drop_assistant/eye_drop_screen.dart';
import '../symptom_diary/symptom_diary_screen.dart';
import '../medication_wizard/add_medication_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final _parserService = PrescriptionParserService();
  final Set<String> _scheduledDraftKeys = {};
  bool _isListening = false;
  bool _speechInitialized = false;

  static const _quickQuestions = [
    '👨‍🏫 Explain glaucoma like I am 5',
    '💧 Why wait 5 minutes between drops?',
    '⏳ Why discard drops after 28 days?',
    '🫀 How does punctal occlusion protect my heart?',
    '🎓 Quiz me on my eye medications',
    '📋 What is my automated daily routine?',
    '🍊 Can I eat grapefruit with statins?',
    '💊 What should I do if I miss a dose?',
  ];

  static const _languageOptions = [
    ('en', '🇬🇧 English'),
    ('hi', '🇮🇳 हिन्दी (Hindi)'),
    ('ta', '🇮🇳 தமிழ் (Tamil)'),
    ('te', '🇮🇳 తెలుగు (Telugu)'),
    ('kn', '🇮🇳 ಕನ್ನಡ (Kannada)'),
    ('ml', '🇮🇳 മലയാളം (Malayalam)'),
    ('bn', '🇮🇳 বাংলা (Bengali)'),
    ('mr', '🇮🇳 मराठी (Marathi)'),
    ('gu', '🇮🇳 ગુજરાતી (Gujarati)'),
    ('pa', '🇮🇳 ਪੰਜਾਬੀ (Punjabi)'),
    ('es', '🇪🇸 Español'),
    ('ar', '🇸🇦 العربية (Arabic)'),
    ('fr', '🇫🇷 Français'),
    ('de', '🇩🇪 Deutsch'),
    ('zh', '🇨🇳 中文 (Chinese)'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechInitialized = await _speech.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _toggleListening() async {
    if (!_speechInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available or permission denied.')),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      if (mounted) setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _chatController.text = result.recognizedWords;
          });
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            _send(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _chatController.clear();
    context.read<AiAssistantService>().sendMessage(text);
    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiAssistantService>(
      builder: (context, service, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF0284C7)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Health Coach & Tutor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Voice & Multilingual • 100% Offline', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            actions: [
              // Auto-speak audio toggle
              IconButton(
                icon: Icon(
                  service.autoSpeakEnabled ? Icons.volume_up : Icons.volume_off_outlined,
                  color: service.autoSpeakEnabled ? const Color(0xFF7C3AED) : null,
                ),
                tooltip: service.autoSpeakEnabled ? 'Auto-speak ON' : 'Auto-speak OFF',
                onPressed: () {
                  service.toggleAutoSpeak();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(service.autoSpeakEnabled ? '🔊 Voice auto-read enabled' : '🔇 Voice auto-read disabled'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              // Language Selector Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.translate),
                tooltip: 'Select AI Language',
                onSelected: (code) {
                  service.setLanguage(code);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('AI Language set to ${_getLangName(code)}')),
                  );
                },
                itemBuilder: (_) => _languageOptions
                    .map((l) => PopupMenuItem(
                          value: l.$1,
                          child: Row(
                            children: [
                              Text(l.$2, style: TextStyle(fontWeight: service.activeLanguageCode == l.$1 ? FontWeight.bold : FontWeight.normal)),
                              if (service.activeLanguageCode == l.$1) ...[
                                const Spacer(),
                                const Icon(Icons.check, size: 16, color: Colors.green),
                              ],
                            ],
                          ),
                        ))
                    .toList(),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear chat',
                onPressed: () => service.clearChat(),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Theme.of(context).colorScheme.primary,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'AI Tutor'),
                Tab(icon: Icon(Icons.checklist_outlined, size: 18), text: 'Daily Tasks'),
                Tab(icon: Icon(Icons.school_outlined, size: 18), text: 'Academy'),
                Tab(icon: Icon(Icons.health_and_safety_outlined, size: 18), text: 'Check-In'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildChatTab(service),
              _buildDailyTasksTab(service),
              _buildAcademyTab(service),
              _buildCheckInTab(service),
            ],
          ),
        );
      },
    );
  }

  String _getLangName(String code) {
    return _languageOptions.firstWhere((l) => l.$1 == code, orElse: () => ('en', 'English')).$2;
  }

  // ──────────────────────────────────────────
  // Tab 1: AI Chat & Multilingual Voice Tutor
  // ──────────────────────────────────────────
  Widget _buildChatTab(AiAssistantService service) {
    final messages = service.messages;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: MediMindTheme.warningOrange.withAlpha(26),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: MediMindTheme.warningOrange),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Educational assistant — not medical advice. Consult your doctor for medical decisions.',
                  style: TextStyle(fontSize: 11, color: MediMindTheme.warningOrange),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                child: Text(service.activeLanguageCode.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            ],
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyChatState(service)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) => _buildMessageBubble(messages[i], service),
                ),
        ),
        if (messages.isEmpty)
          _buildQuickQuestionChips(),
        if (_isListening)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: MediMindTheme.alertRed.withAlpha(26),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, size: 16, color: MediMindTheme.alertRed),
                SizedBox(width: 8),
                Text('Listening in your language... speak your question now', style: TextStyle(fontSize: 12, color: MediMindTheme.alertRed, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        _buildInputBar(service),
      ],
    );
  }

  Widget _buildEmptyChatState(AiAssistantService service) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF0284C7)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.record_voice_over_outlined, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 16),
            const Text('Your Multilingual Medical Tutor', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Ask any question in your native language or speak with your voice.\nSupports English, Spanish, Arabic, French, German, Hindi & Chinese completely offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.withAlpha(204), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(avatar: const Icon(Icons.mic, size: 14, color: Color(0xFF0284C7)), label: const Text('Voice In & Out', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7)))),
                Chip(avatar: const Icon(Icons.language, size: 14, color: Color(0xFF7C3AED)), label: const Text('7 Global Languages', style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED)))),
                Chip(avatar: const Icon(Icons.lock_outline, size: 14, color: Colors.green), label: const Text('100% On-Device', style: TextStyle(fontSize: 11, color: Colors.green))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestionChips() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickQuestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          label: Text(_quickQuestions[i], style: const TextStyle(fontSize: 12)),
          onPressed: () => _send(_quickQuestions[i]),
          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(15),
          side: BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(51)),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage msg, AiAssistantService service) {
    final isUser = msg.role == AiRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF0284C7)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: msg.content));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: isUser
                        ? Text(msg.content, style: const TextStyle(color: Colors.white, fontSize: 14))
                        : MarkdownBody(
                            data: msg.content,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(fontSize: 13.5, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                              strong: const TextStyle(fontWeight: FontWeight.bold),
                              listBullet: TextStyle(fontSize: 13.5, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                  ),
                ),
                // Voice Read-Aloud & Copy Actions for AI Messages
                if (!isUser && msg.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up_outlined, size: 18),
                          tooltip: 'Speak response out loud',
                          onPressed: () => service.speakText(msg.content),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.stop_circle_outlined, size: 18),
                          tooltip: 'Stop voice',
                          onPressed: () => service.stopSpeaking(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.copy_outlined, size: 16),
                          tooltip: 'Copy text',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: msg.content));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ),
                  ),
                // In-Chat Interactive Quick-Schedule Medication Cards
                if (msg.content.trim().isNotEmpty) ...[
                  ..._parserService.parsePrescription(msg.content).map((draft) => _buildQuickScheduleCard(draft)),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildInputBar(AiAssistantService service) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          // Speech-to-text microphone button
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? MediMindTheme.alertRed : Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Speak in your language',
            onPressed: _toggleListening,
          ),
          Expanded(
            child: TextField(
              controller: _chatController,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              decoration: InputDecoration(
                hintText: 'Type or speak in any language...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: service.isProcessing ? null : () => _send(_chatController.text),
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(14),
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: service.isProcessing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Tab 2: Proactive Daily Tasks & Routines
  // ──────────────────────────────────────────
  Widget _buildDailyTasksTab(AiAssistantService service) {
    final tasks = service.dailyTasks;
    final progress = service.taskProgress;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0369A1)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Today\'s AI Health Checklist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${(progress * 100).toStringAsFixed(0)}% Done', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text('${service.completedTasksCount} of ${tasks.length} tasks completed', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Automated Daily Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No tasks generated yet. Add medications to activate your plan!')),
          )
        else
          ...tasks.map((task) => _buildTaskCard(context, task, service)),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, AiDailyTask task, AiAssistantService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => service.toggleTask(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(task.description, style: TextStyle(fontSize: 11, color: Colors.grey.withAlpha(204))),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.timeOfDay.name.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                if (task.actionRoute != null) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      if (task.actionRoute == 'eye_drop') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeDropScreen()));
                      } else if (task.actionRoute == 'lesson') {
                        _tabController.animateTo(2);
                      } else if (task.actionRoute == 'symptom_diary') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomDiaryScreen()));
                      }
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                    child: const Text('Open Tool →', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Tab 3: Medical Academy (Tutor Lessons)
  // ──────────────────────────────────────────
  Widget _buildAcademyTab(AiAssistantService service) {
    final lessons = service.lessons;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber, size: 36),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MediMind Patient Academy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('1-minute clinical masterclasses to understand your eye care, avoid complications & master your health.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Clinical Micro-Courses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        ...lessons.map((l) => _buildLessonCard(context, l, service)),
      ],
    );
  }

  Widget _buildLessonCard(BuildContext context, AiLesson lesson, AiAssistantService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: lesson.isCompleted ? MediMindTheme.successGreen.withAlpha(26) : const Color(0xFF7C3AED).withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(
            lesson.isCompleted ? Icons.check_circle : Icons.auto_stories,
            color: lesson.isCompleted ? MediMindTheme.successGreen : const Color(0xFF7C3AED),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            Text(lesson.readTime, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(lesson.summary, style: TextStyle(fontSize: 12, color: Colors.grey.withAlpha(204))),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.withAlpha(26), borderRadius: BorderRadius.circular(4)),
                  child: Text(lesson.category, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () => _showLessonModal(context, lesson, service),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), minimumSize: const Size(0, 0)),
                  child: Text(lesson.isCompleted ? 'Review' : 'Start Lesson', style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLessonModal(BuildContext context, AiLesson lesson, AiAssistantService service) {
    int? selectedOption;
    bool submitted = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollCtrl) => Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollCtrl,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF7C3AED).withAlpha(26), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.school, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lesson.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${lesson.category} · ${lesson.readTime}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_outlined),
                      tooltip: 'Read lesson aloud',
                      onPressed: () => service.speakText(lesson.detailedContentMarkdown),
                    ),
                  ],
                ),
                const Divider(height: 24),
                MarkdownBody(data: lesson.detailedContentMarkdown),
                const SizedBox(height: 24),
                // Interactive Quiz Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(51)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.quiz_outlined, size: 18, color: Color(0xFF0284C7)),
                          SizedBox(width: 8),
                          Text('Knowledge Check Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(lesson.quizQuestion, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ...List.generate(lesson.quizOptions.length, (i) {
                        final isCorrect = i == lesson.correctOptionIndex;
                        final isSelected = selectedOption == i;
                        Color? tileColor;
                        if (submitted) {
                          if (isCorrect) tileColor = Colors.green.withAlpha(38);
                          if (isSelected && !isCorrect) tileColor = Colors.red.withAlpha(38);
                        }

                        return InkWell(
                          onTap: submitted ? null : () => setModalState(() => selectedOption = i),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: tileColor ?? (isSelected ? Theme.of(context).colorScheme.primary.withAlpha(26) : Colors.transparent),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: submitted && isCorrect
                                    ? Colors.green
                                    : isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.withAlpha(77),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text('${String.fromCharCode(65 + i)}) ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(lesson.quizOptions[i], style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (submitted) ...[
                        const SizedBox(height: 8),
                        Text(lesson.quizExplanation, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.green)),
                      ],
                      const SizedBox(height: 12),
                      if (!submitted)
                        FilledButton(
                          onPressed: selectedOption == null
                              ? null
                              : () {
                                  setModalState(() => submitted = true);
                                  service.completeLesson(lesson.id);
                                },
                          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                          child: const Text('Submit Answer'),
                        )
                      else
                        OutlinedButton(
                          onPressed: () {
                            service.stopSpeaking();
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                          child: const Text('Complete & Close'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Tab 4: Health Check-In (Targeted Questioning)
  // ──────────────────────────────────────────
  Widget _buildCheckInTab(AiAssistantService service) {
    final questions = service.healthQuestions;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.white, size: 36),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily AI Health Triage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Answer 3 quick questions to help AI evaluate your treatment tolerance and flag issues early.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...questions.map((q) => _buildQuestionCard(context, q, service)),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, AiHealthCheckQuestion q, AiAssistantService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(q.subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.withAlpha(204))),
            const SizedBox(height: 12),
            ...q.options.map((opt) {
              final isSelected = q.selectedAnswer == opt;
              return InkWell(
                onTap: () => service.answerHealthQuestion(q.id, opt),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha(26) : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withAlpha(77),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, size: 16, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(child: Text(opt, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                    ],
                  ),
                ),
              );
            }),
            if (q.aiFeedback != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: q.isNegativeSymptom ? MediMindTheme.alertRed.withAlpha(20) : MediMindTheme.successGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: q.isNegativeSymptom ? MediMindTheme.alertRed.withAlpha(77) : MediMindTheme.successGreen.withAlpha(77)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(q.isNegativeSymptom ? Icons.warning_amber : Icons.smart_toy_outlined, size: 16, color: q.isNegativeSymptom ? MediMindTheme.alertRed : MediMindTheme.successGreen),
                    const SizedBox(width: 8),
                    Expanded(child: Text(q.aiFeedback!, style: TextStyle(fontSize: 11.5, color: q.isNegativeSymptom ? MediMindTheme.alertRed : Colors.green.shade800, height: 1.3))),
                    IconButton(
                      icon: const Icon(Icons.volume_up_outlined, size: 18),
                      tooltip: 'Speak feedback',
                      onPressed: () => service.speakText(q.aiFeedback!),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),
              if (q.isNegativeSymptom) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomDiaryScreen())),
                  icon: const Icon(Icons.healing_outlined, size: 14),
                  label: const Text('Log in Symptom Diary →', style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickScheduleCard(ParsedMedicationDraft draft) {
    final draftKey = '${draft.name}_${draft.strength}_${draft.frequencyPattern}';
    final isAlreadyScheduled = _scheduledDraftKeys.contains(draftKey);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlreadyScheduled ? Colors.green : const Color(0xFF7C3AED).withAlpha(120),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isAlreadyScheduled
                      ? Colors.green.withAlpha(26)
                      : (draft.isEyeMedication ? const Color(0xFF0284C7).withAlpha(26) : const Color(0xFF7C3AED).withAlpha(26)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAlreadyScheduled
                      ? Icons.check_circle
                      : (draft.isEyeMedication ? Icons.remove_red_eye_outlined : Icons.medication_outlined),
                  size: 16,
                  color: isAlreadyScheduled
                      ? Colors.green
                      : (draft.isEyeMedication ? const Color(0xFF0284C7) : const Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    if (draft.strength.isNotEmpty)
                      Text(
                        draft.strength,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Quick-Schedule',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Chip(
                avatar: const Icon(Icons.repeat, size: 12),
                label: Text(draft.frequencyLabel, style: const TextStyle(fontSize: 10.5)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              Chip(
                avatar: const Icon(Icons.access_time, size: 12),
                label: Text(draft.scheduleTimes.join(', '), style: const TextStyle(fontSize: 10.5)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              if (draft.durationDays != null)
                Chip(
                  avatar: const Icon(Icons.calendar_today, size: 12),
                  label: Text('${draft.durationDays}d', style: const TextStyle(fontSize: 10.5)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              Chip(
                avatar: const Icon(Icons.restaurant, size: 12),
                label: Text(
                  draft.instruction == AdminInstruction.beforeMeal
                      ? 'Before Food'
                      : draft.instruction == AdminInstruction.atBedtime
                          ? 'Bedtime'
                          : 'After Food',
                  style: const TextStyle(fontSize: 10.5),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isAlreadyScheduled
                      ? null
                      : () {
                          final med = draft.toMedication(doctorName: 'MediMind AI Assistant');
                          context.read<MedicationRepository>().addMedication(med);
                          setState(() {
                            _scheduledDraftKeys.add(draftKey);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green,
                              content: Text('✅ Scheduled ${draft.name} with exact alarms!'),
                            ),
                          );
                        },
                  icon: Icon(isAlreadyScheduled ? Icons.done : Icons.alarm_add_outlined, size: 15),
                  label: Text(
                    isAlreadyScheduled ? 'Added to Schedule' : '1-Tap Add Schedule',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: isAlreadyScheduled ? Colors.green : const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  final med = draft.toMedication(doctorName: 'MediMind AI Assistant');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddMedicationScreen(editMedication: med)),
                  );
                },
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: const Text('Customize', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
