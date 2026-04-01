import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

typedef FaceDetectedCallback = void Function(bool detected);

Object addFaceDetectedListener(FaceDetectedCallback callback) {
  void listener(html.Event event) {
    final customEvent = event is html.CustomEvent ? event : null;
    final detail = customEvent?.detail;

    if (detail is bool) {
      callback(detail);
      return;
    }
    if (detail is String) {
      callback(detail.toLowerCase() == 'true');
      return;
    }
    callback(false);
  }

  html.window.addEventListener('faceDetected', listener);
  return listener;
}

void removeFaceDetectedListener(Object subscription) {
  html.window.removeEventListener(
    'faceDetected',
    subscription as html.EventListener,
  );
}

Future<bool> startFaceDetection() async {
  final videos = html.document.querySelectorAll('video');
  if (videos.isEmpty) return false;

  html.VideoElement? bestVideo;
  for (final element in videos) {
    if (element is! html.VideoElement) continue;
    if (element.videoWidth > 0 && element.readyState >= 2) {
      bestVideo = element;
      break;
    }
  }

  bestVideo ??= videos.first is html.VideoElement
      ? videos.first as html.VideoElement
      : null;
  if (bestVideo == null) return false;

  js_util.callMethod(html.window, 'startFaceDetection', [bestVideo]);
  return true;
}

Future<void> stopFaceDetection() async {
  js_util.callMethod(html.window, 'stopFaceDetection', []);
}

Future<bool> validateCapturedFace(Uint8List imageBytes) async {
  final dataUrl = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
  final result = await js_util.promiseToFuture<Object?>(
    js_util.callMethod(html.window, 'validateCapturedFaceDataUrl', [dataUrl]),
  );

  if (result is bool) {
    return result;
  }
  if (result is String) {
    return result.toLowerCase() == 'true';
  }
  return false;
}

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

Object addFaceMetricsListener(FaceMetricsCallback callback) {
  void listener(html.Event event) {
    final customEvent = event is html.CustomEvent ? event : null;
    final detail = customEvent?.detail;

    if (detail is String) {
      try {
        final map = jsonDecode(detail) as Map<String, dynamic>;
        callback(
          FaceMetrics(
            detected: map['detected'] == true,
            faceWidth: (map['faceWidth'] as num?)?.toDouble() ?? 0,
            faceHeight: (map['faceHeight'] as num?)?.toDouble() ?? 0,
            faceCenterX: (map['faceCenterX'] as num?)?.toDouble() ?? 0.5,
            faceCenterY: (map['faceCenterY'] as num?)?.toDouble() ?? 0.5,
            centerOffsetX: (map['centerOffsetX'] as num?)?.toDouble() ?? 0.5,
            centerOffsetY: (map['centerOffsetY'] as num?)?.toDouble() ?? 0.5,
          ),
        );
        return;
      } catch (_) {}
    }

    callback(const FaceMetrics());
  }

  html.window.addEventListener('faceMetrics', listener);
  return listener;
}

void removeFaceMetricsListener(Object subscription) {
  html.window.removeEventListener(
    'faceMetrics',
    subscription as html.EventListener,
  );
}
