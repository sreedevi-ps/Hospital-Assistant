import 'package:flutter/material.dart';
import 'package:voice_assistant_app/data/models/chat_messages.dart';
import 'conversation_screen.dart';
import 'package:voice_assistant_app/features/interaction_flow/interaction_coordinator.dart';
import 'package:voice_assistant_app/features/face_detection/camera_service.dart';
import 'package:camera/camera.dart';
import 'menu_screen.dart';
// import 'book_appointment_screen.dart';
// import 'check_in_screen.dart';
// import 'pharmacy_token_screen.dart';
// import 'insurance_tpa_screen.dart';
// import 'pay_bills_screen.dart';
// import 'lab_results_screen.dart';
// import 'hospital_map_screen.dart';
// import 'feedback_help_screen.dart';
// import 'virtual_reception_screen.dart';
// import 'visitor_pass_screen.dart';
// import 'queue_status_screen.dart';
// import 'conversation_screen.dart';

enum HomeMode { menu, conversation, loading }

class HomeScreen extends StatefulWidget {
  final InteractionCoordinator coordinator;
  final List<CameraDescription> cameras;

  const HomeScreen({super.key, required this.coordinator, required this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeMode _mode = HomeMode.loading;
  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  final ScrollController _scrollController = ScrollController();
  String _selectedLanguage = "ml_IN";
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Listen for session reset to return to menu
    widget.coordinator.onNewSession = () {
      if (mounted) {
        setState(() {
          _mode = HomeMode.menu;
          _messages.clear(); // Clear messages on session reset
        });
      }
    };
  }

  Future<void> _initializeApp() async {
    try {
      widget.coordinator.setLanguage(_selectedLanguage);
      widget.coordinator.onInteractionComplete = (userInput, reply) {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              text: reply,
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isListening = false;
            _scrollToBottom();
          });
        }
      };
      widget.coordinator.onError = (error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = error;
            _mode = HomeMode.menu; // Fallback to menu on error
          });
        }
      };
      // widget.coordinator.onNavigateWithContext = (context, pageKey) {
      //   if (mounted) {
      //     switch (pageKey) {
      //       case "BOOK_APPOINTMENT":
      //       case "RESCHEDULE":
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (_) => BookAppointmentScreen(
      //                   selectedLanguage: _selectedLanguage)),
      //         );
      //         break;
      //       case "CHECK_IN":
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (_) =>
      //                   CheckInScreen(selectedLanguage: _selectedLanguage)),
      //         );
      //         break;
      //       case "PHARMACY_TOKEN":
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (_) => PharmacyTokenScreen(
      //                   selectedLanguage: _selectedLanguage)),
      //         );
      //         break;
      //       case "INSURANCE_TPA":
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (_) => InsuranceTPAScreen(
      //                   selectedLanguage: _selectedLanguage)),
      //         );
      //         break;
      //       case "PAY_BILLS":
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (_) =>
      //                   PayBillsScreen(selectedLanguage: _selectedLanguage)),
      //         );
      //         break;
      //       case "LAB_RESULTS":
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (_) =>
      //                   LabResultsScreen(selectedLanguage: _selectedLanguage)),
      //         );
      //         break;
      //       case "HOSPITAL_MAP":
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (_) =>
      //                   HospitalMapScreen(selectedLanguage: _selectedLanguage)),
      //         );
      //         break;
      //       case "FEEDBACK_HELP":
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (_) => FeedbackHelpScreen(
      //                   selectedLanguage: _selectedLanguage)),
      //         );
      //         break;
      //       case "VIRTUAL_RECEPTION":
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (_) => VirtualReceptionScreen(
      //                   selectedLanguage: _selectedLanguage)),
      //         );
      //         break;
      //       case "VISITOR_PASS":
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (_) => VisitorPassScreen(
      //                   selectedLanguage: _selectedLanguage)),
      //         );
      //         break;
      //       case "QUEUE_STATUS":
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //               builder: (_) => QueueStatusScreen(
      //                   selectedLanguage: _selectedLanguage)),
      //         );
      //         break;
      //       case "EMERGENCY":
      //         showDialog(
      //           context: context,
      //           builder: (_) => AlertDialog(
      //             title: Text(_selectedLanguage == "ml_IN"
      //                 ? "അടിയന്തരം"
      //                 : _selectedLanguage == "ta_IN"
      //                     ? "அவசரம்"
      //                     : "Emergency"),
      //             content: Text(_selectedLanguage == "ml_IN"
      //                 ? "അടിയന്തര സഹായം വിളിക്കുന്നു."
      //                 : _selectedLanguage == "ta_IN"
      //                     ? "அவசர உதவியை அழைக்கிறது."
      //                     : "Calling emergency assistance."),
      //             actions: [
      //               TextButton(
      //                 onPressed: () => Navigator.pop(context),
      //                 child: const Text("OK"),
      //               ),
      //             ],
      //           ),
      //         );
      //         break;
      //     }
      //   }
      // };
      // await widget.coordinator.initialize();

      if (widget.cameras.isNotEmpty) {
        final camera = widget.coordinator.cameraService;
        camera.onCameraImage = (image) {
          widget.coordinator.handleFaceAndInteraction(
            image,
            camera.description,
          );
        };
        await camera.initialize();
      }

      if (mounted) setState(() => _mode = HomeMode.menu);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "Initialization failed: $e";
          _mode = HomeMode.menu;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.coordinator.onInteractionComplete = null;
    widget.coordinator.onNewSession = null;
    widget.coordinator.onError = null;
    widget.coordinator.onNavigateWithContext = null;
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTileTap(String label) async {
    if (label == "How Can I Help You?" || label == "എനിക്ക് എങ്ങനെ സഹായിക്കാം?" || label == "எப்படி உதவ முடியும்?") {
      if (_messages.isEmpty) {
        _messages.add(ChatMessage(
          text: widget.coordinator.selectedLanguage == "ml_IN"
              ? "സഹായം വേണോ പറഞ്ഞോളൂ"
              : widget.coordinator.selectedLanguage == "ta_IN"
                  ? "உதவி தேவையா? சொல்லுங்கள்"
                  : "Need help? Please speak.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
      try {
        await widget.coordinator.speech.startListening(language: widget.coordinator.sttLanguage);
        setState(() => _mode = HomeMode.conversation);
      } catch (e) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Error starting voice input. Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _scrollToBottom();
        });
      }
    } else {
      setState(() {
        _messages.add(ChatMessage(
          text: label,
          isUser: true,
          timestamp: DateTime.now(),
        ));
        _messages.add(ChatMessage(
          text: "Opening ${label.split('/').firstOrNull?.trim() ?? label}...",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _mode = HomeMode.conversation;
        _scrollToBottom();
      });
      try {
        await widget.coordinator.speech.startListening(language: widget.coordinator.sttLanguage);
      } catch (e) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Failed to process request. Try again.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _scrollToBottom();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        title: const Text("Hospital Assistant", style: TextStyle(color: Colors.white)),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: widget.coordinator.faceDetection.faceFoundNotifier,
            builder: (_, value, __) {
              final found = value == true;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  found ? Icons.face_retouching_natural : Icons.face_retouching_off,
                  color: found ? Colors.greenAccent : Colors.white70,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: Colors.white,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: "ml_IN", child: Text("മലയാളം")),
                DropdownMenuItem(value: "ta_IN", child: Text("தமிழ்")),
                DropdownMenuItem(value: "en_US", child: Text("English")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                  widget.coordinator.setLanguage(_selectedLanguage);
                }
              },
            ),
          ),
        ],
      ),
      body: _mode == HomeMode.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_hasError && _errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: Colors.red.withOpacity(0.1),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: _mode == HomeMode.menu
                      ? MenuScreen(
                          onTileTap: _onTileTap,
                          coordinator: widget.coordinator,
                        )
                      : ConversationScreen(
                          coordinator: widget.coordinator,
                        ),
                ),
              ],
            ),
    );
  }
}
