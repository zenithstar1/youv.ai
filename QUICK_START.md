# Auto-Capture Quick Start Guide

## Installation ✓

The auto-capture feature has been fully integrated into your app. No additional packages needed!

**Existing Dependencies Used**:
- `flutter`
- `camera` (already in pubspec.yaml)
- `google_mlkit_face_detection` (already in pubspec.yaml)

## Basic Usage

### 1. Auto-Capture is Already Active
The feature automatically activates in your `EnhancedCameraScreen`:

```dart
EnhancedCameraScreen(
  onImageCaptured: (imageBytes, fileName) {
    // Handle captured image
  },
  isHair: true,  // or false for skin analysis
)
```

### 2. How Users Will Experience It

1. **Camera opens** → White circular guide appears
2. **Face detected** → Angle values update in real-time
3. **Angle improves** → Circle border transitions from white to amber
4. **Perfect angle** → Green circle with pulsing glow
5. **Countdown** → Beautiful green timer appears (600ms)
6. **Auto-capture** → Image captured, user gets haptic feedback
7. **Navigate** → Proceeds to image preview/processing

## Customization

### Adjust Perfect Angle Requirements

In `EnhancedCameraScreen._initState()`:

```dart
_autoCaptureController = AutoCaptureController(
  minPitch: 40.0,        // Lower = more forward tilt allowed
  maxPitch: 50.0,        // Higher = more backward tilt allowed
  maxYawDeviation: 3.0,  // Lower = stricter centering
  captureTimerMs: 1000,  // Higher = longer wait time
  frameThrottleInterval: 2,  // Higher = less frequent UI updates
);
```

**Recommended Values**:
```
For Hair Analysis:
- minPitch: 35°, maxPitch: 55°        (more forgiving)
- maxYawDeviation: 8°                  (allows side angles)
- captureTimerMs: 800ms                (user time to stabilize)

For Skin/Face Analysis:
- minPitch: 42°, maxPitch: 48°         (strict centering)
- maxYawDeviation: 5°                  (front-facing only)
- captureTimerMs: 600ms                (quick auto-capture)

For Selfie/Portrait:
- minPitch: 38°, maxPitch: 52°         (balanced)
- maxYawDeviation: 10°                 (allows slight tilts)
- captureTimerMs: 800ms                (natural timing)
```

### Adjust Visual Guide Size

In `_buildGuidanceOverlay()`:

```dart
AutoCaptureGuideWidget(
  // ... other parameters
  guideSize: 200,  // Smaller guide (default: 280)
  // or
  guideSize: 350,  // Larger guide
)
```

### Change Colors

Edit colors in `AutoCaptureGuideWidget`:

```dart
// In _buildMainGuideCircle()
final guideColor = widget.isPerfectAngle
    ? Colors.blue.shade400        // Change from green to blue
    : (isYawOk && isPitchOk)
        ? Colors.purple.shade300  // Change from amber
        : Colors.grey.shade600;
```

### Skip Auto-Capture (Manual Only)

Disable the auto-capture countdown:

```dart
// In AutoCaptureController, comment out _startCaptureTimer():
void updateFaceDetection(List<List<double>> landmarks) {
  // ... calculate pitch/yaw ...
  
  if (isPerfectNow) {
    // _startCaptureTimer();  // <- Comment this out
    _onStateChange?.call();
  } else {
    _stopCaptureTimer();
  }
}
```

Or add a flag to `AutoCaptureController`:

```dart
class AutoCaptureController {
  final bool enableAutoCapture;  // Add this
  
  AutoCaptureController({
    // ... other params
    this.enableAutoCapture = true,  // Add this
  });
  
  void updateFaceDetection(List<List<double>> landmarks) {
    // ...
    if (isPerfectNow && enableAutoCapture) {  // Add check
      _startCaptureTimer();
    }
  }
}
```

## Common Customizations

### 1. Different Countdown Duration

```dart
// For longer wait time
AutoCaptureController(
  captureTimerMs: 1500,  // 1.5 seconds
)

// For faster capture
AutoCaptureController(
  captureTimerMs: 300,   // 0.3 seconds
)
```

### 2. Different Angle Ranges for Different Scenarios

```dart
// Hair from back
if (analysisType == AnalysisType.HAIR_BACK) {
  minPitch = 70.0;  // Face looking down
  maxPitch = 85.0;
}

// Hair from front
else if (analysisType == AnalysisType.HAIR_FRONT) {
  minPitch = 35.0;  // Face looking up
  maxPitch = 50.0;
}

// Face frontal
else {
  minPitch = 42.0;  // Neutral position
  maxPitch = 48.0;
}
```

### 3. Skip Guide Circle (Show Only Countdown)

```dart
// Hide the main guide, only show when perfect
if (widget.isPerfectAngle) {
  // Show countdown timer only
  _buildCountdownTimer();
} else {
  // Show text guidance
  Text('Position face in frame')
}
```

### 4. Add Voice Feedback

```dart
// Add to AutoCaptureController
import 'package:flutter_tts/flutter_tts.dart';

class AutoCaptureController {
  final FlutterTts flutterTts = FlutterTts();
  
  void updateFaceDetection(List<List<double>> landmarks) {
    // ... existing code ...
    
    if (isPerfectNow && !wasPerfect) {
      flutterTts.speak("Perfect angle, hold still");
      _startCaptureTimer();
    }
  }
}
```

### 5. Custom Haptic Patterns

```dart
// In _RingProgressPainter or AutoCaptureController
import 'package:sensors_plus/sensors_plus.dart';

void _triggerCapture() async {
  // Different vibration pattern
  await HapticFeedback.vibrate();  // Simple vibration
  // or
  await HapticFeedback.heavyImpact();  // Heavy hit
  // or
  await HapticFeedback.lightImpact();  // Light tap
  
  _onCapture?.call();
}
```

## Testing

### Test Different Angles

Use the angle display in the status bar:
```
Tilt: 35°     ← Change head position
Angle: -8°    ← Rotate head left/right
```

Target values should show **green** when in range.

### Test Auto-Capture

1. Match the perfect angle
2. Keep head still
3. Watch for green circle and countdown
4. Image should capture automatically
5. Should feel haptic feedback (vibration)

### Test Manual Capture

Click the camera button anytime, even if not in perfect angle.

## Troubleshooting

### Auto-capture not triggering?
✓ Check angle values - must be in green range
✓ Ensure good lighting for face detection
✓ Keep head still during countdown
✓ Verify FaceDetectionService is initialized

### Angle values not changing?
✓ Check camera permissions
✓ Verify face is visible and well-lit
✓ Check if ML Kit is properly installed
✓ See `face_detection_service.dart` for debug info

### Visual guide not showing?
✓ Check if `AutoCaptureGuideWidget` is in the layout
✓ Verify screen brightness is sufficient
✓ Check `_buildGuidanceOverlay()` positioning

### Images coming out blurry?
✓ Keep device steady during countdown
✓ Ensure adequate lighting
✓ Check camera resolution (use ResolutionPreset.high)

## Advanced Usage

### Multi-Step Capture Process

```dart
// Capture multiple angles for better analysis
List<Uint8List> _capturedImages = [];

void _handleAutoCapture() {
  _capturedImages.add(/* captured bytes */);
  
  if (_capturedImages.length < 3) {
    // Guide user to capture from different angle
    _showMessage("Capture from different angle");
    _resetForNextCapture();
  } else {
    // All captures done, proceed
    _submitAnalysis(_capturedImages);
  }
}
```

### A/B Test Different Angles

```dart
// Compare quality across angle ranges
final testRanges = [
  (40, 50, 5),  // Current
  (35, 55, 8),  // More forgiving
  (42, 48, 3),  // Strict
];

// Measure which produces best results
```

### Integrate with Analytics

```dart
void _handleAutoCapture() {
  HapticFeedback.mediumImpact();
  
  // Log auto-capture event
  analytics.logEvent(
    name: "auto_capture_triggered",
    parameters: {
      "pitch": _autoCaptureController.currentPitch,
      "yaw": _autoCaptureController.currentYaw,
      "analysis_type": widget.isHair ? "hair" : "skin",
    },
  );
  
  _takePicture();
}
```

## Performance Tips

### Reduce UI Repaints
```dart
// Increase throttle interval
AutoCaptureController(
  frameThrottleInterval: 5,  // Update every 5th frame
)
```

### Optimize Face Detection
```dart
// In FaceDetectionService
_faceDetector = FaceDetector(
  options: FaceDetectorOptions(
    enableLandmarks: true,
    enableClassification: false,  // Disable if not needed
    performanceMode: FaceDetectorMode.fast,  // Fast mode
  ),
);
```

### Battery Optimization
```dart
// Stop processing when not visible
@override
void paused(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    _cameraController?.stopImageStream();
  }
}

@override
void resumed(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _cameraController?.startImageStream(...);
  }
}
```

## File Locations

```
lib/
├── widgets/
│   └── auto_capture_guide_widget.dart      (NEW - Main widget)
│
├── screens/
│   ├── enhanced_camera_screen.dart         (UPDATED)
│   └── image_capture_screen.dart           (Uses enhanced screen)
│
├── services/
│   └── face_detection_service.dart         (Used by enhanced screen)
│
└── Models/
    └── head_pose_calculator.dart           (Angle calculations)
```

## API Reference

### AutoCaptureGuideWidget

```dart
AutoCaptureGuideWidget({
  required double currentPitch,              // Current head tilt (-90 to 90)
  required double currentYaw,                // Current face rotation (-45 to 45)
  required bool isPerfectAngle,              // Whether in perfect angle range
  bool isCountingDown = false,               // Whether countdown is active
  int remainingTime = 0,                     // Remaining ms for capture
  double minTargetPitch = 42.0,              // Minimum pitch acceptable
  double maxTargetPitch = 48.0,              // Maximum pitch acceptable
  double maxYawDeviation = 5.0,              // Max yaw deviation from center
  double guideSize = 280,                    // Size of guide circle in pixels
})
```

### AutoCaptureController

```dart
AutoCaptureController({
  double minPitch = 42.0,                    // Minimum pitch for perfect angle
  double maxPitch = 48.0,                    // Maximum pitch for perfect angle
  double maxYawDeviation = 5.0,              // Max yaw deviation for perfect angle
  int captureTimerMs = 600,                  // Auto-capture countdown duration
  int frameThrottleInterval = 2,             // UI update frequency
})
```

---

**Quick Reference**: Everything is already integrated and working! Start by running the app and testing with a real device. Refer to the comprehensive `AUTO_CAPTURE_FEATURE_GUIDE.md` for in-depth information.

**Last Updated**: February 17, 2024
