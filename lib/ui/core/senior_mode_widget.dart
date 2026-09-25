import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SeniorModeHelper {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> speakAction(String message) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45); // Gentle, slow speech rate for seniors
      await _tts.setPitch(1.0);
      await _tts.speak(message);
    } catch (_) {
      // Graceful fallback if TTS not available
    }
  }

  static Widget buildSeniorDoseCard({
    required BuildContext context,
    required String medicationName,
    required String strength,
    required String instruction,
    required String time,
    required VoidCallback onTake,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber, width: 3.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber,
                ),
              ),
              const Icon(Icons.alarm_on_rounded, color: Colors.amber, size: 32),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            medicationName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ' • ',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 64, // Extra large touch target
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 28),
              label: const Text('I TOOK THIS MEDICINE'),
              onPressed: () {
                speakAction('Dose of  confirmed. Great job!');
                onTake();
              },
            ),
          ),
        ],
      ),
    );
  }
}
