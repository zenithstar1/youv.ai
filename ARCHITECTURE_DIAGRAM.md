# Architecture & Data Flow Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         MOBILE DEVICE                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    IMAGE CAPTURE SCREEN                         │  │
│  │                 (Enhanced Camera Dialog)                       │  │
│  │                                                                │  │
│  │     ┌──────────────────────────────────────────────────────┐  │  │
│  │     │  Ask user: Standard or Smart Capture               │  │  │
│  │     │  ┌───────────────┐          ┌───────────────────┐ │  │  │
│  │     │  │ Standard      │          │ Smart Capture    │ │  │  │
│  │     │  │ (image_picker)│     OR   │ (enhanced_camera)│ │  │  │
│  │     │  └───────────────┘          └───────────────────┘ │  │  │
│  │     └──────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                              ↓                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │              ENHANCED CAMERA SCREEN                              │  │
│  │         (if Smart Capture selected)                            │  │
│  │                                                                │  │
│  │  ┌────────────────────────────────────────────────────────┐  │  │
│  │  │                                                        │  │  │
│  │  │  📷 CAMERA PREVIEW (live preview from device)        │  │  │
│  │  │                                                        │  │  │
│  │  │  🟢 Green Circle: Manual Capture Button               │  │  │
│  │  │                                                        │  │  │
│  │  │  📊 TOP: Pitch & Yaw Display                          │  │  │
│  │  │     Pitch: 45.2°                                      │  │  │
│  │  │     Yaw: 2.1°                                         │  │  │
│  │  │     (Updated in real-time)                            │  │  │
│  │  │                                                        │  │  │
│  │  │  🎨 BOTTOM: TiltGuidanceWidget                        │  │  │
│  │  │  ┌──────────────────────────────────┐                │  │  │
│  │  │  │     ╭─────╮                      │                │  │  │
│  │  │  │    ╱         ╲                    │                │  │  │
│  │  │  │   ╱           ╲     ← Arc Track  │                │  │  │
│  │  │  │  │    🟢 ●     │    ← Pointer    │                │  │  │
│  │  │  │   ╲ GREEN╱     ╲    ← Glow       │                │  │  │
│  │  │  │    ╲         ╱                    │                │  │  │
│  │  │  │     ╰─────╯                      │                │  │  │
│  │  │  │                                  │                │  │  │
│  │  │  │  Green Zone: 40-50°              │                │  │  │
│  │  │  │  Current: 45° (in range ✓)      │                │  │  │
│  │  │  └──────────────────────────────────┘                │  │  │
│  │  │                                                        │  │  │
│  │  └────────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                              ↓                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │              AUTO-CAPTURE LOGIC (Behind the scenes)             │  │
│  │                                                                │  │
│  │  ┌──────────────────────────────────────────────────────────┐  │  │
│  │  │  1. FACE DETECTION STREAM                               │  │  │
│  │  │     Camera frames → MediaPipe/ML Kit → Landmarks        │  │  │
│  │  │     [x₁, y₁, z₁], [x₂, y₂, z₂], ... [x₄₆₈, y₄₆₈, z₄₆₈]│  │  │
│  │  └──────────────────────────────────────────────────────────┘  │  │
│  │                         ↓                                        │  │
│  │  ┌──────────────────────────────────────────────────────────┐  │  │
│  │  │  2. HEAD POSE CALCULATION (HeadPoseCalculator)          │  │  │
│  │  │                                                          │  │  │
│  │  │  Pitch = arctan(   d(forehead→nose)   ) * 180/π        │  │  │
│  │  │                  d(nose→chin)                           │  │  │
│  │  │                                                          │  │  │
│  │  │  Yaw = (noseX - centerX) / faceWidth * 90              │  │  │
│  │  │                                                          │  │  │
│  │  │  Returns: pitch (0-90°), yaw (-45 to 45°)              │  │  │
│  │  └──────────────────────────────────────────────────────────┘  │  │
│  │                         ↓                                        │  │
│  │  ┌──────────────────────────────────────────────────────────┐  │  │
│  │  │  3. CONDITION CHECK (AutoCaptureController)             │  │  │
│  │  │                                                          │  │  │
│  │  │  IF pitch ∈ [42°, 48°] AND |yaw| < 5°                  │  │  │
│  │  │     └─→ START TIMER (600ms)                            │  │  │
│  │  │     └─→ LOOP: Check conditions continue                │  │  │
│  │  │         IF still in range:                             │  │  │
│  │  │            Timer --                                     │  │  │
│  │  │         ELSE:                                           │  │  │
│  │  │            STOP timer, reset to 0                      │  │  │
│  │  │  ELSE                                                   │  │  │
│  │  │     └─→ STOP TIMER                                     │  │  │
│  │  └──────────────────────────────────────────────────────────┘  │  │
│  │                         ↓                                        │  │
│  │  ┌──────────────────────────────────────────────────────────┐  │  │
│  │  │  4. TIMER COMPLETION                                    │  │  │
│  │  │     IF Timer reaches 0 while conditions met:            │  │  │
│  │  │        a) HapticFeedback.mediumImpact() 📳             │  │  │
│  │  │        b) Call _controller.takePicture()               │  │  │
│  │  │        c) Flash saved to: Image Preview Screen         │  │  │
│  │  └──────────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │              IMAGE PREVIEW SCREEN                               │  │
│  │  (user confirms, sends to analysis)                           │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Real-time Data Flow

```
Camera Frames (30fps)
    ↓
Face Detection Service (MediaPipe/ML Kit)
    ↓
Landmarks (List<List<double>>)
    Index  Landmark
    ├─ 0   Left Eye
    ├─ 1   Nose Tip ◄─ Used for calculations
    ├─ ...
    ├─ 10  Forehead ◄─ Used for calculations
    ├─ ...
    └─ 152 Chin ◄─ Used for calculations
    ↓
HeadPoseCalculator.calculatePitch(landmarks)
    ├─ Extract: forehead_y, nose_y, chin_y
    ├─ Calculate distances
    ├─ Apply arctan formula
    └─ Return: 0-90 degrees
    ↓
AutoCaptureController.updateFaceDetection(landmarks)
    ├─ Store currentPitch = 45.2°
    ├─ Store currentYaw = 2.1°
    ├─ Check: 42 ≤ 45.2 ≤ 48 ✓ AND 2.1 < 5 ✓
    ├─ If true: startTimer()
    ├─ Trigger: onStateChange() callback
    └─ Call: setState() in UI
    ↓
UI Updates
    ├─ Text display: "Pitch: 45.2°"
    ├─ Text display: "Yaw: 2.1°"
    ├─ TiltGuidanceWidget repositions pointer
    └─ If isPerfectAngle: Add glow effect
    ↓
Timer Logic (every 50ms)
    ├─ IF still in perfect range:
    │   └─ remainingTime --
    │       └─ When 0: CAPTURE + haptic
    └─ ELSE:
        └─ Cancel timer, reset
```

## Component Relationships

```
┌─────────────────────────────────────────────────────────┐
│              EnhancedCameraScreen                       │
│  (StatefulWidget: _EnhancedCameraScreenState)          │
└─────────────────────────────────────────────────────────┘
         │
         ├─ Creates → AutoCaptureController
         │              ├─ _currentPitch
         │              ├─ _currentYaw
         │              ├─ _captureTimer
         │              ├─ _remainingTime
         │              └─ Public methods:
         │                 ├─ updateFaceDetection()
         │                 ├─ triggerManualCapture()
         │                 └─ dispose()
         │
         ├─ Creates → StreamController<List<List<double>>>
         │   (Face detection landmarks stream)
         │
         ├─ Renders → TiltGuidanceWidget
         │              └─ Uses CustomPaint
         │                 └─ TiltGuidancePainter
         │                    ├─ Draws arc track
         │                    ├─ Draws target zone
         │                    ├─ Draws pointer
         │                    └─ If perfect: glow
         │
         └─ Uses → HeadPoseCalculator (static class)
                    ├─ calculatePitch(landmarks)
                    ├─ calculateYaw(landmarks)
                    └─ isInTargetPose(...)
```

## State Management

```
AutoCaptureController Internal State:

Initial State:
├─ _currentPitch: 0.0
├─ _currentYaw: 0.0
├─ _captureTimer: null
├─ _remainingTime: 0
└─ _onCapture: null


Face Detected (pitch=45°, yaw=2°):
├─ _currentPitch: 45.0 ✓
├─ _currentYaw: 2.0 ✓
├─ Condition met: start timer
├─ _captureTimer: Timer.periodic(50ms)
├─ _remainingTime: 600
└─ _onStateChange() → setState() → UI updates
    ├─ Draw pointer at 45° on arc
    ├─ Detect: 42 ≤ 45 ≤ 48 AND |2| < 5
    ├─ isPerfectAngle: true
    └─ Activate green glow


Timer Countdown (pending: 500ms):
├─ _remainingTime: 500
└─ TiltGuidanceWidget shows glow still active


Timer Completes (pending: 0ms):
├─ _captureTimer ends
├─ HapticFeedback.mediumImpact() 📳
├─ _onCapture() called
├─ Camera picture taken
└─ Reset to initial state
```

## Perfect Angle Zone

```
                    0°
                   ╱│╲
                 ╱  │  ╲
               ╱    │    ╲
             ╱      │      ╲
        45°╱        │        ╲-45° (YAW)
          ╱         │         ╲
         │◄─────────┼─────────►│  
         │          │          │
         │  -5° ←──┼──→ +5°   │
         │          │          │
         │          │ TARGET   │
         │          │  ZONE    │
         │   42°    │    48°   │  (PITCH)
         │    ◄─────┼─────►    │
         │          │          │
         │◄─────────┼─────────►│
         │          │          │
        -45°╲      │      ╱45°
             ╲     │     ╱
               ╲   │   ╱
                 ╲ │ ╱
                   ╲│╱
                   90°

CONDITION FOR AUTO-CAPTURE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
42.0° ≤ PITCH ≤ 48.0° ✓
AND
-5.0° ≤ YAW ≤ 5.0° ✓
AND
Position held for 600ms ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━
→ CAPTURE + HAPTIC FEEDBACK
```

## Timeline: From Face Detection to Capture

```
T+0ms    │ Face enters detection frame
         │ Landmarks received [x₀,y₀,z₀], ..., [x₄₆₇,y₄₆₇,z₄₆₇]
         │
T+10ms   │ HeadPoseCalculator processes
         │ Calculates: pitch = 41°
         │ ✗ Not in range [42-48°]
         │ Timer NOT started
         │
T+50ms   │ Face adjusts position
         │ New landmarks
         │ pitch = 45° ✓, yaw = 2° ✓
         │ ✓✓ CONDITIONS MET
         │ Timer STARTED (600ms remaining)
         │ UI: Pointer green, glow ON
         │
T+150ms  │ Face stays in position
         │ pitch = 45.1°, yaw = 1.8°
         │ ✓ Still in range
         │ Timer continues: 500ms remaining
         │
T+300ms  │ Face position stable
         │ pitch = 45.2°, yaw = 2.0°
         │ ✓ Still in range
         │ Timer continues: 350ms remaining
         │
T+500ms  │ Face moves
         │ pitch = 51° ✗
         │ ✗ OUT OF RANGE
         │ Timer RESET
         │ UI: Pointer white, glow OFF
         │
T+550ms  │ Face back in range
         │ pitch = 45°, yaw = 2°
         │ ✓✓ CONDITIONS MET AGAIN
         │ Timer RESTARTED (600ms remaining)
         │
T+1150ms │ Face held steady for full 600ms
         │ Timer reaches 0ms
         │ HapticFeedback.mediumImpact() 📳
         │ camera_controller.takePicture()
         │ Image saved
         │ → ImagePreviewScreen
         │
```

This completes the entire system visualization! 🎯
