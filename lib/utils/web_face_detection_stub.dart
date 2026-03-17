typedef FaceDetectedCallback = void Function(bool detected);

Object addFaceDetectedListener(FaceDetectedCallback callback) => Object();

void removeFaceDetectedListener(Object subscription) {}

Future<bool> startFaceDetection() async => false;

Future<void> stopFaceDetection() async {}
