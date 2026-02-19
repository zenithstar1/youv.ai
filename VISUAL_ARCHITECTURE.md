# 📊 Visual Guide - Auto-Capture Angle Detection Flow

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Android Device (Phone)                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐                  ┌────────────────────┐   │
│  │   Camera     │       30fps       │  FaceDetectionSvc │   │
│  │  (Front)     │─────────────────→ │  (ML Kit Plugin)   │   │
│  └──────────────┘                  └────────────────────┘   │
│         ▲                                   │                │
│         │                                   │ Detect 10      │
│         │ Video                             │ landmarks      │
│         │ Stream                            ▼                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         EnhancedCameraScreen                         │  │
│  │                                                      │  │
│  │  ┌─────────────────────────────────────────────┐   │  │
│  │  │  updateFaceDetection(landmarks)             │   │  │
│  │  │  ┌──────────────────────────────────────┐  │   │  │
│  │  │  │ HeadPoseCalculator.calculatePitch()  │  │   │  │
│  │  │  │  ┌─ Check: 10 landmarks? ✓          │  │   │  │
│  │  │  │  ├─ Use ML Kit algorithm             │  │   │  │
│  │  │  │  └─ Return: 45.2°                    │  │   │  │
│  │  │  └──────────────────────────────────────┘  │   │  │
│  │  │  ┌──────────────────────────────────────┐  │   │  │
│  │  │  │ HeadPoseCalculator.calculateYaw()    │  │   │  │
│  │  │  │  ┌─ Check: 10 landmarks? ✓          │  │   │  │
│  │  │  │  ├─ Use ML Kit algorithm             │  │   │  │
│  │  │  │  └─ Return: 2.1°                     │  │   │  │
│  │  │  └──────────────────────────────────────┘  │   │  │
│  │  │                                             │   │  │
│  │  │  _currentPitch = 45.2°                      │   │  │
│  │  │  _currentYaw = 2.1°                         │   │  │
│  │  │  isPerfectAngle = true ✓                    │   │  │
│  │  └─────────────────────────────────────────────┘   │  │
│  │          ↓                                          │  │
│  │  AutoCaptureController                             │  │
│  │  ├─ Check: isPerfectAngle?                         │  │
│  │  │  └─ Start 600ms countdown timer                 │  │
│  │  │                                                 │  │
│  │  └─ Countdown expires?                             │  │
│  │     └─ Trigger auto-capture callback               │  │
│  │        └─ takePicture() → Save image               │  │
│  └──────────────────────────────────────────────────────┘  │
│         ▲                                   │                │
│         │                                   │ Angles         │
│         │ Circle color                      │ & timer        │
│         │ Countdown                         ▼                │
│  ┌──────────────────────────────────────────────────┐      │
│  │         AutoCaptureGuideWidget                   │      │
│  │  ┌──────────────────────────────────────────┐   │      │
│  │  │  _buildMainGuideCircle()                 │   │      │
│  │  │  ├─ Color: isPerfectAngle?               │   │      │
│  │  │  │  ├─ true  → Amber                     │   │      │
│  │  │  │  └─ false → White                     │   │      │
│  │  │  └─ Countdown active?                    │   │      │
│  │  │     └─ true → Green + Progress ring      │   │      │
│  │  └──────────────────────────────────────────┘   │      │
│  │  ┌──────────────────────────────────────────┐   │      │
│  │  │  _buildStatusText()                      │   │      │
│  │  │  └─ Display: "Tilt your head to 45°"    │   │      │
│  │  └──────────────────────────────────────────┘   │      │
│  │  ┌──────────────────────────────────────────┐   │      │
│  │  │  _buildAngleIndicators()                 │   │      │
│  │  │  └─ Show: Pitch: 45.2°                   │   │      │
│  │  └──────────────────────────────────────────┘   │      │
│  │  ┌──────────────────────────────────────────┐   │      │
│  │  │  _buildCountdownTimer()                  │   │      │
│  │  │  └─ Show: 600ms → 0ms progress           │   │      │
│  │  └──────────────────────────────────────────┘   │      │
│  └──────────────────────────────────────────────────┘      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## ML Kit Landmark Positions (10 Points)

```
                   Camera View
      ┌──────────────────────────────────────┐
      │                                       │
      │          1———[1]———2                 │
      │          ╱           ╲                │
      │         ╱             ╲               │
      │        3             4                │
      │        │             │                │
      │        │      [0]    │                │
      │        │      Nose   │                │
      │        │             │                │
      │         ╲             ╱               │
      │          ╲           ╱                │
      │          5———[5][6]——6                │
      │                                       │
      │          [7]         [8]              │
      │                                       │
      │          [9]                          │
      │                                       │
      └──────────────────────────────────────┘

Legend:
  [0] = Nose (pitch + yaw calculations)
  [1] = Left Eye (pitch calculation)
  [2] = Right Eye (pitch calculation)
  [3] = Left Ear (yaw center reference)
  [4] = Right Ear (yaw center reference)
  [5] = Left Mouth Corner (pitch calculation)
  [6] = Right Mouth Corner (pitch calculation)
  [7] = Left Shoulder (body position, not used)
  [8] = Right Shoulder (body position, not used)
  [9] = Left Hip (body position, not used)

Pitch uses vertical distances: Eyes ↔ Nose ↔ Mouth
Yaw uses horizontal position: Nose relative to (Ears)
```

---

## Angle Normal Ranges

```
PITCH (Head Tilt Forward/Backward)
┌─────────────────────────────────────────┐
│  0°    10°   20°   30°   40°   50°  60° │
│  ├─────┼────┼────┼────┼────┴───┼──────┤ │
│  │Upright       Forward       HAIR     │Extreme│
│  │                            ZONE    │Tilt  │
│                                        │
│  ✗                ✗        ✓ ✓ ✓       ✗
│  Requires tilt   Too slight  OPTIMAL   Too much
│ 45° forward                  40-50°    tilt
└─────────────────────────────────────────┘

YAW (Head Rotation Left/Right)
┌──────────────────────────────────────────┐
│-45°  -30°  -15°   0°   +15°  +30°  +45° │
│├─────┼────┼─────┼──┼─────┼────┼─────┤   │
│Left    Acceptable  CENTER  Acceptable Right
│extreme  range      FACING   range    extreme
│                             
│ ✗      ✓ ✓ ✓     ✓ ✓      ✓ ✓ ✓      ✗
│ Too    HAIR-    OPTIMAL  HAIR-    Too
│ far    ZONE              ZONE     far
│ left                            right
└──────────────────────────────────────────┘
```

---

## Angle Detection Workflow

```
FRAME: Camera captures user's face

         │
         ▼
    ┌─ Face Detector ─┐
    │ (ML Kit plugin) │
    └─────────────────┘
         │
         ▼ (10 landmarks)
    ├─ Nose:        (402, 380)
    ├─ Left Eye:    (350, 340)
    ├─ Right Eye:   (450, 340)
    ├─ Left Ear:    (300, 350)
    ├─ Right Ear:   (500, 350)
    ├─ Left Mouth:  (380, 430)
    ├─ Right Mouth: (420, 430)
    ├─ L Shoulder:  (280, 480)
    ├─ R Shoulder:  (520, 480)
    └─ Left Hip:    (280, 520)

         │
         ▼ Extract relevant coordinates
    ┌─ Calculate PITCH ─────────┐
    │ Eye Y:          340       │
    │ Nose Y:         380       │
    │ Mouth Y:        430       │
    │                           │
    │ Eye-to-Nose:    40 px     │
    │ Nose-to-Mouth:  50 px     │
    │ Ratio:          0.8       │
    │ atan(0.8) × 180/π = 38.7° │
    │ Scaled:       46.4°  ✓   │
    └─────────────────────────────┘
                │
         ┌──────▼──────┐
         │              │
         ▼              ▼
    ┌─ Calculate YAW ──────┐
    │ Nose X:        402   │
    │ Ear L X:       300   │
    │ Ear R X:       500   │
    │ Face center:   400   │
    │ Offset:        2     │
    │ Width:         200   │
    │ (2/200) × 90 = 0.9° │
    │ Result:       +0.9° ✓│
    └──────────────────────┘

         │
         ▼
    Is Pitch 40-50°?  ✓ YES (46.4°)
    Is |Yaw| ≤ 15°?   ✓ YES (0.9°)
         │
         ├─ BOTH YES → Perfect Angle! ✓
         │
         ▼
    Start Countdown (600ms)
         │
         ├─ 600ms remains... circle turns AMBER
         ├─ 300ms remains... circle stays AMBER
         ├─ 0ms remains... countdown complete
         │
         ▼
    Trigger Auto-Capture
         │
         ├─ Take picture from camera
         ├─ Save to gallery
         ├─ Show confirmation
         │
         ▼
    "✓ Hair photo captured! Processing..."
```

---

## State Transitions

```
┌────────────────┐
│  No Face       │ ← Camera sees empty frame
│ (Pitch=0°)     │   Circle: WHITE
│ (Yaw=0°)       │   State: Searching
└────────────────┘
         │
         │ Face appears
         ▼
┌────────────────┐
│ Face Upright   │ ← User looking straight (tilt near 0°)
│ (Pitch=15°)    │   Circle: WHITE
│ (Yaw=0°)       │   State: Waiting for tilt
└────────────────┘
         │
         │ User tilts head
         ▼
┌────────────────┐
│ Head Tilting   │ ← User gradually tilts forward
│ (Pitch=35°)    │   Circle: WHITE (not in range yet)
│ (Yaw=5°)       │   State: Keep tilting...
└────────────────┘
         │
         │ Reaches optimal angle
         ▼
┌────────────────────┐
│ Perfect Angle      │ ← Angle in 40-50° range & ±15° yaw
│ (Pitch=45.2°)      │   Circle: AMBER
│ (Yaw=2.1°)         │   State: Starting countdown...
└────────────────────┘
         │
         ├─ Hold angle for 600ms
         │
         ▼
┌────────────────────┐
│ Capturing          │ ← Countdown progressing
│ (Pitch=45.2°)      │   Circle: GREEN with progress ring
│ (Yaw=2.1°)         │   State: Countdown 300ms remaining...
└────────────────────┘
         │
         ├─ Countdown complete
         │
         ▼
┌────────────────────┐
│ Auto-Captured!     │ ← Image saved to gallery
│ Ready for next     │   Circle: GREEN (briefly shows ✓)
│                    │   State: "Hair photo captured!"
└────────────────────┘
         │
         │ Move face away or exit
         ▼
┌────────────────┐
│ No Face        │ ← Ready for next capture
│ (Reset)        │   Circle: WHITE
│ (Pitch=0°)     │   State: Searching...
└────────────────┘
```

---

## Color Indicator Legend

```
Circle Guide Colors:
┌─────────────────────────────────────────────┐
│ WHITE                                       │
│ ─────                                       │
│ ●  Face not in perfect angle                │
│    Reasons: Tilt too shallow, too extreme   │
│    Action: Adjust head position             │
│                                             │
│ AMBER                                       │
│ ─────                                       │
│ ●  Head angle in perfect range!             │
│    Condition: 40-50° pitch AND ±15° yaw    │
│    Starting: Countdown timer                │
│    Action: Hold position!                   │
│                                             │
│ GREEN                                       │
│ ─────                                       │
│ ●  Countdown active, capturing image        │
│    Progress: Circular ring depletes         │
│    Time: 600ms → 0ms                        │
│    Action: Continue holding position!       │
│                                             │
│ GREEN ✓                                     │
│ ─────                                       │
│ ●  Capture complete!                        │
│    Status: Image saved to gallery           │
│    Next: Ready for another capture          │
└─────────────────────────────────────────────┘
```

---

## Performance Metrics Timeline

```
TIME    COMPONENT              WORK
────────────────────────────────────────────────
  0ms   Camera Frame           Capture video
────────────────────────────────────────────────
  ↓     Face Detector         Process landmark detection
 +100ms (ML Kit GPU)           Return 10 landmarks
────────────────────────────────────────────────
  ↓     HeadPoseCalculator   Calculate pitch & yaw
 +1ms   (Simple math)          Return angles
────────────────────────────────────────────────
  ↓     AutoCaptureController Check if angles perfect
 +1ms   (Simple comparison)    Update state
────────────────────────────────────────────────
  ↓     UI Update              Re-render widget
 +5ms   (Flutter layer)        Update circle color
────────────────────────────────────────────────
        Next Frame             (~30ms total for 30fps)
```

---

## Data Flow Summary

```
Input:  30fps camera stream
         ↓
Process: Face Detection (10 landmarks)
         ↓
         Pitch = atan(eyeToNose / noseToMouth) × 180/π
         Yaw = (noseX - faceCenter) / faceWidth × 90
         ↓
Logic:   if (40° ≤ pitch ≤ 50°) AND (|yaw| ≤ 15°)
           Start 600ms countdown timer
         ↓
Output:  UI updates + auto-capture after countdown
         ↓
Result:  Image saved to gallery
```

---

This is the complete visual architecture of the angle detection system!
