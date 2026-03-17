# 🔬 Technical Reference - ML Kit Face Landmarks & Angle Detection

## ML Kit Landmark Mapping

Google ML Kit Face Detection returns exactly **10 landmarks**:

| Index | Type | X Range | Y Range | Purpose |
|-------|------|---------|---------|---------|
| 0 | Nose Tip | 0.3-0.7 | 0.4-0.5 | Center reference point |
| 1 | Left Eye | 0.2-0.4 | 0.3-0.45 | Head tilt (Y), head rotation (X) |
| 2 | Right Eye | 0.6-0.8 | 0.3-0.45 | Head tilt (Y), head rotation (X) |
| 3 | Left Ear | 0.0-0.2 | 0.2-0.6 | Face width reference (X) |
| 4 | Right Ear | 0.8-1.0 | 0.2-0.6 | Face width reference (X) |
| 5 | Left Mouth Corner | 0.2-0.45 | 0.55-0.7 | Head tilt (Y) |
| 6 | Right Mouth Corner | 0.55-0.8 | 0.55-0.7 | Head tilt (Y) |
| 7 | Left Shoulder | 0.0-0.3 | 0.7-1.0 | Body position (not used for head pose) |
| 8 | Right Shoulder | 0.7-1.0 | 0.7-1.0 | Body position (not used for head pose) |
| 9 | Left Hip | 0.0-0.3 | 0.9-1.0 | Body position (not used for head pose) |

**Normalization:** Coordinates are in pixel units, not normalized (0-1)

---

## Pitch (Head Tilt Forward/Backward)

### ML Kit Formula
```
Pitch = atan(eyeToNose / noseToMouth) × 180/π
```

### Calculation Steps
1. Get average eye Y position: `avgEyeY = (landmarks[1].y + landmarks[2].y) / 2`
2. Get nose Y position: `noseY = landmarks[0].y`
3. Get average mouth Y position: `avgMouthY = (landmarks[5].y + landmarks[6].y) / 2`
4. Calculate distances (absolute, non-negative):
   - `eyeToNose = |noseY - avgEyeY|`
   - `noseToMouth = |avgMouthY - noseY|`
5. Calculate ratio: `ratio = eyeToNose / noseToMouth`
6. Convert to angle: `pitch = atan(ratio) × 180/π`
7. Optionally scale: `pitch = pitch × 1.2` (optional, for better feedback)
8. Clamp to range: `pitch = clamp(pitch, 0, 90)`

### Interpretation
- **Pitch ≈ 0-20°**: Head upright or tilted back
- **Pitch ≈ 30-40°**: Head slightly tilted forward
- **Pitch ≈ 45-50°**: Head at optimal 45° angle (SAFE for hair analysis)
- **Pitch > 60°**: Head very tilted forward (chin touching chest)

### Geometry Explanation
When user tilts head forward 45°:
- Forehead moves closer to nose
- Chin moves away from nose
- Eye-to-nose distance increases relative to nose-to-mouth distance
- Therefore `ratio` increases → `pitch` increases

---

## Yaw (Head Rotation Left/Right)

### ML Kit Formula
```
Yaw = (noseX - faceCenter) / faceWidth × 90
faceCenter = (leftEarX + rightEarX) / 2
```

### Calculation Steps
1. Get nose X position: `noseX = landmarks[0].x`
2. Get left ear X position: `leftEarX = landmarks[3].x`
3. Get right ear X position: `rightEarX = landmarks[4].x`
4. Calculate face center: `faceCenter = (leftEarX + rightEarX) / 2`
5. Calculate offset: `offsetX = noseX - faceCenter`
6. Calculate face width: `faceWidth = |rightEarX - leftEarX|`
7. Normalize: `normalizedOffset = offsetX / faceWidth`
8. Convert to angle: `yaw = normalizedOffset × 90`
9. Clamp to range: `yaw = clamp(yaw, -45, 45)`

### Interpretation
- **Yaw = -45°**: Head rotated extreme left
- **Yaw = -15°**: Head rotated left (acceptable for hair analysis)
- **Yaw ≈ 0°**: Head directly facing camera (PERFECT)
- **Yaw = +15°**: Head rotated right (acceptable for hair analysis)
- **Yaw = +45°**: Head rotated extreme right

### Geometry Explanation
- Nose at face center → `yaw ≈ 0°` (facing camera)
- Nose left of center → negative yaw (head rotated left)
- Nose right of center → positive yaw (head rotated right)

---

## Hair Analysis Optimal Angles

For hair analysis capture, optimal angles are:
```
Pitch: 40° - 50°  (head tilted forward, but not extreme)
Yaw:   ±15°       (slight head rotation acceptable)
```

These angles ensure:
- Hair visible and properly positioned for analysis
- Face not extreme angle (maintains natural appearance)
- Lighting consistent across hair
- All relevant hair regions visible

---

## Debugging Landmark Values

### Good Face Detection
```
Landmark 0 (nose):    X ∈ [300-400], Y ∈ [350-400]
Landmark 1 (L eye):   X ∈ [250-320], Y ∈ [310-360]
Landmark 2 (R eye):   X ∈ [380-450], Y ∈ [310-360]
Landmark 3 (L ear):   X ∈ [150-250], Y ∈ [300-400]
Landmark 4 (R ear):   X ∈ [450-550], Y ∈ [300-400]
Landmark 5 (L mouth): X ∈ [270-330], Y ∈ [400-450]
Landmark 6 (R mouth): X ∈ [370-430], Y ∈ [400-450]
```

### Bad Face Detection (All Zeros)
```
All landmarks: X = 0, Y = 0
→ Face not detected despite empty list
→ Check camera resolution, lighting, or face visibility
```

### Partial Detection (Some Landmarks Missing)
```
landmarks[1-6] have values, landmarks[7-9] are zero
→ Shoulders/hips outside frame (normal, these aren't used anyway)
→ Face landmarks valid, can proceed with angle calculation
```

---

## Common Issues & Solutions

### Issue 1: Pitch Always 0.0°
**Debug:**
```
Check if landmarks[0].y == landmarks[1].y == landmarks[5].y
→ If all Y coordinates identical: face detected but marked as flat
→ Try moving closer to camera, ensure good lighting
```

### Issue 2: Yaw Always 0.0°
**Debug:**
```
Check if landmarks[0].x == (landmarks[3].x + landmarks[4].x) / 2
→ If nose perfectly centered: either perfect alignment or bad detection
→ Verify landmarks[3] and [4] have different X values
→ If ears at same X position: face detector issue
```

### Issue 3: Angles Jump Wildly
**Debug:**
```
Verify face is clearly visible in camera (80%+ of frame)
Ensure consistent lighting (no shadows on face)
Reduce frame processing speed (process every Nth frame instead of every frame)
Filter angles with Kalman filter or moving average
```

### Issue 4: Countdown Starts Too Early/Late
**Debug:**
```
Adjust minPitch and maxPitch in AutoCaptureController:
- minPitch: 40.0 (lower = start countdown at shallower angle)
- maxPitch: 50.0 (higher = allow countdown up to this angle)

Default is 40-50° for hair analysis.
For face analysis, might be 30-40°.
```

---

## Performance Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| Face Detection | ~100ms | Per frame with GPU acceleration |
| Landmark Extraction | ~50ms | Included in face detection |
| Angle Calculation | <1ms | Simple math operations |
| Update Frequency | 30fps* | Camera stream frequency (*depends on device) |
| Effective Update Rate | ~15fps* | With frame throttling (every 2nd frame) |
| Countdown Accuracy | ±50ms | System timer precision |

---

## Testing Angle Ranges

Use these angle values for testing:

```dart
// Test Case 1: Perfect Angle (should trigger auto-capture)
pitch: 45.0,
yaw: 0.0,
// Expected: isPerfectAngle = true ✓

// Test Case 2: Slightly Left
pitch: 45.0,
yaw: -10.0,
// Expected: isPerfectAngle = true (within ±15°) ✓

// Test Case 3: Too Far Left
pitch: 45.0,
yaw: -20.0,
// Expected: isPerfectAngle = false ✗

// Test Case 4: Tilted Back
pitch: 30.0,
yaw: 0.0,
// Expected: isPerfectAngle = false (< 40°) ✗

// Test Case 5: Tilted Forward (Good)
pitch: 48.0,
yaw: 5.0,
// Expected: isPerfectAngle = true ✓

// Test Case 6: Extreme Forward
pitch: 75.0,
yaw: 0.0,
// Expected: isPerfectAngle = false (> 50°) ✗
```

---

## ML Kit vs MediaPipe Comparison

| Feature | ML Kit | MediaPipe |
|---------|--------|-----------|
| Landmarks | 10 points | 468 points |
| Latency | ~100ms | ~200-300ms |
| Accuracy | Good for head pose | Excellent facial detail |
| Dependencies | google_mlkit_face_detection | google_ml_kit (different package) |
| Hair Analysis Support | ✅ Works perfectly | ✅ Over-engineered |
| Recommended | ✅ For this use case | For facial expressions/micro-movements |

**Conclusion:** ML Kit's 10 landmarks are **sufficient and optimal** for hair analysis angle detection.

---

## References

- [Google ML Kit Face Detection](https://developers.google.com/ml-kit/vision/face-detection/android)
- [Face Landmark Indices](https://developers.google.com/ml-kit/vision/face-detection#landmarks)
- [Head Pose Estimation from Landmarks](https://arxiv.org/pdf/1706.00253.pdf)
