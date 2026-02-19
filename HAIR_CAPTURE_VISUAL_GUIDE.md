# Hair Capture Visual Guide & Timeline

## What Hair Analysis Users Will Experience

### Journey Map

```
┌──────────────────────────────────────────────────────────────────────┐
│                         HAIR ANALYSIS FLOW                           │
└──────────────────────────────────────────────────────────────────────┘

STEP 1: Hair Analysis Started
┌─────────────────────────────────────────┐
│  👤 Analysis Type Screen                │
│                                         │
│  □ Hair Analysis                        │
│    ├─ Hair Density & Scalp              │
│    ├─ DHT-related Hair Loss             │
│    └─ Hair Root Analysis                │
│                                         │
│  [Tap Hair Analysis]                    │
│         ↓                               │
└─────────────────────────────────────────┘

STEP 2: Capture Instructions
┌─────────────────────────────────────────┐
│  💡 How to take a great shot            │
│                                         │
│  ✓ Allow camera access when prompted    │
│  ✓ Use even, diffuse lighting           │
│  ✓ Part or lift hair to expose scalp    │
│  ✓ Keep the head centered & steady      │
│  ✓ Remove accessories/hats              │
│  ✓ Capture dry hair                     │
│                                         │
│  [Got it!]                              │
│         ↓                               │
└─────────────────────────────────────────┘

STEP 3: Choose Capture Method
┌─────────────────────────────────────────┐
│  Start your hair scan                   │
│                                         │
│  [🎥 Open Camera]                       │
│     (Auto-selects Smart Capture)        │
│         ↓                               │
│  [📁 Upload from device]                │
└─────────────────────────────────────────┘

STEP 4: Smart Capture Screen (NEW!)
┌─────────────────────────────────────────┐
│  ✕                  ✓ Perfect position! │
│  Pitch:45.2° Yaw:2.1°  [progress bar] │
│                                         │
│  ╔═════════════════════════════════╗  │
│  ║  📷 LIVE CAMERA PREVIEW        ║  │
│  ║                               ║  │
│  ║     [User's scalp here]       ║  │
│  ║                               ║  │
│  ╚═════════════════════════════════╝  │
│                                         │
│      📍 Position your scalp             │
│    Keep your head tilted forward        │
│                                         │
│      ╭──────────────╮                  │
│     ╱    🟢 ● (GREEN) ╲                │ ← PERFECT!
│    │   (GLOW effect)  │               │   Pointer turns
│     ╲                ╱                 │   green & glows
│      ╰──────────────╯                  │
│   ════ 40-50° Zone ════                │
│                                         │
│  Stay in position for 600ms...          │
│                                         │
│            🟢 (GREEN BUTTON)            │
│                                         │
└─────────────────────────────────────────┘
         ↓ (600ms auto-capture)
    [📳 HAPTIC FEEDBACK]
         ↓

STEP 5: Image Captured!
┌─────────────────────────────────────────┐
│  ✓ Hair photo captured! Processing...  │
│                                         │
│  (Processing screen with spinner)       │
│  Analyzing your hair...                 │
│         ↓                               │
└─────────────────────────────────────────┘

STEP 6: Preview & Confirm
┌─────────────────────────────────────────┐
│  📷 PREVIEW                             │
│                                         │
│  [Captured hair image here]             │
│                                         │
│  [✓ Looks good] [🔄 Retake]             │
│         ↓                               │
└─────────────────────────────────────────┘

STEP 7: Hair Analysis Results
┌─────────────────────────────────────────┐
│  🔬 Hair Analysis Results               │
│                                         │
│  Density Grade: 4/5 ████               │
│  ├─ Hair Density: HIGH DENSITY          │
│  ├─ Scalp Health: GOOD                  │
│  └─ Root Condition: HEALTHY             │
│  Recommendations:                       │
│  • Maintain current routine              │
│  • Stay hydrated                         │
│  • Use gentle hair products              │
│         ↓                               │
└─────────────────────────────────────────┘
```

## Real-Time Capture Experience (600ms Timeline)

### T+0ms - User in wrong position

```
┌──────────────────────────────────┐
│ ○ Adjust angle to target zone    │ ← Orange status
│ Pitch: 35.2° ✗ Yaw: 1.2°        │ (out of range)
└──────────────────────────────────┘

    ╭──────────╮
   ╱            ╲
  │  WHITE ●    │ ← Pointer is WHITE
   ╲  (no glow) ╱   (not perfect)
    ╰──────────╯
   ═══ 40-50° ═══

Instruction: Tilt head slightly forward
         (42-48°) and center it

🔘 Brown button (not ready)
```

### T+50ms - User tilting head correctly

```
┌──────────────────────────────────┐
│ ✓ Perfect position! Staying...   │ ← Green status
│ Pitch: 42.5° ✓ Yaw: 2.1° ✓      │ (in range!)
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ (0% progress)
└──────────────────────────────────┘

    ╭──────────╮
   ╱    🟢      ╲
  │  (GREEN)    │ ← Pointer TURNS GREEN
   ╲  ● GLOW    ╱   Glow effect ON
    ╰──────────╯
   ═══ 40-50° ═══

Timer started! Hold still...

🟢 Green button (ready!)
```

### T+300ms - Still in perfect position (50% of 600ms)

```
┌──────────────────────────────────┐
│ ✓ Perfect position! Staying...   │
│ Pitch: 45.0° ✓ Yaw: 1.8° ✓      │
│ ████████████████░░░░░░░░░░░░░░░░│ (50% progress)
└──────────────────────────────────┘

    ╭──────────╮
   ╱    🟢      ╲
  │  (GREEN)    │
   ╲  ● GLOW    ╱ ← Still glowing
    ╰──────────╯

Continue holding position...

🟢 Green button
```

### T+600ms - CAPTURE TRIGGERED! 🎉

```
┌──────────────────────────────────┐
│ ✓ Perfect position! Staying...   │
│ Pitch: 45.1° ✓ Yaw: 2.0° ✓      │
│ ████████████████████████████████ │ (100% complete!)
└──────────────────────────────────┘

    ╭──────────╮
   ╱    🟢      ╲
  │  (GREEN)    │
   ╲  ● GLOW    ╱
    ╰──────────╯

[📳 HAPTIC FEEDBACK: mediumImpact()]
📸 CAMERA SHUTTER FIRE! 

[Transition to Processing Screen]
```

### Scenario: User Moves Mid-Countdown (T+400ms)

```
Before (T+350ms):
┌──────────────────────────────────┐
│ ✓ Perfect position! Staying...   │
│ Pitch: 45.0° Yaw: 1.8°           │
│ ██████████████████░░░░░░░░░░░░░░ │ (58% done)
└──────────────────────────────────┘

User moves head UP (pitch goes to 38°)

After (T+400ms):
┌──────────────────────────────────┐
│ ○ Adjust angle to target zone    │ ← STATUS RESETS
│ Pitch: 38.2° ✗ Yaw: 2.1°        │   to ORANGE
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ (TIMER RESETS TO 0)
└──────────────────────────────────┘

    ╭──────────╮
   ╱            ╲
  │  WHITE ●    │ ← Pointer back to WHITE
   ╲           ╱   Glow OFF
    ╰──────────╯

Timer reset! Please get back in range

🔘 Brown button again
```

## Visual Feedback Elements

### Status Indicator (Top Bar)
```
┌────────────────────────────────────────┐
│ ✓ Perfect position! Staying steady...  │ ← GREEN (in range)
└────────────────────────────────────────┘

vs

┌────────────────────────────────────────┐
│ ○ Adjust angle to target zone          │ ← ORANGE (out of range)
└────────────────────────────────────────┘
```

### Angle Value Colors
```
Pitch: 45.2°  ← GREEN (within 42-48°)
Yaw: 2.1°     ← GREEN (within ±5°)

vs

Pitch: 38.2°  ← WHITE (below 42°)
Yaw: 8.5°     ← WHITE (above 5°)
```

### Pointer Animation
```
Current Position                Perfect Position
    
╭──────────╮              ╭──────────╮
╱            ╲            ╱    🟢      ╲
│  WHITE ●   │ ───→ │  (GREEN)    │
╲           ╱       ╲  ● GLOW    ╱
╰──────────╯        ╰──────────╯

No Glow                Glow Effect
Not ready             READY!
```

### Progress Bar
```
Starting:               Halfway:               Complete:
░░░░░░░░░░░░░░░░░░░░   ████████████░░░░░░░░░░  ████████████████████████████░░

0% → Timer not started  58% → Keep position    100% → AUTO-CAPTURE! 📷
```

### Button State Changes
```
NOT IN RANGE              IN RANGE
┌──────────────┐          ┌──────────────┐
│    🔘        │    →     │    🟢        │
│  BROWN       │          │   GREEN      │
│  Regular     │          │  Elevated    │
│  elevation   │          │  elevation   │
└──────────────┘          └──────────────┘

Tap text: "Tap to capture"      Auto-captures when ready
```

## Hair Capture Tips (Shown on Intro Screen)

```
📸 How to Capture Hair Properly:

1️⃣ LIGHTING
   • Use even, diffuse lighting
   • Avoid harsh shadows
   • Natural daylight is best

2️⃣ SCALP VISIBILITY
   • Part or lift hair to expose scalp clearly
   • Show scalp area (not just hair strands)
   • Position camera directly above scalp

3️⃣ HEAD POSITION
   • Tilt head slightly forward (42-48°)
   • Keep head centered in frame
   • Stay steady for 600ms

4️⃣ CLEAN CAPTURE
   • Remove hats, clips, accessories
   • Capture dry hair (not wet/oily)
   • Ensure no background distractions

✅ System will:
   • Auto-align your position
   • Capture when ready
   • Provide haptic feedback
```

## Error Scenarios & Recovery

### Scenario 1: Face not in frame
```
Status: ○ Adjust angle to target zone
Pitch: 0° (no face detected)
Result: "No face detected. Please face the camera."
Recovery: Move head into frame (even slightly forward)
```

### Scenario 2: Pitch too low (34°)
```
Status: ○ Adjust angle to target zone
Pitch: 34° ✗ (too looking down)
Result: "Tilt head more forward (42-48°)"
Recovery: Tilt head forward until pointer reaches green zone
```

### Scenario 3: Pitch too high (52°)
```
Status: ○ Adjust angle to target zone
Pitch: 52° ✗ (too looking up)
Result: "Reduce head tilt (42-48°)"
Recovery: Tilt head back slightly until pointer reaches green zone
```

### Scenario 4: Head too far left/right (Yaw: 12°)
```
Status: ○ Adjust angle to target zone
Yaw: 12° ✗ (too rotated)
Result: "Center your head (max 5° from center)"
Recovery: Rotate head towards camera center
```

## Performance During Capture

| Metric | Value | Notes |
|--------|-------|-------|
| Face Detection Latency | <100ms | Real-time landmark processing |
| Pitch/Yaw Calculation | <16ms | Mathematics computation only |
| UI Update Rate | 60fps | Smooth pointer animation |
| Timer Precision | ±50ms | 50ms interval checks |
| Total Response Time | <150ms | Detection → UI update |
| Haptic Duration | ~50ms | mediumImpact() feedback |

## Accessibility Features

### For Users with Tremor/Movement
- 600ms is long enough to accommodate slight movements
- Timer resets when out of range (not punishing)
- Manual capture button available as fallback

### For Users with Poor Vision
- Large on-screen pointer (easy to see)
- High contrast colors (white on black, green on black)
- Real-time angle numbers (for reference)

### For Users with Hearing Impairment
- Haptic feedback (vibration) alternative to sound
- Visual progress bar (not just timer text)
- Green status indicator (not just audio tone)

---

**Hair analysis capture is now a fully guided, automated experience!** 💇‍♀️✨
