import 'dart:typed_data';

typedef FaceDetectedCallback = void Function(bool detected);

Object addFaceDetectedListener(FaceDetectedCallback callback) => Object();

void removeFaceDetectedListener(Object subscription) {}

Future<bool> startFaceDetection() async => false;

Future<void> stopFaceDetection() async {}

Future<bool> validateCapturedFace(Uint8List imageBytes) async => true;

class FaceMetrics {
  final bool detected;
  final double faceWidth;
  final double faceHeight;
  final double faceCenterX;
  final double faceCenterY;
  final double centerOffsetX;
  final double centerOffsetY;

  const FaceMetrics({
    this.detected = false,
    this.faceWidth = 0,
    this.faceHeight = 0,
    this.faceCenterX = 0.5,
    this.faceCenterY = 0.5,
    this.centerOffsetX = 0.5,
    this.centerOffsetY = 0.5,
  });
}

typedef FaceMetricsCallback = void Function(FaceMetrics metrics);

Object addFaceMetricsListener(FaceMetricsCallback callback) => Object();

void removeFaceMetricsListener(Object subscription) {}
