import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'image_preview_screen.dart';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui' as ui;

/// =================================================
/// COLORS
/// =================================================
const _kBurgundy = Color(0xFF6B3A3A);
const _kMutedBurgundy = Color(0xFF8A7A72);
const _kIvory = Color(0xFFFDF8F3);
const _kCardCream = Color(0xFFFFFBF7);
const _kBlush = Color(0xFFE8B4BA);
const _kRoseAccent = Color(0xFFD79096);
const _kSoftGreen = Color(0xFF7BAF6E);
const _kValidGreenBg = Color(0xFFE8F5E4);
const _kDarkText = Color(0xFF3A2A22);
const List<String> _skinFacts = [
  "Your skin renews itself roughly every 28 days.",
  "Skin is the body’s largest organ.",
  "Hydration helps maintain skin elasticity.",
  "UV exposure accelerates skin aging.",
  "Collagen keeps skin firm and smooth.",
  "Sleep helps repair skin cells.",
  "Stress can trigger acne flare-ups.",
  "Healthy skin contains billions of microbes.",
  "Water intake supports skin barrier function.",
  "Skin protects your body from bacteria and pollution."
];

/// =================================================
/// SCAN PHASE ENUM
/// =================================================
enum ScanPhase { live, freeze, mapping, analyzing, calculating, complete }

/// =================================================
/// CAMERA SCREEN
/// =================================================
class StandardCameraScreen extends StatefulWidget {
  final CameraLensDirection lensDirection;
  final Function(Uint8List imageBytes, String fileName)? onImageCaptured;
  final bool isHair;

  const StandardCameraScreen({
    super.key,
    required this.lensDirection,
    this.onImageCaptured,
    this.isHair = false,
  });

  @override
  State<StandardCameraScreen> createState() => _StandardCameraScreenState();
}

class _StandardCameraScreenState extends State<StandardCameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  bool _faceDetected = false;

  bool _initialized = false;
  bool _capturing = false;
  bool _initializing = false;
  bool _isDisposed = false;
  bool _hasNavigated = false;

  late CameraLensDirection _lens;

  Timer? _autoCaptureTimer;
  html.EventListener? _faceEventListener;

  // Auto-capture ring animation
  AnimationController? _autoRingController;

  // Countdown state
  int _countdown = 0; // 3, 2, 1, 0=idle
  bool _holdSteady = false;
  Timer? _countdownTimer;
  Timer? _engagementTimer;
  int _liveWaitSeconds = 0;

  // Scan phase state
  ScanPhase _phase = ScanPhase.live;
  Uint8List? _capturedBytes;
  String? _capturedFileName;

  // Scanning animation controllers
  AnimationController? _scanController;
  String _scanText = '';
  int _highlightIndex = -1; // for skin marker highlighting
  double _ringProgress = 0.0;
  String _getRandomSkinFact() {
  final facts = List<String>.from(_skinFacts);
  facts.shuffle();
  return facts.first;
}

  /// =================================================
  /// INIT
  /// =================================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _lens = widget.lensDirection;

    _autoRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _startEngagementTimer();

    _initCamera();
    _faceEventListener = (event) {
      final e = event as html.CustomEvent;
      final detected = e.detail as bool;

      if (mounted && !_isDisposed && _phase == ScanPhase.live) {
        final wasDetected = _faceDetected;
        if (wasDetected != detected) {
          debugPrint('[FaceDetection] event: $detected');
        }
        setState(() {
          _faceDetected = detected;
        });

        if (detected && !wasDetected) {
          // Face just became stable → start countdown
          _startCountdown();
        } else if (!detected && wasDetected) {
          // Face lost → cancel countdown
          _cancelCountdown();
        }
      }
    };
    html.window.addEventListener("faceDetected", _faceEventListener);
  }

  /// =================================================
  /// WAIT FEEDBACK TIMER
  /// =================================================
  void _startEngagementTimer() {
    _engagementTimer?.cancel();
    _engagementTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isDisposed || _hasNavigated) return;

      if (_phase != ScanPhase.live || _capturing || _holdSteady || _countdown > 0 || _faceDetected) {
        if (_liveWaitSeconds != 0) {
          setState(() => _liveWaitSeconds = 0);
        }
        return;
      }

      setState(() => _liveWaitSeconds++);
    });
  }

  /// =================================================
  /// CAMERA INIT
  /// =================================================
  Future<void> _initCamera() async {
    if (_initializing) return;
    _initializing = true;

    try {
      final cameras = await availableCameras();
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == _lens,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      if (mounted) {
        setState(() {
          _controller = controller;
          _initialized = true;
        });
      }
      // Start face detection after camera is fully set up and rendered
      _startFaceDetectionWithRetry();
    } catch (e) {
      debugPrint("Camera init error: $e");
    }

    _initializing = false;
  }

  /// =================================================
  /// FACE DETECTION INIT (with retry until video is found)
  /// =================================================
  void _startFaceDetectionWithRetry([int attempt = 0]) {
    if (!mounted || _isDisposed || attempt > 15) return;

    Future.delayed(Duration(milliseconds: attempt == 0 ? 500 : 800), () {
      if (!mounted || _isDisposed) return;

      // Find ALL video elements and pick the one that's actually playing
      final videos = html.document.querySelectorAll("video");
      html.Element? bestVideo;

      for (int i = 0; i < videos.length; i++) {
        final v = videos[i] as html.VideoElement;
        if (v.videoWidth > 0 && v.readyState >= 2) {
          bestVideo = v;
          break;
        }
      }

      // Fallback: take the first video element even if not ready yet
      // (the JS side will wait for readyState)
      if (bestVideo == null && videos.isNotEmpty) {
        bestVideo = videos.first;
      }

      if (bestVideo != null) {
        try {
          js_util.callMethod(html.window, 'startFaceDetection', [bestVideo]);
          debugPrint("Face detection started on video element (attempt $attempt)");
        } catch (e) {
          debugPrint("Face detection start error: $e");
        }
      } else {
        debugPrint("No video element found (attempt $attempt), retrying...");
        _startFaceDetectionWithRetry(attempt + 1);
      }
    });
  }

  /// =================================================
  /// COUNTDOWN LOGIC: 3 → 2 → 1 → Hold steady → Capture
  /// =================================================
  void _startCountdown() {
    if (_capturing || _hasNavigated || _isDisposed || _countdown > 0) return;

    debugPrint('[CaptureFlow] countdown started');

    setState(() {
      _countdown = 3;
      _holdSteady = false;
    });
    _autoRingController?.forward(from: 0.0);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDisposed || _hasNavigated) {
        timer.cancel();
        return;
      }
      // If face lost during countdown, abort
      if (!_faceDetected) {
        _cancelCountdown();
        return;
      }

      if (_countdown > 1) {
        setState(() => _countdown--);
      } else if (_countdown == 1) {
        // Countdown finished → show "Hold steady"
        setState(() {
          _countdown = 0;
          _holdSteady = true;
        });
        timer.cancel();
        // Hold steady briefly, then capture.
        Future.delayed(const Duration(milliseconds: 450), () {
          () async {
            final stableBeforeCapture = await _verifyFaceContinuous(const Duration(milliseconds: 280));
            if (mounted && !_isDisposed && !_hasNavigated && stableBeforeCapture && !_capturing) {
              debugPrint('[CaptureFlow] hold steady complete -> capture');
              _capture();
            } else {
              debugPrint('[CaptureFlow] hold steady failed, cancelling countdown');
              _cancelCountdown();
            }
          }();
        });
      }
    });
  }

  Future<bool> _verifyFaceContinuous(Duration duration) async {
    final checks = (duration.inMilliseconds / 70).ceil();
    for (int i = 0; i < checks; i++) {
      if (!mounted || _isDisposed || _hasNavigated || !_faceDetected) {
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 70));
    }
    return mounted && !_isDisposed && !_hasNavigated && _faceDetected;
  }

  void _cancelCountdown() {
    debugPrint('[CaptureFlow] countdown cancelled');
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _autoCaptureTimer?.cancel();
    _autoCaptureTimer = null;
    _autoRingController?.reset();
    if (mounted && !_isDisposed) {
      setState(() {
        _countdown = 0;
        _holdSteady = false;
      });
    }
  }

  /// =================================================
  /// APP LIFECYCLE
  /// =================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _controller;
    if (camera == null || !camera.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      // Stop face detection so it can restart with new camera
      try {
        js_util.callMethod(html.window, 'stopFaceDetection', []);
      } catch (_) {}
      setState(() {
        _initialized = false;
        _faceDetected = false;
        _countdown = 0;
        _holdSteady = false;
        _controller = null;
      });
      camera.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  /// =================================================
  /// CAPTURE → SCANNING FLOW
  /// =================================================
  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !_initialized || _capturing || !controller.value.isInitialized || _isDisposed || _hasNavigated) {
      return;
    }
    // Block capture if no face detected (skip for hair mode)
    if (!widget.isHair && !_faceDetected) {
      debugPrint('[CaptureFlow] capture blocked: no face detected');
      return;
    }
    try {
      if (!mounted || _isDisposed || _hasNavigated) return;
      debugPrint('[CaptureFlow] capture started');
      setState(() => _capturing = true);
      _autoCaptureTimer?.cancel();
      _autoRingController?.reset();

      final pic = await controller.takePicture();
      final bytes = await pic.readAsBytes();
      if (!mounted || _isDisposed || _hasNavigated) return;

      _capturedBytes = bytes;
      _capturedFileName = pic.name;
      debugPrint('[CaptureFlow] capture success: ${bytes.lengthInBytes} bytes');

      // Enter scanning phases
      _startScanningAnimation();
    } catch (e) {
      debugPrint("Capture error: $e");
      if (mounted && !_isDisposed) {
        setState(() => _capturing = false);
      }
    }
  }

  /// =================================================
  /// SCANNING ANIMATION SEQUENCE
  /// =================================================
  Future<void> _startScanningAnimation() async {
    if (!mounted || _isDisposed || _hasNavigated) return;

    // PHASE 0: Freeze (400ms)
    setState(() {
      _phase = ScanPhase.freeze;
      _scanText = '';
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || _isDisposed || _hasNavigated) return;

    // PHASE 1: Mapping (1.5s)
    setState(() {
      _phase = ScanPhase.mapping;
      _scanText = 'Mapping facial structure…';
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _isDisposed || _hasNavigated) return;

    // PHASE 2: Analyzing (2s) — sequential highlights with micro-label cycling
    setState(() {
      _phase = ScanPhase.analyzing;
      _scanText = 'Analyzing visible skin markers…';
    });
    const microLabels = ['Hydration', 'Pigmentation', 'Pore Visibility', 'Acne Activity'];
    for (int i = 0; i < 6; i++) {
      if (!mounted || _isDisposed || _hasNavigated) return;
      setState(() {
        _highlightIndex = i;
        _scanText = microLabels[i % microLabels.length];
      });
      await Future.delayed(const Duration(milliseconds: 380));
    }
    if (!mounted || _isDisposed || _hasNavigated) return;
    setState(() => _scanText = 'Analyzing visible skin markers…');
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted || _isDisposed || _hasNavigated) return;

    // PHASE 3: Calculating with random skin facts
setState(() {
  _phase = ScanPhase.calculating;
  _scanText = _getRandomSkinFact();
  _ringProgress = 0;
});

const ringSteps = 20;

for (int i = 1; i <= ringSteps; i++) {
  await Future.delayed(const Duration(milliseconds: 50));

  if (!mounted || _isDisposed || _hasNavigated) return;

  setState(() {
    _ringProgress = i / ringSteps;

    // change fact every few steps
    if (i % 5 == 0) {
      _scanText = _getRandomSkinFact();
    }
  });
}

await Future.delayed(const Duration(milliseconds: 350));
if (!mounted || _isDisposed || _hasNavigated) return;
    // Animate ring from 0 to 0.85 over 1s
   
    if (!mounted || _isDisposed || _hasNavigated) return;

    
    if (!mounted || _isDisposed || _hasNavigated) return;

    // Navigate
    _hasNavigated = true;
    if (mounted && context.mounted && _capturedBytes != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ImagePreviewScreen(
            imageBytes: _capturedBytes!,
            fileName: _capturedFileName ?? 'capture.jpg',
            isHair: widget.isHair,
          ),
        ),
      );
    }
  }

  /// =================================================
  /// DISPOSE
  /// =================================================
  @override
  void dispose() {
    _isDisposed = true;
    _autoCaptureTimer?.cancel();
    _countdownTimer?.cancel();
    _engagementTimer?.cancel();
    _autoRingController?.dispose();
    _scanController?.dispose();
    if (_faceEventListener != null) {
      html.window.removeEventListener("faceDetected", _faceEventListener);
    }
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  /// =================================================
  /// CAMERA PREVIEW
  /// =================================================
  Widget _buildCameraPreview() {
    if (_isDisposed || _hasNavigated) return const SizedBox.shrink();

    final controller = _controller;
    if (!_initialized || controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: _kBlush),
        ),
      );
    }

    if (controller.value.previewSize == null) {
      Future.microtask(() {
        if (mounted) _initCamera();
      });
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: _kBlush)),
      );
    }

    final size = controller.value.previewSize!;
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.height,
            height: size.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  /// =================================================
  /// BUILD
  /// =================================================
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;
    final isLive = _phase == ScanPhase.live;
    final isScanning = _phase != ScanPhase.live;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── CAMERA ──
          Positioned.fill(child: _buildCameraPreview()),

          // ── DIM OVERLAY (during scanning) ──
          if (isScanning)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _phase == ScanPhase.freeze ? 0.10 : 0.12,
                  duration: const Duration(milliseconds: 300),
                  child: Container(color: Colors.black),
                ),
              ),
            ),

          // ── BLUR OVERLAY (freeze only) ──
          if (_phase == ScanPhase.freeze)
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

          // ── SOFT GRADIENT (live only) ──
          if (isLive)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.15),
                        Colors.transparent,
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.50),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── HEADER (live) ──
          if (isLive)
            Positioned(
              top: topPadding + 12,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    "SKIN ANALYSIS",
                    style: TextStyle(
                      letterSpacing: 3,
                      color: _kIvory.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Position your face\nwithin the frame",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "serif",
                      fontSize: 22,
                      color: _kIvory.withOpacity(0.95),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

          // ── FACE GUIDE OVERLAY (live + freeze) ──
          if (_phase == ScanPhase.live || _phase == ScanPhase.freeze)
            Align(
              alignment: const Alignment(0, -0.08),
              child: IgnorePointer(
                child: _FaceGuideOverlay(faceDetected: _faceDetected),
              ),
            ),

          // ── VALIDATION CHIPS (live) ──
          if (isLive)
            Positioned(
              top: topPadding + 96,
              left: 0,
              right: 0,
              child: Center(
                child: _ValidationChips(faceDetected: _faceDetected),
              ),
            ),

          // ── FACE DETECTED PILL / COUNTDOWN / HOLD STEADY (live) ──
          if (isLive)
            Align(
              alignment: const Alignment(0, 0.42),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _holdSteady
                    ? Container(
                        key: const ValueKey('hold'),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _kSoftGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kSoftGreen.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt, size: 16, color: _kSoftGreen),
                            const SizedBox(width: 6),
                            Text(
                              "Hold steady…",
                              style: TextStyle(
                                fontSize: 14,
                                color: _kSoftGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _countdown > 0
                        ? Container(
                            key: ValueKey('cd_$_countdown'),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kBlush.withOpacity(0.2),
                              border: Border.all(color: _kBlush.withOpacity(0.6), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '$_countdown',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontFamily: 'serif',
                                  fontWeight: FontWeight.bold,
                                  color: _kIvory.withOpacity(0.95),
                                ),
                              ),
                            ),
                          )
                        : _faceDetected
                            ? Container(
                                key: const ValueKey('detected'),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _kValidGreenBg.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 16, color: _kSoftGreen),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Face detected",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _kSoftGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),

          // ── CAPTURE BUTTON (live) ──
          if (isLive)
            Align(
              alignment: const Alignment(0, 0.72),
              child: _CaptureButton(
                enabled: _initialized && !_capturing && _controller != null && _controller!.value.isInitialized && (widget.isHair || _faceDetected),
                faceDetected: _faceDetected,
                autoRingController: _autoRingController,
                subLabel: (_countdown > 0 || _holdSteady)
                    ? 'Hold still…'
                    : _faceDetected
                        ? 'Auto-capturing…'
                        : 'Position your face in frame',
                onTap: (_initialized && !_capturing && _controller != null && _controller!.value.isInitialized && (widget.isHair || _faceDetected))
                    ? _capture
                    : null,
              ),
            ),

          // ── BOTTOM LABEL (live) ──
          if (isLive)
            Positioned(
              bottom: screenH * 0.05,
              left: 0,
              right: 0,
              child: Text(
                _buildLiveBottomLabel(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kIvory.withOpacity(0.65),
                  fontSize: 12,
                ),
              ),
            ),

          // ── SCANNING OVERLAY ──
          if (isScanning) _buildScanOverlay(),
        ],
      ),
    );
  }

  /// =================================================
  /// LIVE BOTTOM LABEL
  /// =================================================
  String _buildLiveBottomLabel() {
    if (_countdown > 0) return 'Keep your face steady';
    if (_holdSteady) return 'Capturing…';
    if (_faceDetected) return 'Nice. Snap incoming…';

    const tips = [
      'Ensure neutral expression',
      'Remove glasses',
      'Use even lighting',
      'Keep phone at eye level',
    ];
    final tip = tips[(_liveWaitSeconds ~/ 3) % tips.length];

    if (_liveWaitSeconds <= 0) {
      return 'Align your face in frame';
    }
    return 'Finding face... ${_liveWaitSeconds}s  •  $tip';
  }

  /// =================================================
  /// SCANNING OVERLAY WIDGET
  /// =================================================
  Widget _buildScanOverlay() {
    final screenW = MediaQuery.of(context).size.width;

    return Positioned.fill(
      child: IgnorePointer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // Mapping mesh lines (Phase 1)
            if (_phase == ScanPhase.mapping)
              SizedBox(
                width: screenW * 0.65,
                height: screenW * 0.65 * 1.3,
                child: CustomPaint(
                  painter: _MeshPainter(),
                ),
              ),

            // Skin markers (Phase 2)
            if (_phase == ScanPhase.analyzing)
              SizedBox(
                width: screenW * 0.65,
                height: screenW * 0.65 * 1.3,
                child: CustomPaint(
                  painter: _SkinMarkerPainter(highlightIndex: _highlightIndex),
                ),
              ),

            // Ring progress (Phase 3)
            if (_phase == ScanPhase.calculating || _phase == ScanPhase.complete)
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _RingProgressPainter(
                    progress: _ringProgress,
                    color: _kBlush,
                  ),
                  child: Center(
                    child: Text(
                      '${(_ringProgress * 100).toInt()}',
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'serif',
                        color: _kIvory.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            const Spacer(flex: 2),

            // Scan text
            if (_scanText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Text(
                  _scanText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'serif',
                    color: _kIvory.withOpacity(0.85),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// =================================================
/// VALIDATION CHIPS
/// =================================================
class _ValidationChips extends StatelessWidget {
  final bool faceDetected;
  const _ValidationChips({required this.faceDetected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chip(label: "Face aligned", valid: faceDetected),
        const SizedBox(width: 6),
        _Chip(label: "Good lighting", valid: faceDetected),
        const SizedBox(width: 6),
        _Chip(label: "Neutral expression", valid: faceDetected),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool valid;
  const _Chip({required this.label, required this.valid});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: valid ? _kValidGreenBg.withOpacity(0.85) : _kIvory.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: valid ? null : Border.all(color: _kBurgundy.withOpacity(0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.circle_outlined,
            size: 12,
            color: valid ? _kSoftGreen : _kMutedBurgundy,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: valid ? const Color(0xFF4A7A3A) : _kBurgundy,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// =================================================
/// CAPTURE BUTTON (with auto-ring)
/// =================================================
class _CaptureButton extends StatelessWidget {
  final bool enabled;
  final bool faceDetected;
  final AnimationController? autoRingController;
  final VoidCallback? onTap;
  final String subLabel;

  const _CaptureButton({
    required this.enabled,
    required this.faceDetected,
    required this.subLabel,
    this.autoRingController,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring when face detected
                  if (faceDetected)
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _kBlush.withOpacity(0.35),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  // Auto-ring progress
                  if (autoRingController != null && faceDetected)
                    AnimatedBuilder(
                      animation: autoRingController!,
                      builder: (_, __) => SizedBox(
                        width: 96,
                        height: 96,
                        child: CustomPaint(
                          painter: _AutoRingPainter(
                            progress: autoRingController!.value,
                            color: _kBlush,
                          ),
                        ),
                      ),
                    ),
                  // Outer ring
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: faceDetected
                            ? _kBlush.withOpacity(0.9)
                            : _kIvory.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                  // Inner fill
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _kBlush,
                          _kRoseAccent,
                        ],
                      ),
                      boxShadow: faceDetected
                          ? [
                              BoxShadow(
                                color: _kBlush.withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subLabel,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 13,
            color: _kIvory.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

/// =================================================
/// AUTO RING PAINTER
/// =================================================
class _AutoRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _AutoRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(1.5),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_AutoRingPainter old) => old.progress != progress;
}

/// =================================================
/// FACE GUIDE OVERLAY
/// =================================================
class _FaceGuideOverlay extends StatelessWidget {
  final bool faceDetected;
  const _FaceGuideOverlay({required this.faceDetected});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.70;
    return Center(
      child: SizedBox(
        width: width,
        height: width * 1.30,
        child: CustomPaint(painter: _FacePainter(faceDetected: faceDetected)),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final bool faceDetected;
  const _FacePainter({required this.faceDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final ovalColor = faceDetected
        ? _kBlush.withOpacity(0.85)
        : const Color(0xFFFDF8F3).withOpacity(0.6);

    // Glow aura when face detected
    if (faceDetected) {
      final glowPaint = Paint()
        ..color = _kBlush.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawOval(Offset.zero & size, glowPaint);
    }

    // Oval
    final ovalPaint = Paint()
      ..color = ovalColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceDetected ? 2.0 : 1.5;
    canvas.drawOval(Offset.zero & size, ovalPaint);

    // Vertical center line
    final linePaint = Paint()
      ..color = ovalColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.08),
      Offset(size.width / 2, size.height * 0.92),
      linePaint,
    );

    // Eye markers (two small horizontal lines)
    final eyeY = size.height * 0.38;
    final eyeLen = size.width * 0.08;
    final leftEyeX = size.width * 0.32;
    final rightEyeX = size.width * 0.68;

    canvas.drawLine(
      Offset(leftEyeX - eyeLen / 2, eyeY),
      Offset(leftEyeX + eyeLen / 2, eyeY),
      linePaint,
    );
    canvas.drawLine(
      Offset(rightEyeX - eyeLen / 2, eyeY),
      Offset(rightEyeX + eyeLen / 2, eyeY),
      linePaint,
    );

    // Chin boundary mark
    final chinY = size.height * 0.90;
    final chinLen = size.width * 0.10;
    canvas.drawLine(
      Offset(size.width / 2 - chinLen / 2, chinY),
      Offset(size.width / 2 + chinLen / 2, chinY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.faceDetected != faceDetected;
}

/// =================================================
/// MESH PAINTER (Phase 1 — Mapping)
/// =================================================
class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kIvory.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    // Vertical center
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    // Horizontal center
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Simple grid overlay for "mesh" feel
    const divisions = 8;
    for (int i = 1; i < divisions; i++) {
      final x = size.width * i / divisions;
      final y = size.height * i / divisions;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Oval outline
    final ovalPaint = Paint()
      ..color = _kIvory.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(Offset.zero & size, ovalPaint);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

/// =================================================
/// SKIN MARKER PAINTER (Phase 2 — Analyzing)
/// =================================================
class _SkinMarkerPainter extends CustomPainter {
  final int highlightIndex;
  _SkinMarkerPainter({required this.highlightIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // 5 zones: forehead, left cheek, right cheek, under-eye, chin
    final zones = [
      Offset(size.width * 0.50, size.height * 0.15),  // forehead
      Offset(size.width * 0.25, size.height * 0.48),  // left cheek
      Offset(size.width * 0.75, size.height * 0.48),  // right cheek
      Offset(size.width * 0.50, size.height * 0.40),  // under-eye
      Offset(size.width * 0.50, size.height * 0.58),  // T-zone
      Offset(size.width * 0.50, size.height * 0.80),  // chin
    ];

    for (int i = 0; i < zones.length; i++) {
      final active = i <= highlightIndex;
      final paint = Paint()
        ..color = active
            ? _kBlush.withOpacity(0.5)
            : _kIvory.withOpacity(0.1)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(zones[i], active ? 24 : 16, paint);

      if (active) {
        final ringPaint = Paint()
          ..color = _kBlush.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(zones[i], 32, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SkinMarkerPainter old) => old.highlightIndex != highlightIndex;
}

/// =================================================
/// RING PROGRESS PAINTER (Phase 3 — Calculating)
/// =================================================
class _RingProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    final bgPaint = Paint()
      ..color = _kIvory.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingProgressPainter old) => old.progress != progress;
}