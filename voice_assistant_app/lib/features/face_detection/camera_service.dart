import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';



class CameraService {
  final List<CameraDescription> cameras;
  late CameraController controller;
  late CameraDescription description;
  Function(CameraImage)? onCameraImage;

  CameraService(this.cameras, {this.onCameraImage}) {
    description = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
  }

  Future<void> initialize() async {
    print("📷 Initializing camera...");
    controller = CameraController(description, ResolutionPreset.low, enableAudio: false);
    try {
      await controller.initialize();
      print("✅ Camera initialized!");
      controller.startImageStream((image) {
        print("📸 Frame captured & sent to detection");
        if (onCameraImage != null) onCameraImage!(image);
      });
    } catch (e, stackTrace) {
      debugPrint("❌ Camera initialization failed: $e");
      debugPrint("StackTrace: $stackTrace");
    }
  }

  /// Capture a single frame on-demand (without stopping live stream permanently)
  Future<CameraImage?> captureSingleFrame() async {
    try {
      print("📸 captureSingleFrame() called");
      final completer = Completer<CameraImage>();

      void listener(CameraImage image) {
        if (!completer.isCompleted) {
          completer.complete(image);
        }
      }

      await controller.stopImageStream(); // stop existing stream
      await controller.startImageStream(listener); // start temporary listener

      final frame = await completer.future;

      await controller.stopImageStream(); // stop again to release
      await controller.startImageStream((image) {
        if (onCameraImage != null) onCameraImage!(image);
      }); // resume original listener

      print("✅ Single frame captured");
      return frame;
    } catch (e, stackTrace) {
      print("❌ Error in captureSingleFrame: $e");
      print("StackTrace: $stackTrace");
      return null;
    }
  }

  void dispose() {
    controller.dispose();
    print("🧹 CameraService disposed");
  }
}
