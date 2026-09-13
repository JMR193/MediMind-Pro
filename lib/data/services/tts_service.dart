import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  String _currentLanguage = 'en-US';

  bool get isPlaying => _isPlaying;
  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    try {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isPlaying = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
      });

      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isPlaying = false;
        debugPrint('TTS Error: $msg');
      });
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  /// Converts ISO 2-letter language code to BCP-47 locale tag
  String _mapLocaleTag(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'es': return 'es-ES';
      case 'ar': return 'ar-SA';
      case 'fr': return 'fr-FR';
      case 'de': return 'de-DE';
      case 'hi': return 'hi-IN';
      case 'ta': return 'ta-IN';
      case 'te': return 'te-IN';
      case 'kn': return 'kn-IN';
      case 'ml': return 'ml-IN';
      case 'bn': return 'bn-IN';
      case 'mr': return 'mr-IN';
      case 'gu': return 'gu-IN';
      case 'pa': return 'pa-IN';
      case 'zh': return 'zh-CN';
      case 'ja': return 'ja-JP';
      case 'ko': return 'ko-KR';
      case 'pt': return 'pt-BR';
      case 'ru': return 'ru-RU';
      case 'tr': return 'tr-TR';
      case 'it': return 'it-IT';
      case 'id': return 'id-ID';
      case 'ur': return 'ur-PK';
      default: return 'en-US';
    }
  }

  /// Cleans markdown characters (asterisks, headers, bullets) for clean spoken audio
  String _cleanMarkdownForSpeech(String markdown) {
    return markdown
        .replaceAll(RegExp(r'[*#_`~]'), '')
        .replaceAll(RegExp(r'•\s*'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp(r'(\r?\n)+'), '. ')
        .trim();
  }

  Future<void> speak(String text, {String? languageCode}) async {
    try {
      final localeTag = _mapLocaleTag(languageCode ?? 'en');
      await _flutterTts.setLanguage(localeTag);
      _currentLanguage = localeTag;

      final cleanText = _cleanMarkdownForSpeech(text);
      if (cleanText.isEmpty) return;

      _isPlaying = true;
      await _flutterTts.speak(cleanText);
    } catch (e) {
      _isPlaying = false;
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
    } catch (_) {}
  }
}
