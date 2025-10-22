import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  // 🔥 FIX: make them mutable so VoiceWaveform can reassign
  Function(String)? onTextRecognized; 
  void Function(bool)? onListeningStatusChanged;

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool isListening = false;
  bool _isInitialized = false;

  // 🔥 FIX: constructor assigns to mutable vars, no final fields anymore
  SpeechService({
    this.onTextRecognized,
    this.onListeningStatusChanged,
  });

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) throw Exception("Microphone permission not granted");

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          isListening = false;
          onListeningStatusChanged?.call(false); // 🔥 FIX safe call
        }
      },
      onError: (error) {
        isListening = false;
        onListeningStatusChanged?.call(false); // 🔥 FIX safe call
      },
    );

    if (available) {
      _isInitialized = true;
    } else {
      throw Exception("Speech recognition not available");
    }
  }

  Future<void> startListening({required String language}) async {
    if (!_speech.isListening && _isInitialized) {
      await _speech.listen(
        localeId: language,
        listenMode: stt.ListenMode.dictation,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 10),
        cancelOnError: true,
        partialResults: false,
        onResult: (result) {
          isListening = false;
          onListeningStatusChanged?.call(false); // 🔥 FIX safe call
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            onTextRecognized?.call(result.recognizedWords); // 🔥 FIX safe call
          }
        },
      );
      isListening = true;
      onListeningStatusChanged?.call(true); // 🔥 FIX safe call
    }
  }

  void stopListening() {
    if (_speech.isListening) {
      _speech.stop();
      isListening = false;
      onListeningStatusChanged?.call(false); // 🔥 FIX safe call
    }
  }

  void dispose() => _speech.stop();
}
