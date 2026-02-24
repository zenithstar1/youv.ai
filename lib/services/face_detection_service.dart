import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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

/// FaceDetectionService handles real-time face detection for hair analysis
/// 
/// IMPORTANT: Google ML Kit Face Detection returns only ~10 landmarks per face:
/// - Nose tip (index 0)
/// - Left eye (index 1)
/// - Right eye (index 2)
/// - Left ear (index 3)
/// - Right ear (index 4)
/// - Left mouth corner (index 5)
/// - Right mouth corner (index 6)
/// - Left shoulder (index 7)
/// - Right shoulder (index 8)
/// - Left hip (index 9)
/// 
/// For full 468-point MediaPipe geometry, consider separate MediaPipe package
class FaceDetectionService {
  late FaceDetector _faceDetector;
  final StreamController<FaceDetectionFrame> _landmarksStream =
      StreamController<FaceDetectionFrame>.broadcast();

  bool _isInitialized = false;
  bool _isProcessing = false;
  InputImageRotation _imageRotation = InputImageRotation.rotation0deg;
  static const bool _debugLogs = false;

  /// Stream of face landmarks for subscription
  Stream<FaceDetectionFrame> get landmarksStream => _landmarksStream.stream;

  /// Configure image rotation from camera sensor orientation.
  void setSensorRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        _imageRotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        _imageRotation = InputImageRotation.rotation180deg;
        break;
      case 270:
        _imageRotation = InputImageRotation.rotation270deg;
        break;
      case 0:
      default:
        _imageRotation = InputImageRotation.rotation0deg;
        break;
    }
  }

  /// Initialize the face detection service
  /// Uses fast mode which is sufficient for hair analysis with ML Kit's 10 landmarks
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,  // Required for angle calculations
          enableClassification: false,
          // Accurate mode gives more stable Euler angles for capture gating.
          performanceMode: FaceDetectorMode.accurate,
          enableContours: false,  // Not needed with 10 landmarks
        ),
      );
      _isInitialized = true;
      if (_debugLogs) {
        print('✅ FaceDetector initialized (Accurate mode, ~10 landmarks)');
      }
    } catch (e) {
      print('Error initializing FaceDetectionService: $e');
      throw Exception('Failed to initialize face detection: $e');
    }
  }

  /// Process camera frame and extract face landmarks
  Future<void> processCameraFrame(CameraImage cameraImage) async {
    if (!_isInitialized || _isProcessing) return;
    _isProcessing = true;

    try {
      // Convert camera image to InputImage for ML Kit
      InputImage? inputImage = _convertCameraImage(cameraImage);

      if (inputImage != null) {
        // Process with face detector
        final faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty) {
          final face = faces.first;
          if (_debugLogs) {
            print('✅ Face detected! Landmarks count: ${face.landmarks.length}');
          }

          // Build deterministic landmark vector by type:
          // [nose, leftEye, rightEye, leftEar, rightEar, mouthLeft, mouthRight, leftCheek, rightCheek, mouthBottom]
          final List<List<double>> landmarks = List<List<double>>.generate(
            10,
            (_) => [double.nan, double.nan],
          );

          try {
            void setPoint(int index, FaceLandmarkType type) {
              final landmark = face.landmarks[type];
              if (landmark == null) return;
              final point = landmark.position;
              landmarks[index] = [point.x.toDouble(), point.y.toDouble()];
            }

            setPoint(0, FaceLandmarkType.noseBase);
            setPoint(1, FaceLandmarkType.leftEye);
            setPoint(2, FaceLandmarkType.rightEye);
            setPoint(3, FaceLandmarkType.leftEar);
            setPoint(4, FaceLandmarkType.rightEar);
            setPoint(5, FaceLandmarkType.leftMouth);
            setPoint(6, FaceLandmarkType.rightMouth);
            setPoint(7, FaceLandmarkType.leftCheek);
            setPoint(8, FaceLandmarkType.rightCheek);
            setPoint(9, FaceLandmarkType.bottomMouth);

            if (_debugLogs) {
              final validCount = landmarks
                  .where((p) => p[0].isFinite && p[1].isFinite)
                  .length;
              print('📍 Extracted $validCount mapped landmarks from face');
            }
          } catch (e) {
            print('❌ Error extracting landmarks: $e');
          }

          // Emit landmarks to stream
          if (!_landmarksStream.isClosed) {
            final frameWidth = inputImage.metadata!.size.width;
            final frameHeight = inputImage.metadata!.size.height;
            final bounds = face.boundingBox;

            final faceWidthRatio =
                (bounds.width / frameWidth).clamp(0.0, 1.0).toDouble();
            final faceHeightRatio =
                (bounds.height / frameHeight).clamp(0.0, 1.0).toDouble();

            final centerX = bounds.left + (bounds.width / 2);
            final centerY = bounds.top + (bounds.height / 2);
            final normalizedOffsetX =
                ((centerX - (frameWidth / 2)).abs() / (frameWidth / 2))
                    .clamp(0.0, 1.0)
                    .toDouble();
            final normalizedOffsetY =
                ((centerY - (frameHeight / 2)).abs() / (frameHeight / 2))
                    .clamp(0.0, 1.0)
                    .toDouble();
            final centerXRatio = (centerX / frameWidth).clamp(0.0, 1.0).toDouble();
            final centerYRatio = (centerY / frameHeight).clamp(0.0, 1.0).toDouble();

            _landmarksStream.add(
              FaceDetectionFrame(
                landmarks: landmarks,
                hasFace: true,
                headEulerAngleX: face.headEulerAngleX,
                headEulerAngleY: face.headEulerAngleY,
                headEulerAngleZ: face.headEulerAngleZ,
                faceWidthRatio: faceWidthRatio,
                faceHeightRatio: faceHeightRatio,
                faceCenterOffsetX: normalizedOffsetX,
                faceCenterOffsetY: normalizedOffsetY,
                faceCenterXRatio: centerXRatio,
                faceCenterYRatio: centerYRatio,
              ),
            );
            if (_debugLogs) {
              print('📤 Emitted ${landmarks.length} landmarks to stream');
            }
          }
        } else {
          // No faces detected in this frame - this is normal, keep scanning
          if (_debugLogs) {
            print('⚠️ No faces detected in this frame');
          }
          if (!_landmarksStream.isClosed) {
            _landmarksStream.add(const FaceDetectionFrame.noFace());
          }
        }
      } else {
        if (_debugLogs) {
          print('⚠️ Failed to convert camera image to InputImage');
        }
      }
    } catch (e) {
      print('❌ Error processing camera frame: $e');
    }

    _isProcessing = false;
  }


  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final allBytes = <int>[];
      for (Plane plane in image.planes) {
        allBytes.addAll(plane.bytes);
      }
      final bytes = Uint8List.fromList(allBytes);

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      InputImageFormat inputImageFormat;
      switch (image.format.group) {
        case ImageFormatGroup.yuv420:
          inputImageFormat = InputImageFormat.yuv420;
          break;
        case ImageFormatGroup.bgra8888:
          inputImageFormat = InputImageFormat.bgra8888;
          break;
        default:
          return null;
      }

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: _imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      return inputImage;
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  /// Dispose the service
  Future<void> dispose() async {
    await _faceDetector.close();
    await _landmarksStream.close();
    _isInitialized = false;
  }
}
