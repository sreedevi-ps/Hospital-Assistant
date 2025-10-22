import 'package:flutter/material.dart';
import '../../interaction_flow/interaction_coordinator.dart';
import '../widgets/voice_waveform.dart';

class ConversationScreen extends StatefulWidget {
  final InteractionCoordinator coordinator;

  const ConversationScreen({Key? key, required this.coordinator})
    : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messagesInternal = [];
  int? _speakingMessageIndex;
  bool _isProcessingQuery = false; // Loading indicator

  List<Map<String, String>> get _messages => _messagesInternal;
  String get _selectedLanguage => widget.coordinator.selectedLanguage;

  @override
  void initState() {
    super.initState();

    // Handle assistant replies
    widget.coordinator.onInteractionComplete = (userText, assistantText) {
      setState(() {
        _messages.add({"role": "user", "text": userText});
        _messages.add({"role": "assistant", "text": assistantText});
        _isProcessingQuery = false; // Stop loading
      });
      _scrollToBottom();

      // Speak assistant reply
      widget.coordinator.tts.speak(assistantText);
    };

    // Initialize with welcome message
    final welcomeMessage = widget.coordinator.welcomeMessage;
    _messages.add({"role": "assistant", "text": welcomeMessage});
    widget.coordinator.tts.speak(welcomeMessage);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Multilingual typing text
  String _getTypingText() {
    switch (_selectedLanguage) {
      case "ml_IN":
        return "അസിസ്റ്റന്റ് ടൈപ്പിംഗ് ചെയ്യുന്നു...";
      case "ta_IN":
        return "உதவியாளர் தட்டச்சு செய்கிறார்...";
      case "en_US":
      default:
        return "Assistant is typing...";
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> chatHeader = {
      "ml_IN": "ഇവിടെ ചാറ്റ് ചെയ്യുക",
      "en_US": "Chat Here",
      "ta_IN": "இங்கே உரையாடவும்",
    };

    final String headerText =
        chatHeader[_selectedLanguage] ?? chatHeader["ml_IN"]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade800,
        title: Text(headerText),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.coordinator.onNewSession?.call();
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount:
                  _messages.length +
                  (_isProcessingQuery ? 1 : 0), // Extra slot for typing
              itemBuilder: (context, index) {
                if (_isProcessingQuery && index == _messages.length) {
                  // Show typing indicator
                  return Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.red.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
            _getTypingText(),
            style: const TextStyle(
              fontSize: 14, // smaller font
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
                        ],
                      ),
                    ),
                  );
                }

                final message = _messages[index];
                final isUser = message["role"] == "user";

                return Container(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color.fromARGB(255, 234, 120, 124)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      message["text"] ?? "", // <- use actual message here
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: VoiceWaveform(
              coordinator: widget.coordinator,
              onQueryStart: () => setState(() => _isProcessingQuery = true),
            ),
          ),
        ],
      ),
    );
  }
}
