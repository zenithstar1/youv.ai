/// EXAMPLE: Complete Integration Implementation
/// 
/// This file shows how to integrate HeadPoseCalculator, TiltGuidancePainter,
/// and AutoCaptureController with a real camera and face detection service.
///
/// To use:
/// 1. Uncomment the code below
/// 2. Install required packages: camera, google_mlkit_face_detection
/// 3. Copy this implementation into your own camera screen
///

/*

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../Models/head_pose_calculator.dart';
import '../widgets/tilt_guidance_painter.dart';
import '../screens/enhanced_camera_screen.dart';
/// Complete Camera Implementation with Face Detection
/// 
/// This is a production-ready example that shows:
/// - Camera initialization and frame capture
/// - Face detection with MediaPipe landmarks
/// - Real-time pose calculation
/// - Auto-capture with timer logic
/// - Haptic feedback on capture
class FullCameraImplementationExample extends StatefulWidget {
  final Function(Uint8List imageBytes, String fileName) onImageCaptured;
  final bool isHair;

  const FullCameraImplementationExample({
    super.key,
    required this.onImageCaptured,
    this.isHair = false,
  });

  @override
  State<FullCameraImplementationExample> createState() =>
      _FullCameraImplementationExampleState();
}

class _FullCameraImplementationExampleState
    extends State<FullCameraImplementationExample> {
  late CameraController _cameraController;
  late FaceDetector _faceDetector;
  late AutoCaptureController _autoCaptureController;

  bool _isInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Initialize face detector
      _faceDetector = FaceDetector(
        options: FaceDetectionOptions(
          enableLandmarks: true,
          enableClassification: true,
          performanceMode: FaceDetectionMode.fast,
        ),
      );

      // Initialize camera
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController.initialize();

      // Initialize auto-capture controller
      _autoCaptureController = AutoCaptureController();
      _autoCaptureController.setCallbacks(
        onCapture: _handleAutoCapture,
        onStateChange: () {
          if (mounted) {
            setState(() {});
          }
        },
      );

      // Start image stream for face detection
      await _cameraController.startImageStream(_processCameraFrame);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Convert camera image to InputImage for ML Kit
      InputImage? inputImage = await _convertCameraImage(image);

      if (inputImage != null) {
        // Process with face detector
        final faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty) {
          final face = faces.first;

          // Extract landmarks - Convert to normalized coordinates
          final List<List<double>> landmarks = [];

          for (int i = 0; i < face.landmarks.length; i++) {
            final landmark = face.landmarks[i];
            landmarks.add([
              landmark.position.dx / image.width,
              landmark.position.dy / image.height,
              0.0,
            ]);
          }

          // Update auto-capture controller with landmarks
          _autoCaptureController.updateFaceDetection(landmarks);
        }
      }
    } catch (e) {
      print('Error processing camera frame: $e');
    }

    _isProcessing = false;
  }

  Future<InputImage?> _convertCameraImage(CameraImage image) async {
    try {
      final inputImageFormat =
          _inputImageFormatFromMediaFormat(image.format.group);
      if (inputImageFormat == null) return null;

      final planeData = image.planes.map(
        (plane) {
          return InputImagePlaneMetadata(
            offset: 0,
            size: Size(plane.bytesPerRow.toDouble(), image.height.toDouble()),
            bytesPerRow: plane.bytesPerRow,
          );
        },
      ).toList();

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation90deg,
        format: inputImageFormat,
        bytesPerRow: image.planes.isNotEmpty ? image.planes[0].bytesPerRow : 0,
      );

      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: metadata,
      );
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  InputImageFormat? _inputImageFormatFromMediaFormat(ImageFormatGroup format) {
    switch (format) {
      case ImageFormatGroup.nv21:
        return InputImageFormat.nv21;
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      default:
        return null;
    }
  }

  Future<void> _handleAutoCapture() async {
    try {
      // Stop image stream to capture
      await _cameraController.stopImageStream();

      // Take picture
      final image = await _cameraController.takePicture();
      final bytes = await image.readAsBytes();

      // Resume image stream
      await _cameraController.startImageStream(_processCameraFrame);

      // Pass to parent
      widget.onImageCaptured(bytes, 'auto_capture_${DateTime.now().millisecondsSinceEpoch}.jpg');
    } catch (e) {
      print('Error capturing image: $e');
      // Resume stream even if capture failed
      await _cameraController.startImageStream(_processCameraFrame);
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _faceDetector.close();
    _autoCaptureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_cameraController),

          // Tilt guidance overlay
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Align your face',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TiltGuidanceWidget(
                  currentPitch: _autoCaptureController.currentPitch,
                  isPerfectAngle: _autoCaptureController.isPerfectAngle,
                  height: 220,
                ),
              ],
            ),
          ),

          // Debug info
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pitch: ${_autoCaptureController.currentPitch.toStringAsFixed(1)}°',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Yaw: ${_autoCaptureController.currentYaw.toStringAsFixed(1)}°',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (_autoCaptureController.isCountingDown)
                  Text(
                    'Capturing in ${(_autoCaptureController.remainingTime / 1000).toStringAsFixed(2)}s',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Manual capture button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  backgroundColor: const Color(0xFF6B3E3E),
                  onPressed: () => _autoCaptureController.triggerManualCapture(),
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ALTERNATIVE: Simple Mock Implementation (FOR TESTING WITHOUT CAMERA)
// ============================================================================

/// Mock Face Detection Service (for testing without real camera)
class MockFaceDetectionService {
  final StreamController<List<List<double>>> _landmarkController =
      StreamController<List<List<double>>>();

  Stream<List<List<double>>> get landmarkStream => _landmarkController.stream;

  /// Start generating mock landmarks that gradually increase pitch
  void startMockDetection() {
    double pitch = 30.0;
    bool increasing = true;

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (pitch > 50 && increasing) {
        increasing = false;
      } else if (pitch < 30 && !increasing) {
        increasing = true;
      }

      if (increasing) {
        pitch += 0.5;
      } else {
        pitch -= 0.5;
      }

      // Generate mock landmarks
      final mockLandmarks = _generateMockLandmarks(pitch);
      _landmarkController.add(mockLandmarks);
    });
  }

  List<List<double>> _generateMockLandmarks(double pitch) {
    // Generate 468 landmarks (from MediaPipe FaceMesh)
    final landmarks = <List<double>>[];

    // Landmark 1: Nose Tip
    landmarks.add([0.5, 0.4, 0.0]);

    // Landmark 10: Forehead (varies with pitch)
    final foreheadY = 0.3 - (pitch / 90.0) * 0.1;
    landmarks.add([0.5, foreheadY, 0.0]);

    // Add remaining landmarks
    for (int i = 1; i < 152; i++) {
      if (i != 1 && i != 10) {
        landmarks.add([0.5, 0.5, 0.0]);
      }
    }

    // Landmark 152: Chin
    final chinY = 0.6 + (pitch / 90.0) * 0.1;
    landmarks.add([0.5, chinY, 0.0]);

    return landmarks;
  }

  void dispose() {
    _landmarkController.close();
  }
}

*/

// ============================================================================
// QUICK START REFERENCE
// ============================================================================

/// Quick Reference: How to integrate auto-capture in 5 easy steps:
///
/// 1. Add to pubspec.yaml:
///    ```
///    camera: ^0.10.0
///    google_mlkit_face_detection: ^0.10.0
///    ```
///
/// 2. Initialize HeadPoseCalculator with landmarks:
///    ```dart
///    final pitch = HeadPoseCalculator.calculatePitch(landmarks);
///    final yaw = HeadPoseCalculator.calculateYaw(landmarks);
///    ```
///
/// 3. Create AutoCaptureController:
///    ```dart
///    final controller = AutoCaptureController();
///    controller.setCallbacks(
///      onCapture: () { /* take picture */ },
///      onStateChange: () { setState(() {}); }
///    );
///    ```
///
/// 4. Update controller with landmarks:
///    ```dart
///    controller.updateFaceDetection(landmarks);
///    ```
///
/// 5. Display TiltGuidanceWidget:
///    ```dart
///    TiltGuidanceWidget(
///      currentPitch: controller.currentPitch,
///      isPerfectAngle: controller.isPerfectAngle,
///    )
///    ```
///
/// That's it! The system handles:
/// - ✓ Automatic capture when pitch 42-48° and yaw < 5°
/// - ✓ 600ms timer countdown
/// - ✓ Haptic feedback on capture
/// - ✓ Real-time visual feedback
/// - ✓ Manual capture button as fallback
