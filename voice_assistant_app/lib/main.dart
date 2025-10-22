import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:voice_assistant_app/features/interaction_flow/interaction_coordinator.dart';
import 'package:voice_assistant_app/features/face_detection/face_service.dart';
import 'package:voice_assistant_app/features/speech/speech_service.dart';
import 'package:voice_assistant_app/features/speech/tts_service.dart';
import 'package:voice_assistant_app/features/face_detection/camera_service.dart';
import 'features/home_ui/pages/home_screen.dart';
import 'core/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log("Flutter error: ${details.exception}", error: details.exception, stackTrace: details.stack);
  };

  runZonedGuarded<Future<void>>(() async {
    try {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      developer.log("Permission statuses - Camera: ${statuses[Permission.camera]}, Microphone: ${statuses[Permission.microphone]}");
      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        developer.log("Permissions denied. Prompting user to retry.");
        runApp(ErrorApp(
          message: "Permissions denied. Please enable camera and microphone.",
          onRetry: _retryInitialization,
        ));
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        developer.log("No cameras available.");
        runApp(ErrorApp(
          message: "No camera available on this device.",
          onRetry: _retryInitialization,
        ));
        return;
      }

      // Initialize services
      final cameraService = CameraService(cameras);
      developer.log("CameraService initialized.");
      final faceDetection = FaceDetectionService();
      developer.log("FaceDetectionService initialized.");
      final tts = TextToSpeechService();
      developer.log("TextToSpeechService initialized.");
      final speech = SpeechService(
        onTextRecognized: (text) {
          developer.log("Recognized text: $text");
        },
        onListeningStatusChanged: (isListening) {
          developer.log("Listening status changed: $isListening");
        },
      );
      developer.log("SpeechService initialized.");
      final coordinator = InteractionCoordinator(
        faceDetection: faceDetection,
        tts: tts,
        cameraService: cameraService,
        onInteractionComplete: (userInput, reply) {
          developer.log("Interaction complete: $userInput -> $reply");
        },
        onFacePromptToggle: (isActive) {
          developer.log("Face prompt toggled: $isActive");
        },
        onError: (error) {
          developer.log("Coordinator error: $error");
        },
      );
      developer.log("InteractionCoordinator created.");

      // Initialize coordinator
      await coordinator.initialize();
      developer.log("InteractionCoordinator initialized.");

      runApp(MyApp(coordinator: coordinator, cameras: cameras));
    } catch (e, stack) {
      developer.log("Initialization failed: $e", stackTrace: stack);
      runApp(ErrorApp(
        message: "Initialization failed: $e",
        onRetry: _retryInitialization,
      ));
    }
  }, (error, stack) {
    developer.log("Uncaught error: $error", stackTrace: stack);
  });
}

// Retry initialization function
Future<void> _retryInitialization() async {
  developer.log("Retrying initialization...");
  runZonedGuarded<Future<void>>(() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        developer.log("Permissions still denied after retry.");
        runApp(const ErrorApp(message: "Permissions still denied. Please enable camera and microphone."));
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        developer.log("No cameras available after retry.");
        runApp(const ErrorApp(message: "No camera available on this device."));
        return;
      }

      final cameraService = CameraService(cameras);
      final faceDetection = FaceDetectionService();
      final tts = TextToSpeechService();
      final speech = SpeechService(
        onTextRecognized: (text) {
          developer.log("Recognized text: $text");
        },
        onListeningStatusChanged: (isListening) {
          developer.log("Listening status changed: $isListening");
        },
      );
      final coordinator = InteractionCoordinator(
        faceDetection: faceDetection,
        tts: tts,
        cameraService: cameraService,
        onInteractionComplete: (userInput, reply) {
          developer.log("Interaction complete: $userInput -> $reply");
        },
        onFacePromptToggle: (isActive) {
          developer.log("Face prompt toggled: $isActive");
        },
        onError: (error) {
          developer.log("Coordinator error: $error");
        },
      );

      await coordinator.initialize();
      runApp(MyApp(coordinator: coordinator, cameras: cameras));
    } catch (e, stack) {
      developer.log("Retry initialization failed: $e", stackTrace: stack);
      runApp(ErrorApp(
        message: "Retry failed: $e",
        onRetry: _retryInitialization,
      ));
    }
  }, (error, stack) {
    developer.log("Uncaught error during retry: $error", stackTrace: stack);
  });
}

// Fallback app in case of initialization failure
class ErrorApp extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorApp({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message ?? "Failed to initialize the app. Please try again.",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: onRetry,
                    child: const Text("Retry"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final InteractionCoordinator coordinator;
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.coordinator, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hospital AI Assistant',
      theme: AppTheme.lightTheme,
      home: HomeScreen(coordinator: coordinator, cameras: cameras),
    );
  }
}