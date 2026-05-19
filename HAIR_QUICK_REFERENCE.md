# Hair Analysis Auto-Capture - Quick Reference

## 🎯 Perfect Angle Requirements

| Parameter | Min | Max | Unit | Status |
|-----------|-----|-----|------|--------|
| Pitch (forward tilt) | 42 | 48 | degrees | ✅ Implemented |
| Yaw (horizontal center) | -5 | +5 | degrees | ✅ Implemented |
| Hold duration | 600 | 600 | milliseconds | ✅ Implemented |

## 🔄 Complete Hair Capture Flow

```
Step 1: User taps "Hair Analysis" on Analysis Type Screen
    ↓
Step 2: Sees hair capture tips on ImageCaptureScreen
    ↓
Step 3: Taps "Open Camera"
    ↓
Step 4: EnhancedCameraScreen opens AUTOMATICALLY
    (No dialog, directly to smart capture)
    ↓
Step 5: See real-time guidance:
    • Tilt guidance arc (white pointer initially)
    • Pitch/Yaw values (top)
    • Status (orange = "adjust", green = "perfect")
    • Hair-specific text
    ↓
Step 6: User adjusts head position:
    • Tilt head slightly forward (42-48°)
    • Keep head centered (±5°)
    ↓
Step 7: When perfect angle reached:
    • Pointer turns GREEN
    • Glow effect activates
    • Status turns GREEN
    • 600ms timer starts
    • Button turns GREEN
    ↓
Step 8: Hold position for 600ms
    • If position maintained: continues counting
    • If head moves out of range: timer resets
    ↓
Step 9: Auto-capture triggered!
    • 📳 Haptic feedback (medium impact)
    • ✓ "Hair photo captured! Processing..."
    ↓
Step 10: ImagePreviewScreen shows captured photo
    ↓
Step 11: User confirms or retakes
    ↓
Step 12: Hair analysis begins
```

## 👁️ What User Sees on Screen

### Hair Capture Screen Layout

```
┌─────────────────────────────────────┐
│ ✕                                   │  Back Button
│                                     │
│  STATUS BAR (Top):              │
│  ┌─────────────────────────────├┤  
│  │ ✓ Perfect position!...      │
│  │ Pitch: 45.2°  Yaw: 2.1°     │
│  │ ████████░░ (600ms timer)    │
│  └─────────────────────────────┘
│                                     │
│  ╔═════════════════════════════╗   │
│  ║   📷 LIVE CAMERA PREVIEW    ║   │  Camera Feed
│  ║                             ║   │
│  ║                             ║   │
│  ╚═════════════════════════════╝   │
│                                     │
│  GUIDED INSTRUCTIONS (Bottom):   │
│  ┌─────────────────────────────┐  │
│  │  📍 Position your scalp     │  │  Hair-specific
│  │  Keep head tilted forward   │  │  text
│  │                             │  │
│  │    ╭─────────╮              │  │
│  │   ╱    🟢     ╲             │  │  Tilt guidance
│  │  │  ● GLOW    │             │  │  with pointer
│  │   ╲           ╱             │  │
│  │    ╰─────────╯              │  │
│  │   ═══ 40-50° ═══            │  │
│  │                             │  │
│  │  Stay in position 600ms     │  │
│  │          🟢                  │  │  Green button
│  └─────────────────────────────┘  │
└─────────────────────────────────────┘
```

## 🟢 Status Indicators

### When IN PERFECT RANGE (Green Zone)
```
Text: "✓ Perfect position! Staying steady..." (GREEN)
Color: Green background
Pointer: GREEN with GLOW effect
Button: GREEN (elevated shadow)
Pitch: Shows angle in GREEN text
Yaw: Shows angle in GREEN text
Timer: Progress bar visible and filling
```

### When OUT OF RANGE (Orange Zone)
```
Text: "○ Adjust angle to target zone" (ORANGE)
Color: Orange background
Pointer: WHITE (no glow)
Button: BROWN (normal elevation)
Pitch: Shows angle in WHITE text
Yaw: Shows angle in WHITE text
Timer: Hidden (not counting)
```

## 📊 Real-Time Feedback

### Pitch Angle (Forward Tilt)
```
35° (Too high - face down)  → WHITE (not ready)
42° (Minimum)               → GREEN (starting zone)
45° (Perfect center)        → GREEN (ideal)
48° (Maximum)               → GREEN (ending zone)
52° (Too low - face up)     → WHITE (not ready)
```

### Yaw Angle (Head Centering)
```
-10° (Head far left)    → WHITE (not ready)
-5° (Slight left)       → GREEN (edge of range)
0° (Perfectly centered) → GREEN (ideal)
+5° (Slight right)      → GREEN (edge of range)
+10° (Head far right)   → WHITE (not ready)
```

## ⏱️ 600ms Timeline

```
T+0ms    : Perfect angle detected, timer STARTS
T+50ms   : Pointer GREEN, glow ON
T+150ms  : Status GREEN, button GREEN
T+300ms  : Halfway through countdown
T+450ms  : Nearing completion (³⁄₄ full progress bar)
T+600ms  : ✓ TIMER COMPLETE!
           • HapticFeedback.mediumImpact() 📳
           • Camera takes picture
           • Snackbar: "✓ Hair photo captured!"
           • Navigate to ImagePreviewScreen
```

## ✨ Visual Feedback Timeline

```
Not in Range:
WHITE pointer  →  White pointer zone  →  No glow
Brown button   →  Regular elevation   →  Manual only

↓ (User adjusts position)

Enters Range:
WHITE pointer  →  Turns GREEN  →  Glow effect ON
Brown button   →  Turns GREEN  →  Elevated effect ON
Timer          →  Starts       →  Progress bar appears

↓ (600ms passes)

Complete:
GREEN glow   →  Maintains  →  📳 Haptic fires!
Auto-capture →  Triggered →  Photo saved
```

## 🎬 Frame Animation (60fps)

```
Each frame (~16ms):
    1. Get face landmarks from camera
    2. Calculate pitch & yaw
    3. Update AutoCaptureController
    4. UI refreshes:
        • Pointer position on arc
        • Angle values updated
        • Glow intensity (if perfect)
        • Progress bar (if timing)
    5. Back to step 1
```

## 📱 Button States

### Manual Capture Button

**Not Ready (Brown):**
```
🔘 BROWN BUTTON
   • Regular elevation (shadow: 2)
   • Tap to capture anytime
   • Not auto-capturing yet
```

**Ready (Green):**
```
🟢 GREEN BUTTON
   • Elevated (shadow: 8)
   • Auto-captures soon (if held steady)
   • Can also tap to capture immediately
```

## 🎨 Color Palette

| Element | Color | Hex | Usage |
|---------|-------|-----|-------|
| Perfect Status | Green | #00FF00 | Perfect angle zone |
| Adjust Status | Orange | #FF8800 | Out of range |
| Pointer (Ready) | Green | #00FF00 | Head in perfect angle |
| Pointer (Waiting) | White | #FFFFFF | Waiting for angle |
| Glow Effect | Light Green | #00FF00 + blur | Perfect angle feedback |
| Progress Bar | Green | #00FF00 | Timer countdown |
| Button (Ready) | Green | #00FF00 | Can capture |
| Button (Waiting) | Brown | #6B3E3E | Manual capture only |
| Background | Black | #000000 | Camera preview area |

## 🔊 Haptic Feedback

```
Trigger: When 600ms timer completes
Type: HapticFeedback.mediumImpact()
Duration: ~50ms vibration
Phone: Light shake/buzz feedback
Purpose: Confirms auto-capture triggered
```

## 📝 Instruction Messages

### Top Status Bar
- **Perfect:** "✓ Perfect position! Staying steady..."
- **Out of Range:** "○ Adjust angle to target zone"

### Bottom Guidance
- **Hair-specific Title:** "📍 Position your scalp"
- **Hair-specific Subtitle:** "Keep your head tilted slightly forward"
- **Fallback (if no face):** "Tilt head slightly forward (42-48°) and center it"

## ❌ Error Handling

| Situation | Message | Recovery |
|-----------|---------|----------|
| No face detected | Status: orange | "Adjust angle to target zone" |
| Pitch too low | Pitch: WHITE | Tilt head more forward |
| Pitch too high | Pitch: WHITE | Reduce head tilt |
| Yaw too left | Yaw: WHITE | Move head right |
| Yaw too right | Yaw: WHITE | Move head left |
| Position lost mid-capture | Timer resets | Re-center head |

## 🎯 Hair Capture Tips (From Intro Screen)

1. **Use even, diffuse lighting** (avoid harsh shadows)
2. **Part or lift hair to expose scalp clearly** (show scalp area)
3. **Keep head centered in frame** (don't lean)
4. **Tilt slightly forward** (42-48° angle)
5. **Remove accessories** (hats, clips, etc.)
6. **Use dry hair** (not wet or oily)

## ✅ Verification Checklist

- [ ] Hair analysis directly opens EnhancedCameraScreen (no dialog)
- [ ] Tilt guidance arc visible with proper colors
- [ ] Pointer moves smoothly as head tilts
- [ ] Status changes from orange to green when in range
- [ ] Button changes from brown to green when ready
- [ ] Glow effect activates when perfect angle reached
- [ ] 600ms timer counts down visibly
- [ ] Haptic feedback feels strong enough (medium impact)
- [ ] Auto-capture triggers at 600ms
- [ ] Photo saves and preview shown
- [ ] Manual button works as fallback

---

**Hair analysis auto-capture is now LIVE!** 🚀💇‍♂️
