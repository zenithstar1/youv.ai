import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

class FaceDetectionFrame {
  final List<List<double>> landmarks;
  final double? headEulerAngleX;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final bool hasFace;
  final double faceWidthRatio;
  final double faceHeightRatio;
  final double faceCenterOffsetX;
  final double faceCenterOffsetY;
  final double faceCenterXRatio;
  final double faceCenterYRatio;

  const FaceDetectionFrame({
    required this.landmarks,
    required this.hasFace,
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.faceWidthRatio = 0.0,
    this.faceHeightRatio = 0.0,
    this.faceCenterOffsetX = 1.0,
    this.faceCenterOffsetY = 1.0,
    this.faceCenterXRatio = 0.5,
    this.faceCenterYRatio = 0.5,
  });

  const FaceDetectionFrame.noFace()
    : landmarks = const [],
      hasFace = false,
      headEulerAngleX = null,
      headEulerAngleY = null,
      headEulerAngleZ = null,
      faceWidthRatio = 0.0,
      faceHeightRatio = 0.0,
      faceCenterOffsetX = 1.0,
      faceCenterOffsetY = 1.0,
      faceCenterXRatio = 0.5,
      faceCenterYRatio = 0.5;
}

/// FaceDetectionService wraps MediaPipe FaceLandmarker via platform method
/// channel for real-time face detection on Android & iOS.
///
/// Replaces the previous ML Kit implementation — the bundled model works on
/// ALL devices (no Google Play Services dependency) and provides 478
/// landmarks with faster inference (~15-40 ms vs ML Kit fast mode ~50-100 ms).
///
/// Output format:
/// 10 mapped landmarks matching the old ML Kit positions:
///   [nose, leftEye, rightEye, leftEar, rightEar,
///    mouthLeft, mouthRight, leftCheek, rightCheek, mouthBottom]
///
/// Plus euler angles (pitch, yaw, roll) computed from the full 478 landmarks.
class FaceDetectionService {
  static const MethodChannel _channel = MethodChannel(
    'com.globalspace.youvai/mediapipe_face',
  );

  final StreamController<FaceDetectionFrame> _landmarksStream =
      StreamController<FaceDetectionFrame>.broadcast();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool _isProcessing = false;
  int _sensorRotation = 0;
  static const bool _debugLogs = false;

  /// Frame throttling: skip frames so MediaPipe has headroom on slow chipsets.
  int _frameCounter = 0;
  static const int _processEveryNthFrame = 2;

  /// Timeout to prevent hangs on problematic frames.
  static const Duration _processingTimeout = Duration(milliseconds: 2000);

  /// Max number of init retries before giving up.
  int _initRetries = 0;
  static const int _maxInitRetries = 3;

  /// Stream of face landmarks for subscription
  Stream<FaceDetectionFrame> get landmarksStream => _landmarksStream.stream;

  /// Configure image rotation from camera sensor orientation.
  void setSensorRotation(int sensorOrientation) {
    _sensorRotation = sensorOrientation;
  }

  /// Initialize MediaPipe FaceLandmarker.
  ///
  /// The native side loads the model from bundled assets (instant) or downloads
  /// it on first launch (~3.8 MB, cached). GPU acceleration with CPU fallback.
  /// Retries up to [_maxInitRetries] times on failure.
  Future<void> initialize() async {
    if (_isInitialized) return;

    for (int attempt = 0; attempt <= _maxInitRetries; attempt++) {
      try {
        final result = await _channel
            .invokeMethod<dynamic>('initialize')
            .timeout(const Duration(seconds: 15), onTimeout: () => null);
        _isInitialized = result == true;
        if (_isInitialized) {
          if (_debugLogs) {
            debugPrint('[MediaPipe] FaceLandmarker initialized (attempt $attempt)');
          }
          return;
        }
      } catch (e) {
        debugPrint('[MediaPipe] Init attempt $attempt failed: $e');
      }
      if (attempt < _maxInitRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    debugPrint('[MediaPipe] All init attempts failed — face detection disabled');
  }

  /// Process camera frame and extract face landmarks via MediaPipe.
  Future<void> processCameraFrame(CameraImage image) async {
    if (_isProcessing) return;

    // Auto-retry init if it failed earlier
    if (!_isInitialized && _initRetries < _maxInitRetries) {
      _initRetries++;
      try {
        await initialize();
      } catch (_) {}
    }
    if (!_isInitialized) return;

    // Throttle: only process every Nth frame
    _frameCounter++;
    if (_frameCounter < _processEveryNthFrame) return;
    _frameCounter = 0;

    _isProcessing = true;

    try {
      final Uint8List bytes;
      final int frameWidth = image.width;
      final int frameHeight = image.height;
      final String format;

      if (defaultTargetPlatform == TargetPlatform.iOS ||
          image.format.group == ImageFormatGroup.bgra8888) {
        // iOS: BGRA8888 — direct copy (single plane, no YUV complexity)
        final buf = WriteBuffer();
        for (final plane in image.planes) {
          buf.putUint8List(plane.bytes);
        }
        bytes = buf.done().buffer.asUint8List();
        format = 'bgra8888';
      } else {
        // Android: Extract Y-plane only (grayscale luminance).
        // This works reliably on ALL Camera2 devices regardless of whether
        // the YUV format is NV21, NV12, I420, YV12, or YUV_420_888.
        // The Y plane is always plane[0] with pixelStride=1.
        // MediaPipe face detection works perfectly on grayscale input.
        bytes = _extractYPlane(image);
        format = 'y_only';
      }

      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('processFrame', {
            'bytes': bytes,
            'width': frameWidth,
            'height': frameHeight,
            'rotation': _sensorRotation,
            'format': format,
          })
          .timeout(_processingTimeout, onTimeout: () => null);

      if (result != null && result['hasFace'] == true) {
        _emitFaceFrame(result);
      } else {
        if (!_landmarksStream.isClosed) {
          _landmarksStream.add(const FaceDetectionFrame.noFace());
        }
      }
    } catch (e) {
      if (_debugLogs) debugPrint('[MediaPipe] Frame error: $e');
      if (!_landmarksStream.isClosed) {
        _landmarksStream.add(const FaceDetectionFrame.noFace());
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Extract Y (luminance) plane from camera image, stripping row-stride padding.
  /// Works on ALL Camera2 YUV formats (NV21, NV12, I420, YUV_420_888).
  Uint8List _extractYPlane(CameraImage image) {
    final w = image.width;
    final h = image.height;
    final yPlane = image.planes[0];
    final rowStride = yPlane.bytesPerRow;
    final ySize = w * h;

    if (rowStride == w && yPlane.bytes.length >= ySize) {
      // No stride padding — fast sublist copy
      return yPlane.bytes.sublist(0, ySize);
    }

    // Strip row-stride padding
    final yBytes = Uint8List(ySize);
    for (int row = 0; row < h; row++) {
      final srcOffset = row * rowStride;
      final dstOffset = row * w;
      if (srcOffset + w <= yPlane.bytes.length) {
        yBytes.setRange(dstOffset, dstOffset + w, yPlane.bytes, srcOffset);
      }
    }
    return yBytes;
  }

  /// Validate a captured still image for acceptable face presence.
  ///
  /// Used by [StandardCameraScreen] to check the final captured image.
  /// Returns `true` if the image contains a well-positioned face.
  /// Since the user already passed live auto-capture checks, this is a
  /// light safety net — not a strict gate.
  Future<bool> validateCapturedImage(String imagePath) async {
    if (!_isInitialized) {
      debugPrint('[MediaPipe] validateCapturedImage: not initialized, accepting');
      return true; // Accept — can't validate without service
    }

    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>(
            'processImageFile',
            {'imagePath': imagePath},
          )
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      if (result == null) {
        debugPrint('[MediaPipe] validateCapturedImage: timeout, accepting');
        return true; // Accept on timeout — user already passed live checks
      }
      if (result['hasFace'] != true) {
        debugPrint('[MediaPipe] validateCapturedImage: no face detected in still image');
        return false;
      }
      return _isAcceptableSkinCaptureFace(result);
    } catch (e) {
      debugPrint('[MediaPipe] Image validation error: $e');
      return true; // Accept on error — don't block user after successful live detection
    }
  }

  /// Applies relaxed geometric/landmark thresholds for post-capture validation.
  /// These are intentionally more generous than the live-stream auto-capture
  /// thresholds because:
  /// 1. The still image may be cropped/rotated differently than the preview.
  /// 2. Front cameras on some devices mirror the image.
  /// 3. The user already passed live auto-capture checks, so re-validation
  ///    should only reject truly bad captures (no face at all, extreme angle).
  bool _isAcceptableSkinCaptureFace(Map<dynamic, dynamic> result) {
    final double imageWidth =
        (result['imageWidth'] as num?)?.toDouble() ?? 1.0;
    final double imageHeight =
        (result['imageHeight'] as num?)?.toDouble() ?? 1.0;
    if (imageWidth <= 0 || imageHeight <= 0) return false;

    final double bbLeft = (result['bbLeft'] as num?)?.toDouble() ?? 0;
    final double bbTop = (result['bbTop'] as num?)?.toDouble() ?? 0;
    final double bbWidth = (result['bbWidth'] as num?)?.toDouble() ?? 0;
    final double bbHeight = (result['bbHeight'] as num?)?.toDouble() ?? 0;

    final faceWidthRatio = bbWidth / imageWidth;
    final faceHeightRatio = bbHeight / imageHeight;
    final faceAreaRatio = (bbWidth * bbHeight) / (imageWidth * imageHeight);
    final aspectRatio = bbWidth / math.max(bbHeight, 1.0);

    final centerX = bbLeft + (bbWidth / 2);
    final centerY = bbTop + (bbHeight / 2);
    final offsetX = (centerX - (imageWidth / 2)).abs() / (imageWidth / 2);
    final offsetY = (centerY - (imageHeight / 2)).abs() / (imageHeight / 2);

    // Landmarks check (10-point mapped format)
    final landmarksList = result['landmarks'] as List?;
    if (landmarksList == null || landmarksList.length < 7) {
      debugPrint('[MediaPipe] Validation FAIL: insufficient landmarks (${landmarksList?.length})');
      return false;
    }

    List<double> lm(int i) {
      final pt = landmarksList[i] as List;
      return [
        (pt[0] as num).toDouble(),
        (pt[1] as num).toDouble(),
      ];
    }

    final leftEye = lm(1);
    final rightEye = lm(2);
    final nose = lm(0);
    final mouthLeft = lm(5);
    final mouthRight = lm(6);

    final eyeDx = (leftEye[0] - rightEye[0]).abs();
    final eyeDy = (leftEye[1] - rightEye[1]).abs();
    if (eyeDx <= 0) return false;

    final eyesLevel = eyeDy / eyeDx;
    final mouthWidth = (mouthRight[0] - mouthLeft[0]).abs();
    final noseCenteredToEyes =
        ((nose[0] - ((leftEye[0] + rightEye[0]) / 2)).abs() / eyeDx);

    final yaw = ((result['eulerAngleY'] as num?) ?? 0).toDouble().abs();
    final roll = ((result['eulerAngleZ'] as num?) ?? 0).toDouble().abs();

    debugPrint('[MediaPipe] Validation: faceW=$faceWidthRatio faceH=$faceHeightRatio '
        'area=$faceAreaRatio aspect=$aspectRatio offX=$offsetX offY=$offsetY '
        'eyesLevel=$eyesLevel noseCentered=$noseCenteredToEyes mouth=$mouthWidth eyeDx=$eyeDx '
        'yaw=$yaw roll=$roll');

    // Relaxed thresholds — user already passed live auto-capture checks.
    // Only reject truly bad captures.
    if (faceWidthRatio < 0.08 || faceWidthRatio > 0.92) return false;
    if (faceHeightRatio < 0.10 || faceHeightRatio > 0.95) return false;
    if (faceAreaRatio < 0.02 || faceAreaRatio > 0.75) return false;
    if (aspectRatio < 0.40 || aspectRatio > 1.60) return false;
    if (offsetX > 0.45 || offsetY > 0.50) return false;
    if (eyesLevel > 0.25) return false;
    if (noseCenteredToEyes > 0.75) return false;
    if (mouthWidth < eyeDx * 0.18 || mouthWidth > eyeDx * 1.60) return false;
    if (yaw > 35 || roll > 25) return false;

    return true;
  }

  /// Build and emit a [FaceDetectionFrame] from the native result map.
  void _emitFaceFrame(Map<dynamic, dynamic> result) {
    if (_landmarksStream.isClosed) return;

    final landmarksList = result['landmarks'] as List?;
    final landmarks = landmarksList?.map((lm) {
          final list = lm as List;
          return [
            (list[0] as num).toDouble(),
            (list[1] as num).toDouble(),
          ];
        }).toList() ??
        [];

    final imageWidth = (result['imageWidth'] as num?)?.toDouble() ?? 1.0;
    final imageHeight = (result['imageHeight'] as num?)?.toDouble() ?? 1.0;

    final bbLeft = (result['bbLeft'] as num?)?.toDouble() ?? 0.0;
    final bbTop = (result['bbTop'] as num?)?.toDouble() ?? 0.0;
    final bbWidth = (result['bbWidth'] as num?)?.toDouble() ?? 0.0;
    final bbHeight = (result['bbHeight'] as num?)?.toDouble() ?? 0.0;

    final faceWidthRatio = (bbWidth / imageWidth).clamp(0.0, 1.0);
    final faceHeightRatio = (bbHeight / imageHeight).clamp(0.0, 1.0);

    final centerX = bbLeft + (bbWidth / 2);
    final centerY = bbTop + (bbHeight / 2);
    final normalizedOffsetX =
        ((centerX - (imageWidth / 2)).abs() / (imageWidth / 2)).clamp(0.0, 1.0);
    final normalizedOffsetY =
        ((centerY - (imageHeight / 2)).abs() / (imageHeight / 2)).clamp(0.0, 1.0);
    final centerXRatio = (centerX / imageWidth).clamp(0.0, 1.0);
    final centerYRatio = (centerY / imageHeight).clamp(0.0, 1.0);

    _landmarksStream.add(
      FaceDetectionFrame(
        landmarks: landmarks,
        hasFace: true,
        headEulerAngleX: (result['eulerAngleX'] as num?)?.toDouble(),
        headEulerAngleY: (result['eulerAngleY'] as num?)?.toDouble(),
        headEulerAngleZ: (result['eulerAngleZ'] as num?)?.toDouble(),
        faceWidthRatio: faceWidthRatio,
        faceHeightRatio: faceHeightRatio,
        faceCenterOffsetX: normalizedOffsetX,
        faceCenterOffsetY: normalizedOffsetY,
        faceCenterXRatio: centerXRatio,
        faceCenterYRatio: centerYRatio,
      ),
    );
  }

  /// Dispose the service
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod<dynamic>('dispose');
    } catch (_) {}
    await _landmarksStream.close();
    _isInitialized = false;
  }
}
