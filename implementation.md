# YouV.AI — User Profile & Activity Module
## Complete Implementation Guide

> **Status:** Frontend-only (mock data). Backend integration points are clearly marked throughout.

---

## Changelog

| Version | Date | Summary |
|---|---|---|
| v1.0 | Initial | Profile, History, bottom navigation, logout flow, mock data |
| v1.1 | Patch | Fixed `_dependents.isEmpty` BLoC assertion; fixed camera screen deactivated-context crash |
| v1.2 | Feature | Added profile avatar shortcut button on Home tab |
| v1.3 | Patch | Fixed profile avatar button position — `extendBodyBehindAppBar: true` + correct `padding.top` offset |
| v1.4 | Feature | Introduced `HomeTabPage` — profile avatar is now **part of the Home tab's own widget tree**, always visible when on the Home tab, taps directly to scan History |
| v1.5 | Bugfix | Fixed `already_login_screen.dart` — was still navigating to `AnalysisTypeScreen` after OTP verification; changed to `HomeNavigationScreen` with `pushAndRemoveUntil` to clear back stack |
| v1.8 | Feature | Smart launch routing — `AuthBloc` now writes `hasRegistered = true` on every successful auth (persists across logouts). `onboarding_flow.dart` routes: `isLogin=true` → AnalysisTypeScreen, `hasRegistered=true` → AlreadyLoginScreen (OTP for returning users), neither → LoginPage (sign-up for brand-new users) |
| v1.7 | UI Polish | Redesigned `ProfileScreen` — replaced `SliverAppBar` with a gradient hero header card (rounded bottom), unified background to `0xFFFDEDED` matching AnalysisTypeScreen, tighter spacing, section headers in Lora w700 with scan-count badge, divider indent matched to icon width |
| v1.6 | Redesign | Removed `HomeNavigationScreen` tab shell from all navigation. All post-login routes now land on `AnalysisTypeScreen` directly. Profile avatar button added to `AnalysisTypeScreen` (top-right, always visible). `ProfileScreen` is now self-contained (owns its own `AuthBloc`) and includes the full scan history list below the user info cards. Tapping the avatar pushes `ProfileScreen` via `Navigator.push`. |

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Folder Structure](#2-folder-structure)
3. [Module Descriptions](#3-module-descriptions)
4. [Profile Flow](#4-profile-flow)
5. [Activity / History Flow](#5-activity--history-flow)
6. [SharedPreferences Integration](#6-sharedpreferences-integration)
7. [Logout Flow](#7-logout-flow)
8. [Bottom Navigation](#8-bottom-navigation)
9. [Home Tab — Profile Avatar Shortcut](#9-home-tab--profile-avatar-shortcut)
10. [Reusable Widgets](#10-reusable-widgets)
11. [Navigation After Login](#11-navigation-after-login)
12. [Dummy Data & Mock Layer](#12-dummy-data--mock-layer)
13. [Bug Fixes & Stability Patches](#13-bug-fixes--stability-patches)
14. [Future Backend Integration Plan](#14-future-backend-integration-plan)
15. [Scalability Recommendations](#15-scalability-recommendations)
16. [Best Practices Used](#16-best-practices-used)
17. [Step-by-Step Implementation Guide](#17-step-by-step-implementation-guide)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         App Entry (main.dart)                   │
│                         OnboardingScreen                        │
└──────────────────────────┬──────────────────────────────────────┘
                           │ User taps "Start Your Scan"
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                       OnboardingFlow                            │
│           (checks isLogin via SharedPreferences)               │
└────────────┬────────────────────────────┬───────────────────────┘
             │ Not logged in              │ Already logged in
             ▼                            ▼
┌────────────────────────┐   ┌────────────────────────────────────┐
│   LoginPage / SignUp   │   │        HomeNavigationScreen        │
│   OtpScreen            │   │  ┌──────────┬──────────┬────────┐ │
│        │               │   │  │  Home    │ History  │Profile │ │
│        │ AuthAuthenticated  │  │  (tab 0) │ (tab 1) │(tab 2) │ │
│        └───────────────┼──▶│  │  [avatar]│         │        │ │
└────────────────────────┘   │  └──────────┴──────────┴────────┘ │
                             └────────────────────────────────────┘
```

> `[avatar]` = the profile avatar shortcut button overlaid on the Home tab (top-right corner).

### Key Design Decisions

| Decision | Reason |
|---|---|
| **`IndexedStack`** for tabs | Preserves page state (scroll, loaded data) when switching tabs |
| **`BlocProvider.value` + `initState` AuthBloc** | Prevents `_dependents.isEmpty` assertion — see §13 for details |
| **Repository pattern for activities** | `ActivityRepository.getMockActivities()` is a single drop-in replacement point for the real API call |
| **SharedPreferences as cache** | Auth data is written once on login and read on Profile/Home load — no extra network call needed |
| **Null-safe field access** | All `userInfo` JSON fields are read with `?.toString() ?? ''` to survive partial API responses |
| **`NavigatorState` captured before `await`** | Prevents deactivated-context crash in camera screen async callbacks |

---

## 2. Folder Structure

```
lib/
│
├── Bloc/                          # Existing BLoC (unchanged)
│   ├── auth_bloc.dart             #   Business logic (login, logout, OTP)
│   ├── auth_event.dart            #   Events: LoginRequested, LogoutRequested …
│   └── auth_state.dart            #   States: AuthAuthenticated, AuthLogout …
│
├── models/
│   └── activity_model.dart        # ★ NEW — ActivityModel + ActivityRepository
│
├── screens/
│   ├── home_navigation_screen.dart # ★ NEW — Shell + BLoC provision + avatar overlay
│   ├── profile_screen.dart        # ★ NEW — User profile, loads from SharedPreferences
│   ├── history_screen.dart        # ★ NEW — Analysis history list with filter chips
│   ├── LoginPage.dart             #   MODIFIED — navigates to HomeNavigationScreen
│   ├── standard_camera_screen.dart #   PATCHED — NavigatorState captured before async
│   └── … (other existing screens)
│
├── widgets/
│   ├── profile_header.dart        # ★ NEW — Reusable avatar + name header
│   ├── history_card.dart          # ★ NEW — Single analysis session card
│   ├── empty_activity_widget.dart # ★ NEW — Empty state with CTA
│   └── … (other existing widgets)
│
├── otp_screen.dart                #   MODIFIED — navigates to HomeNavigationScreen
├── signup_screens.dart            #   MODIFIED — navigates to HomeNavigationScreen
└── … (rest of existing files)
```

> Files marked **★ NEW** were created in this implementation.  
> Files marked **MODIFIED** had their post-auth navigation target changed.  
> Files marked **PATCHED** received a targeted stability fix.

---

## 3. Module Descriptions

### `activity_model.dart`
Defines the data shape for a single skin-analysis session.

```dart
class ActivityModel {
  final String id;            // unique session ID (used as API key later)
  final String analysisType;  // "Comprehensive Facial Analysis" etc.
  final DateTime date;        // session timestamp
  final double acneScore;     // 0–100
  final double hydrationScore;
  final double? pigmentationScore;   // nullable — not all scan types return this
  final double? wrinklesScore;
  final String? thumbnailAsset;      // local asset (mock only)
  final String? thumbnailUrl;        // remote URL (backend)
  final String status;               // 'completed' | 'pending' | 'failed'
}
```

`ActivityRepository.getMockActivities()` returns five hardcoded entries.  
**Replace this method body** with the real API call when the backend is ready.

---

## 4. Profile Flow

```
ProfileScreen.initState()
      │
      ▼
_loadUserData()
      │
      ├─ SharedPreferences.getInstance()
      ├─ prefs.getString('userInfo')   → JSON string
      ├─ json.decode(...)              → Map<String, dynamic>
      └─ setState() with name, phone, email, city, clinic
             │
             ▼
      build() renders
      ├─ SliverAppBar (CollapsingHeader with ProfileHeader widget)
      ├─ Personal Information card (_InfoCard)
      │     ├─ Full Name
      │     ├─ Phone
      │     └─ Email
      ├─ Location & Clinic card
      │     ├─ City
      │     └─ Clinic
      └─ Logout button → confirmation dialog → AuthBloc.add(LogoutRequested())
```

### SharedPreferences Keys Read

| Key | Type | Example value |
|---|---|---|
| `userInfo` | `String` (JSON) | `{"name":"Ayesha","phone":"9876543210","email":"a@b.com","city":"Mumbai","clinic_name":"Glow Clinic","token":"eyJ..."}` |
| `isLogin` | `bool` | `true` |
| `_token` | `String` | `eyJhbGci...` |

### Field Fallback Logic

Some API responses use `phone`, others use `mobile`. The loader handles both:

```dart
_phone = userInfo['phone']?.toString() ?? userInfo['mobile']?.toString() ?? '';
_clinic = userInfo['clinic_name']?.toString() ?? userInfo['clinic']?.toString() ?? '';
```

---

## 5. Activity / History Flow

```
HistoryScreen.initState()
      │
      ▼
_loadActivities()   ← async, shows CircularProgressIndicator while loading
      │
      ├─ [MOCK] Future.delayed(600ms) + ActivityRepository.getMockActivities()
      │
      └─ setState(_activities = data, _isLoading = false)
             │
             ▼
      build() renders
      ├─ SliverAppBar with filter chip bar (All / Completed / Pending)
      ├─ _filtered getter applies status filter
      ├─ SliverList of HistoryCard widgets  ← if data exists
      └─ EmptyActivityWidget               ← if filtered list is empty
             │
             └─ "Start Your First Scan" CTA → AnalysisTypeScreen
```

### Filter Logic

```dart
List<ActivityModel> get _filtered {
  if (_selectedFilter == 'all') return _activities;
  return _activities.where((a) => a.status == _selectedFilter).toList();
}
```

No network call is made when the filter changes — filtering is purely in-memory.

---

## 6. SharedPreferences Integration

### How Data Gets There (existing auth flow, unchanged)

```dart
// Inside AuthBloc.mobileLogin() — runs after successful OTP verification:
final prefs = await SharedPreferences.getInstance();
prefs.setBool('isLogin', true);
prefs.setString('userInfo', json.encode(responseData['data']));
prefs.setString('_token', responseData['data']['token'] ?? '');
prefs.setBool('isSubscribe', responseData['data']['isSubscribed'] ?? false);
```

### Where It Is Read

| Screen / Widget | Purpose |
|---|---|
| `ProfileScreen._loadUserData()` | Populates name, phone, email, city, clinic fields |
| `HomeNavigationScreen._loadInitials()` | Extracts up to 2 initials for the Home tab avatar button |

### How Logout Clears It (existing AuthBloc, unchanged)

```dart
// Inside AuthBloc.logout():
await prefs.remove('isLogin');
await prefs.remove('userInfo');
await prefs.remove('_token');
await prefs.remove('isSubscribe');
emit(AuthLogout());
```

---

## 7. Logout Flow

```
User taps "Logout" button
      │
      ▼
Confirmation dialog (AlertDialog)
      │
      ├─ Cancel → dialog dismissed, nothing changes
      │
      └─ Confirm
            │
            ▼
      context.read<AuthBloc>().add(LogoutRequested())
            │
            ▼
      AuthBloc.logout() runs:
        ├─ Calls POST /auth/logout (backend clears server session)
        └─ Clears SharedPreferences keys
            │
            ▼
      Emits AuthLogout state
            │
            ▼
      BlocListener in ProfileScreen catches AuthLogout
            │
            ▼
      Navigator.pushAndRemoveUntil → OnboardingScreen
      (entire back stack is cleared so user cannot go back)
```

### Why `pushAndRemoveUntil`?

Using `pushAndRemoveUntil` with `(_) => false` removes every route from the stack. This prevents the user from pressing the back button to return to the authenticated area after logout — an important security behaviour.

---

## 8. Bottom Navigation

`HomeNavigationScreen` is the root scaffold after login. It manages:

- **Which tab is active** (`_currentIndex` int state)
- **Page list** (`IndexedStack` children — always mounted)
- **AuthBloc lifecycle** (created in `initState`, disposed in `dispose`, exposed via `BlocProvider.value`)

```dart
// Tab definitions (index → screen)
0 → HomeTabPage(onProfileTap: () => _currentIndex = 1)  // Home + avatar button
1 → HistoryScreen()                                      // past scan sessions
2 → ProfileScreen()                                      // user info + logout
```

### `IndexedStack` vs `PageView`

`IndexedStack` was chosen over `PageView` because:
- All pages stay **mounted** (no dispose/rebuild on tab switch)
- Scroll positions and loaded data are **preserved**
- `HistoryScreen`'s mock data fetch does not re-run every time the tab is visited

### `BlocProvider.value` Pattern

```dart
late final AuthBloc _authBloc;

@override
void initState() {
  super.initState();
  _authBloc = AuthBloc();  // created ONCE
}

@override
void dispose() {
  _authBloc.close();       // cleaned up with the widget
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return BlocProvider.value(   // exposes existing instance — never recreates it
    value: _authBloc,
    child: Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNav(...),
    ),
  );
}
```

**Why not `BlocProvider(create: ...)`?**  
See §13 — Patch 1.

### Custom Bottom Navigation

The built-in `BottomNavigationBar` was replaced with a custom `_BottomNav` to match the design system (rosy pink active colour, animated pill background, Google Fonts Poppins labels).

---

## 9. Home Tab — `HomeTabPage` and the Profile Avatar Button

### The Problem with Shell Overlays

Earlier versions added the profile avatar as a `Positioned` overlay inside `HomeNavigationScreen.build()`. This had one fundamental flaw: the button was part of the shell's widget layer. When any scan screen was pushed on top (camera → preview → results), that route painted over the entire shell — hiding the button completely.

### The Solution — `HomeTabPage`

The avatar button is now **embedded directly inside the Home tab's own widget subtree** via `HomeTabPage`. Because it lives inside the `IndexedStack` tab content, it is always present whenever the user is on the Home tab. There is no separate shell overlay to manage.

```
IndexedStack
  ├─ [0] HomeTabPage          ← avatar button lives HERE, inside this tab
  │        ├─ StartJourneyScreen
  │        └─ Positioned → _ProfileAvatarButton
  ├─ [1] HistoryScreen
  └─ [2] ProfileScreen
```

### Flow

```
HomeTabPage._loadInitials()  (called in initState)
      │
      ├─ SharedPreferences → 'userInfo' JSON
      ├─ Extracts name → splits → takes first letters → "AK"
      └─ setState(_initials = 'AK')
             │
             ▼
      build() renders Stack:
        ├─ StartJourneyScreen()       (full-screen scan CTA)
        └─ Positioned (top-right)
               └─ _ProfileAvatarButton
                     ├─ Shows initials "AK" (or person icon while loading)
                     └─ onTap → widget.onProfileTap()
                                      │
                                      ▼
                           HomeNavigationScreen:
                           setState(_currentIndex = 1)  → History tab
```

### Code Pattern

```dart
// HomeNavigationScreen passes the tab-switch callback:
_pages = [
  HomeTabPage(
    onProfileTap: () => setState(() => _currentIndex = 1), // → History
  ),
  const HistoryScreen(),
  const ProfileScreen(),
];

// HomeTabPage owns its own initials state:
class _HomeTabPageState extends State<HomeTabPage> {
  String _initials = '';

  @override
  void initState() {
    super.initState();
    _loadInitials(); // async, reads SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        const StartJourneyScreen(),
        Positioned(
          top: topPad + 14,
          right: 20,
          child: _ProfileAvatarButton(
            initials: _initials,
            onTap: widget.onProfileTap,
          ),
        ),
      ],
    );
  }
}
```

### Visual Spec

| Property | Value |
|---|---|
| Size | 44 × 44 dp |
| Shape | Circle |
| Background | Pink gradient `#E4B3B8` → `#D79096` |
| Border | 2.5 dp white — stands out on the dark `StartJourneyScreen` background |
| Shadow | `#3B1F1F` at 35% opacity, blur 12, offset (0, 4) |
| Content | User initials in white Lora 700, or `Icons.person_rounded` while loading |
| Position | `top: MediaQuery.padding.top + 14`, `right: 20` |
| Visibility | Always visible on the Home tab; not present on pushed routes (camera, results) — this is expected mobile behaviour |
| Tap action | Switches to **History tab** (index 1) — user sees all past scans immediately |

### Initials Extraction

```dart
final parts = name.split(RegExp(r'\s+'));
final initials = parts.length >= 2
    ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()   // "Ayesha Khan" → "AK"
    : parts[0][0].toUpperCase();                       // "Ayesha"     → "A"
```

---

## 10. Reusable Widgets

### `ProfileHeader`

```dart
ProfileHeader(
  name: 'Ayesha Khan',
  subtitle: 'ayesha@example.com',  // optional
  imageUrl: 'https://...',         // optional — falls back to initials
)
```

- Generates initials automatically from the name (e.g. "AK")
- Gradient circle avatar fallback when no image is available
- Accepts a network image URL for future backend avatar support

### `HistoryCard`

```dart
HistoryCard(
  activity: activityModel,
  onTap: () { /* navigate to detail */ },
)
```

- Shows thumbnail (asset, network URL, or icon fallback)
- Status chip (Completed / Pending / Failed) with colour coding
- Score pills for Acne, Hydration, and optionally Pigmentation
- Fully responsive via the `Responsive` utility

### `EmptyActivityWidget`

```dart
EmptyActivityWidget(
  onStartScan: () { /* navigate to scan */ },
)
```

- Illustrated empty state with gradient icon circle
- Optional CTA button — pass `null` to hide it
- Used when the history list is empty (either no scans or filter returns nothing)

### `_ProfileAvatarButton` *(internal to `home_navigation_screen.dart`)*

```dart
_ProfileAvatarButton(
  initials: 'AK',
  onTap: () { /* switch to Profile tab */ },
)
```

- Private widget — not exported, used only inside `HomeNavigationScreen`
- Falls back to `Icons.person_rounded` while initials are loading

---

## 11. Navigation After Login

Three files were updated to navigate to `HomeNavigationScreen` after successful authentication:

| File | Change |
|---|---|
| `lib/otp_screen.dart` | `StartJourneyScreen` → `HomeNavigationScreen` |
| `lib/signup_screens.dart` | `StartJourneyScreen` → `HomeNavigationScreen` |
| `lib/screens/LoginPage.dart` | `AnalysisTypeScreen` → `HomeNavigationScreen` |

All use `pushReplacement` or `pushAndRemoveUntil` so the login/OTP screens are removed from the back stack.

---

## 12. Dummy Data & Mock Layer

All mock data lives in `ActivityRepository.getMockActivities()` inside `activity_model.dart`. The method signature and return type will remain identical when the backend is wired in — only the body changes.

**Current (mock):**
```dart
static List<ActivityModel> getMockActivities() {
  return [ /* hardcoded ActivityModel list */ ];
}
```

**Future (real API):**
```dart
static Future<List<ActivityModel>> getActivities(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/analysis-history'),
    headers: {'Authorization': 'Bearer $token'},
  );
  final data = json.decode(response.body)['data'] as List;
  return data.map((j) => ActivityModel.fromJson(j)).toList();
}
```

`HistoryScreen._loadActivities()` will need the matching async call and error handling — that is the only other change required.

---

## 13. Bug Fixes & Stability Patches

### Patch 1 — `_dependents.isEmpty` Assertion (BLoC / InheritedWidget)

**File:** `lib/screens/home_navigation_screen.dart`

**Symptom:**
```
Assertion failed: framework.dart:6271:12
_dependents.isEmpty is not true
```

**Root cause:**  
`BlocProvider(create: (_) => AuthBloc())` was placed inside `build()`. Every `setState` call (e.g., tapping a tab) created a **new** `InheritedWidget` element and deactivated the old one. At the moment of deactivation, `ProfileScreen` (inside `IndexedStack`) still had a registered dependency on the old element — triggering Flutter's internal assertion that an `InheritedElement` must have no dependents when it is deactivated.

**Fix:**  
Move `AuthBloc` creation to `initState`, manage its lifecycle explicitly in `dispose`, and use `BlocProvider.value` in `build()`:

```dart
// BEFORE (broken)
Widget build(BuildContext context) {
  return BlocProvider(
    create: (_) => AuthBloc(),   // ← new bloc on every rebuild
    child: ...
  );
}

// AFTER (fixed)
late final AuthBloc _authBloc;

@override
void initState() {
  _authBloc = AuthBloc();        // ← created exactly once
  super.initState();
}

@override
void dispose() {
  _authBloc.close();             // ← cleaned up with the widget
  super.dispose();
}

Widget build(BuildContext context) {
  return BlocProvider.value(
    value: _authBloc,            // ← exposes existing instance, never recreates
    child: ...
  );
}
```

---

### Patch 2 — Deactivated Widget Context Crash (Camera Screen)

**File:** `lib/screens/standard_camera_screen.dart`

**Symptom:**
```
DartError: Looking up a deactivated widget's ancestor is unsafe.
    at Navigator.pushReplacement (navigator.dart:2402)
    at standard_camera_screen.dart:789
```

**Root cause:**  
`_startScanningAnimation()` runs a multi-phase `async` sequence (freeze → mapping → analyzing → calculating) with many `await` points. At line 789 the code called `Navigator.pushReplacement(context, ...)`, which internally calls `Navigator.of(context)` → `context.findAncestorStateOfType()`. Even though a `mounted` check was present just above, there is a micro-task window between the check and the actual tree traversal in which the element can be deactivated — especially on slower devices or when routes are being popped from elsewhere.

**Fix:**  
Capture `Navigator.of(context)` at the **top** of `_startScanningAnimation()`, before the first `await`. The `NavigatorState` object is a plain Dart reference that remains valid even after the originating widget is deactivated.

```dart
Future<void> _startScanningAnimation() async {
  if (!mounted || _isDisposed || _hasNavigated) return;

  // ✅ Captured here — before ANY await — so it stays valid
  //    even if the widget is deactivated later in the async chain.
  final navigator = Navigator.of(context);

  // ... all the async phases (freeze, mapping, analyzing, calculating) ...

  // ✅ Use the stored reference instead of Navigator.pushReplacement(context, ...)
  if (!_hasNavigated && _capturedBytes != null) {
    _hasNavigated = true;
    navigator.pushReplacement(MaterialPageRoute(...));
  }
}
```

**General rule:** Any time you need to use `Navigator`, `ScaffoldMessenger`, or any other context-dependent object after an `await`, capture it **before** the first `await` in the function.

---

### Patch 4 — Profile Avatar Button Hidden on Pushed Screens → Migrated to Overlay

**File:** `lib/screens/home_navigation_screen.dart`

**Symptom:**  
The profile avatar button was invisible whenever a screen was pushed on top of `HomeNavigationScreen` (e.g., during the camera → image preview → analysis results flow). It only appeared on the Home tab.

**Root cause:**  
The button was a `Positioned` widget inside `HomeNavigationScreen`'s `build()` `Stack`. Any screen pushed via `Navigator.push()` paints over the entire `HomeNavigationScreen` widget tree — the button was simply covered by the new route.

**Fix:**  
Replaced the `Stack`/`Positioned` approach with a `OverlayEntry` inserted into Flutter's `Overlay` (which sits above the `Navigator` stack):

```dart
// BEFORE — hidden by pushed routes
Stack(
  children: [
    IndexedStack(...),
    if (_currentIndex == 0)
      Positioned(top: ..., child: _ProfileAvatarButton(...)),
  ],
)

// AFTER — always visible, above all routes
WidgetsBinding.instance.addPostFrameCallback((_) {
  _avatarOverlay = OverlayEntry(
    builder: (_) => Positioned(
      top: MediaQuery.of(_).padding.top + 14,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: _PersistentAvatarButton(initials: _initials, onTap: _onAvatarTap),
      ),
    ),
  );
  Overlay.of(context).insert(_avatarOverlay!);
});
```

The `OverlayEntry` is removed in `dispose()` so the button automatically disappears after logout.

---

### Patch 3 — Profile Avatar Button Off-Screen on Real Devices

**File:** `lib/screens/home_navigation_screen.dart`

**Symptom:**  
The profile avatar button was not visible in the expected top-right corner of the Home tab on real devices. On web it appeared near the top (correct), but on physical phones it was pushed ~73 dp below where it should be.

**Root cause:**  
`Scaffold.body` already starts its coordinate system at `y = 0` **below** the status bar. The original code also added `MediaQuery.padding.top` (≈ 44–59 dp on modern phones) to the `Positioned.top` value, double-counting the status bar and pushing the button far down the screen:

```dart
// BEFORE — broken on real devices
final topInset = MediaQuery.of(context).padding.top;  // e.g. 59 dp

Scaffold(
  // extendBodyBehindAppBar NOT set — body starts below status bar
  body: Stack(
    children: [
      ...
      Positioned(
        top: topInset + 14,  // ❌  59 + 14 = 73 dp below body top
                             //     = 73 dp below the status bar
        right: 20,
        ...
      ),
    ],
  ),
)
```

**Fix:**  
Set `extendBodyBehindAppBar: true` on the `Scaffold` so the body's coordinate system now covers the **full screen** including the status bar. With that, `MediaQuery.padding.top + 14` correctly places the button just below the status-bar icons — every time, on every device:

```dart
// AFTER — correct on all devices and web
Scaffold(
  extendBodyBehindAppBar: true,   // ✅ body covers full screen
  body: Stack(
    children: [
      ...
      Positioned(
        top: MediaQuery.of(context).padding.top + 14,  // ✅ status bar + 14 dp gap
        right: 20,
        ...
      ),
    ],
  ),
)
```

| Device | Status bar height | Button `top` value | Result |
|---|---|---|---|
| Web (browser) | 0 dp | 0 + 14 = **14 dp** | Top-right corner ✓ |
| iPhone 13 | 47 dp | 47 + 14 = **61 dp** | Below notch ✓ |
| iPhone 14 Pro Max | 59 dp | 59 + 14 = **73 dp** | Below Dynamic Island ✓ |
| Android (typical) | 24–30 dp | 24 + 14 = **38 dp** | Below status bar ✓ |

---

## 14. Future Backend Integration Plan

### Endpoints to Add

| Method | Endpoint | Used by |
|---|---|---|
| `GET` | `/api/user/profile` | ProfileScreen (fresh data refresh) |
| `PUT` | `/api/user/profile` | Future edit-profile screen |
| `PUT` | `/api/user/avatar` | Profile image upload via `image_picker` |
| `GET` | `/api/analysis-history` | HistoryScreen |
| `GET` | `/api/analysis-history/{id}` | Future detail screen |
| `DELETE` | `/api/analysis-history/{id}` | Future swipe-to-delete |

### Integration Checklist

- [ ] **ProfileScreen**: Add a `_refreshFromApi()` method that hits `GET /user/profile` and updates SharedPreferences cache.
- [ ] **HomeNavigationScreen**: After profile refresh, call `_loadInitials()` again so the avatar button reflects any name changes.
- [ ] **HistoryScreen**: Change `_loadActivities()` to call `ActivityRepository.getActivities(token)` (async, returning `Future<List<ActivityModel>>`).
- [ ] **HistoryCard `onTap`**: Navigate to a new `AnalysisDetailScreen` passing `activity.id`.
- [ ] **Pagination**: Add a `ScrollController` to `HistoryScreen` and load more items when the user scrolls near the bottom (`page` query parameter).
- [ ] **Pull-to-refresh**: Wrap `CustomScrollView` in `RefreshIndicator` to re-fetch on pull-down.
- [ ] **Profile image upload**: Add `image_picker` flow to `ProfileHeader` and `PUT /user/avatar` endpoint.

### Replacing Mock Data — Step by Step

1. Make `ActivityRepository.getMockActivities()` async, rename to `getActivities(String token)`.
2. Inside, call the API and parse with `ActivityModel.fromJson()`.
3. In `HistoryScreen._loadActivities()`, get the token from SharedPreferences and `await` the repository.
4. Add error handling: show a `SnackBar` on network failure and keep the stale list visible.
5. Delete the hardcoded list from `activity_model.dart`.

---

## 15. Scalability Recommendations

### State Management
- Move `_activities` out of `_HistoryScreenState` into a dedicated **`ActivityBloc`** or **`ActivityCubit`** when the list needs to be shared across screens (e.g., a dashboard widget showing the latest scan).
- Use `hydrated_bloc` to persist the activity list across app restarts without a network call.

### Caching
- Cache the history response in SharedPreferences (serialised JSON) so the list is visible instantly on next launch while a refresh runs in the background.

### Folder Structure (when the app grows)
```
lib/
├── features/
│   ├── auth/          ← existing Bloc + screens
│   ├── profile/       ← ProfileScreen, ProfileBloc, ProfileRepository
│   ├── history/       ← HistoryScreen, ActivityBloc, ActivityRepository
│   └── home/          ← HomeNavigationScreen, StartJourneyScreen
└── core/
    ├── models/        ← shared models
    ├── widgets/       ← shared widgets
    └── utils/         ← Responsive, constants, theme
```

### Theming
Create a `lib/core/theme/app_theme.dart` file that centralises all colours, text styles, and border radii currently duplicated across screens:

```dart
class AppColors {
  static const primary   = Color(0xFFD79096);
  static const dark      = Color(0xFF3B1F1F);
  static const surface   = Color(0xFFFFF5F0);
  static const muted     = Color(0xFF8A7A72);
}
```

---

## 16. Best Practices Used

| Practice | Where Applied |
|---|---|
| **Null safety** | All SharedPreferences reads use `?.toString() ?? ''` |
| **`const` constructors** | All stateless widgets and constant values |
| **`mounted` check** | Before every `setState()` inside `async` methods |
| **`withValues(alpha:)`** | Instead of deprecated `withOpacity()` |
| **Repository pattern** | `ActivityRepository` decouples data source from UI |
| **`factory` constructor** | `ActivityModel.fromJson()` for clean deserialization |
| **`IndexedStack`** | Preserves tab state without rebuilding pages |
| **`SliverAppBar`** | Collapsible app bar on Profile and History screens |
| **`BlocListener` for navigation** | Side-effects (navigation, snackbars) handled in listener, not builder |
| **`pushAndRemoveUntil` on logout** | Prevents back-navigation into authenticated area |
| **`BlocProvider.value` in shell** | Reuses a single bloc instance across rebuilds — prevents InheritedWidget assertion |
| **`NavigatorState` captured before `await`** | Prevents deactivated-context crash in long async chains |
| **`OverlayEntry` for global persistent UI** | Inserted above the Navigator so the profile avatar button is visible on every screen — camera, results, preview — not just the Home tab |
| **`markNeedsBuild()` on `OverlayEntry`** | Forces the overlay to repaint when async state (initials) loads, since `OverlayEntry` doesn't subscribe to `setState` automatically |
| **`addPostFrameCallback` for overlay insertion** | `Overlay.of(context)` is only available after the first frame; inserting inside `initState` directly would throw |
| **Responsive utility** | `r.w()`, `r.h()`, `r.sp()` used throughout for device-agnostic sizing |
| **Single-responsibility widgets** | `_InfoCard`, `_InfoRow`, `_ScorePill`, `_ProfileAvatarButton` etc. are small and focused |

---

## 17. Step-by-Step Implementation Guide

This section walks a developer through the full implementation from scratch.

### Step 1 — Create the Activity Model

Create `lib/models/activity_model.dart`. Define `ActivityModel` with all score fields and a `fromJson` factory. Add `ActivityRepository` with a static `getMockActivities()` method returning dummy data.

**Why:** Having the model before the screens means the widgets can reference real types from the start.

### Step 2 — Create the Reusable Widgets

In order:
1. `lib/widgets/profile_header.dart` — avatar + name, depends on nothing new.
2. `lib/widgets/history_card.dart` — card layout, depends on `ActivityModel`.
3. `lib/widgets/empty_activity_widget.dart` — empty state, depends on nothing new.

**Why:** Building widgets before screens lets you develop and test each widget in isolation.

### Step 3 — Create the Screens

1. `lib/screens/profile_screen.dart`
   - Uses `SharedPreferences` to load user data on `initState`.
   - Uses `BlocListener<AuthBloc, AuthState>` to catch `AuthLogout` and navigate to `OnboardingScreen`.
   - Renders `ProfileHeader`, two `_InfoCard` groups, and a logout button.

2. `lib/screens/history_screen.dart`
   - Calls `ActivityRepository.getMockActivities()` in `initState` with a simulated delay.
   - Renders filter chips and a `SliverList` of `HistoryCard` widgets.
   - Shows `EmptyActivityWidget` when the filtered list is empty.

3. `lib/screens/home_navigation_screen.dart`
   - Creates `AuthBloc` in `initState`, provides it via `BlocProvider.value` — never inside `create`.
   - Calls `_loadInitials()` on startup to read user name from SharedPreferences.
   - Uses `IndexedStack` to keep all three tab pages mounted.
   - Wraps `IndexedStack` in a `Stack` to overlay `_ProfileAvatarButton` on the Home tab.
   - Custom `_BottomNav` with animated active indicator.

### Step 4 — Wire Up Post-Auth Navigation

Update the three files that navigate after successful login/OTP:

```dart
// Before (in otp_screen.dart, signup_screens.dart, LoginPage.dart):
MaterialPageRoute(builder: (_) => const StartJourneyScreen())

// After:
MaterialPageRoute(builder: (_) => const HomeNavigationScreen())
```

Also update imports accordingly.

### Step 5 — Apply Stability Patches

1. **`standard_camera_screen.dart`**: Capture `Navigator.of(context)` at the top of `_startScanningAnimation()` before any `await`, then use it at the navigation call site instead of `Navigator.pushReplacement(context, ...)`.

2. **`home_navigation_screen.dart`**: Ensure `AuthBloc` is created in `initState` and provided via `BlocProvider.value`, not `BlocProvider(create: ...)` in `build()`.

### Step 6 — Verify the Flow

Manual test path:
1. Launch app → tap "Start Your Scan"
2. Enter phone number → receive OTP → verify
3. Should land on `HomeNavigationScreen` (Home tab)
4. Confirm profile avatar button is visible in the top-right corner showing user initials
5. Tap the avatar → should switch to Profile tab instantly
6. Tap "History" tab → see mock analysis cards with filter chips
7. Tap "Profile" tab → see user data loaded from SharedPreferences
8. Tap "Logout" → confirm → lands back on `OnboardingScreen`
9. Press device back — should **not** return to the profile (stack was cleared)
10. Go back through the scan flow → confirm no crash during camera → preview navigation

### Step 7 — Backend Integration (when ready)

1. Replace `ActivityRepository.getMockActivities()` with the real API call.
2. Add `_refreshFromApi()` to `ProfileScreen` for fresh data; follow it with `_loadInitials()` in `HomeNavigationScreen` to keep the avatar in sync.
3. Implement `AnalysisDetailScreen` and wire up `HistoryCard.onTap`.
4. Add pull-to-refresh and pagination to `HistoryScreen`.
5. Add profile image upload to `ProfileHeader`.

---

*Generated for YouV.AI — Feature branch: `feature/Demobodycraft1`*
