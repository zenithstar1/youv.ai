# Auto-Capture UI Components - Visual Reference

## 1. Main Guide Circle

The white circular guide is the centerpiece of the auto-capture UI:

```
    ┌──────────────────────────────┐
    │   ╱─────────────────────╲    │
    │  ╱      ┌─────────┐      ╲   │
    │ │  ╱────┤ / \ | ├────╲  │   │
    │ │ ╱     └─────────┘     ╲ │   │
    │ │ │     | | / \ |       │ │   │
    │ │ │   / └─────────╲ \  │ │   │
    │  ╲│  │  | |/   |  │ ╱  │╱    │
    │   ╲  │   ╲|    |  / ╱   ╱     │
    │    ╲─┘────@────┘─╱      ╱     │
    │     ╲   ╱─ ─────╱      ╱      │
    │      ╲─────────────────╱       │
    └──────────────────────────────┘
    
    Components:
    - White/Green border (4px)
    - Corner guides (24x24px)
    - Center crosshair
    - Background opacity
```

## 2. Status States & Colors

### State 1: Not in Range (Gray)
```
• Status: "○ Tap to adjust"
• Border Color: Gray (#757575)
• Button Color: Gray
• Feedback: "Adjust position for auto-capture"
• User Action: Position face toward center
```

### State 2: Approaching Range (Amber)
```
• Status: "○ Getting closer"
• Border Color: Amber (#FFC107)
• Indicators: Angle values turn amber
• Feedback: "Almost there..."
• User Action: Fine-tune angle
```

### State 3: Perfect Angle (Green) ✓
```
• Status: "✓ Position perfect"
• Border Color: Green (#4CAF50)
• Outer Ring: Pulsing green glow
• Button Color: Green
• Countdown: Starts immediately
• Duration: 600ms by default
```

## 3. Countdown Timer Animation

When perfect angle is achieved, a beautiful countdown timer appears:

```
        Round 1 (500ms)      Round 2 (400ms)      Round 3 (300ms)
        
         ╱─────╲              ╱──────╲            ╱───────╲
        ╱         ╲          ╱          ╲        ╱           ╲
       │     0.5    │        │    0.3     │      │     0.1      │
        ╲         ╱          ╲          ╱        ╲           ╱
         ╲─────╱              ╲──────╱            ╲───────╱
        
        Progress: ███░░░░░ 16%   Progress: ██████░░ 68%  Progress: █████████ 100%
```

**Features**:
- Circular timer background (green gradient)
- Animated progress ring
- Digital counter (0.5s, 0.4s, etc.)
- Shadow effect for depth

## 4. Top Status Bar

Compact, minimalistic status indicator:

```
┌─────────────────────────────────────────────┐
│ ✓ Position perfect      [Tilt: 45°] [Angle: 1°]  │
│ Capturing in 0.4s                           │
└─────────────────────────────────────────────┘
```

**Components**:
- Status text (left-aligned)
- Angle values (compact box on right)
- Optional countdown text
- Semi-transparent background

## 5. Angle Indicator Rows

Detailed angle feedback below the main guide:

```
┌─────────────────────────────────────┐
│ Head Tilt              45° ✓         │  ← Green when OK
│ Target: 42° - 48°                   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Face Angle             2° ✓          │  ← Green when OK
│ Target: ±5°                         │
└─────────────────────────────────────┘
```

## 6. Capture Button States

### Default State (Not Ready)
```
         ╭───────╮
        │  📷   │  Gray background
        │       │  Subtle shadow
         ╰───────╯
    "Adjust position for auto-capture"
```

### Ready State (Perfect Angle)
```
      ╭─────────────╮
     │  ╭───────╮   │  Green outer ring
     │ │  📷   │  │  Green button
     │  ╰───────╰   │  Strong shadow (8px)
      ╰─────────────╯
    "Tap or wait for auto-capture"
```

## 7. Complete Layout

```
┌─────────────────────────────────────────────────────┐
│  ✗ (close button)                                   │
├─────────────────────────────────────────────────────┤
│                                                     │ Top:20px
│  ✓ Position perfect    [Tilt: 45°] [Angle: 1°]    │ Status Bar
│                                                     │
│                                                     │
│              120px space                           │
│                                                     │
│           ┌────────────────────┐                   │ Main Guide
│           │  ╱─────────────╲   │                   │ (280x280)
│           │ ╱     ┌────┐    ╲  │                   │
│           ││       │    │      │ │                  │
│           │ ╲     └────┘    ╱  │                   │
│           │  ╲─────────────╱    │                   │
│           └────────────────────┘                   │
│                                                     │
│           ✓ Position perfect                        │ Status Text
│           Keep your face centered                  │
│                                                     │
│      Head Tilt: 45° (42-48°) ✓                     │ Angle Indicators
│                                                     │
│      Face Angle: 1° (±5°) ✓                        │
│                                                     │
│                                                     │ 120px space
│                                                     │
│              📷 (green)                             │ Capture Button
│      Tap or wait for auto-capture                  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 8. Color Palette

```
Primary Colors:
- White (Guide): #FFFFFF
- Green (Success): #4CAF50 or Colors.green.shade400
- Amber (Warning): #FFC107 or Colors.amber.shade300
- Gray (Inactive): #757575 or Colors.grey.shade600

Backgrounds:
- Black (Base): #000000
- Dark Glass: rgba(0, 0, 0, 0.54)
- Transparent Overlay: rgba(255, 255, 255, 0.05)

Transparency Levels:
- High Emphasis: 1.0 (100%)
- Medium Emphasis: 0.7 (70%)
- Low Emphasis: 0.5 (50%)
- Subtle: 0.3 (30%)
- Very Subtle: 0.1 (10%)
```

## 9. Animation Timings

```
Pulse Animation (Outer Ring when Perfect Angle):
├─ Duration: 1500ms
├─ Scale: 0.8 to 1.0
├─ Easing: Curves.easeInOut
└─ Repeat: Continuous

Countdown Progress Ring:
├─ Duration: Variable (600ms total)
├─ Starts: When perfect angle detected
├─ Style: Circular stroke with round cap
└─ Interval: Updated every 50ms

Transitions:
├─ Color Changes: Instant
├─ Button Highlight: 200ms fade
└─ Status Updates: 100-150ms

Touch Feedback:
├─ Haptic: HapticFeedback.mediumImpact()
└─ Timing: On auto-capture trigger
```

## 10. Corner Guide Details

```
Each corner features a small L-shaped bracket:

Top-Left        Top-Right
┌─────┐         ┐─────┐
│             │
│             │
              
            
Bottom-Left     Bottom-Right
│             │
│             │
└─────┐       ┌─────┘

Thickness: 2px
Size: 24x24px
Color: White with 40% opacity
Position: 12px from edges
```

## 11. Text Hierarchy

```
Primary Text (16px, Bold):
"✓ Perfect Position"

Secondary Text (14px, Normal):
"Keep your face centered"

Tertiary Text (12px, Normal):
"Head Tilt: 45° (Target: 42-48°)"

UI Labels (11px, Small):
"Tap or wait for auto-capture"

Small Details (10px, Very Small):
"Target: ±5°"

Color Values:
- Primary: Colors.white
- Secondary: Colors.white.withOpacity(0.7)
- Tertiary: Colors.white.withOpacity(0.5)
- Details: Colors.white.withOpacity(0.3)
```

## 12. Responsive Layout

```
Device: Mobile (360px width)
├─ Main Circle: 280x280
├─ Margins: 16px left/right
├─ Gaps: 16-32px between elements
└─ Fits comfortably 👍

Device: Tablet (600px width)
├─ Main Circle: 320x320
├─ More space for indicators
└─ Better readability 👍

Device: Large (900px+ width)
├─ Main Circle: 360x360
├─ Extra information can be added
└─ Movie theater mode 👍
```

## 13. Accessibility Features

```
✓ High Contrast Colors
├─ Text: White on dark background
├─ Circles: Green/White on black
└─ Minimum WCAG AA compliance

✓ Clear Visual Feedback
├─ Color coding (green/amber/gray)
├─ Icon indicators (✓, ○)
└─ Text labels

✓ Haptic Feedback
├─ Medium impact on capture
├─ Device vibration confirmation
└─ No visual-only feedback

✓ Large Touch Targets
├─ Capture button: 72x72px
├─ Minimum 44x44px recommended
└─ Easy to tap
```

## 14. Performance Optimizations

```
UI Updates:
├─ Only redraw when state changes (isPerfectAngle, angles)
├─ Throttle refresh (frameThrottleInterval = 2)
└─ Reduce jank by skipping unnecessary frames

Animations:
├─ GPU-accelerated (ScaleTransition)
├─ SingleTickerProviderStateMixin for smooth 60fps
└─ Automatic cleanup on dispose

Memory:
├─ Lazy load text painters once
├─ Reuse paint objects
└─ Clean up resources properly
```

---

**Reference Date**: February 17, 2024
