# Auto-Capture & Tilt Guidance Integration Guide

This guide explains how to integrate the auto-capture system with your camera and face detection service.

## Files Created/Modified

### 1. **HeadPoseCalculator** (`lib/Models/head_pose_calculator.dart`)
Calculates head pose (pitch and yaw) from MediaPipe landmarks.

**Key Methods:**
- `calculatePitch(landmarks)` - Returns pitch angle in degrees (0-90)
- `calculateYaw(landmarks)` - Returns yaw angle in degrees (-45 to 45)
- `isInTargetPose()` - Checks if pose is within acceptable range

**Example Landmarks Structure:**
```dart
List<List<double>> landmarks = [
  [x0, y0, z0],  // Landmark 0
  [x1, y1, z1],  // Landmark 1 (Nose Tip)
  ...
  [x10, y10, z10], // Landmark 10 (Forehead)
  ...
  [x152, y152, z152], // Landmark 152 (Chin)
];
```

### 2. **TiltGuidancePainter** (`lib/widgets/tilt_guidance_painter.dart`)
CustomPainter that displays real-time tilt guidance with:
- Semi-circular arc track
- Green target zone (40-50 degrees)
- White/Green pointer showing current pitch
- Glow effect when in perfect angle

**Usage:**
```dart
TiltGuidanceWidget(
  currentPitch: 45.0,
  isPerfectAngle: true,
  minTargetPitch: 40.0,
  maxTargetPitch: 50.0,
  height: 250,
  width: double.infinity,
)
```

### 3. **EnhancedCameraScreen** (`lib/screens/enhanced_camera_screen.dart`)
Complete camera interface with auto-capture logic.

**AutoCaptureController Features:**
- Monitors face detection stream
- Automatically captures when conditions are met
- Provides haptic feedback on capture
- Tracks remaining time for countdown

**Integration Steps:**

#### Step 1: Install Required Packages
Add to `pubspec.yaml`:
```yaml
dependencies:
  camera: ^0.10.0  # Camera access
  google_mlkit_face_detection: ^0.10.0  # Or your face detection library
```

#### Step 2: Implement Face Detection Service
Create `lib/services/face_detection_service.dart`:
```dart
import 'dart:async';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final faceDetector = FaceDetector(
    options: FaceDetectionOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectionMode.fast,
    ),
  );

  final _landmarksController = StreamController<List<List<double>>>();

  Stream<List<List<double>>> get landmarksStream => _landmarksController.stream;

  Future<void> processCameraFrame(CameraImage image) async {
    final inputImage = InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation90deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    final faces = await faceDetector.processImage(inputImage);
    
    if (faces.isNotEmpty) {
      final face = faces.first;
      final landmarks = face.landmarks
          .map((l) => [l.position.dx, l.position.dy, 0.0] as List<double>)
          .toList();
      
      _landmarksController.add(landmarks);
    }
  }

  void dispose() {
    faceDetector.close();
    _landmarksController.close();
  }
}
```

#### Step 3: Update EnhancedCameraScreen
Replace the mock detection in `_initializeFaceDetectionStream()`:

```dart
void _initializeFaceDetectionStream() {
  _faceDetectionService = FaceDetectionService();

  // Connect to real face detection service
  _faceDetectionService!.landmarksStream.listen((landmarks) {
    _faceDetectionStream!.add(landmarks);
  });

  // Start camera frame stream
  _cameraController.startImageStream((CameraImage image) async {
    await _faceDetectionService!.processCameraFrame(image);
  });
}
```

#### Step 4: Implement Image Capture
Replace the TODO in `_handleAutoCapture()`:

```dart
void _handleAutoCapture() async {
  try {
    final image = await _controller.takePicture();
    final bytes = await image.readAsBytes();
    
    widget.onImageCaptured(bytes, 'auto_capture.jpg');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Photo captured!')),
      );
    }
  } catch (e) {
    print('Error capturing image: $e');
  }
}
```

## Configuration

### Adjust Auto-Capture Parameters

```dart
AutoCaptureController(
  minPitch: 40.0,        // Minimum pitch angle
  maxPitch: 50.0,        // Maximum pitch angle
  maxYawDeviation: 5.0,  // Max yaw deviation from center
  captureTimerMs: 600,   // Time to hold position before capture
)
```

## Haptic Feedback Integration

The system automatically provides `HapticFeedback.mediumImpact()` when:
1. Face enters the target zone
2. Position is held for 600ms (auto-capture)
3. User manually triggers capture

No additional setup needed - uses Flutter's built-in `services.dart`.

## Best Practices

1. **Performance**: Use RAW face detection mode for fast processing
2. **Threading**: Process face detection on a separate thread
3. **Memory**: Dispose controllers properly to avoid memory leaks
4. **Testing**: Test with different lighting conditions and angles

## Troubleshooting

### Face detection not working
- Check camera permissions in Android/iOS manifests
- Verify face detector model is properly loaded
- Test with good lighting conditions

### Auto-capture not triggering
- Verify pitch and yaw values are being calculated
- Check timer duration isn't too short
- Ensure haptic feedback permissions are granted

### Performance issues
- Reduce camera frame rate
- Use fast detection mode instead of accurate
- Add frame skipping (process every 2nd frame)

## Example Integration (Complete)

```dart
// In _EnhancedCameraScreenState
late FaceDetectionService _faceDetectionService;

@override
void initState() {
  super.initState();
  _initializeCameraAndDetection();
}

Future<void> _initializeCameraAndDetection() async {
  _faceDetectionService = FaceDetectionService();
  
  // Listen to landmarks
  _faceDetectionService.landmarksStream.listen((landmarks) {
    _autoCaptureController.updateFaceDetection(landmarks);
  });
  
  // Start camera
  await _cameraController.initialize();
  await _cameraController.startImageStream((image) {
    _faceDetectionService.processCameraFrame(image);
  });
}
```

This completes the auto-capture and tilt guidance system!
