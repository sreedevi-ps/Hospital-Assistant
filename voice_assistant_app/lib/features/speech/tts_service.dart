import 'dart:ui';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart'; // Needed for ValueNotifier

class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);

  bool get isSpeaking => _isSpeaking;

  TextToSpeechService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage("ml-IN"); // Default to Malayalam
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      _isSpeaking = true;
      isSpeakingNotifier.value = true;
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      isSpeakingNotifier.value = false;
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
      isSpeakingNotifier.value = false;
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      isSpeakingNotifier.value = false;
    });
  }

  Future<void> setLanguage(String languageCode) async {
    await _tts.setLanguage(languageCode);
    print("TTS language set to: $languageCode");
  }

  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    await _tts.speak(text);
    if (onComplete != null) {
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        isSpeakingNotifier.value = false;
        onComplete();
      });
    }
  }

  void stop() {
    _tts.stop();
    _isSpeaking = false;
    isSpeakingNotifier.value = false;
  }
}