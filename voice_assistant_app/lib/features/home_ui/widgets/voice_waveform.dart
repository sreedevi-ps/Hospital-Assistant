import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../interaction_flow/interaction_coordinator.dart';
import '../../speech/speech_service.dart';

class VoiceWaveform extends StatefulWidget {
  final InteractionCoordinator coordinator;
  final VoidCallback? onQueryStart;

  const VoiceWaveform({super.key, required this.coordinator, this.onQueryStart});

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isListening = false;
  bool _isAutoListening = false;
  Timer? _autoStopTimer;
  String _recognizedText = "";

  late VoidCallback _ttsCompletionListener;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _ttsCompletionListener = () {
      if (!widget.coordinator.tts.isSpeaking &&
          mounted &&
          !widget.coordinator.speech.isListening) {
        // 🔹 Add 4-second delay before starting auto listening
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted &&
              !widget.coordinator.speech.isListening &&
              !_isAutoListening) {
            _startAutoListening();
          }
        });
      }
    };

    widget.coordinator.tts.isSpeakingNotifier.addListener(_ttsCompletionListener);

    final speechService = widget.coordinator.speech;

    // 🔥 FIX: safely override callbacks
    speechService.onTextRecognized = (text) {
      setState(() {
        _recognizedText = text;
      });

      // 🔥 FIX: trigger query flow when text recognized
      if (text.isNotEmpty) {
        widget.onQueryStart?.call();
        widget.coordinator.handleUserQuery(text);
      }
    };

    speechService.onListeningStatusChanged = (listening) {
      setState(() {
        _isListening = listening;
        _isAutoListening = listening && _isAutoListening; // Maintain auto state
        if (listening && widget.coordinator.speech.isListening) {
          _controller.repeat();
        } else {
          _controller.stop();
          _controller.value = 1.0;
          _isAutoListening = false; // Reset auto-listening
          _autoStopTimer?.cancel();
        }
      });
    };
  }

  @override
  void dispose() {
    widget.coordinator.tts.isSpeakingNotifier.removeListener(_ttsCompletionListener);
    _controller.stop();
    _controller.dispose();
    _autoStopTimer?.cancel();
    widget.coordinator.speech.stopListening(); // Ensure SpeechService is stopped
    super.dispose();
  }

  String _getListeningText() {
    switch (widget.coordinator.selectedLanguage) {
      case "ml_IN":
        return "🎤 കേൾക്കുന്നു...";
      case "ta_IN":
        return "🎤 கேட்கிறேன்...";
      case "en_US":
      default:
        return "🎤 Listening...";
    }
  }

  Future<void> _startAutoListening() async {
    if (widget.coordinator.speech.isListening ||
        _isAutoListening ||
        widget.coordinator.tts.isSpeaking) {
      return;
    }

    setState(() {
      _isAutoListening = true;
    });

    try {
      await widget.coordinator.speech.startListening(
        language: widget.coordinator.selectedLanguage,
      );
      // Only update UI if SpeechService confirms listening
      if (widget.coordinator.speech.isListening) {
        setState(() {
          _isListening = true;
          _controller.repeat();
        });
      }

      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(const Duration(seconds: 8), () {
        if (_isAutoListening && widget.coordinator.speech.isListening) {
          _stopListening();
        }
      });
    } catch (e) {
      debugPrint("Error starting auto listening: $e");
      _resetListening();
    }
  }

  Future<void> _startManualListening() async {
    if (widget.coordinator.speech.isListening) {
      _stopListening();
    }

    try {
      await widget.coordinator.speech.startListening(
        language: widget.coordinator.selectedLanguage,
      );
      // Only update UI if SpeechService confirms listening
      if (widget.coordinator.speech.isListening) {
        setState(() {
          _isListening = true;
          _isAutoListening = false;
          _controller.repeat();
        });
      }
    } catch (e) {
      debugPrint("Error starting manual listening: $e");
      _resetListening();
    }
  }

  void _stopListening() {
    widget.coordinator.speech.stopListening();
    _resetListening();
  }

  void _resetListening() {
    setState(() {
      _isListening = false;
      _isAutoListening = false;
      _controller.stop();
      _controller.value = 1.0;
    });
    _autoStopTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Colors.red.shade600;
    final inactiveColor = Colors.grey.shade400;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _controller.value;
                return SizedBox(
                  width: 120,
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(16, (i) {
                      final height = _isListening &&
                              widget.coordinator.speech.isListening
                          ? 6 + (math.sin(progress * 2 * math.pi + i * 0.4) + 1) * 4
                          : 6;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 2,
                        height: height.toDouble(),
                        decoration: BoxDecoration(
                          color: _isListening &&
                                  widget.coordinator.speech.isListening
                              ? activeColor
                              : inactiveColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onLongPressStart: (_) => _startManualListening(),
              onLongPressEnd: (_) => _stopListening(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                transform:
                    Matrix4.translationValues(_isListening ? 4.0 : 0.0, 0, 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? activeColor : inactiveColor,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? activeColor : inactiveColor)
                          .withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 24,
                  color: _isListening ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedOpacity(
          opacity: _isListening ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            _getListeningText(),
            style: TextStyle(
              fontSize: 12, // Reduced font size
              color: activeColor,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ],
    );
  }
}