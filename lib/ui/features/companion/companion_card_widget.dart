import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../core/apple_glass_decorations.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import 'medi_buddy_character.dart';

class CompanionCardWidget extends StatefulWidget {
  const CompanionCardWidget({super.key});

  @override
  State<CompanionCardWidget> createState() => _CompanionCardWidgetState();
}

class _CompanionCardWidgetState extends State<CompanionCardWidget> {
  MediBuddyOutfit _currentOutfit = MediBuddyOutfit.doctor;
  String _activeSpeechBubble = '';

  @override
  void initState() {
    super.initState();
    _updateSpeechForTime();
  }

  void _updateSpeechForTime() {
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 6) {
      _activeSpeechBubble = 'Rest well tonight! Your body heals during sleep. 🌙';
    } else if (hour < 12) {
      _activeSpeechBubble = 'Good morning! Ready for today\'s healthy journey? ☀️';
    } else if (hour < 17) {
      _activeSpeechBubble = 'Keep up the great rhythm! Stay hydrated! 💧';
    } else {
      _activeSpeechBubble = 'Evening check-in! Reviewing your evening doses. 🌅';
    }
  }

  MediBuddyMood _resolveMood(double adherence) {
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 6) {
      return MediBuddyMood.sleeping;
    }
    if (adherence >= 80.0) {
      return MediBuddyMood.celebrating;
    }
    if (adherence >= 50.0) {
      return MediBuddyMood.happy;
    }
    return MediBuddyMood.encouraging;
  }

  void _toggleOutfit() {
    AppleGlassDecorations.lightHaptic();
    setState(() {
      final nextIdx = (_currentOutfit.index + 1) % MediBuddyOutfit.values.length;
      _currentOutfit = MediBuddyOutfit.values[nextIdx];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationRepository>(
      builder: (context, repo, _) {
        final adherence = repo.calculateAdherenceRate();
        final mood = _resolveMood(adherence);
        final patientName = repo.userProfile?.name.split(' ').first ?? 'Friend';

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE0F2FE), Color(0xFFF0FDF4), Color(0xFFFAF5FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withAlpha(20),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // MediBuddy Mascot with Tap Bounce & Voice
                MediBuddyCharacter(
                  size: 110,
                  mood: mood,
                  outfit: _currentOutfit,
                  interactive: true,
                  enableVoiceOnTap: true,
                  onTap: () {
                    setState(() {
                      _activeSpeechBubble = 'I love seeing you take such great care of your health, $patientName!';
                    });
                  },
                ),
                const SizedBox(width: 14),

                // Companion Dialogue & Quick Actions
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mascot Name Badge & Outfit Switcher
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'PIP • YOUR MEDIBUDDY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Outfit Cycle button
                          InkWell(
                            onTap: _toggleOutfit,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(200),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                '👔 ${_currentOutfit.name.toUpperCase()}',
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Speech Bubble with Callout Tail
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _activeSpeechBubble,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Action Pills
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                AppleGlassDecorations.mediumHaptic();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AiAssistantScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.psychology_outlined, size: 14, color: Color(0xFF7C3AED)),
                              label: const Text(
                                'Chat with AI',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                side: const BorderSide(color: Color(0xFFDDD6FE)),
                                backgroundColor: const Color(0xFFF5F3FF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: adherence >= 80 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  adherence >= 80 ? Icons.emoji_events_rounded : Icons.bolt_rounded,
                                  size: 14,
                                  color: adherence >= 80 ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${adherence.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: adherence >= 80 ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
