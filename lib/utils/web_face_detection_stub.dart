import 'dart:typed_data';

typedef FaceDetectedCallback = void Function(bool detected);

Object addFaceDetectedListener(FaceDetectedCallback callback) => Object();

void removeFaceDetectedListener(Object subscription) {}

Future<bool> startFaceDetection() async => false;

Future<void> stopFaceDetection() async {}

Future<bool> validateCapturedFace(Uint8List imageBytes) async => true;
