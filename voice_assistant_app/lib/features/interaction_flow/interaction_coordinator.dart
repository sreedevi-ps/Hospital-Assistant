import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../face_detection/face_service.dart';
import '../speech/speech_service.dart';
import '../speech/tts_service.dart';
import '../face_detection/camera_service.dart';
import 'package:voice_assistant_app/data/services/network_service.dart';

class InteractionCoordinator {
  final FaceDetectionService faceDetection;
  final TextToSpeechService tts;
  final CameraService cameraService;
  void Function(String, String)? onInteractionComplete;
  final void Function(bool) onFacePromptToggle;
  void Function(bool)? onListeningStatusChanged;
  void Function()? onNewSession;
  void Function(String)? onError; // Removed 'final' to allow reassignment
  void Function(BuildContext, String)? onNavigateWithContext; // Ensure field is defined
  void Function(bool)? onQueryProcessing; // true = start, false = done

  late SpeechService _speech;
  String sessionId = const Uuid().v4();
  Timer? _noFaceTimer;
  Timer? _reminderTimer;
  bool _faceDetectedBefore = false; // Tracks if a session has started (sticky until reset)
  bool _currentFaceDetected = false; // Tracks real-time face detection state
  String _selectedLanguage = "ml_IN";

  VoidCallback? _ttsListener;

  InteractionCoordinator({
    required this.faceDetection,
    required this.tts,
    required this.cameraService,
    required this.onFacePromptToggle,
    this.onInteractionComplete,
    this.onListeningStatusChanged,
    this.onNewSession,
    this.onError,
    String initialLanguage = "ml_IN",
  }) {
    _selectedLanguage = initialLanguage;
    _speech = SpeechService(
      onTextRecognized: _handleUserQuery,
      onListeningStatusChanged: (listening) {
        if (listening && tts.isSpeaking) {
          _speech.stopListening();
          onListeningStatusChanged?.call(false);
        } else {
          onListeningStatusChanged?.call(listening);
        }
      },
    );
  }

  SpeechService get speech => _speech;

  String get selectedLanguage => _selectedLanguage;

  Future<void> initialize() async {
    try {
      await _speech.initialize();
      await tts.setLanguage(ttsLanguage);

      // Detach any previous listener before adding a new one
      if (_ttsListener != null) {
        tts.isSpeakingNotifier.removeListener(_ttsListener!);
      }

      _ttsListener = () {
        if (tts.isSpeaking && _speech.isListening) {
          _speech.stopListening();
          onListeningStatusChanged?.call(false);
        }
      };

      tts.isSpeakingNotifier.addListener(_ttsListener!);
      print("✅ InteractionCoordinator initialized safely");

      // Start attraction reminder loop initially (kiosk idle state)
      _startReminderLoop();
    } catch (e) {
      onError?.call("Error initializing coordinator: $e");
      print("⚠ Error initializing coordinator: $e");
    }
  }

  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
    if (_speech.isInitialized) {
      _speech.stopListening();
      _speech.dispose();
    }
    _speech = SpeechService(
      onTextRecognized: _handleUserQuery,
      onListeningStatusChanged: (listening) {
        if (listening && tts.isSpeaking) {
          _speech.stopListening();
          return;
        }
        onListeningStatusChanged?.call(listening);
      },
    );
    try {
      _speech.initialize();
      // Map ta_IN to ta-IN for TTS
      tts.setLanguage(ttsLanguage);
    } catch (e) {
      print("⚠ Error setting language: $e");
      onError?.call("Failed to set language: $e");
    }
  }

  Future<void> handleFaceAndInteraction(CameraImage image, CameraDescription description) async {
    final bool faceDetected = await faceDetection.detect(image, description);
    _currentFaceDetected = faceDetected; // Update real-time state

    if (faceDetected) {
      onFacePromptToggle(true);

      if (!_faceDetectedBefore) {
        _faceDetectedBefore = true;
        await _startSession();
      }

      _noFaceTimer?.cancel();
      _noFaceTimer = Timer(const Duration(seconds: 30), () async {
        await _resetSession("😴 No face detected for 30 seconds – resetting session.");
      });

      // Cancel reminder when face is detected (no attraction prompts during interaction)
      _reminderTimer?.cancel();
    } else {
      onFacePromptToggle(false);

      // Ensure reminder loop is active when no face is detected (for attraction)
      _startReminderLoop();
    }
  }

  Future<void> _startSession() async {
    print("🎉 Starting new session: $sessionId");
    onNewSession?.call();

    await tts.speak(_getWelcomeMessage());

    _startReminderLoop(); // Re-start reminder in case needed post-session, but it will be canceled if face still present

    if (!tts.isSpeaking) {
      try {
        await _speech.startListening(language: sttLanguage);
      } catch (e) {
        print("Failed to start listening in _startSession: $e");
        onError?.call("Speech start failed: $e");
      }
    }
  }

  Future<void> _handleUserQuery(String userInput) async {
    print("🗣 User query: $userInput");

    // Stop listening immediately
    _speech.stopListening();
    onListeningStatusChanged?.call(false);

    // Notify UI: query started
    onQueryProcessing?.call(true);

    try {
      final networkService = NetworkService();
      final response = await networkService.getResponseKey(userInput, sessionId);

      final key = response["key"];
      final backendAnswer = response["answer"];
      final reply = (backendAnswer != null && backendAnswer.trim().isNotEmpty)
          ? backendAnswer
          : _mapKeyToResponse(key);

      // Notify UI: assistant reply received → stop loading
      onQueryProcessing?.call(false);

      if (onInteractionComplete != null) {
        onInteractionComplete!(userInput, reply);
      }

      await tts.speak(reply);

      _startReminderLoop(); // Prepare for potential idle after response

      if (_faceDetectedBefore && !tts.isSpeaking) {
        try {
          await _speech.startListening(language: sttLanguage);
        } catch (e) {
          print("Failed to start listening in _handleUserQuery: $e");
          onError?.call("Speech start failed: $e");
        }
      }
    } catch (e) {
      onQueryProcessing?.call(false);
      print("⚠ Error handling user query: $e");
      final errorMessage = _mapKeyToResponse("error");
      onError?.call(errorMessage);
    }
  }

  Future<void> handleUserQuery(String userInput) async {
    await _handleUserQuery(userInput);
  }

  void _startReminderLoop() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(seconds: 40), (timer) async {
      if (!_currentFaceDetected && !tts.isSpeaking && !_speech.isListening) {
        print("🔔 Attraction reminder: No face detected...");
        await tts.speak(_getWelcomeMessage());
      }
    });
  }

  Future<void> _resetSession(String reason) async {
    print(reason);
    _noFaceTimer?.cancel();
    _reminderTimer?.cancel();
    _faceDetectedBefore = false;
    _currentFaceDetected = false;
    _speech.stopListening();

    try {
      final networkService = NetworkService();
      await networkService.resetSession(sessionId);
    } catch (e) {
      print("⚠ Error resetting session: $e");
      onError?.call("Error resetting session: $e");
    }

    sessionId = const Uuid().v4();
    onNewSession?.call();
    print("🔄 New session started: $sessionId");

    // Re-start attraction mode after reset
    _startReminderLoop();
  }

  String _getWelcomeMessage() {
    switch (_selectedLanguage) {
      case "ml_IN":
        return "സഹായം വേണോ പറഞ്ഞോളൂ";
      case "ta_IN":
        return "உதவி தேவையா? சொல்லுங்கள்";
      case "en_US":
      default:
        return "Need help? Please speak.";
    }
  }

  String get welcomeMessage => _getWelcomeMessage();

  // Assuming these are defined elsewhere in your class (added stubs if missing)
  String get ttsLanguage {
    switch (_selectedLanguage) {
      case "ml_IN":
        return "ml-IN";
      case "ta_IN":
        return "ta-IN";
      case "en_US":
      default:
        return "en-US";
    }
  }

  String get sttLanguage {
    switch (_selectedLanguage) {
      case "ml_IN":
        return "ml-IN";
      case "ta_IN":
        return "ta-IN";
      case "en_US":
      default:
        return "en-US";
    }
  }
 String _mapKeyToResponse(String? key) {
    final responseMap = {
      "bt_lab_location": {
        "ml_IN": "ബ്ലഡ് ടെസ്റ്റ് ലാബ് ആശുപത്രിയുടെ രണ്ടാം നിലയിൽ ഇടത് വശത്താണ്.",
        "ta_IN": "ரத்த பரிசோதனை ஆய்வகம் மருத்துவமனையின் இரண்டாவது மாடியில், இடது பக்கத்தில் உள்ளது.",
        "en_US": "The blood test lab is on the second floor, left wing."
      },
      "ad_pharmacy": {
        "ml_IN": "വയസ്കർക്കുള്ള ഫാർമസി പ്രധാന ബ്ലോക്കിന്റെ നിലയിലായി റിസെപ്ഷൻ സമീപത്താണ്.",
        "ta_IN": "பெரியவர்களுக்கான மருந்தகம் முதன்மை பிளாக்கில், வரவேற்பறைக்கு அருகில் உள்ளது.",
        "en_US": "The adult pharmacy is in the main block, near the reception."
      },
      "kids_pharmacy": {
        "ml_IN": "കുട്ടികളുടെ ഫാർമസി കുട്ടികളുടെ വിഭാഗത്തിനടുത്തായി കളിപ്പാട്ട കോർണറിനു സമീപമാണ്.",
        "ta_IN": "குழந்தைகளுக்கான மருந்தகம் குழந்தைகள் பிரிவுக்கு அருகில், பொம்மை மூலையில் உள்ளது.",
        "en_US": "The kids' pharmacy is near the children's section, close to the toy corner."
      },
      "emergency_room": {
        "ml_IN": "എമർജൻസി വിഭാഗം ഗ്രൗണ്ട് നിലയിൽ, ആംബുലൻസ് പ്രവേശനവഴി സമീപമാണ്.",
        "ta_IN": "அவசர பிரிவு தரைதளத்தில், ஆம்புலன்ஸ் நுழைவாயிலுக்கு அருகில் உள்ளது.",
        "en_US": "The emergency room is on the ground floor, near the ambulance entry."
      },
      "canteen_location": {
        "ml_IN": "കാന്റീൻ ഗ്രൗണ്ട് നിലയിൽ, പാർക്കിംഗ് ഏരിയയോട് ചേർന്നാണ്.",
        "ta_IN": "கேன்டீன் தரைதளத்தில், பார்க்கிங் பகுதிக்கு அருகில் உள்ளது.",
        "en_US": "The canteen is on the ground floor, adjacent to the parking area."
      },
      "ground_flr": {
        "ml_IN": "ഇത് ആശുപത്രിയുടെ ഗ്രൗണ്ട് നിലയിലാണ്. മുഖ്യ പ്രവേശനം ഈ നിലയിലായിരിക്കും.",
        "ta_IN": "இது மருத்துவமனையின் தரைதளத்தில் உள்ளது. முதன்மை நுழைவாயில் இந்த தளத்தில் உள்ளது.",
        "en_US": "This is the ground floor of the hospital. The main entrance is on this floor."
      },
      "first_flr": {
        "ml_IN": "ഇത് ഒന്നാം നിലയിലാണ്. ലിഫ്റ്റ് അല്ലെങ്കിൽ കയറ്റുമുറി ഉപയോഗിച്ച് ഇവിടെ എത്താം.",
        "ta_IN": "இது முதல் தளத்தில் உள்ளது. லிஃப்ட் அல்லது படிக்கட்டுகள் மூலம் இங்கு வரலாம்.",
        "en_US": "This is the first floor. You can reach it using the lift or stairs."
      },
      "second_flr": {
        "ml_IN": "ഇത് രണ്ടാം നിലയിലാണ്. പ്രധാന ലിഫ്റ്റിന്റെ ഇടത് വശത്താണ് പ്രവേശനം.",
        "ta_IN": "இது இரண்டாவது தளத்தில் உள்ளது. முதன்மை லிஃப்ட்டின் இடது பக்கத்தில் நுழைவு உள்ளது.",
        "en_US": "This is the second floor. The entrance is to the left of the main lift."
      },
      "main_block": {
        "ml_IN": "പ്രധാന ബ്ലോക്ക് ആശുപത്രിയുടെ മുൻവശത്തായി മുഖ്യ കവാടത്തിന് നേരെ എത്തിയാൽ കാണാം.",
        "ta_IN": "முதன்மை பிளாக் மருத்துவமனையின் முன்பகுதியில், முதன்மை நுழைவாயிலுக்கு நேராக உள்ளது.",
        "en_US": "The main block is at the front of the hospital, directly opposite the main entrance."
      },
      "near_reception": {
        "ml_IN": "റിസെപ്ഷൻ ആശുപത്രിയുടെ മുഖ്യ പ്രവേശനത്തിൽനിന്ന് കയറുമ്പോൾ നേരെ നടന്ന് സമീപവശത്താണ്.",
        "ta_IN": "வரவேற்பறை மருத்துவமனையின் முதன்மை நுழைவாயிலில் இருந்து நேராக சென்று அருகில் உள்ளது.",
        "en_US": "The reception is near the main entrance, straight ahead as you enter."
      },
      "toy_corner": {
        "ml_IN": "കളിപ്പാട്ട കോർണർ കുട്ടികളുടെ വിഭാഗത്തിനകത്തായി, കളിസ്ഥലത്തിനു സമീപമാണ്.",
        "ta_IN": "பொம்மை மூலை குழந்தைகள் பிரிவில், விளையாட்டு இடத்திற்கு அருகில் உள்ளது.",
        "en_US": "The toy corner is inside the children's section, near the play area."
      },
      "parking_area": {
        "ml_IN": "പാർക്കിംഗ് ഏരിയ ആശുപത്രിയുടെ പുറകുവശത്തായി, കിഴക്ക് കവാടം വഴി ഇടത് തിരിഞ്ഞാൽ കണ്ടെത്താം.",
        "ta_IN": "பார்க்கிங் பகுதி மருத்துவமனையின் பின்புறத்தில், கிழக்கு நுழைவாயில் வழியாக இடதுபுறம் திரும்பினால் காணலாம்.",
        "en_US": "The parking area is at the back of the hospital, accessible by turning left from the east entrance."
      },
      "ambulance_entry": {
        "ml_IN": "ആംബുലൻസ് പ്രവേശനം ആശുപത്രിയുടെ വലത് വശത്തായി, എമർജൻസി വിഭാഗത്തിലേക്ക് നേരിട്ട് പ്രവേശിക്കാൻ ഒരുക്കിയിട്ടുള്ള പ്രവേശന മാർഗമാണ്.",
        "ta_IN": "ஆம்புலன்ஸ் நுழைவு மருத்துவமனையின் வலது பக்கத்தில், அவசர பிரிவுக்கு நேரடியாக செல்ல ஏற்பாடு செய்யப்பட்டுள்ளது.",
        "en_US": "The ambulance entry is on the right side of the hospital, set up for direct access to the emergency department."
      },
      "left_wing": {
        "ml_IN": "ഇത് ആശുപത്രിയുടെ ഇടത് ഭാഗത്ത്, ലിഫ്റ്റിനുശേഷമുള്ള വഴിയിലൂടെ നീങ്ങുമ്പോൾ കാണാം.",
        "ta_IN": "இது மருத்துவமனையின் இடது பகுதியில், லிஃப்ட்டிற்கு பிறகு செல்லும் பாதையில் காணலாம்.",
        "en_US": "This is in the left wing of the hospital, visible along the path after the lift."
      },
      "children_section": {
        "ml_IN": "കുട്ടികളുടെ വിഭാഗം കളിപ്പാട്ട കോർണറിനും കുട്ടികളുടെ ഫാർമസിക്കും സമീപമാണ്.",
        "ta_IN": "குழந்தைகள் பிரிவு பொம்மை மூலை மற்றும் குழந்தைகள் மருந்தகத்திற்கு அருகில் உள்ளது.",
        "en_US": "The children's section is near the toy corner and kids' pharmacy."
      },
      "main_lift": {
        "ml_IN": "പ്രധാന ലിഫ്റ്റ് ആശുപത്രിയുടെ മുഖ്യ കവാടത്തിന് സമീപം, റിസെപ്ഷന് അടുത്താണ്.",
        "ta_IN": "முதன்மை லிஃப்ட் மருத்துவமனையின் முதன்மை நுழைவாயிலுக்கு அருகில், வரவேற்பறைக்கு அருகில் உள்ளது.",
        "en_US": "The main lift is near the hospital’s main entrance, close to the reception."
      },
      "radiology": {
        "ml_IN": "റേഡിയോളജി വിഭാഗം ഒന്നാം നിലയിൽ, ലിഫ്റ്റ് ഉപയോഗിച്ച് എത്താം. എക്‌സ്റേ, എംആർഐ, സിടി സ്കാൻ എന്നിവ ഇവിടെ ചെയ്യപ്പെടുന്നു.",
        "ta_IN": "ரேடியாலஜி பிரிவு முதல் தளத்தில் உள்ளது. எக்ஸ்ரே, எம்ஆர்ஐ, சிடி ஸ்கேன் இங்கு செய்யப்படுகிறது.",
        "en_US": "The radiology department is on the first floor, accessible via lift. X-rays, MRIs, and CT scans are done here."
      },
      "opd": {
        "ml_IN": "ഔട്ട്പേഷ്യന്റ് വിഭാഗം (OPD) മുഖ്യ പ്രവേശനത്തിൽനിന്ന് നേരെ നടന്ന് ഇടത്തേക്ക് തിരിഞ്ഞാൽ കാണാം.",
        "ta_IN": "வெளிநோயாளிகள் பிரிவு (OPD) முதன்மை நுழைவாயிலில் இருந்து நேராக சென்று இடதுபுறம் திரும்பினால் காணலாம்.",
        "en_US": "The outpatient department (OPD) is straight from the main entrance, turning left."
      },
      "billing_counter": {
        "ml_IN": "ബില്ലിംഗ് കൗണ്ടർ റിസെപ്ഷനിന് അടുത്തായി, പ്രവേശന കവാടം കടന്നതിന്റെ വലത് വശത്താണ്.",
        "ta_IN": "பில்லிங் கவுண்டர் முதல் தளத்தில் உள்ளது.",
        "en_US": "The billing counter is on the first floor."
      },
      "icu": {
        "ml_IN": "ഐസിയു (ICU) പ്രധാന ബ്ലോക്കിന്റെ രണ്ടാം നിലയിലാണ്. പ്രവേശനം നിയന്ത്രിതമാണ്.",
        "ta_IN": "ஐசியு முதன்மை பிளாக்கின் இரண்டாவது தளத்தில் உள்ளது. நுழைவு கட்டுப்படுத்தப்பட்டுள்ளது.",
        "en_US": "The ICU is on the second floor of the main block. Access is restricted."
      },
      "laboratory": {
        "ml_IN": "ലബോറട്ടറി വിഭാഗം ബ്ളഡ് ടെസ്റ്റ് ലാബിനു സമീപമാണ്. വിവിധ മെഡിക്കൽ ടെസ്റ്റുകൾ ഇവിടെ നടത്തുന്നു.",
        "ta_IN": "ஆய்வகம் ரத்த பரிசோதனை ஆய்வகத்திற்கு அருகில் உள்ளது. பல மருத்துவ பரிசோதனைகள் இங்கு நடைபெறுகின்றன.",
        "en_US": "The laboratory is near the blood test lab. Various medical tests are conducted here."
      },
      "waiting_area": {
        "ml_IN": "കാത്തിരിപ്പ് ഏരിയ OPD വിഭാഗത്തിനടുത്തായി, രോഗികൾക്കും ബന്ധുക്കൾക്കും സുഖവാസം ഒരുക്കിയിട്ടുണ്ട്.",
        "ta_IN": "காத்திருப்பு பகுதி OPD பிரிவுக்கு அருகில் உள்ளது, நோயாளிகள் மற்றும் உறவினர்களுக்கு வசதியாக அமைக்கப்பட்டுள்ளது.",
        "en_US": "The waiting area is near the OPD, equipped for patients and relatives."
      },
      "physiotherapy": {
        "ml_IN": "ഫിസിയോതെറാപ്പി സെക്ഷൻ ആദ്യ നിലയിൽ, പാര്കിംഗ് ഏരിയയുടെ പിന്നിൽ നിന്നും പ്രവേശിക്കാം.",
        "ta_IN": "பிசியோதெரபி பிரிவு முதல் தளத்தில், பார்க்கிங் பகுதியின் பின்புறத்தில் இருந்து நுழையலாம்.",
        "en_US": "The physiotherapy section is on the first floor, accessible from behind the parking area."
      },
      "admin_office": {
        "ml_IN": "അഡ്മിനിസ്ട്രേറ്റീവ് ഓഫീസ് മുഖ്യ ലിഫ്റ്റിനടുത്തായി, സ്റ്റാഫ് മാറ്റേഴ്സ് ഇവിടെ കൈകാര്യം ചെയ്യപ്പെടുന്നു.",
        "ta_IN": "நிர்வாக அலுவலகம் முதன்மை லிஃப்ட்டுக்கு அருகில் உள்ளது, பணியாளர் விவகாரங்கள் இங்கு கையாளப்படுகின்றன.",
        "en_US": "The administrative office is near the main lift, handling staff matters."
      },
      "nursing_station": {
        "ml_IN": "നേഴ്സിംഗ് സ്റ്റേഷൻ ഓരോ നിലയിലുമുള്ള വിഭാഗങ്ങൾക്കടുത്തായി, അടിയന്തിര സഹായത്തിനായി ഇവിടെ സമീപിക്കാം.",
        "ta_IN": "நர்ஸிங் நிலையம் ஒவ்வொரு தளத்திலும் உள்ள பிரிவுகளுக்கு அருகில் உள்ளது, அவசர உதவிக்கு இங்கு அணுகலாம்.",
        "en_US": "The nursing station is near each floor’s departments, approachable for emergency assistance."
      },
      "book_token_doctor": {
  "ml_IN": "ടോക്കൺ ബുക്ക് ചെയ്യാൻ, മെനു സ്ക്രീനിൽ നിന്ന് 'അപോയിന്റ്മെന്റ് / പുനഃക്രമീകരണം' തിരഞ്ഞെടുക്കുക.",
  "ta_IN": "டோக்கன் பதிவு செய்ய, மெனு திரையில் 'நியமனம் / மீண்டும் திட்டமிடல்' தேர்வை தெரிவுசெய்க.",
  "en_US": "To book a token, please choose 'Appointment / Reschedule' from the menu screen."
},

      "need_token_doctor": {
        "ml_IN": "താങ്കളുടെ ഡോക്ടർ അപ്പോയിന്റ്മെന്റ് രജിസ്റ്റർ ചെയ്തു. ദയവായി രണ്ടാം നിലയിലെ OPD-യിലേക്ക് പോകുക.",
        "ta_IN": "டாக்டரிடம் குறியீடு பெற வேண்டும்.",
        "en_US": "booked a token with Dr. Anil Kumar. Please proceed to the General Medicine OPD waiting area on the second floor. Your token number is 15"
      },
      "ml_token_request": {
        "ml_IN": "താങ്കളുടെ ഡോക്ടർ അപ്പോയിന്റ്മെന്റ് രജിസ്റ്റർ ചെയ്തു. ദയവായി രണ്ടാം നിലയിലെ OPD-യിലേക്ക് പോകുക.",
        "ta_IN": "இன்று உங்களுக்கு குறியீடு வழங்கப்பட்டுள்ளது.",
        "en_US": "booked a token with Dr. Anil Kumar. Please proceed to the General Medicine OPD waiting area on the second floor. Your token number is 15."
      },
      "ta_token_request": {
        "ml_IN": "താങ്കളുടെ ഡോക്ടർ അപ്പോയിന്റ്മെന്റ് രജിസ്റ്റർ ചെയ്തു. ദയവായി രണ്ടാ�ം നിലയിലെ OPD-യിലേക്ക് പോകുക.",
        "ta_IN": "இன்று உங்களுக்கு குறியீடு வழங்கப்பட்டுள்ளது.",
        "en_US": "booked a token with Dr. Anil Kumar. Please proceed to the General Medicine OPD waiting area on the second floor. Your token number is 15"
      },
      "today_token_number": {
        "ml_IN": "താങ്കളുടെ ടോക്കൺ നമ്പർ 27 ആണ്. താങ്കളുടെ മുന്നിൽ 3 രോഗികൾ ഉണ്ട്. ദയവായി കൺസൾട്ടേഷൻ റൂമിനടുത്ത് കാത്തിരിക്കുക.",
        "ta_IN": "உங்கள் குறியீட்டு எண் 27 ஆகும். உங்கள் முன்னிலையில் 3 நோயாளிகள் உள்ளனர். தயவுசெய்து ஆலோசனை அறைக்கு அருகே காத்திருங்கள்.",
        "en_US": "Your token number is 27. There are 3 patients ahead of you. Please wait near the consultation room."
      },
      "reschedule_appointment": {
        "ml_IN": "ശരി. താങ്കളുടെ അപ്പോയിന്റ്മെന്റ് നാളെ രാവിലെ 10:30-ന് ഡോ. അനിൽ കുമാറിനൊപ്പം ജനറൽ മെഡിസിനിൽ പുനഃക്രമീകരിച്ചു.",
        "ta_IN": "சரி. உங்கள் சந்திப்பை நாளை காலை 10:30 மணிக்கு டாக்டர் அனில் குமாருடன் பொது மருத்துவத்தில் மறுசீரமைத்துள்ளேன்.",
        "en_US": "Your appointment has been rescheduled for 10:30 AM on Monday. Dr. Anil Kumar from General Medicine."
      },
      "available_doctors_now": {
        "ml_IN": "നിലവിൽ ലഭ്യമായ ഡോക്ടർമാർ: ഡോ. അനിൽ കുമാർ (ജനറൽ മെഡിസിൻ), ഡോ. പ്രിയ മേനോൻ (പീഡിയാട്രിക്സ്), ഡോ. സുരേഷ് നായർ (കാർഡിയോളജി), ഡോ. ലക്ഷ്മി ദേവി (ഡെർമറ്റോളജി).",
        "ta_IN": "இப்போது கிடைக்கும் டாக்டர்கள்: டாக்டர் அனில் குமார் (பொது மருத்துவம்), டாக்டர் பிரியா மேனன் (குழந்தைகள் மருத்துவம்), டாக்டர் சுரேஷ் நாயர் (இதயவியல்), டாக்டர் லக்ஷ்மி தேவீ (தோல் நோய்கள்).",
        "en_US": "Available Doctors: Dr. Anil Kumar (General Medicine), Dr. Priy Menon (Pediatrics), Dr. Suresh Nair (Cardiology), Dr. Lakshmi Devi (Dermatology)."
      },
      "availability_suresh_nair": {
        "ml_IN": "അതെ, ഡോ. സുരേഷ് നായർ ഇന്ന് 11:00 AM മുതൽ 2:00 PM വരെ കാർഡിയോളജി OPD-യിൽ, മൂന്നാം നിലയിൽ ലഭ്യമാണ്.",
        "ta_IN": "டாக்டர் சுரேஷ் நாயர் இன்று கிடைக்கிறார்.",
        "en_US": "Dr. Suresh Nair is available today."
      },
      "suggest_doctor_stomach_pain": {
        "ml_IN": "വയറുമായി ബന്ധപ്പെട്ട പ്രശ്നങ്ങൾക്ക്, താങ്കൾക്ക് ഞങ്ങളുടെ ഗ്യാസ്ട്രോഎന്ററോളജിസ്റ്റ് ഡോ. മീര കൃഷ്ണനെ കൺസൾട്ട് ചെയ്യാം. അവരുടെ OPD രണ്ടാം നിലയിൽ, റൂം 205-ലാണ്.",
        "ta_IN": "வயிற்று வலிக்காக குடல்நோய் நிபுணரை பார்க்கவும்.",
        "en_US": "For any questions about your stomach pain, please consult Dr. Meera Krishnan. Dr. Meera Krishnan is available at OPD, Room 205."
      },
      "emergency_duty_doctor": {
        "ml_IN": "ഞങ്ങളുടെ എമർജൻസി ഡ്യൂട്ടി ഡോക്ടർ ഡോ. അജിത്താണ്. ഗ്രൗണ്ട് ഫ്ലോറിലെ എമർജൻസി വിഭാഗത്തിൽ, 24/7 തുറന്നിരിക്കുന്നു.",
        "ta_IN": "அவசர சேவைக்கான டாக்டர் உடனே கிடைக்கிறார்.",
        "en_US": "Dr. Ajitta is your Emergency Duty Doctor. Dr. Ajitta is available in the Emergency Department 24/7."
      },
      "reach_priya_menon_room": {
        "ml_IN": "ഡോ. പ്രിയ മേനോന്റെ പീഡിയാട്രിക്സ് OPD രണ്ടാം നിലയിൽ, റൂം 212-ലാണ്. ദയവായി താങ്കളുടെ വലതുവശത്തുള്ള ലിഫ്റ്റ് എടുക്കുക.",
        "ta_IN": "டாக்டர் பிரியா மேனனின் அறை மூன்றாம் தளத்தில் உள்ளது.",
        "en_US": "Dr. Priya Menon's Pediatrics OPD is on the third floor, Room 212. Please approach the nearest lift."
      },
      "where_is_laboratory": {
        "ml_IN": "ലബോറട്ടറി ഗ്രൗണ്ട് ഫ്ലോറിൽ, ഫാർമസിക്ക് സമീപമാണ്. ദയവായി ‘ലാബ്’ എന്ന് അടയാളപ്പെടുത്തിയ നീല ചിഹ്നങ്ങൾ പിന്തുടരുക.",
        "ta_IN": "ஆய்வகம் இரண்டாம் தளத்தில் உள்ளது.",
        "en_US": "The laboratory is on the second floor.Follow the signs marked 'Lab'."
      },
      "guide_to_ot": {
        "ml_IN": "ഓപ്പറേഷൻ തിയേറ്റർ കോംപ്ലക്സ് നാലാം നിലയിലാണ്. ഹെൽപ്പ് ഡെസ്കിനടുത്തുള്ള ലിഫ്റ്റ് എടുക്കുക, ‘OT’ എന്ന് അടയാളപ്പെടുത്തിയ ചിഹ്നങ്ങൾ പിന്തുടരുക.",
        "ta_IN": "அறுவை சிகிச்சை அறை இங்கே உள்ளது.",
        "en_US": "The operating theater is on the eleventh floor. Please approach the nearest lift, and follow the signs marked 'OT'."
      },
      "ta_how_to_pharmacy": {
        "ml_IN": "ആശുപത്രി ഫാർമസി ഗ്രൗണ്ട് ഫ്ലോറിൽ, മുഖ്യ കവാടത്തിനടുത്താണ്.",
        "ta_IN": "மருந்தகம் தரை தளத்தில் உள்ளது.",
        "en_US": "The pharmacy is on the ground floor."
      },
      "reach_lab": {
        "ml_IN": "ദയവായി ഗ്രൗണ്ട് ഫ്ലോറിൽ ‘ലാബ്’ എന്ന് അടയാളപ്പെടുത്തിയ ചിഹ്നങ്ങൾ പിന്തുടരുക.",
        "ta_IN": "ஆய்வகத்தை அடைய உதவுகிறேன்.",
        "en_US": "Follow the signs marked 'Lab'."
      },
      "where_is_pharmacy": {
        "ml_IN": "ആശുപത്രി ഫാർമസി ഗ്രൗണ്ട് ഫ്ലോറിൽ, മുഖ്യ കവാടത്തിനടുത്താണ്. ഇത് ദിവസവും രാവിലെ 8 മുതൽ രാത്രി 10 വരെ തുറന്നിരിക്കും.",
        "ta_IN": "மருந்தகம் தரை தளத்தில் உள்ளது.",
        "en_US": "The pharmacy is on the ground floor."
      },
      "availability_paracetamol": {
        "ml_IN": "അതെ, പാരസെറ്റമോൾ ഞങ്ങളുടെ ഫാർമസിയിൽ ലഭ്യമാണ്. ദയവായി കൗണ്ടറിൽ താങ്കളുടെ കുറിപ്പടി കാണിക്കുക.",
        "ta_IN": "பராசிட்டமால் மருந்தகம் கிடைக்கிறது.",
        "en_US": "Paracetamol is available in the pharmacy.please show your prescription at the counter."
      },
      "deliver_medicines_rooms": {
        "ml_IN": "അതെ, അഡ്മിറ്റ് ചെയ്ത രോഗികളുടെ മുറികളിലേക്ക് മരുന്നുകൾ ഡെലിവർ ചെയ്യുന്നു. ദയവായി ഫാർമസി ജീവനക്കാർക്ക് താങ്കളുടെ റൂം നമ്പർ നൽകുക.",
        "ta_IN": "மருந்துகள் உங்கள் அறைக்கு கொண்டு வரப்படும்.",
        "en_US": "Medicines will be delivered to your room.please provide your room number to the pharmacy staff."
      },
      "blood_test_results": {
        "ml_IN": "അതെ, താങ്കളുടെ ബ്ലഡ് ടെസ്റ്റ് ഫലങ്ങൾ തയ്യാറാണ്. ഗ്രൗണ്ട് ഫ്ലോറിലെ ലാബ് റിസെപ്ഷനിൽ നിന്ന് റിപ്പോർട്ട് ശേഖരിക്കാം, അല്ലെങ്കിൽ ആശുപത്രി മൊബൈൽ ആപ്പിൽ കാണാം.",
        "ta_IN": "உங்கள் இரத்த பரிசோதனை முடிவுகள் தயாராக உள்ளன.",
        "en_US": "Your blood test results are ready.collect the report from the lab reception on the ground floor, or view it on the hospital mobile app."
      },
      "where_xray": {
        "ml_IN": "റേഡിയോളജി വിഭാഗം ഒന്നാം നിലയിൽ, റൂം 105-ലാണ്. ദയവായി താങ്കളുടെ ടോക്കൺ സ്ലിപ്പ് കൊണ്ടുപോകുക.",
        "ta_IN": "எக்ஸ்-ரே அறை முதல் தளத்தில் உள்ளது.",
        "en_US": "The X-ray room is on the first floor, Room 105. Please bring your token slip."
      },
      "mri_results_ready": {
        "ml_IN": "MRI സ്കാൻ റിപ്പോർട്ടുകൾ 24 മണിക്കൂറിനുള്ളിൽ ലഭ്യമാകും. ഫലങ്ങൾ അപ്‌ലോഡ് ചെയ്തുകഴിഞ്ഞാൽ താങ്കൾക്ക് ഒരു SMS ലഭിക്കും.",
        "ta_IN": "எம்.ஆர்.ஐ. பரிசோதனை முடிவுகள் நாளைக்குள் கிடைக்கும்.",
        "en_US": "MRI reports will be available within 24 hours. You will receive an SMS once the reports are uploaded."
      },
      "operation_time": {
        "ml_IN": "താങ്കളുടെ ശസ്ത്രക്രിയ നാളെ രാവിലെ 9:00-ന് OT-2-ൽ, നാലാം നിലയിൽ നടക്കും. ദയവായി രാവിലെ 7:00-ന് അഡ്മിഷൻ ഡെസ്കിൽ റിപ്പോർട്ട് ചെയ്യുക.",
        "ta_IN": "அறுவை சிகிச்சை காலை 10 மணிக்கு திட்டமிடப்பட்டுள்ளது.",
        "en_US": "The operation will start at 9:00 AM on the day of your surgery. Please arrive at the admission desk by 7:00 AM."
      },
      "family_updates_during_surgery": {
        "ml_IN": "അതെ, താങ്കളുടെ കുടുംബം നാലാം നിലയിലെ സർജിക്കൽ വെയിറ്റിംഗ് ഹാളിൽ കാത്തിരിക്കാം. ഓരോ 30 മിനിറ്റിലും അപ്ഡേറ്റുകൾ നൽകും.",
        "ta_IN": "சிகிச்சை நடக்கும் போது குடும்பத்தினருக்கு புதுப்பிப்பு வழங்கப்படும்.",
        "en_US": "Updates will be provided to your family every 30 minutes in the surgical waiting hall on the fourth floor."
      },
      "where_wait_before_ot": {
        "ml_IN": "ദയവായി നാലാം നിലയിലെ പ്രീ-ഓപ്പറേറ്റീവ് വെയിറ്റിംഗ് റൂമിൽ കാത്തിരിക്കുക. സമയമാകുമ്പോൾ ഒരു നഴ്സ് താങ്കളെ വിളിക്കും.",
        "ta_IN": "அறுவை சிகிச்சைக்கு முன் காத்திருக்கும் பகுதி இரண்டாம் தளத்தில் உள்ளது.",
        "en_US": "The operation will start at 9:00 AM on the day of your surgery. Please arrive at the admission desk by 7:00 AM."
      },
      "where_billing_counter": {
        "ml_IN": "ബില്ലിംഗ് കൗണ്ടർ ഗ്രൗണ്ട് ഫ്ലോറിൽ, റിസെപ്ഷന്റെ എതിർവശത്താണ്. പ്രവർത്തന സമയം രാവിലെ 8 മുതൽ രാത്രി 8 വരെ.",
        "ta_IN": "பில்லிங் கவுண்டர் முதல் தளத்தில் உள்ளது.",
        "en_US": "The billing counter is on the first floor."
      },
      "accept_upi": {
        "ml_IN": "അതെ, ഞങ്ങൾ UPI, ഡെബിറ്റ്/ക്രെഡിറ്റ് കാർഡുകൾ, ക്യാഷ് പേയ്മെന്റുകൾ എന്നിവ സ്വീകരിക്കുന്നു.",
        "ta_IN": "இங்கே UPI கட்டணங்கள் ஏற்கப்படும்.",
        "en_US": "We accept UPI payments here."
      },
      "insurance_accepted": {
        "ml_IN": "അതെ, ഞങ്ങൾ സ്റ്റാർ ഹെൽത്ത്, ICICI ലോംബാർഡ്, ഓറിയന്റൽ ഇൻഷുറൻസ് തുടങ്ങിയ പ്രധാന ഇൻഷുറൻസ് ദാതാക്കളെ സ്വീകരിക്കുന്നു. വിശദാംശങ്ങൾക്ക് ബില്ലിംഗ് കൗണ്ടറിൽ പരിശോധിക്കുക.",
        "ta_IN": "உங்கள் காப்பீடு ஏற்றுக்கொள்ளப்படுகிறது.",
        "en_US": "yes,we accept star health,icici lombard,oriental insurance and other major insurance providers.please check with the billing counter for details."
      },
      "where_wheelchair": {
        "ml_IN": "വീൽചെയറുകൾ ഗ്രൗണ്ട് ഫ്ലോറിലെ എമർജൻസി റൂമിനടുത്ത് ലഭ്യമാണ്. ഞങ്ങളുടെ ജീവനക്കാർ താങ്കളെ സഹായിക്കും.",
        "ta_IN": "சக்கர நாற்காலிகள் நுழைவாயிலில் கிடைக்கின்றன.",
        "en_US": "The wheelchair is located on the first floor. Our staff will help you."
      },
      "where_canteen": {
        "ml_IN": "ആശുപത്രി കാന്റീൻ ഗ്രൗണ്ട് ഫ്ലോറിൽ, മെയിൻ ബ്ലോക്കിന്റെ പിന്നിലാണ്. ഇത് രാവിലെ 7 മുതൽ രാത്രി 9 വരെ തുറന്നിരിക്കും.",
        "ta_IN": "கேன்டீன் மூன்றாம் தளத்தில் உள்ளது.",
        "en_US": "The canteen is on the ground floor.it is open from 7 AM to 9 PM."
      },
      "visiting_hours": {
        "ml_IN": "സന്ദർശന സമയം ജനറൽ വാർഡുകൾക്ക് വൈകുന്നേരം 4 മുതൽ 6 വരെയും, ICU-കൾക്ക് രാവിലെ 11 മുതൽ ഉച്ചയ്ക്ക് 12 വരെയും വൈകുന്നേരം 5 മുതൽ 6 വരെയുമാണ്.",
        "ta_IN": "வருகை நேரம் மாலை 4 மணி முதல் 7 மணி வரை.",
        "en_US": "Visiting hours are 4 AM to 6 PM, ICU-ward 11 AM to 12 PM and 5 PM to 6 PM."
      },
      "emergency_help": {
        "ml_IN": "ദയവായി ഉടൻ ഗ്രൗണ്ട് ഫ്ലോറിലെ എമർജൻസി റൂമിലേക്ക്, മുഖ്യ കവാടത്തിന്റെ ഇടതുവശത്തേക്ക് പോകുക. ഞങ്ങളുടെ ടീം 24/7 തയ്യാറാണ്.",
        "ta_IN": "அவசர சேவை அழைக்கப்படுகிறது.",
        "en_US": "please proceed immediately to the emergency room on the ground floor, to the left of the main entrance. Our team is ready 24/7."
      },
      "call_nurse_assist": {
        "ml_IN": "ഒരു നഴ്സിനെ അറിയിച്ചിട്ടുണ്ട്. ദയവായി താങ്കളുടെ നിലവിലെ സ്ഥലത്ത് കാത്തിരിക്കുക.",
        "ta_IN": "நர்ஸ் உதவி உடனே அனுப்பப்படும்.",
        "en_US": "There is a nurse in the waiting room. Please proceed to the waiting room."
      },
      "dial_nurse_number": {
        "ml_IN": "ഏതെങ്കിലും ആശുപത്രി ഫോണിൽ നിന്ന്, നഴ്സിനെ വിളിക്കാൻ 101 ഡയൽ ചെയ്യുക.",
        "ta_IN": "நர்ஸ் உதவியை அழைக்க 102 டயல் செய்யவும்.",
        "en_US": "from any hospital phone, dial 101 to reach a nurse for assistance."
      },
      "unknown_request": {
        "ml_IN": "ക്ഷമിക്കണം, അതിനുള്ള വിശദവിവരം ലഭ്യമല്ല.",
        "ta_IN": "மன்னிக்கவும், அந்த தகவல் கிடைக்கவில்லை.",
        "en_US": "Sorry, that information is not available."
      },
      "error": {
        "ml_IN": "നെറ്റ്‌വർക്ക് പിശക്. ദയവായി വീണ്ടും ശ്രമിക്കുക.",
        "ta_IN": "நெட்வொர்க் பிழை. மீண்டும் முயற்சிக்கவும்.",
        "en_US": "Network error. Please try again."
      }
    };

    return responseMap[key ?? "unknown_request"]?[_selectedLanguage] ??
        responseMap["unknown_request"]![_selectedLanguage]!;
  }



  

 void dispose() {
  _noFaceTimer?.cancel();
  _reminderTimer?.cancel();
  if (_ttsListener != null) {
    tts.isSpeakingNotifier.removeListener(_ttsListener!);
  }
  _speech.dispose();
  tts.stop();
  faceDetection.dispose();
}


}

// -------------------- Language code mapping for STT/TTS --------------------
extension LanguageCodeMapping on InteractionCoordinator {
  /// Returns the correct language code for speech recognition (STT)
  String get sttLanguage {
    switch (selectedLanguage) {
      case "ta_IN":
        return "ta_IN"; // Tamil for STT
      case "ml_IN":
        return "ml_IN"; // Malayalam
      case "en_US":
        return "en_US"; // English
      default:
        return selectedLanguage;
    }
  }

  /// Returns the correct language code for text-to-speech (TTS)
  String get ttsLanguage {
    switch (selectedLanguage) {
      case "ta_IN":
        return "ta-IN"; // Tamil TTS needs hyphen
      case "ml_IN":
        return "ml-IN"; // Malayalam TTS
      case "en_US":
        return "en-US"; // English TTS
      default:
        return selectedLanguage.replaceAll("_", "-");
    }
  }
}
