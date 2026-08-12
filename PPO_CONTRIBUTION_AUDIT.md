# Contribution Audit — Sahil Singh (`amnsahil123@gmail.com`)
### Repository: `youv.ai` (Flutter mobile + web AI skin/hair analysis app)
### Audit window: repository inception (2025-11-23) → 2026-08-12
### Method: Git history, diff inspection, blame analysis, file-creation attribution across **all 76 branches**

---

## 0. Audit integrity notes (read first)

Three structural facts about this repository materially affect every number below. They are stated up front so no conclusion in this report is read out of context.

**(a) The repository has TWO root commits — two disconnected histories.**

| Root | Date | Author | Meaning |
|---|---|---|---|
| `f2bb4af` | 2025-11-23 | zenithstar1 | Original project. `origin/main` contains **only** this single commit. |
| `a41b7bd` | 2026-05-29 | **Sahil Singh** | Orphan re-import of the entire working tree (248 files, no parent). |

**Every currently active client-delivery branch** — `feature/SahilStable`, `feature/Sahilakumentisstable`, `feature/SahilNaryana`, `feature/Naryannewsetup`, `feature/akumentis-upload`, `feature/SahilDynamicUrl`, `feature/Sahil-reportsent`, `feature/SahilVersionlatest`, `hair-frontend`, `hair-camera`, and the current `feature/sahil-hairredesign` — descends from **Sahil's root `a41b7bd`**, not from the original one. The pre-2026-05-29 history lives only on the legacy branch set.

**(b) Because of (a), `git blame` on HEAD is not valid evidence of authorship.** Blame reports 100% Sahil on `standard_camera_screen.dart`, `auth_bloc.dart`, `Apiservice.dart`, `LoginPage.dart`, `skin_analysis_redesigned.dart`, `main.dart`, `onboarding_flow.dart` and `web/face_detector.js` — but that is an artifact of the re-import flattening all prior authorship into one commit. **This report deliberately does not use blame as evidence.** All attribution below comes from the legacy history, where per-commit authorship is intact.

**(c) Raw LOC is unusable without filtering.** Build output (`build/`), `node_modules/`, `.dart_tool/`, and a 90 MB `.tmp/out.dill` are committed to the repo. Unfiltered, Sahil's diff totals read **+2,347,294 / −2,177,882** — a meaningless number. All LOC figures in this report are restricted to `lib/` (application source) unless explicitly stated.

---

# 1. Executive Summary

**If a manager asked "what did this developer actually contribute?", the evidence-based answer is:**

Over a **~6-month tenure (first commit 2026-02-10, most recent 2026-08-06)**, Sahil Singh became the **primary engineer of the youv.ai client application**. He contributed **76 commits (74 non-merge)** and **+53,235 / −13,138 lines of application source in `lib/`** — approximately **64% of all application-source lines added to the project by anyone**, versus 17,291 by `gajendra82` and 12,392 by `zenithstar1`.

The contribution is not distributed evenly across trivial work. Four systems in this app are **his by creation, not by modification** — he authored the first version of each file and every subsequent revision:

1. **The AI auto-capture / face-validation pipeline** — Dart + JavaScript + native **Kotlin (523 lines)** and **Swift (358 lines)** MediaPipe plugins, with a confidence-driven capture state machine computing yaw/roll/pitch, motion delta and stability hold. (`standard_camera_screen.dart`, now 2,044 lines, created by him.)
2. **The authentication & session layer** — `auth_service.dart` (secure-storage token vault, access/refresh rotation, expiry detection, PII sanitisation) and `auth_http_client.dart` (401-triggered refresh-and-retry wrapper, multipart-safe).
3. **The user profile / activity / history subsystem** — `profile_screen.dart`, `history_screen.dart`, `home_navigation_screen.dart`, `activity_model.dart` and supporting widgets, all created in one architecture commit.
4. **The runtime API configuration and multi-tenant white-labeling layer** — `api_config.dart`, `app_config_service.dart`, `app_config_response.dart`, `otp_bypass_config.dart`, plus backend-driven feature flags. This is what allowed one codebase to ship as **four distinct client products** (Bodycraft, Akumentis, Narayana, Aesthetic).

**Strongest single signal of ownership:** the entire currently-shipping line of the product descends from a root commit he authored, and 12 of that lineage's 14 commits are his. In practice, he *is* the maintainer of the delivered application.

**Honest limits:** there is effectively **no automated test contribution** (only Flutter's default `test/widget_test.dart` exists), **no CI/CD, Docker, or cloud-infrastructure work** in this repository, and **no database or backend work** (the backend module was explicitly removed in `5b81419`). Commit hygiene is weak — build artifacts and `node_modules/` are committed, several commit messages are duplicated or non-descriptive, and one commit message materially overstates its diff. These are stated plainly rather than omitted.

---

# 2. Contribution Scorecard

| Category | Contribution | Evidence | Ownership | Complexity | Impact |
|---|---|---|---|---|---|
| **Computer-vision / auto-capture** | Created the entire face-detection + auto-capture pipeline across web (JS), Flutter, Android (Kotlin), iOS (Swift) | `ef48a1f`, `079b29c`, `70556c8`, `dbba12f`, `279adec`, `ee573be`; file-creation of `standard_camera_screen.dart`, `face_detection_service.dart`, `head_pose_calculator.dart` | **Primary ownership** | **Very High** | Enabled hands-free, quality-gated capture — the core UX of an AI analysis product |
| **Authentication & session** | Created `auth_service.dart` + `auth_http_client.dart`; token refresh, secure storage, web session persistence, international phone, OTP bypass | `ede3bb5`, `a6a652e`, `0fd9923`, `2a8b05f`, `9f0811e` | **Primary ownership** | High | Fixed users being logged out on web reload; unblocked non-Indian phone onboarding |
| **Architecture / configuration** | Centralised all endpoints; runtime-switchable API host; backend-driven feature flags | `a41b7bd`, `8a8919d`, `f214df6`, `e1fd8a8`, `ee66795`; `lib/config/api_config.dart` | **Primary ownership** | High | One codebase → 4 client deployments without forking logic |
| **Frontend (Flutter)** | Login/registration restructure, onboarding video + face-mesh animation, skin-results redesign, preview UI, profile/history UI | `7b82a1a`, `ff00319`, `3257952`, `45439d3`, `b371c3d`, `7808bcb`, `9ca5d83` | **Primary → Major contributor** | High | Full-app UI ownership; `LoginPage.dart` 1,913 lines, `skin_analysis_redesigned.dart` 3,607 lines |
| **Native mobile (Kotlin/Swift)** | `MediaPipeFaceDetectorPlugin.kt` (523 L) + `.swift` (358 L), ProGuard rules, bundled `face_landmarker.task` model | `dbba12f` | **Primary ownership** | **Very High** | On-device ML inference instead of JS-only detection |
| **Bug fixing / stabilisation** | Login redirect, camera zoom/stretch (7-commit campaign), Android landscape stream, plugin dependency conflict, unmounted-widget crash, navigation flow | `96e1fb3`, `47ed82a`→`fbef0b8`, `e5f21b1`, `ea5d464` | **Primary ownership** | Medium–High | Directly reduced field-visible defects |
| **Multi-tenant / white-label delivery** | Bodycraft, Akumentis, Narayana, Aesthetic variants | `b57eabd`, `4aef365`, `9f0811e`, `2563ac8`, `537e5f7` | **Primary ownership** | Medium–High | Enabled multiple client shipments |
| **Deployment (web)** | Build scripts (`tool/build_web.ps1/.sh`), `web/.htaccess`, `web/_headers`, `WEB_DEPLOYMENT.md` | `043d210`, `7767521`, `da6876b` | Major contributor | Medium | Repeatable web release process |
| **Performance / optimisation** | Upload-pipeline rework, frame-throttled detection loop, rAF-driven layout sync, `9337c0f` optimisation pass | `7808bcb`, `9337c0f`, `ee573be` | Primary | Medium–High | Qualitative only — **no before/after measurements exist in the repo** |
| **Testing** | **None beyond default scaffold** | only `test/widget_test.dart` | — | — | **Gap** |
| **Database** | **None in this repo** | backend removed in `5b81419` | — | — | Not applicable |
| **CI/CD, Docker, cloud infra** | **None found** | no `.github/workflows`, no Dockerfile | — | — | **Gap** |

---

# 3. Git Contribution Metrics

### 3.1 Timeline

| Metric | Value |
|---|---|
| Repository created | 2025-11-23 (`f2bb4af`, zenithstar1) |
| Project state before Sahil | ~34 commits by `gajendra82` + `zenithstar1` (Nov 2025 – Jan 2026) |
| **Sahil's first commit** | **2026-02-10** (`83ac7c0`, `7767521`, `46da829`, `da6876b`, `96e1fb3`, `9cf8d97` — 6 commits same day) |
| First *architectural* contribution | 2026-02-19 (`ef48a1f`, auto-capture + `head_pose_calculator.dart`) |
| Latest commit | 2026-08-06 (`b3c2421`) |
| Active tenure | **~6 months (2026-02-10 → 2026-08-06)** |

### 3.2 Volume

| Metric | Sahil | gajendra82 | zenithstar1 | aniket9909 |
|---|---|---|---|---|
| Commits (all branches) | **76** (74 non-merge, 2 merge) | 80 | 19 | 5 |
| `lib/` lines added | **53,235** | 17,291 | 12,392 | 2 |
| `lib/` lines deleted | 13,138 | 7,639 | 1,945 | 2 |
| `lib/` net | **+40,097** | +9,652 | +10,447 | 0 |
| Share of all `lib/` lines added | **≈ 64%** | ≈ 21% | ≈ 15% | ~0% |

- Unique `lib/` files touched by Sahil: **79**
- Unique source files touched (excluding `build/`, `.dart_tool/`): **454**
- Merge commits: 2 (`73fbc0c` — PR #23 merge; `1c7add0` — a stash/WIP artifact)

### 3.3 Activity by month (non-merge commits)

| Month | Sahil | gajendra82 | zenithstar1 |
|---|---|---|---|
| 2025-11 | — | 16 | 1 |
| 2025-12 | — | 14 | — |
| 2026-01 | — | 3 | — |
| **2026-02** | **11** | 1 | — |
| **2026-03** | **7** | — | 14 |
| **2026-04** | **3** | 46 | — |
| **2026-05** | **38** | — | — |
| **2026-06** | **12** | — | — |
| **2026-07** | **2** | — | — |
| **2026-08** | **1** | — | 4 |

**Consistency:** Sahil is the *only* author with commits in every month from Feb 2026 onward. From May 2026 onward he is effectively the sole active contributor until zenithstar1 returns for the hair module in August.

### 3.4 Stated limitations of these metrics

- **Commit count is not comparable across authors.** `gajendra82`'s 80 commits include 46 in April 2026 alone, many of them repeated `build created` commits. Sahil's 76 commits include several near-duplicate messages (`fix zoomed issue` ×3, `update the new short base url` ×4) that represent iterative debugging rather than distinct features.
- **LOC is inflated for everyone** by committed build output; the `lib/`-only figures above are the defensible ones. Even within `lib/`, large single-commit numbers (e.g. `45439d3`, +1,090 lines in `onboarding_flow.dart`) reflect a UI file rewrite, not 1,090 lines of novel logic.
- **The 2026-05-29 re-import destroys line-level provenance** on the active branch. Attribution here relies on the legacy history, which is intact.
- **Uncommitted work is not counted.** The current working tree holds 1,088 added / 832 deleted lines of hair-module changes plus a new file that are not yet in any commit (see §4, row 15).

---

# 4. Complete Feature Inventory

| # | Feature | My Role | Technical Work | Complexity | Evidence | Impact |
|---|---|---|---|---|---|---|
| 1 | **Auto-capture pipeline (mobile)** | Primary ownership | Created `standard_camera_screen.dart`, `enhanced_camera_screen.dart`, `face_detection_service.dart`, `head_pose_calculator.dart`. Confidence constants, `_ValidationStatus`, `_computeValidation` (yaw/roll/pitch from landmarks), `_checkMotion` (nose-tip delta), `_processConfidence`, stability progress + countdown, `_triggerAutoCapture` | **Very High** | `ef48a1f`, `079b29c`, `279adec`, `a4922ff`, `d875a60` | Hands-free capture; quality gate before AI inference |
| 2 | **Native MediaPipe integration** | Primary ownership | `MediaPipeFaceDetectorPlugin.kt` (523 L), `MediaPipeFaceDetectorPlugin.swift` (358 L), `MainActivity.kt`/`AppDelegate.swift` registration, `face_landmarker.task` (3.7 MB model), ProGuard keep-rules, Gradle config | **Very High** | `dbba12f` (+1,638 / −612) | On-device landmark inference on both mobile platforms |
| 3 | **Web face-detection pipeline** | Major contributor (file created by zenithstar1 2026-03-11; Sahil authored the large majority of its current 874 lines) | `web/face_detector.js`: `createFaceMeshInstance`, `getBrowserFaceDetector`, `findBestVideoElement`/`getVideoScore`, `validateBrowserFaceGeometry`, `isValidFace`, `isValidCapturedFace`, `createCroppedImage`; Dart bridge via conditional imports (`web_face_detection_web.dart` / `_stub.dart`) | High | `079b29c` (+386 JS), `2a8b05f` (+276 JS), `70556c8` | Feature parity for the web build without native code |
| 4 | **Web camera rendering architecture** | Primary ownership | `CameraLayoutManager` in JS as single source of truth for CSS transforms; `applyLayout()` resets before applying (`object-fit:cover` + `scaleX(-1)`), `sync()` on rAF, `start()` installing `ResizeObserver` + 500 ms polling + `visualViewport` resize/scroll + `orientationchange` + `visibilitychange` + `pageshow`; Dart side `ValueListenableBuilder<CameraValue>` with `MediaQuery` dependency for viewport rebuilds | High | `ee573be` (documented in commit body), `5b93e83`, `88575f1`, `dbddd08`, `a11c407`, `47ed82a` | Eliminated a recurring zoom/stretch/black-strip defect class |
| 5 | **Authentication & session layer** | Primary ownership | Created `auth_service.dart` (320 L): `FlutterSecureStorage` vault, separate web/native token keys, `getAccessToken`/`getRefreshToken`, `hasActiveSession`, `restoreSession`, `saveSession`, `clearSession(keepRegistration)`, `logoutRemote`, `refreshAccessToken`, `isAccessTokenExpired`, `_sanitizeUserData`, `_removeSensitiveFieldsFromCachedUser`, `AuthStorageException`. Created `auth_http_client.dart`: `_sendWithRetry` (refresh-on-401 then replay), `_headers`, `sendMultipart` | High | `ede3bb5` (+652 / −361 across 33 files) | Fixed web session loss on reload; centralised auth on every request |
| 6 | **Auth migration to Akumentis backend** | Primary ownership | Rewrote `LoginPage.dart` auth path (−164 L of inline logic), `auth_bloc.dart`, `main.dart` bootstrap, added `web/js/app_update.js` | Medium–High | `a6a652e` | Backend swap without a rewrite of the UI layer |
| 7 | **International phone + OTP dev bypass + Korea localisation** | Primary ownership | `auth_bloc.dart` phone normalisation, `LoginPage.dart` country handling, later `otp_bypass_config.dart` + `dev_mode_badge.dart` | Medium | `2a8b05f`, `0fd9923`, `8970857`, `9f0811e` | Unblocked non-Indian onboarding; removed OTP dependency from QA |
| 8 | **Profile / activity / history subsystem** | Primary ownership | Created `profile_screen.dart` (570 L), `history_screen.dart` (253 L), `home_navigation_screen.dart` (304 L), `activity_model.dart` (152 L), `history_card.dart` (300 L), `profile_header.dart`, `empty_activity_widget.dart`; auth-safe navigation guards in `auth_bloc`/`auth_event` | High | `9ca5d83` | Added a whole product surface (user history/activity) that did not exist |
| 9 | **Runtime / dynamic API configuration** | Primary ownership | Created `lib/config/api_config.dart` (single `dashboardOrigin` → `apiBaseUrl` → `authBaseUrl` chain), extended to runtime resolution; `README_RUNTIME_API_CONFIG.md` (442 L) | High | `a41b7bd`, `8a8919d` (+48 config, +70 service), `537e5f7` | Host switching without recompiling per client |
| 10 | **Backend-driven feature flags** | Primary ownership | Created `app_config_service.dart` (`GET /app/config`, timeout, wrapped-`data` tolerant parsing, `AppConfigException`) and `app_config_response.dart`; wired Send-Report visibility, location visibility, retake-vs-send branching | Medium–High | `f214df6`, `ee66795`, `a9811a2`, `e1fd8a8` | Feature toggles per client without an app release |
| 11 | **Skin analysis results redesign** | Major contributor (file created by zenithstar1 2026-03-16; Sahil added the overwhelming majority of its 3,607 lines) | `skin_analysis_redesigned.dart` +837/−163 then +1,449/−407; `analysis_score_parser.dart`; Narayana-specific acne colour mapping | High | `b371c3d`, `70556c8`, `9337c0f`, `9f0811e` | Primary results surface of the product |
| 12 | **Onboarding UX (video intro + face-mesh animation)** | Primary ownership | `main.dart` (+232), `onboarding_flow.dart` (+1,090/−388), `face_mapper_animation.dart`, `FaceRatioPainter.dart`, intro video assets, `intro_video_pointer_fix_{web,stub}.dart` | Medium–High | `3257952`, `45439d3`, `9337c0f` | First-impression flow; outcome-focused expectation screen |
| 13 | **Upload pipeline + preview UI rework** | Primary ownership | `image_preview_screen.dart` rewritten (+439/−…), `Apiservice.dart` upload path, conditional web face-detection imports | High | `7808bcb` (+1,007 / −624) | Faster, more reliable submission path (qualitative) |
| 14 | **Clinic location service** | Primary ownership | Created `clinic_location_service.dart` (156 L), `location_utils.dart`; removed location permission from registration; `LoginPage` +179 | Medium | `043d210`, `9337c0f`, `1400bc9` | Removed a permission prompt from the signup funnel |
| 15 | **Web deployment tooling** | Major contributor | `tool/build_web.ps1`, `tool/build_web.sh`, `web/.htaccess`, `web/_headers`, `WEB_DEPLOYMENT.md` (77 L) | Medium | `043d210`, `7767521`, `da6876b` | Repeatable web release; cache/SPA-routing headers |
| 16 | **Hair analysis (early)** | Primary ownership | Front/rear camera for hair analysis; auto hair capture; `hair_api_service.dart`, `hair_result_screen.dart`, `hair_analysis_model.dart` | Medium–High | `46da829`, `ef48a1f` | First hair-analysis capability |
| 17 | **Hair module redesign (current, UNCOMMITTED)** | **Likely** primary — see confidence note | Working-tree changes to 14 files under `lib/features/hair/` (+1,088 / −832), plus new untracked `hair_pose_coach.dart`; `hair_analysis_client.dart` −/+155, `hair_quick_scan_screen.dart` ±530, `hair_hub_screen.dart` ±405 | Medium–High | `git status` on branch `feature/sahil-hairredesign`; **not yet committed, therefore not Git-attributable** | In progress |
| 18 | **Multi-tenant white-labeling** | Primary ownership | Bodycraft (`b57eabd`), Akumentis (`4aef365`, `11ed3e1`, `2563ac8`), Narayana (`9f0811e`), Aesthetic (`537e5f7`) — endpoint, branding, and feature-surface variance | Medium–High | listed commits | 4 client-specific deliveries from one codebase |

---

# 5. Major Technical Contributions (ranked)

### #1 — Confidence-driven auto-capture pipeline
**Problem:** AI skin analysis is garbage-in/garbage-out. Users submitted off-angle, blurred, or badly framed selfies, producing unusable analyses and support load.
**My work:** Designed and implemented a capture state machine that refuses to fire until the face passes a geometric and stability gate.
**Technical implementation:** `_computeValidation(FaceDetectionFrame)` derives **yaw** (nose-tip offset against the eye-line midpoint), **roll** (inter-eye vertical delta), and **pitch** (vertical camera angle relative to face) from landmarks; `_checkMotion` tracks nose-tip delta between frames to reject movement; `_processConfidence` accumulates a stability progress value across frames, with a separate `_startWebStabilityHold` path for the web platform's noisier detector, then `_triggerAutoCapture`. Guidance strings are throttled via `_scheduleGuidanceUpdate` to avoid UI thrash. The file is now 2,044 lines and was created by him.
**Complexity:** **Very High** — real-time CV, per-frame budget, cross-platform behavioural divergence.
**Impact:** Qualitative — image quality gate before inference. No before/after metrics exist in the repo.
**Evidence:** `ef48a1f`, `079b29c`, `279adec` (`standard_camera_screen.dart` ±1,020), `a4922ff`, `d875a60`.
**Confidence:** **Confirmed.**

### #2 — Native MediaPipe face detection on Android and iOS
**Problem:** The JS/MediaPipe web detector could not deliver acceptable latency or reliability inside the mobile app.
**My work:** Wrote first-party platform plugins on both mobile platforms and moved detection on-device.
**Technical implementation:** `MediaPipeFaceDetectorPlugin.kt` (523 lines) and `MediaPipeFaceDetectorPlugin.swift` (358 lines) exposed over a Flutter platform channel, registered in `MainActivity.kt` and `AppDelegate.swift`; bundled `face_landmarker.task` (3.7 MB) as an Android asset; added `proguard-rules.pro` (46 lines) so release minification does not strip MediaPipe classes; Gradle changes for asset packaging. `face_detection_service.dart` was restructured (+537/−…) into a platform-abstracted service with `camera_setup_mobile.dart` / `camera_setup_noop.dart` conditional setup.
**Complexity:** **Very High** — this is the single most technically demanding contribution in the repository: two native languages, an ML runtime, a platform channel, and release-build minification correctness.
**Impact:** On-device inference on mobile; web path preserved unchanged.
**Evidence:** `dbba12f` (+1,638 / −612 across 20 files).
**Confidence:** **Confirmed.**

### #3 — Web camera rendering architecture (`CameraLayoutManager`)
**Problem:** A camera zoom/stretch/black-strip defect kept recurring on mobile browsers. The commit body diagnoses it precisely: stream dimensions were read once at init and dynamic changes ignored; there was no single authority for CSS transforms, so they accumulated; and viewport changes (browser address bar collapse) were not handled reactively.
**My work:** Replaced one-shot `fixVideoRendering()` with a continuously-reconciling layout authority.
**Technical implementation:** `applyLayout()` clears all inline CSS before reapplying `object-fit:cover` + `scaleX(-1)` — so transforms can never accumulate; `sync()` runs on the rAF loop and only calls `applyLayout` on actual change; `start()` installs `ResizeObserver`, a 500 ms polling fallback, `visualViewport` resize/scroll, `resize`, `orientationchange` (+350 ms settle), `visibilitychange`, `focus`, `pageshow`; `stop()` tears all of it down. On the Dart side, `ValueListenableBuilder<CameraValue>` rebuilds the preview when `previewSize` changes, and `MediaQuery.of(context)` inside the builder creates an inherited dependency so viewport changes also trigger rebuild.
**Complexity:** High — root-caused a recurring defect and replaced symptomatic patches with an invariant.
**Impact:** Ended a defect class rather than one bug. Notably, the preceding commits (`47ed82a` → `a11c407` revert → `dbddd08` → `88575f1`) show him trying CSS rotation, reverting it when it caused sideways video, and *then* re-architecting — a documented debugging progression.
**Evidence:** `ee573be` (+226 / −95), `5b93e83`.
**Confidence:** **Confirmed** (commit body is unusually detailed and matches the diff).

### #4 — Authentication and session architecture
**Problem:** Sessions did not survive a page reload on Flutter Web, auth logic was scattered across screens, and tokens were handled ad hoc.
**My work:** Extracted a dedicated auth layer and an auth-aware HTTP client.
**Technical implementation:** `auth_service.dart` (320 lines, created by him) — `FlutterSecureStorage` with distinct web keys (`auth_access_token_web`, `auth_refresh_token_web`) alongside native keys and a `_legacyTokenKey` migration path; `restoreSession`, `hasActiveSession`, `isAccessTokenExpired`, `refreshAccessToken`, `logoutRemote`, `clearSession({keepRegistration})`; `_sanitizeUserData` and `_removeSensitiveFieldsFromCachedUser` strip sensitive fields from the local cache; typed `AuthStorageException`. `auth_http_client.dart` — `_sendWithRetry` wraps every request so a 401 triggers a refresh and a single replay, and `sendMultipart` gets the same treatment (a common place where auth wrappers break). The same commit removed ~99 lines of auth handling from `Apiservice.dart` and ~100 from `auth_bloc.dart`.
**Complexity:** High — token lifecycle, platform-divergent storage, security hygiene, and a large call-site migration in one pass (33 files).
**Impact:** Users stay logged in on web reload; auth is enforced in one place rather than per-screen.
**Evidence:** `ede3bb5` (+652 / −361).
**Confidence:** **Confirmed.**

### #5 — Runtime API configuration + multi-tenant white-labeling
**Problem:** The product had to ship to four different clinic clients (Bodycraft, Akumentis, Narayana, Aesthetic) against different backends, with different enabled features and branding.
**My work:** Collapsed scattered hardcoded URLs into one derived configuration chain, then made it runtime-resolvable, then added a backend-driven feature-flag channel on top.
**Technical implementation:** `ApiConfig` derives `apiBaseUrl` from `dashboardOrigin` and `authBaseUrl` from `apiBaseUrl`, so a single constant repoints the whole app. `8a8919d` extended this to runtime resolution across `main.dart` bootstrap, `Apiservice`, `auth_bloc`, `auth_service`, `clinic_location_service` and `app_config_service`, documented in a 442-line `README_RUNTIME_API_CONFIG.md`. `AppConfigService.getConfig()` calls `GET /app/config` with a 15 s timeout and tolerant parsing (`AppConfigResponse.fromJson` accepts both bare and `{data:{...}}`-wrapped responses), driving Send-Report visibility, location visibility, and the retake-vs-send branch.
**Complexity:** High — this is the change that made the product multi-tenant.
**Impact:** Four client deliveries from one codebase without permanent forks. Directly commercial.
**Evidence:** `a41b7bd`, `8a8919d`, `f214df6`, `ee66795`, `e1fd8a8`, `b57eabd`, `4aef365`, `9f0811e`, `537e5f7`, `2563ac8`.
**Confidence:** **Confirmed.**

### #6 — Profile / activity / history subsystem
Created seven files in one commit (`9ca5d83`) establishing a product surface that did not previously exist: `profile_screen.dart` (570 L), `home_navigation_screen.dart` (304 L), `history_screen.dart` (253 L), `activity_model.dart` (152 L), `history_card.dart` (300 L), `profile_header.dart`, `empty_activity_widget.dart` — plus auth-safe navigation guards in `auth_bloc.dart`/`auth_event.dart` and a 933-line `implementation.md` design note written alongside. **Complexity: High. Ownership: Primary. Confidence: Confirmed.**

### #7 — Platform-divergent auto-capture without regressing web
`079b29c` is a notable engineering decision: rather than one pipeline forced onto both platforms, he introduced conditional-import seams (`camera_setup_mobile.dart` / `camera_setup_noop.dart`, `web_face_detection_web.dart` / `_stub.dart`) so the mobile pipeline could evolve independently while the web build kept its existing behaviour. The commit message states the constraint explicitly: *"for mobile without affecting web."* **Complexity: High. Confidence: Confirmed.**

### #8 — Upload pipeline and preview UI rework
`7808bcb` (+1,007 / −624): `image_preview_screen.dart` substantially rewritten, upload path in `Apiservice.dart` reworked, `standard_camera_screen.dart` restructured (+341/−…). **Complexity: High. Impact: qualitative — no measurements captured. Confidence: Strongly supported** (message says "optimize"; the diff confirms a rewrite but does not itself prove a speed gain).

### #9 — Skin analysis results screen
Grew `skin_analysis_redesigned.dart` from a zenithstar1-created file to 3,607 lines across `b371c3d` (+837/−163), `70556c8` (+1,449/−407), `9337c0f`, and `9f0811e` (client-specific acne colour semantics), plus `analysis_score_parser.dart`. **Ownership: Major contributor (not original creator). Confidence: Confirmed.**

### #10 — Onboarding: video intro, face mesh, scan animation
`3257952` and `45439d3` (+1,090/−388 in `onboarding_flow.dart`) built the intro-video flow, face-mesh visualisation, `FaceRatioPainter`/`FaceRatioLine`, and `face_mapper_animation.dart`; `9337c0f` later added web-specific `intro_video_pointer_fix_web.dart` to fix pointer-event capture over the video element on web. **Complexity: Medium–High. Confidence: Confirmed.**

### #11 — Cross-platform stabilisation of the web auto-capture pipeline
`70556c8` (+1,493 / −407) explicitly addresses three axes at once — web pipeline correctness, stability, and Android compatibility — touching `AndroidManifest.xml`, `build.gradle.kts`, `auth_bloc.dart`, and both camera screens. **Confidence: Confirmed.**

### #12 — Clinic location service and permission-funnel reduction
`043d210` created `clinic_location_service.dart` (156 L) and removed the location permission request from registration (`otp_screen.dart`, `signup_screens.dart`), replacing it with a config-driven, deferred model (`1400bc9`, `ee66795`). **Complexity: Medium. Impact: removed a permission prompt from the signup funnel — qualitative.**

### #13 — Web release engineering
`043d210` added `tool/build_web.ps1` and `tool/build_web.sh`, `web/.htaccess`, `web/_headers` (21 lines of cache/security headers), and `WEB_DEPLOYMENT.md`. Earlier, `7767521`/`da6876b` established the checked-in web release build. **Complexity: Medium. Ownership: Major contributor.**

### #14 — OTP dev-bypass harness
`9f0811e` added `otp_bypass_config.dart` and a visible `dev_mode_badge.dart`. Worth noting as *responsible* tooling: the bypass is gated behind explicit config and surfaces a visible on-screen badge so a bypassed build cannot be mistaken for production. **Complexity: Low–Medium, but shows judgement.**

### #15 — Recurring-defect debugging campaigns
Two multi-commit campaigns are visible in history and are strong evidence of persistence and method: the camera zoom series (`47ed82a` → `a11c407` revert → `dbddd08` → `88575f1` → `0adee5e` → `5b93e83` → `8515bad` → `fbef0b8` → resolved architecturally in `ee573be`), and the base-URL series (`61c5656` → `c47ebc9` → `30f624a` → `e5e7ea4` → resolved structurally in `a41b7bd`/`8a8919d`). In both cases the pattern is *symptomatic patches → root cause → structural fix.*

---

# 6. Bug Fixes & Problem Solving

| Problem | Investigation (per commit evidence) | Solution | My Contribution | Evidence | Impact |
|---|---|---|---|---|---|
| Camera preview zoomed/stretched on mobile web | Commit body identifies 3 root causes: one-shot stream-dim read, no single transform authority, unhandled viewport changes | `CameraLayoutManager` with reset-then-apply + 7 reactive event sources | Diagnosis, architecture, implementation, and one self-revert of a wrong hypothesis | `47ed82a`, `a11c407` (revert), `dbddd08`, `88575f1`, `5b93e83`, `ee573be` | Ended a recurring defect class |
| Black strip below camera preview | Traced to `FittedBox` removal | Restored `FittedBox`, then swapped dims for landscape-stream-on-portrait-screen | Full | `dbddd08`, `88575f1` | Visual correctness |
| Android returns landscape stream on a portrait screen | Tried CSS rotation → produced sideways video → reverted → solved via dimension swap | Dimension swap rather than rotation | Full — including recognising and reverting his own wrong fix | `47ed82a` → `a11c407` → `88575f1` | Correct Android preview |
| Users logged out on every Flutter Web reload | Web storage differs from native secure storage | Separate web token keys + `restoreSession` on bootstrap | Full | `ede3bb5` | Session persistence on web |
| Login redirecting to the wrong screen | — | Navigation guard corrections | Full | `96e1fb3`, `9cf8d97`, `ea5d464` | Correct post-login routing |
| Flutter plugin dependency conflict blocking builds | — | Resolved `.flutter-plugins-dependencies` | Full | `e5f21b1` | Unblocked the build |
| Unmounted-widget setState crash | Documented in `UNMOUNTED_WIDGET_FIX.md` (251 L) | Mount guards around async setState | Full | doc added in `a41b7bd`; guards visible in camera screens | Crash removal |
| MediaPipe classes stripped in Android release build | — | `proguard-rules.pro` keep-rules (46 L) | Full | `dbba12f` | Release build works, not just debug — a classic production-only failure |
| Non-Indian phone numbers rejected at login | — | Phone normalisation in `auth_bloc` + country UI | Full | `2a8b05f`, `0fd9923` | Unblocked international onboarding |
| Page scroll broken | — | Layout fix | Full | `26075b1` | UX |
| Backend module bloating the repo | — | Removed module + `.gitignore` update | Full | `5b81419`, `f272f03`, `7cdca3d` | Repo hygiene |

---

# 7. Performance Improvements

| Problem | Before | My Change | After | Evidence |
|---|---|---|---|---|
| Upload/preview path inefficiency | **Not measured — no baseline in repo** | Rewrote `image_preview_screen.dart` and upload path in `Apiservice.dart`; commit titled "optimize upload pipeline" | **Not measured** | `7808bcb` (+1,007/−624) |
| Per-frame layout recomputation on web | Layout reapplied unconditionally / transforms accumulating | `sync()` fires `applyLayout()` **only on change**, on the rAF loop; `ResizeObserver` replaces naive polling (polling kept only as a 500 ms fallback) | Qualitatively fewer redundant DOM writes | `ee573be` |
| Camera pre-zoom from browser-scaled stream | Browser-supplied scaled stream | Request **native sensor stream** directly | Correct framing without post-hoc scaling | `5b93e83` |
| Face detection cost per frame | — | Throttled guidance updates (`_scheduleGuidanceUpdate`), motion-gated processing, native on-device inference replacing JS on mobile | Qualitative | `dbba12f`, `279adec` |
| General optimisation pass | — | `9337c0f` "changes done for optimization" across 17 `lib/` files | **Diff shows refactoring and feature work; it does not demonstrate a measured performance gain** | `9337c0f` |

> **Explicit statement required for credibility:** this repository contains **no benchmarks, no profiling output, no performance test, and no before/after timing data**. Every performance claim above is **structurally justified but unquantified**. Do not present numeric performance improvements in a PPO discussion — present the mechanism and say the measurement was not captured.

---

# 8. Architecture & Engineering Decisions

| Decision | What it demonstrates | Why it matters |
|---|---|---|
| **Conditional-import platform seams** (`camera_setup_mobile`/`_noop`, `web_face_detection_web`/`_stub`, `intro_video_pointer_fix_web`/`_stub`) | Separation of concerns; platform abstraction | Lets mobile and web pipelines diverge without `if (kIsWeb)` scattered through UI code. This is the idiomatic Flutter answer and he applied it consistently, three separate times. |
| **Extracting `AuthService` + `AuthHttpClient` out of screens and `Apiservice`** | Layering; single responsibility | Auth policy lives in one place; every call site inherits refresh-and-retry for free, including multipart. |
| **`ApiConfig` derived-constant chain** (`dashboardOrigin` → `apiBaseUrl` → `authBaseUrl`) | Configuration as a first-class concern | One edit repoints the entire app. This is what ended the four-commit "update the new short base url" thrash. |
| **Backend-driven config (`GET /app/config`) with tolerant parsing** | API design; forward compatibility | Feature toggles without an app release; the wrapped-vs-bare response tolerance means a backend shape change does not break the client. |
| **`CameraLayoutManager` as single source of truth with reset-then-apply** | Invariant-based design over patching | Makes transform accumulation *structurally impossible* rather than fixing each occurrence. |
| **Confidence state machine separated from UI** (`_ValidationStatus`, confidence constants at file top) | Modularisation; tunability | Thresholds are tunable without touching rendering logic. |
| **Platform-channel plugin boundary for MediaPipe** | Service design across a language boundary | Native ML stays native; Dart consumes a narrow typed interface (`FaceDetectionFrame`). |
| **Typed exceptions** (`AuthStorageException`, `AppConfigException`) | Error-handling discipline | Callers can distinguish failure modes instead of catching `Exception`. |
| **PII sanitisation before local caching** | Security awareness | `_sanitizeUserData` / `_removeSensitiveFieldsFromCachedUser` keep sensitive fields out of the local cache — an unprompted security decision. |
| **Gated dev bypass with a visible badge** | Operational safety | A bypassed build cannot be silently mistaken for production. |

**Counter-evidence (stated for balance):** the same history shows weak repository hygiene — `build/`, `node_modules/`, a 90 MB `.tmp/out.dill`, a 72 MB `.dill` cache, and a stray `mediola_crm.sql` (3,856 lines) committed into `assets/images/`; ~35 top-level `*.md` status documents; several non-descriptive commit messages (`rrytu`, `new changes done`, four identical `update the new short base url`). An honest audit records this. It is a discipline gap, not a capability gap, and it is the most actionable improvement area.

---

# 9. AI-Assisted Development Analysis

**Direct evidence in the repository:**
- **6 commits carry `Co-Authored-By: Claude Sonnet 4.6`** — all authored by Sahil, all within the web-camera debugging campaign of 2026-05-21/22 (`47ed82a`, `a11c407`, `dbddd08`, `88575f1`, `5b93e83`, `ee573be`).
- **`.claude/settings.local.json` is committed in 10 commits**, all Sahil's, spanning 2026-05-20 → 2026-06-15 — confirming sustained use of an agentic coding assistant during the profile-architecture, auto-capture, and auth-architecture work.
- **`node_modules/playwright` and `playwright-core` were committed in `9337c0f`**, indicating browser-automation tooling (likely for AI-driven verification of the web build) was in use.
- No other contributor has any AI-tooling artifact in this repository.

**Fair separation of AI contribution from human engineering contribution:**

| Engineering responsibility | Who performed it | Evidence |
|---|---|---|
| **Requirements understanding** | Human | Client-specific commits (`b57eabd` bodycraft, `9f0811e` "according to narayana requirnment about acne colors", `2563ac8` "removed hair car for akumentis") encode requirements no tool could infer. |
| **Root-cause diagnosis** | Human | The `ee573be` commit body enumerates three specific causes tied to this codebase's actual behaviour; the preceding revert (`a11c407`) shows a hypothesis tested against a real device and rejected. |
| **Architecture decisions** | Human | Conditional-import seams, the `ApiConfig` chain, and extracting `AuthService` are structural choices applied consistently across months and commits — a pattern, not a generation. |
| **Integration** | Human | `ede3bb5` migrated 33 files to the new auth layer; `dbba12f` wired native plugins through Gradle, ProGuard, `MainActivity`, `AppDelegate` and the Dart service. Integration at this breadth is human-driven. |
| **Debugging & iteration** | Human | The 9-commit zoom campaign and the 4-commit base-URL campaign, each ending in a structural fix, are iterative human loops. |
| **Deployment** | Human | Build scripts, `.htaccess`/`_headers`, release-build ProGuard correctness. |
| **Maintenance** | Human | He returns to the same files for months — `LoginPage.dart` 26 times, `standard_camera_screen.dart` 22 times, `auth_bloc.dart` 20 times. |
| **Code generation (some portion)** | **AI-assisted** | The 6 trailered commits; plausibly some of the large documentation set and boilerplate elsewhere. |

**Honest verdict:** the correct characterisation is **AI-assisted implementation with full human engineering ownership.** The AI-trailered commits are concentrated in one two-day debugging window and total ~363 changed lines out of ~53,000 `lib/` lines added — a small, well-scoped slice. Critically, the *hardest* contributions (the native Kotlin/Swift MediaPipe plugins, the auth architecture migration, the multi-tenant configuration layer) carry no AI trailer.

**What cannot be determined:** whether AI assistance was used in commits that carry no trailer. Trailer presence proves assistance; trailer absence proves nothing. It is also impossible to attribute specific *lines* to a model. Any claim about which model produced which code beyond the six explicit trailers would be unsupported.

**Note on the documentation set:** the ~35 top-level `*.md` files (`ARCHITECTURE_DIAGRAM.md`, `AUTO_CAPTURE_FEATURE_GUIDE.md`, `HAIR_IMPLEMENTATION_COMPLETE.md`, etc., ~9,000 lines total) have the structural signature of AI-generated implementation summaries. **Do not present this documentation volume as a personal contribution in a PPO discussion** — it is the weakest-defensible part of the record and inviting scrutiny there would undercut the strong parts.

---

# 10. Ownership Analysis

| Project Area | Evidence of Ownership | My Responsibility | Confidence |
|---|---|---|---|
| **Camera / auto-capture / face detection** | Created `standard_camera_screen.dart`, `enhanced_camera_screen.dart`, `face_detection_service.dart`, `head_pose_calculator.dart`; touched the camera screen 22× over 6 months; sole author of both native plugins | **Sole owner** | **Confirmed** |
| **Authentication & session** | Created `auth_service.dart`, `auth_http_client.dart`; `auth_bloc.dart` modified 20× (created by gajendra82, but every 2026 change is his) | **Sole owner** | **Confirmed** |
| **API configuration & multi-tenancy** | Created `api_config.dart`, `app_config_service.dart`, `app_config_response.dart`, `otp_bypass_config.dart`; every client-variant commit is his | **Sole owner** | **Confirmed** |
| **Profile / history / navigation** | Created all 7 files in one commit; no other author has modified them | **Sole owner** | **Confirmed** |
| **Login / registration / OTP** | `LoginPage.dart` touched 26× (most-touched source file in the project by any author); `otp_screen.dart` 9×; `signup_screens.dart` 9× | **Sole owner** | **Confirmed** |
| **Onboarding flow** | `onboarding_flow.dart` 14×, `main.dart` 13× | **Sole owner** | **Confirmed** |
| **Skin analysis results** | `skin_analysis_redesigned.dart` 14× (created by zenithstar1; grew to 3,607 lines under Sahil) | **De facto owner, not originator** | **Confirmed** |
| **Web build / deployment** | `web/index.html` 12×, build scripts, headers, checked-in web release | **Primary maintainer** | **Strongly supported** |
| **The shipping codebase line itself** | Every active client branch descends from his root `a41b7bd`; 12 of that lineage's 14 commits are his | **De facto maintainer of the delivered product** | **Confirmed** |
| **Hair analysis module** | Early hair work is his (`46da829`, `ef48a1f`); `lib/features/hair/*` was created by zenithstar1 (2026-08-04); the current uncommitted redesign modifies 14 of those files | **Shared — currently the modifying engineer, not the originator** | **Likely** (uncommitted work is not Git-attributable) |
| **Testing** | No test files authored | **No ownership** | **Confirmed** |
| **Backend / database / CI/CD** | None present in this repository | **No ownership** | **Confirmed** |

---

# 11. Responsibility Growth Timeline

| Date | Work | Complexity | Responsibility level |
|---|---|---|---|
| **2026-02-10** | UI bug sweep, front/rear camera for hair analysis, login redirect fix, web release build | Low–Medium | **Onboarding** — fixes inside someone else's codebase |
| **2026-02-19** | First created files: `standard_camera_screen.dart`, `enhanced_camera_screen.dart`, `face_detection_service.dart`, `head_pose_calculator.dart` — auto hair capture | Medium–High | **Feature developer** — now creating modules, not editing them |
| **2026-02-23 → 02-27** | Onboarding video + expectation screen; face-mesh visualisation (+1,090 L); login page restructure; camera & already-login redesign | Medium–High | **Independent feature owner** across the whole front end |
| **2026-03-17 → 03-20** | Upload pipeline rework; skin-analysis redesign; **platform-specific auto-capture with explicit "without affecting web" constraint** | High | **Architectural** — introducing platform seams and reasoning about regression risk |
| **2026-03-31 → 04-01** | Cross-platform stabilisation (+1,493 L); **native Kotlin + Swift MediaPipe plugins**, ProGuard, on-device model | **Very High** | **Cross-platform / native systems engineer** |
| **2026-05-19 → 05-22** | Bodycraft white-label; profile+activity architecture (7 new files); production auto-capture pipeline; `CameraLayoutManager` re-architecture | High | **Subsystem architect + recurring-defect owner** |
| **2026-05-26 → 05-29** | International phone / OTP bypass / localisation; Akumentis refactor; **`a41b7bd` — becomes the root of the shipping codebase**; endpoint centralisation | High | **Codebase custodian** — the delivered product now branches from his commit |
| **2026-06-04 → 06-25** | Auth architecture (`ede3bb5`); Akumentis auth migration; clinic location service; **backend-driven feature flags**; web deployment tooling; optimisation pass | High | **Platform owner** — auth, config, deployment |
| **2026-06-29 → 07-24** | Runtime dynamic URL resolution (442-line design doc); Narayana acne-colour semantics; OTP bypass config; Akumentis surface changes | Medium–High | **Multi-client delivery owner** — shipping to named customers |
| **2026-08-04 → 08-12** | Hair-module redesign in progress on `feature/sahil-hairredesign` (uncommitted: 14 files, +1,088/−832, plus new `hair_pose_coach.dart`) | Medium–High | **Current: owning a redesign of another engineer's module** |

**Progression summary:** UI bug fixes → module creation → cross-platform architecture → native systems work → subsystem ownership → **custodianship of the shipping codebase** → multi-client platform delivery. The trajectory is monotonic and each step is evidenced by a step-change in the *kind* of work, not merely its volume. The clearest inflection is **2026-03-20 to 2026-04-01**, when he moved from writing Flutter features to writing native Android and iOS ML plugins.

---

# 12. Technical Skills Demonstrated

| Skill | Evidence | Level |
|---|---|---|
| **Dart / Flutter** | ~53,000 `lib/` lines added across 79 files; 2,044-line and 3,607-line screens; custom painters, `ValueListenableBuilder`, conditional imports, BLoC | **Advanced** |
| **Flutter Web** | Platform-view camera, `dart:js` interop, `visualViewport` handling, web-specific storage, SPA headers, pointer-event fixes | **Strong** |
| **Kotlin (Android)** | `MediaPipeFaceDetectorPlugin.kt` (523 L), platform channels, Gradle, ProGuard, `AndroidManifest` permissions | **Strong** |
| **Swift (iOS)** | `MediaPipeFaceDetectorPlugin.swift` (358 L), `AppDelegate` registration, `Info.plist` | **Working–Strong** |
| **JavaScript (browser APIs)** | `web/face_detector.js` (874 L): MediaPipe FaceMesh, `ResizeObserver`, `visualViewport`, rAF loops, canvas cropping, custom events | **Strong** |
| **Computer vision / on-device ML integration** | Landmark-based yaw/roll/pitch derivation, face-geometry validation, motion detection, confidence state machine, MediaPipe model bundling | **Strong** |
| **State management (BLoC)** | `auth_bloc.dart` / `auth_event.dart` / `auth_state.dart` modified 20× incl. auth-safe navigation events | **Strong** |
| **API integration** | `Apiservice.dart` (18×), multipart upload, `app/config`, profile/history/hair services, tolerant JSON parsing | **Strong** |
| **Authentication & security** | Secure storage, access/refresh rotation, expiry detection, 401 retry, PII sanitisation before caching, gated dev bypass | **Strong** |
| **Architecture / refactoring** | Layer extraction, config centralisation, platform seams, invariant-based redesign | **Strong** |
| **Debugging** | Two documented multi-commit root-cause campaigns including a self-revert; production-only ProGuard failure | **Strong** |
| **Cross-platform engineering** | Web / Android / iOS parity with deliberate divergence | **Strong** |
| **Release/deployment (web)** | Build scripts (PowerShell + bash), cache/security headers, `.htaccess`, deployment doc | **Working** |
| **Localisation / i18n** | Korea localisation, international phone handling | **Working** |
| **AI-assisted development** | Agentic tooling used and co-authorship attributed in commit trailers | **Working** (and — attributing AI co-authorship in commits is good practice worth stating) |
| **Automated testing** | **No evidence** — only the default `test/widget_test.dart` | **Not demonstrated** |
| **CI/CD** | **No evidence** — no workflows, no pipelines | **Not demonstrated** |
| **Docker / containers / cloud infra** | **No evidence** | **Not demonstrated** |
| **Backend (PHP/Laravel/Node/Python)** | **No evidence** — backend module removed from this repo | **Not demonstrated** |
| **Database / SQL** | **No evidence of design work.** (`mediola_crm.sql` was committed into `assets/images/` — an accidental inclusion, not authored schema work) | **Not demonstrated** |
| **Git hygiene** | Build output, `node_modules/`, and 160 MB+ of caches committed; duplicated/non-descriptive messages | **Below expectation — improvement area** |

---

# 13. Collaboration Analysis

**Team composition (all-branch commit counts):** `gajendra82` 80 · **Sahil Singh 76** · `zenithstar1` (Anuj) 19 · `aniket9909` 5.

| Area | Originator | Sahil's role | Nature of collaboration |
|---|---|---|---|
| Core app scaffold, `main.dart`, `onboarding_flow.dart` | zenithstar1 (Nov 2025) | Rewrote substantially from Feb 2026 | **Handoff received** |
| `Apiservice.dart`, `auth_bloc.dart`, `LoginPage.dart` | gajendra82 (Nov–Dec 2025) | Every 2026 change; ~all current behaviour | **Handoff received, then full ownership** |
| `skin_analysis_redesigned.dart` | zenithstar1 (2026-03-16) | Grew it to 3,607 lines; primary maintainer since | **Shared origin, sole subsequent owner** |
| `web/face_detector.js` | zenithstar1 (2026-03-11) | Authored the large majority of its 874 lines across `079b29c`, `2a8b05f`, `5b93e83`, `ee573be` | **Started by another, matured by Sahil** |
| Camera / auto-capture / native plugins | **Sahil** | Sole author throughout | **No collaboration — independent** |
| Auth, profile, config, feature flags | **Sahil** | Sole author throughout | **No collaboration — independent** |
| `lib/features/hair/*` (new module) | **zenithstar1** (2026-08-04) | Currently redesigning 14 of its files (uncommitted) | **Reverse handoff — Sahil is now the modifying engineer on Anuj's module** |
| Merge/integration | — | `73fbc0c` merged PR #23 from `feature/SahilVersionlatest` | Light integration responsibility |

**Explicitly not claimed:** the original project setup and the initial skin-analysis screens (gajendra82, Nov 2025 – Apr 2026, including a 46-commit April burst) and the `lib/features/hair` module scaffold (zenithstar1) are **other developers' work**. Sahil's contribution to the hair module is modification and redesign, not creation.

**Notable pattern:** from May 2026 onward Sahil is the *only* active contributor for four consecutive months. That is evidence of trust and sole responsibility — and also, honestly, means much of his later work was not peer-reviewed, which shows in the hygiene issues.

---

# 14. Before vs After

### BEFORE (project state on 2026-02-09, immediately before his first commit)
- Flutter app scaffold with landing page, basic skin-analysis screens, and image capture (gajendra82, zenithstar1).
- Manual photo capture — the user pressed a button; **no image-quality gate of any kind**.
- Hardcoded endpoints scattered across `Apiservice.dart` and screens. Single-tenant.
- Auth logic inline in screens and `auth_bloc`; **no session persistence on web**; no token refresh.
- **No** profile, history, or activity surface.
- **No** native platform code — no Kotlin or Swift plugins beyond the Flutter defaults.
- **No** onboarding intro, no face-mesh visualisation.
- Web build produced ad hoc.

### MY CONTRIBUTIONS (2026-02-10 → 2026-08-12)
- Built a **cross-platform AI auto-capture pipeline** — JS detector, Dart confidence state machine, and **native Kotlin (523 L) + Swift (358 L) MediaPipe plugins with on-device landmark inference** — including release-build correctness (ProGuard) and a re-architected web rendering layer that ended a recurring defect class.
- Built the **authentication and session layer** from nothing: secure token vault, refresh rotation, 401 retry-and-replay, web session persistence, PII sanitisation.
- Built the **profile / history / activity subsystem** (7 files, one architecture commit).
- Built the **runtime configuration and multi-tenant layer** that turned a single-client app into a **four-client product** (Bodycraft, Akumentis, Narayana, Aesthetic), including backend-driven feature flags via `GET /app/config`.
- Rebuilt onboarding, login/registration, image preview, and the skin-analysis results surface.
- Added international phone support, Korea localisation, a gated OTP dev-bypass, clinic location handling, and web deployment tooling.
- Became the **de facto maintainer of the shipping codebase** — every active client branch descends from a root commit he authored.

### CURRENT STATE (2026-08-12)
- Multi-tenant Flutter app shipping to four named clinic clients from one codebase with runtime host switching and backend-controlled feature flags.
- Hands-free, quality-gated capture on web, Android and iOS with on-device ML on mobile.
- Persistent, refresh-capable authenticated sessions across all three platforms.
- Full user surface: onboarding → capture → analysis results → profile/history.
- **Still missing:** automated tests, CI/CD, and repository hygiene.

### Significance
The difference attributable to his work is the difference between **a demo-quality skin-analysis screen** and **a multi-tenant, cross-platform product with on-device ML, real session management, and per-client configuration**. The single most commercially consequential change is the configuration/multi-tenancy layer, because it is what allowed the same codebase to be sold and delivered four times.

---

# 15. Top 10 PPO-Worthy Contributions

**1. Built the on-device face-detection capability on both mobile platforms.**
*Evidence:* `dbba12f` — `MediaPipeFaceDetectorPlugin.kt` (523 lines), `MediaPipeFaceDetectorPlugin.swift` (358 lines), bundled `face_landmarker.task`, platform-channel integration, ProGuard keep-rules; +1,638/−612 across 20 files.
*Why it matters:* This is native systems work in two languages against an ML runtime, including the release-build minification failure that only appears in production. It is the highest-difficulty contribution in the repository and it is unambiguously sole-authored.

**2. Designed and implemented the confidence-driven auto-capture state machine.**
*Evidence:* `ef48a1f`, `079b29c`, `279adec` — created `standard_camera_screen.dart` (now 2,044 lines) and `head_pose_calculator.dart`; yaw/roll/pitch derivation, motion gating, stability hold, countdown, platform-divergent web hold path.
*Why it matters:* It converts an AI product's biggest input-quality risk into an automated gate, and it is the core differentiating UX of the application.

**3. Made the product multi-tenant, enabling four client deliveries from one codebase.**
*Evidence:* `a41b7bd` (endpoint centralisation), `8a8919d` (runtime URL resolution + 442-line design doc), `f214df6`/`ee66795`/`e1fd8a8` (backend-driven flags via `GET /app/config`), and the client commits `b57eabd`, `4aef365`, `9f0811e`, `537e5f7`, `2563ac8`.
*Why it matters:* Direct commercial leverage — new clients become configuration, not forks.

**4. Built the authentication and session layer that made web sessions survive reload.**
*Evidence:* `ede3bb5` — created `auth_service.dart` (320 L) and `auth_http_client.dart`, migrating 33 files; removed ~200 lines of scattered auth logic from `Apiservice.dart` and `auth_bloc.dart`.
*Why it matters:* Fixed a user-visible defect *and* eliminated the class of defect by centralising the policy — including refresh-and-retry on multipart uploads, which is where such wrappers usually break.

**5. Root-caused and architecturally eliminated a recurring camera-rendering defect.**
*Evidence:* `ee573be` (commit body enumerates three root causes; introduces `CameraLayoutManager`), preceded by `47ed82a` → `a11c407` (self-revert of a wrong hypothesis) → `dbddd08` → `88575f1` → `5b93e83`.
*Why it matters:* Demonstrates the full engineering loop — hypothesis, device testing, disproof, reversion, root-cause analysis, invariant-based redesign. The self-revert is a *strength*, not a weakness, and worth saying so out loud.

**6. Introduced platform abstraction seams so mobile could evolve without regressing web.**
*Evidence:* `079b29c` (explicitly titled "for mobile without affecting web") — `camera_setup_mobile`/`_noop`, `web_face_detection_web`/`_stub`, later `intro_video_pointer_fix_web`/`_stub`.
*Why it matters:* Shows regression risk being reasoned about *before* the change, and the same idiom applied consistently three times.

**7. Created an entire product surface — profile, activity, and history — in one coherent architecture commit.**
*Evidence:* `9ca5d83` — 7 new files (`profile_screen.dart` 570 L, `home_navigation_screen.dart` 304 L, `history_screen.dart` 253 L, `activity_model.dart` 152 L, plus widgets), auth-safe navigation guards, and a 933-line design note.
*Why it matters:* Delivered a full vertical slice — model, service, screens, widgets, navigation — not just UI.

**8. Became the maintainer of the shipping codebase.**
*Evidence:* All active client branches descend from `a41b7bd`, a root commit he authored; 12 of that lineage's 14 commits are his; he is the sole contributor for four consecutive months (May–Aug 2026).
*Why it matters:* This is organisational trust made visible in the repository graph, not a self-assessment.

**9. Sustained ownership of the same subsystems over six months.**
*Evidence:* `LoginPage.dart` 26 revisions, `standard_camera_screen.dart` 22, `auth_bloc.dart` 20, `Apiservice.dart` 18, `skin_analysis_redesigned.dart` 14, `onboarding_flow.dart` 14 — with commits in every month from Feb 2026.
*Why it matters:* Maintenance and follow-through, not drive-by feature delivery.

**10. Used AI assistance and attributed it in commit history.**
*Evidence:* 6 commits carry `Co-Authored-By: Claude Sonnet 4.6`; the hardest contributions (native plugins, auth architecture, config layer) carry no such trailer.
*Why it matters:* Correct professional practice around AI-assisted development — provenance is recorded rather than hidden, and the record shows the assistance was scoped to a debugging window rather than substituting for the engineering.

---

# 16. PPO Contribution Statement

> Over roughly six months on the youv.ai Flutter application (first commit 2026-02-10, most recent 2026-08-06), I contributed 76 commits and approximately 53,000 added lines of application source across 79 files in `lib/` — about 64% of all application-source lines added to the project — and moved from fixing UI defects in someone else's code to maintaining the codebase that ships to customers.
>
> My primary technical contribution is the AI capture pipeline. I created the camera and face-detection modules from scratch and implemented a confidence-driven auto-capture state machine that derives head yaw, roll and pitch from facial landmarks, rejects motion between frames, and only fires once the framing has been stable long enough. To make this work on mobile, I wrote native MediaPipe plugins in Kotlin (523 lines) and Swift (358 lines) behind a Flutter platform channel, bundled the landmark model, and fixed a release-only failure where minification stripped the MediaPipe classes. On web I re-architected the preview rendering after a zoom-and-stretch defect kept recurring: rather than patch it again, I traced it to three root causes and replaced the ad hoc CSS handling with a single layout authority that resets before it applies and reconciles continuously against resize, orientation and viewport events. That ended the defect class. Along the way I reverted one of my own fixes when device testing showed it was wrong.
>
> I also built two platform layers the app did not previously have. The first is authentication and session management — a secure token store with separate web and native paths, refresh-token rotation, expiry detection, an HTTP client that transparently refreshes and replays on 401 (including multipart uploads), and sanitisation of sensitive fields before anything is cached locally. Introducing it required migrating 33 files and removing roughly 200 lines of auth logic that had been scattered across screens. The second is configuration: I collapsed hardcoded endpoints into a single derived configuration chain, extended it to resolve the API host at runtime, and added a backend-driven config endpoint that controls feature visibility. Together these are what allowed one codebase to be delivered as four separate client products — Bodycraft, Akumentis, Narayana and Aesthetic — without maintaining forks. I additionally built the profile, activity and history surface end to end, rebuilt onboarding, login and the analysis-results screen, added international phone support and localisation, and set up the web build and deployment tooling.
>
> I used AI coding assistance during this period and attributed it in commit trailers where it applied — six commits, all within a two-day debugging window, totalling a few hundred lines. The architecture decisions, the native platform work, the root-cause analysis, the 33-file integration, and six months of maintaining these subsystems were mine. I would characterise it as AI-assisted implementation under full engineering ownership, and I'd rather state that precisely than either overclaim or undersell it.
>
> Two gaps I want to name rather than have discovered. First, there is no automated test coverage for any of this work — the repository has only Flutter's default scaffold test, and given how much of what I built is stateful and platform-divergent, that is the change I would make first. Second, repository hygiene is poor: build output, `node_modules`, and large cache files are committed, and several of my commit messages are duplicated or uninformative. Neither is a capability limit, but both are things I should have handled better, particularly during the months when I was the only active contributor and nothing I wrote was being reviewed.

---

# 17. Evidence Appendix

| Date | Commit | Files / Area | Work | Type | Importance |
|---|---|---|---|---|---|
| 2026-02-10 | `83ac7c0` | UI (multiple) | UI defect sweep | Bug Fix | Low |
| 2026-02-10 | `46da829` | Hair analysis camera | Front + rear camera for hair analysis | Feature | Medium |
| 2026-02-10 | `96e1fb3`, `9cf8d97` | Login navigation | Login redirect fix | Bug Fix | Medium |
| 2026-02-10 | `7767521`, `da6876b` | `build/web` | Web release build | Deployment | Low–Medium |
| 2026-02-19 | `ef48a1f` | **Created** `standard_camera_screen.dart`, `enhanced_camera_screen.dart`, `face_detection_service.dart`, `head_pose_calculator.dart` (192 L); `Apiservice.dart` ±124 | Auto hair capture + head-pose foundation | **Feature / Architecture** | **High** |
| 2026-02-23 | `3257952` | `main.dart` +232, `onboarding_flow.dart`, intro video asset | Onboarding video + expectation screen | Feature | Medium–High |
| 2026-02-24 | `45439d3` | `onboarding_flow.dart` +1,090/−388 | Face-mesh visualisation + scan animation | Feature | Medium–High |
| 2026-02-25 | `7b82a1a` | `LoginPage.dart` | Login page restructure | Feature/Refactor | Medium |
| 2026-02-27 | `ff00319` | Camera + `already_login_screen.dart` | Redesign | Feature | Medium |
| 2026-03-02 | `26075b1` | Layout | Page scroll fix | Bug Fix | Low |
| 2026-03-17 | `7808bcb` | `image_preview_screen.dart`, `Apiservice.dart`, `standard_camera_screen.dart` (+1,007/−624) | Upload pipeline rework + preview revamp | Optimization/Refactor | **High** |
| 2026-03-17 | `c403bd8` | Retake button | Glass-effect visibility fix | Bug Fix | Low |
| 2026-03-18 | `b371c3d` | `skin_analysis_redesigned.dart` +837/−163 | Skin analysis redesign | Feature | High |
| 2026-03-20 | `079b29c` | 16 files; `face_detector.js` +386; `camera_setup_*`; `web_face_detection_*` (+1,343/−348) | Platform-specific auto-capture with web-regression guard | **Architecture** | **High** |
| 2026-03-31 | `70556c8` | `skin_analysis_redesigned.dart` +1,449/−407, `enhanced_camera_screen.dart`, `auth_bloc.dart`, Android manifest/gradle | Web pipeline fix + stability + Android compat | Bug Fix / Feature | **High** |
| 2026-04-01 | `dbba12f` | `MediaPipeFaceDetectorPlugin.kt` (523 L), `.swift` (358 L), `face_landmarker.task`, `proguard-rules.pro`, `face_detection_service.dart` ±537 | **Native on-device face capture** | **Feature / Architecture** | **Very High** |
| 2026-05-18 | `e5f21b1` | `.flutter-plugins-dependencies` | Plugin dependency conflict fix | Bug Fix | Medium (build unblocked) |
| 2026-05-19 | `b57eabd` | `LoginPage.dart` +231, `Apiservice`, `auth_bloc` | Bodycraft white-label | Feature/Config | Medium–High |
| 2026-05-19 | `61c5656`, `c47ebc9`, `30f624a`, `e5e7ea4` | Base URL | Repeated URL updates (later solved structurally) | Configuration | Low (but motivates `a41b7bd`) |
| 2026-05-20 | `9ca5d83` | **Created** `profile_screen.dart` (570), `home_navigation_screen.dart` (304), `history_screen.dart` (253), `activity_model.dart` (152), `history_card.dart` (300), `profile_header.dart`, `empty_activity_widget.dart`; `signup_screens.dart` ±662; `otp_screen.dart` ±437 | Profile + activity architecture, auth-safe navigation | **Architecture / Feature** | **High** |
| 2026-05-21 | `47ed82a` | `face_detector.js` | CSS rotation for Android landscape stream | Bug Fix (AI-assisted) | Medium |
| 2026-05-21 | `a11c407` | `face_detector.js` | **Revert** — rotation caused sideways video | Bug Fix (AI-assisted) | Medium — shows verification |
| 2026-05-21 | `dbddd08` | Camera preview | Restore `FittedBox`, remove black strip | Bug Fix (AI-assisted) | Medium |
| 2026-05-21 | `279adec` | `standard_camera_screen.dart` ±1,020 | Production confidence-driven capture pipeline | **Feature / Architecture** | **Very High** |
| 2026-05-22 | `88575f1` | Camera preview | Landscape/portrait dimension swap | Bug Fix (AI-assisted) | Medium |
| 2026-05-22 | `ee573be` | `face_detector.js` +237, `standard_camera_screen.dart` | **`CameraLayoutManager`** continuous rendering architecture | **Architecture** | **High** |
| 2026-05-22 | `5b93e83` | `face_detector.js`, `web/index.html` | Request native sensor stream (eliminate pre-zoom) | Optimization (AI-assisted) | Medium–High |
| 2026-05-22 | `5b81419`, `f272f03`, `7cdca3d` | backend module, `.gitignore` | Remove backend module, gitignore hygiene | Configuration | Medium |
| 2026-05-26 | `2a8b05f`, `0fd9923`, `8970857` | `auth_bloc.dart`, `LoginPage.dart`, `face_detector.js` +276, `web/index.html` | International phone, OTP dev bypass, Korea localisation | Feature | Medium–High |
| 2026-05-29 | `4aef365`, `11ed3e1` | Multiple | Akumentis refactor | Feature/Config | Medium |
| 2026-05-29 | **`a41b7bd`** | **Root commit, 248 files**; created `lib/config/api_config.dart` | Endpoint centralisation; becomes root of shipping lineage | **Architecture** | **High** |
| 2026-06-04 | `f214df6` | `CreateAnalysisProfileScreen.dart` +96, `LoginPage.dart` −145, `profile_service.dart`, app icons | Backend-controlled Send Report visibility | Feature | Medium–High |
| 2026-06-15 | `ede3bb5` | **Created** `auth_service.dart` (278→320 L), `auth_http_client.dart` (92 L); 33 files (+652/−361) | Persistent auth session architecture | **Architecture** | **High** |
| 2026-06-19 | `043d210` | **Created** `clinic_location_service.dart` (156 L), `tool/build_web.{ps1,sh}`, `web/.htaccess`, `web/_headers`, `WEB_DEPLOYMENT.md` | Location permission removal + web deployment tooling | Feature / Deployment | Medium–High |
| 2026-06-19 | `a6a652e` | `LoginPage.dart` −164, `main.dart`, `auth_bloc.dart`, `web/js/app_update.js` | Auth migration to Akumentis backend | Refactor/Integration | Medium–High |
| 2026-06-25 | `9337c0f` | 17 `lib/` files incl. **created** `analysis_score_parser.dart`, `intro_video_pointer_fix_web.dart` | Optimisation/refactor pass | Refactor | Medium–High |
| 2026-06-25 | `ee66795` | **Created** `app_config_service.dart`, `app_config_response.dart`; `LoginPage.dart` +125 | Configurable location visibility, retake flow, health profile UI | **Feature / Architecture** | **High** |
| 2026-06-25 | `a9811a2`, `e1fd8a8`, `1400bc9` | `app_config_response.dart`, `skin_analysis_redesigned.dart` | Send-report vs retake branching driven by config | Feature | Medium |
| 2026-06-26 | `ea5d464` | `LoginPage.dart`, `api_config.dart` | Navigation flow fix | Bug Fix | Medium |
| 2026-06-29 | `8a8919d` | `api_config.dart` +48, `app_config_service.dart` +70, `main.dart` +68, `README_RUNTIME_API_CONFIG.md` (442 L) | **Runtime dynamic API host resolution** | **Architecture** | **High** |
| 2026-06-30 | `537e5f7` | `api_config.dart` | Aesthetic client base change | Configuration | Low |
| 2026-07-17 | `9f0811e` | **Created** `otp_bypass_config.dart`, `dev_mode_badge.dart`, `height_input.dart`; `LoginPage.dart` +108, `auth_service.dart` +74, `skin_analysis_redesigned.dart` | Narayana acne-colour semantics + dev-mode tooling | Feature | Medium–High |
| 2026-07-24 | `2563ac8` | `analysis_type_screen.dart`, `api_config.dart` | Remove hair card for Akumentis | Configuration | Low |
| 2026-07-27 | `73fbc0c` | — | Merge PR #23 from `feature/SahilVersionlatest` | Integration | Low–Medium |
| 2026-08-06 | `b3c2421` | — | (commit message `rrytu` — non-descriptive) | Other | Low |
| **Uncommitted** | working tree | 14 files in `lib/features/hair/` (+1,088/−832) + new `hair_pose_coach.dart` | Hair module redesign, in progress | Feature | **Not Git-attributable** |

---

# 18. Missing Evidence / Limitations

**Cannot be determined from this repository:**

1. **Line-level provenance on the active branch.** The orphan re-import `a41b7bd` (2026-05-29) flattened all prior authorship. `git blame` on HEAD returns 100% Sahil for files demonstrably created by `gajendra82` and `zenithstar1`. Any report citing blame percentages on HEAD would be wrong. This report avoids it entirely.
2. **`origin/main` is effectively empty** (one commit). There is no canonical integrated history, so "percentage of main" cannot be computed for anyone.
3. **Backend, database, and infrastructure work.** The backend module was removed (`5b81419`) and its submodule pointer (`youvai_backend`) is a dangling reference. If Sahil did backend or deployment work, **it is not in this repository** and cannot be evidenced here.
4. **No CI/CD or GitHub metadata.** No workflows, no Actions history, no PR review comments, no issue tracker. PR #23 is referenced by a merge commit only. Code-review participation, design discussion, standups, and product decisions are all invisible to this audit.
5. **No performance measurements anywhere.** No benchmarks, profiling artifacts, or before/after timings. All optimisation claims are structural, not quantified. **Do not cite numbers.**
6. **No test coverage data**, because there are effectively no tests.
7. **AI attribution is incomplete by nature.** Six commits carry an explicit AI co-author trailer. Whether other commits used assistance is unknowable — trailer absence proves nothing. Line-level AI attribution is impossible in principle.
8. **Uncommitted work is unattributable.** The hair-redesign changes in the working tree (14 files, +1,088/−832, plus `hair_pose_coach.dart`) sit on a branch named `feature/sahil-hairredesign` on Sahil's machine — **strongly suggestive but not proven** by Git. Committing this work would convert it into citable evidence, and doing so before any PPO discussion is worth the five minutes.
9. **Squashed and duplicated commits.** Several commits share identical messages (`fix zoomed issue` ×3, `feat(profile): fix mobile browser camera view with video view to` ×5, `update the new short base url` ×4), some with near-empty diffs. Some may be rebase or force-push artifacts. Individual commit counts should not be read as individual units of work.
10. **`1c7add0`** is a `git stash` artifact (`WIP on feature/Demobodycraft`), not deliberate work.
11. **Some commit messages materially overstate their diffs.** `e4f503e` is titled *"implement guest cart + login checkout flow with backend cart migration and real OTP auth"* but its diff contains **only deletions of build artifacts (52 files, 216,658 deletions) and no application code**. Per Rule 4, the diff governs: **this feature cannot be substantiated from this repository** and should not be claimed. Flagged as **UNCERTAIN**.
12. **Branches not fully audited.** 76 branches exist; several legacy ones (`Toofani`, `dilip`, `meta`, `combined`, `demo`, `m_skinanalysis`, `buildcraft`) were surveyed for authorship only, not diff-inspected. Author totals include them, so the volume figures are complete; the feature inventory may be marginally incomplete.
13. **`assets/images/mediola_crm.sql` (3,856 lines)** was committed in `45439d3`. This is an unrelated CRM dump accidentally included — **not evidence of database design work**, and should not be presented as such.

**Confidence key applied throughout:** Confirmed = multiple independent git signals agree (file creation + diff content + repeated modification). Strongly supported = diff content supports it but one signal is missing. Likely = circumstantial (e.g. branch naming). Uncertain = commit message and diff disagree. Not enough evidence = absent from the repository.

---

# MY ACTUAL CONTRIBUTION — ONE PAGE

**Duration and scale.** Six months, 2026-02-10 to 2026-08-06. 76 commits. **+53,235 / −13,138 lines of Flutter application source across 79 files — roughly 64% of every application-source line added to this project by anyone**, against 17,291 from the next contributor. Commits in every single month from February onward, and the sole active contributor for four consecutive months.

**What I built that did not exist before me.** Four systems, each created file-by-file and maintained afterward:

- **A cross-platform AI capture pipeline.** A confidence-driven state machine that derives head yaw, roll and pitch from facial landmarks, rejects inter-frame motion, holds for stability, and only then captures — plus the **native Kotlin (523 lines) and Swift (358 lines) MediaPipe plugins** that run landmark inference on-device, the bundled model, the platform channel, and the ProGuard rules that keep it working in release builds. This is the technically hardest work in the repository and it is entirely sole-authored.
- **An authentication and session layer.** Secure token storage with divergent web/native paths, refresh-token rotation, expiry detection, an HTTP client that transparently refreshes and replays on 401 including multipart uploads, and PII sanitisation before local caching. Introducing it meant migrating 33 files and deleting ~200 lines of auth logic scattered through screens.
- **A runtime configuration and multi-tenant layer.** A derived endpoint chain, runtime host resolution, and a backend-driven `GET /app/config` feature-flag channel — **the change that let one codebase ship as four client products** (Bodycraft, Akumentis, Narayana, Aesthetic) without forks.
- **The profile, activity and history surface.** Seven files in one architecture commit — model, screens, widgets, and auth-safe navigation.

**How technically significant it is.** The strongest evidence is not volume, it is *kind*. In six months the work moved from UI defect fixes, to creating Flutter modules, to writing native Android and iOS ML plugins, to owning platform layers, to being trusted with client delivery. The clearest engineering signal in the whole history is the camera-rendering campaign: nine commits in which I patched a defect, reverted my own fix after device testing disproved it, root-caused three separate underlying causes, and then replaced the ad hoc handling with a single layout authority that makes the failure structurally impossible. That loop — hypothesis, disproof, reversion, root cause, invariant — is what distinguishes engineering from feature coding.

**Ownership, stated conservatively.** Every active client-delivery branch descends from a root commit I authored, and 12 of that lineage's 14 commits are mine. I have touched `LoginPage.dart` 26 times, the camera screen 22, `auth_bloc.dart` 20, `Apiservice.dart` 18 — over six months, not one sprint. That is maintenance and follow-through, visible in the graph rather than asserted.

**On AI assistance, honestly.** I used agentic coding tools and recorded it: six commits carry an explicit AI co-author trailer, all inside one two-day debugging window, totalling a few hundred lines out of ~53,000. The native plugins, the auth architecture, the configuration layer, the 33-file migration, the root-cause work and six months of maintenance carry no such trailer. The accurate description is **AI-assisted implementation under full engineering ownership** — and attributing it in commit history rather than hiding it is itself the correct practice.

**What I did not do, so it is not discovered later.** No automated tests beyond Flutter's default scaffold. No CI/CD, Docker, or cloud infrastructure in this repository. No backend or database work — the backend module was removed early. Repository hygiene is poor: build output, `node_modules`, and 160 MB+ of cache files are committed, and several commit messages are duplicated or uninformative. One commit message (`e4f503e`) claims a checkout/cart feature its diff does not contain, so I do not claim that feature. These are real gaps; the first two are the things I would fix before anything else.

**Why this justifies strong PPO consideration.** In six months I went from fixing other people's UI bugs to being the person the shipping codebase branches from. I built the capability that differentiates the product (on-device AI capture across three platforms), the layer that makes it sellable to multiple clients (runtime configuration and feature flags), and the layer that makes it usable (persistent authenticated sessions). I diagnosed and structurally eliminated a recurring production defect rather than patching it a tenth time. I did this largely without review, shipped to four named customers, and I can point to a specific commit for every claim in this document — including the ones that are unflattering.
