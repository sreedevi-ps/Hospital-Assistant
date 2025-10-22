import 'dart:ui';
import 'dart:typed_data';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  final ValueNotifier<bool> faceFoundNotifier = ValueNotifier(false);
  bool faceFound = false;

  // ✅ Add throttling state
  DateTime _lastDetect = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration _throttleDuration = const Duration(milliseconds: 500);

  Future<bool> detect(CameraImage image, CameraDescription description) async {
    final now = DateTime.now();
    if (now.difference(_lastDetect) < _throttleDuration) {
      // ⏩ Skip detection, just return last known state
      return faceFound;
    }
    _lastDetect = now;

    try {
      final inputImage = _convertToInputImage(image, description);
      final List<Face> faces = await _detector.processImage(inputImage);
      faceFound = faces.isNotEmpty;
      faceFoundNotifier.value = faceFound; // notify UI
      return faceFound;
    } catch (e) {
      debugPrint("❌ Face detection failed: $e");
      faceFound = false;
      faceFoundNotifier.value = false;
      return false;
    }
  }

  static InputImage _convertToInputImage(CameraImage image, CameraDescription desc) {
    final rotation = _rotationFromSensor(desc.sensorOrientation);
    final format = _getImageFormat(image);

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    final bytes = _concatenatePlanes(image.planes);
    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  static Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer buffer = WriteBuffer();
    for (final Plane plane in planes) {
      buffer.putUint8List(plane.bytes);
    }
    return buffer.done().buffer.asUint8List();
  }

  static InputImageRotation _rotationFromSensor(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  static InputImageFormat _getImageFormat(CameraImage image) {
    if (Platform.isIOS) {
      return InputImageFormat.bgra8888;
    } else if (Platform.isAndroid) {
      return InputImageFormat.nv21;
    } else {
      return InputImageFormat.yuv420;
    }
  }

  void dispose() {
    _detector.close();
    faceFoundNotifier.dispose();
  }
}
