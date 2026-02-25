# Auto-Capture Feature Guide

## Overview

The enhanced auto-capture feature provides an intelligent, user-friendly interface for capturing perfect facial images with automatic angle detection. When the user's face reaches the optimal angle, the app automatically captures the image with visual and haptic feedback.

## Key Features

### 1. **Perfect Angle Detection**
- **Pitch Detection (Head Tilt)**: Monitors the angle of the head's vertical tilt
  - Target Range: 42° - 48°
  - Real-time feedback shown in the angle indicators
  
- **Yaw Detection (Face Angle)**: Tracks horizontal face rotation
  - Maximum Deviation: ±5°
  - Ensures face is centered and looking toward the camera

### 2. **Visual Guide System**

#### Main Circular Guide
- **White circular border**: Professional minimalistic frame that guides face positioning
- **Corner guides**: Four corner markers to help frame the face correctly
- **Center crosshair**: Identifies the exact center point for face alignment
- **Pulsing outer ring**: Appears when perfect angle is achieved (green glow effect)

#### Real-Time Status Indicators
- **Circle Color Coding**:
  - **White/Gray**: Face not in range
  - **Amber/Yellow**: Close to target angle
  - **Green**: Perfect angle achieved ✓
  
- **Angle Display**:
  - Head Tilt (Pitch): Shows current vertical angle
  - Face Angle (Yaw): Shows horizontal rotation
  - Both change color when in acceptable range

### 3. **Auto-Capture Countdown**
When perfect angle is detected:
1. A **green circular timer** appears in the center
2. **Countdown starts**: 600ms (0.6 seconds) by default
3. **Visual progress ring**: Shows remaining time
4. **Auto-capture triggers**: Image is captured automatically when countdown completes
5. **Haptic feedback**: Device vibrates to confirm capture

### 4. **Professional Minimalistic UI Design**

The design philosophy focuses on:
- **Clarity**: Only essential information is displayed
- **Minimal Visual Clutter**: No unnecessary elements
- **Smooth Animations**: Professional transitions and effects
- **Accessibility**: Clear feedback for all user actions
- **Dark Theme**: Professional appearance with good contrast

## User Interface Components

### Top Status Bar
- Shows position status (Position perfect / Tap to adjust)
- Displays current angle values (Tilt & Angle)
- Shows countdown timer during auto-capture
- Semi-transparent background for visibility over camera feed

### Center Guide Circle (280x280px)
- Main positioning frame
- Features corner guides for face alignment
- Shows crosshair for center positioning
- Pulses with soft glow when perfect angle achieved
- Subtly visible even when not actively aligned

### Bottom Capture Button
- **Design**: Large circular button (72x72px)
- **Color States**:
  - Gray when not ready
  - Green when ready for capture
- **Ring Effect**: Shows outer ring when perfect angle detected
- **User Guidance**: Text below indicates next action

### Angle Indicators
- Display target ranges
- Show actual vs. target values
- Color-coded feedback (green for good, amber for marginal)
- Icons for quick status recognition

## How Auto-Capture Works

### Detection Flow
```
Face Detection → Extract Landmarks → Calculate Pitch/Yaw
                                            ↓
                                   Check if in target range
                                            ↓
                              Yes → Start 600ms countdown
                                     ↓
                         Countdown completes → Capture image
                                     ↓
                           Trigger haptic feedback
                                     ↓
                           Call onImageCaptured callback
```

### Perfect Angle Requirements
- **Pitch**: Between 42° and 48° (slightly forward head tilt)
- **Yaw**: Between -5° and +5° (face centered)
- **Duration**: Maintained for 600ms before auto-capture

## Customization Options

The `AutoCaptureGuideWidget` can be customized through parameters:

```dart
AutoCaptureGuideWidget(
  currentPitch: 45.0,              // Current head tilt angle
  currentYaw: 2.0,                 // Current face rotation angle
  isPerfectAngle: true,            // Whether angle is perfect
  isCountingDown: false,           // Whether countdown is active
  remainingTime: 0,                // Remaining ms until capture
  minTargetPitch: 42.0,            // Minimum acceptable pitch
  maxTargetPitch: 48.0,            // Maximum acceptable pitch
  maxYawDeviation: 5.0,            // Maximum yaw deviation
  guideSize: 280,                  // Size of circular guide
)
```

### Adjusting Angle Targets
Edit the `AutoCaptureController` in `enhanced_camera_screen.dart`:

```dart
_autoCaptureController = AutoCaptureController(
  minPitch: 42.0,           // Lower pitch limit
  maxPitch: 48.0,           // Upper pitch limit
  maxYawDeviation: 5.0,     // Yaw tolerance
  captureTimerMs: 600,      // Countdown duration
  frameThrottleInterval: 2,  // UI update frequency
);
```

## Integration Details

### Components Used
1. **AutoCaptureController**: Manages auto-capture logic and timers
2. **FaceDetectionService**: Detects face landmarks using ML Kit
3. **HeadPoseCalculator**: Calculates pitch and yaw from landmarks
4. **AutoCaptureGuideWidget**: Displays user interface and guides
5. **EnhancedCameraScreen**: Orchestrates everything together

### Face Detection Pipeline
```
Camera Frame → ML Kit Face Detection → Landmarks Extracted
                           ↓
                  Normalize coordinates
                           ↓
      HeadPoseCalculator (Pitch/Yaw calculation)
                           ↓
         AutoCaptureController (Angle validation)
                           ↓
                  Update UI in real-time
```

## Best Practices for Users

1. **Positioning**: 
   - Keep your face centered in the white circle
   - Slightly tilt your head forward (42-48°)
   - Face directly toward the camera

2. **Lighting**:
   - Ensure adequate lighting for face detection
   - Avoid strong backlighting or shadows

3. **Device Placement**:
   - Hold device at eye level or slightly above
   - Keep device steady to maintain angle

4. **Waiting**:
   - Once you see the green circle and countdown, hold still
   - The app will auto-capture in about 0.6 seconds

## Technical Specifications

### Performance
- Face detection runs at ~10-15 FPS (optimized for smoothness)
- UI updates throttled to reduce battery consumption
- Minimal impact on device resources

### Supported Scenarios
- **Hair Analysis**: Real camera with live face detection
- **Skin Analysis**: Mock camera for demo/testing

### Error Handling
- Gracefully handles lost face detection
- Timer resets if angle drifts out of range
- User can manually tap capture button anytime

## Troubleshooting

### Auto-capture not triggering
- Ensure face is clearly visible to camera
- Check lighting conditions
- Keep head still once in perfect angle
- Allow permission for camera access

### Angle values seem off
- Ensure face landmarks are being detected
- Check camera resolution and quality
- Verify device is upright (not tilted)

### Visual guide not showing
- Restart the camera screen
- Check screen brightness
- Verify camera permissions are granted

## File References

- **Main Widget**: `lib/widgets/auto_capture_guide_widget.dart`
- **Camera Screen**: `lib/screens/enhanced_camera_screen.dart`
- **Face Detection**: `lib/services/face_detection_service.dart`
- **Pose Calculation**: `lib/Models/head_pose_calculator.dart`

## Future Enhancements

Potential improvements for future versions:
- Adjustable angle ranges per analysis type
- Custom haptic feedback patterns
- Voice guidance ("tilt forward", "look left")
- Multiple capture points for better analysis
- Saved photos preview before submission
- A/B testing for optimal angle ranges

---

**Last Updated**: February 17, 2024
**Version**: 1.0
