import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'image_preview_screen.dart';
import 'dart:ui' as ui;
import '../services/face_detection_service.dart';
import '../utils/web_face_detection.dart' as web_face;

Timer? _faceStableTimer;

// --- CONFIDENCE CONSTANTS ----------------------------------------------------
const _kCameraWarmupMs = 1500;
const _kStabilityHoldMs = 1500;
const _kMotionThreshold = 0.016;
const _kMinFaceWidthRatio = 0.24;
const _kMaxFaceWidthRatio = 0.74;

const _kLostFramesThreshold = 5;
const _kFeedbackDebounceMs = 600;

/// =================================================
/// VALIDATION STATUS
/// =================================================
class _ValidationStatus {
  final bool faceDetected;
  final bool centeredOk;
  final bool distanceOk;
  final bool poseOk;
  final bool motionOk;
  final bool lightingOk;
  final bool tooClose;
  final bool tooFar;

  const _ValidationStatus({
    this.faceDetected = false,
    this.centeredOk = false,
    this.distanceOk = false,
    this.poseOk = false,
    this.motionOk = true,
    this.lightingOk = false,
    this.tooClose = false,
    this.tooFar = false,
  });

  bool get allOk =>
      faceDetected && centeredOk && distanceOk && poseOk && motionOk && lightingOk;

  String get primaryGuidance {
    if (!faceDetected) return 'Position your face in the frame';
    if (!centeredOk) return 'Center your face';
    if (tooFar) return 'Move slightly closer';
    if (tooClose) return 'Move slightly back';
    if (!poseOk) return 'Look straight ahead';
    if (!motionOk) return 'Hold still';
    if (!lightingOk) return 'Improve your lighting';
    return 'Hold still...';
  }

  @override
  bool operator ==(Object other) =>
      other is _ValidationStatus &&
      faceDetected == other.faceDetected &&
      centeredOk == other.centeredOk &&
      distanceOk == other.distanceOk &&
      poseOk == other.poseOk &&
      motionOk == other.motionOk &&
      lightingOk == other.lightingOk &&
      tooClose == other.tooClose &&
      tooFar == other.tooFar;

  @override
  int get hashCode => Object.hash(
        faceDetected,
        centeredOk,
        distanceOk,
        poseOk,
        motionOk,
        lightingOk,
        tooClose,
        tooFar,
      );
}

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
  "Skin is the body's largest organ.",
  "Hydration helps maintain skin elasticity.",
  "UV exposure accelerates skin aging.",
  "Collagen keeps skin firm and smooth.",
  "Sleep helps repair skin cells.",
  "Stress can trigger acne flare-ups.",
  "Healthy skin contains billions of microbes.",
  "Water intake supports skin barrier function.",
  "Skin protects your body from bacteria and pollution.",
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
  Object? _faceDetectedListenerSub;
  FaceDetectionService? _nativeFaceDetectionService;
  StreamSubscription<FaceDetectionFrame>? _nativeFaceSubscription;
  bool _isStartingNativeImageStream = false;
  int _missedFaceFrames = 0;

  // Auto-capture ring animation
  AnimationController? _autoRingController;

  // Hold steady / countdown state (kept for UX pill)
  int _countdown = 0;
  bool _holdSteady = false;
  Timer? _countdownTimer;
  Timer? _engagementTimer;
  int _liveWaitSeconds = 0;

  // Scan phase state
  ScanPhase _phase = ScanPhase.live;
  Uint8List? _capturedBytes;
  String? _capturedFileName;

  // Scanning animation
  AnimationController? _scanController;
  String _scanText = '';
  int _highlightIndex = -1;
  double _ringProgress = 0.0;

  // -- CONFIDENCE SYSTEM ----------------------------------------------------
  _ValidationStatus _validation = const _ValidationStatus();
  DateTime? _stabilityStartTime;
  double _stabilityProgress = 0.0;
  List<double>? _prevNosePos;
  bool _cameraWarmedUp = false;
  Timer? _warmupTimer;
  String _guidanceMessage = 'Position your face in the frame';
  Timer? _feedbackDebounceTimer;

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
      duration: const Duration(milliseconds: _kStabilityHoldMs),
    );

    _startEngagementTimer();
    _initCamera();

    if (kIsWeb && !widget.isHair) {
      _faceDetectedListenerSub = web_face.addFaceDetectedListener((detected) {
        if (!mounted || _isDisposed || _phase != ScanPhase.live) return;
        if (!_cameraWarmedUp) return;

        final wasDetected = _faceDetected;
        if (wasDetected != detected) {
          debugPrint('[FaceDetection] web event: $detected');
        }

        final validation = _ValidationStatus(
          faceDetected: detected,
          centeredOk: detected,
          distanceOk: detected,
          poseOk: detected,
          motionOk: true,
          lightingOk: detected,
        );

        setState(() {
          _faceDetected = detected;
          _validation = validation;
        });
        _scheduleGuidanceUpdate(validation.primaryGuidance);

        if (detected && !wasDetected) {
          _faceStableTimer?.cancel();
          _faceStableTimer = Timer(const Duration(milliseconds: 500), () {
            if (!mounted || _isDisposed || !_faceDetected || _capturing) return;
            _startWebStabilityHold();
          });
        } else if (!detected && wasDetected) {
          _faceStableTimer?.cancel();
          _cancelCountdown();
          _resetStability();
        }
      });
    }
  }

  /// =================================================
  /// WEB STABILITY HOLD
  /// =================================================
  void _startWebStabilityHold() {
    if (!mounted || _isDisposed || !_faceDetected || _capturing) return;

    _stabilityStartTime = DateTime.now();
    _autoRingController?.stop();
    _autoRingController?.animateTo(
      1.0,
      duration: const Duration(milliseconds: _kStabilityHoldMs),
      curve: Curves.linear,
    );

    _faceStableTimer?.cancel();
    _faceStableTimer = Timer(
      const Duration(milliseconds: _kStabilityHoldMs),
      () {
        if (!mounted || _isDisposed || !_faceDetected || _capturing) {
          _resetStability();
          return;
        }
        _triggerAutoCapture();
      },
    );
  }

  /// =================================================
  /// ENGAGEMENT TIMER
  /// =================================================
  void _startEngagementTimer() {
    _engagementTimer?.cancel();
    _engagementTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isDisposed || _hasNavigated) return;

      if (_phase != ScanPhase.live ||
          _capturing ||
          _holdSteady ||
          _countdown > 0 ||
          _faceDetected) {
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
        kIsWeb ? ResolutionPreset.high : ResolutionPreset.veryHigh,
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

      // Warmup delay: ignore detections until auto-exposure/focus settle
      _warmupTimer?.cancel();
      _warmupTimer = Timer(const Duration(milliseconds: _kCameraWarmupMs), () {
        if (!mounted || _isDisposed) return;
        _cameraWarmedUp = true;
        debugPrint('[Confidence] camera warmed up -- detection active');
      });

      _startFaceDetectionWithRetry();
      await _startNativeFaceDetection(controller, cam);
    } catch (e) {
      debugPrint("Camera init error: $e");
    }

    _initializing = false;
  }

  /// =================================================
  /// NATIVE FACE DETECTION
  /// =================================================
  Future<void> _startNativeFaceDetection(
    CameraController controller,
    CameraDescription camera,
  ) async {
    if (kIsWeb || widget.isHair || _isDisposed) return;

    _nativeFaceDetectionService ??= FaceDetectionService();
    final service = _nativeFaceDetectionService!;
    if (!service.isInitialized) {
      await service.initialize();
    }
    service.setSensorRotation(camera.sensorOrientation);

    await _nativeFaceSubscription?.cancel();
    _nativeFaceSubscription = service.landmarksStream.listen((frame) {
      if (!mounted || _isDisposed || _phase != ScanPhase.live) return;
      if (!_cameraWarmedUp) return;

      final validation = _computeValidation(frame);
      _processConfidence(validation);
    });

    await _startNativeImageStream(controller, service);
  }

  /// =================================================
  /// COMPUTE VALIDATION
  /// =================================================
  _ValidationStatus _computeValidation(FaceDetectionFrame frame) {
    if (!frame.hasFace) {
      _prevNosePos = null;
      return const _ValidationStatus();
    }

    final faceW = frame.faceWidthRatio;
    final faceH = frame.faceHeightRatio;

    // Bounding box must sit fully inside the frame
    const frameMargin = 0.04;
    final halfW = (faceW / 2).clamp(0.0, 0.5);
    final halfH = (faceH / 2).clamp(0.0, 0.5);
    final minX = frame.faceCenterXRatio - halfW;
    final maxX = frame.faceCenterXRatio + halfW;
    final minY = frame.faceCenterYRatio - halfH;
    final maxY = frame.faceCenterYRatio + halfH;
    if (minX < frameMargin ||
        maxX > (1.0 - frameMargin) ||
        minY < frameMargin ||
        maxY > (1.0 - frameMargin)) {
      return const _ValidationStatus(faceDetected: true);
    }

    // Distance
    final tooFar = faceW < _kMinFaceWidthRatio;
    final tooClose = faceW > _kMaxFaceWidthRatio;
    final distanceOk = !tooFar && !tooClose;

    // Centering
    final centeredOk =
        frame.faceCenterOffsetX <= 0.28 && frame.faceCenterOffsetY <= 0.28;

    // Vertical position relative to oval guide
    if (frame.faceCenterYRatio < 0.38 || frame.faceCenterYRatio > 0.64) {
      return _ValidationStatus(
        faceDetected: true,
        distanceOk: distanceOk,
        tooFar: tooFar,
        tooClose: tooClose,
        centeredOk: false,
      );
    }

    // Require core landmarks
    if (frame.landmarks.length < 3) {
      return _ValidationStatus(
        faceDetected: true,
        distanceOk: distanceOk,
        tooFar: tooFar,
        tooClose: tooClose,
        centeredOk: centeredOk,
      );
    }

    final nose = frame.landmarks[0];
    final leftEye = frame.landmarks[1];
    final rightEye = frame.landmarks[2];
    final hasCoreLandmarks = [nose, leftEye, rightEye].every(
      (p) => p.length >= 2 && p[0].isFinite && p[1].isFinite,
    );
    if (!hasCoreLandmarks) {
      return _ValidationStatus(
        faceDetected: true,
        distanceOk: distanceOk,
        tooFar: tooFar,
        tooClose: tooClose,
        centeredOk: centeredOk,
      );
    }

    final eyeDx = (leftEye[0] - rightEye[0]).abs();
    if (eyeDx <= 6) {
      return _ValidationStatus(
        faceDetected: true,
        distanceOk: distanceOk,
        tooFar: tooFar,
        tooClose: tooClose,
        centeredOk: centeredOk,
      );
    }

    // Head pose — pure landmark geometry, fully device-independent.
    // MediaPipe euler angles are skipped entirely: they vary wildly across
    // Android sensors and routinely report 25-40° for a forward-facing person.
    //
    // Yaw proxy: nose tip should sit near the horizontal midpoint of the eyes.
    //   Threshold 0.75× inter-eye distance catches true side profiles.
    final noseToEyeMidX =
        (nose[0] - ((leftEye[0] + rightEye[0]) / 2)).abs();
    final yawOk = noseToEyeMidX <= eyeDx * 0.75;

    // Roll proxy: eyes should be at roughly the same height.
    //   0.40 allows ≈22° of head tilt — fine for a natural selfie.
    final eyeDy = (leftEye[1] - rightEye[1]).abs();
    final rollOk = (eyeDy / eyeDx) <= 0.40;

    final poseOk = yawOk && rollOk;

    // Nose centered check (reuse noseToEyeMidX already computed above)
    final noseCenteredOk = noseToEyeMidX <= eyeDx * 1.40;

    // Eye vertical position to match oval guide
    final eyeMidY = (leftEye[1] + rightEye[1]) / 2;
    final eyeMidYRatio =
        (eyeMidY / math.max(frame.imageHeight, 1.0)).clamp(0.0, 1.0);
    final eyePositionOk = eyeMidYRatio >= 0.28 && eyeMidYRatio <= 0.48;

    // Nose must be below eyes
    if (nose[1] <= eyeMidY) {
      return _ValidationStatus(
        faceDetected: true,
        distanceOk: distanceOk,
        tooFar: tooFar,
        tooClose: tooClose,
        centeredOk: centeredOk && eyePositionOk,
        poseOk: false,
      );
    }

    // Motion stability
    final motionOk = _checkMotion(frame, nose);

    // Lighting quality -- eye spread ratio as a proxy for image sharpness/exposure
    final eyeDistanceRatio = eyeDx / math.max(frame.imageWidth, 1.0);
    final lightingOk = eyeDistanceRatio >= 0.05 && eyeDistanceRatio <= 0.45;

    return _ValidationStatus(
      faceDetected: true,
      distanceOk: distanceOk,
      tooFar: tooFar,
      tooClose: tooClose,
      centeredOk: centeredOk && eyePositionOk && noseCenteredOk,
      poseOk: poseOk,
      motionOk: motionOk,
      lightingOk: lightingOk,
    );
  }

  /// =================================================
  /// MOTION CHECK (nose-tip delta between frames)
  /// =================================================
  bool _checkMotion(FaceDetectionFrame frame, List<double> nose) {
    final nosePosX = nose[0] / math.max(frame.imageWidth, 1.0);
    final nosePosY = nose[1] / math.max(frame.imageHeight, 1.0);

    final prev = _prevNosePos;
    _prevNosePos = [nosePosX, nosePosY];

    if (prev == null) return true;

    final dx = nosePosX - prev[0];
    final dy = nosePosY - prev[1];
    return math.sqrt(dx * dx + dy * dy) < _kMotionThreshold;
  }

  /// =================================================
  /// PROCESS CONFIDENCE (called every native frame)
  /// =================================================
  void _processConfidence(_ValidationStatus validation) {
    if (!mounted || _isDisposed || _capturing || _phase != ScanPhase.live) {
      return;
    }

    final wasDetected = _faceDetected;

    // Hysteresis: don't drop face on a single missed frame
    if (!validation.faceDetected) {
      _missedFaceFrames++;
    } else {
      _missedFaceFrames = 0;
    }
    final effectiveDetected = validation.faceDetected ||
        (wasDetected && _missedFaceFrames < _kLostFramesThreshold);
    final effectiveValidation =
        effectiveDetected ? validation : const _ValidationStatus();

    final needsStateUpdate = _validation != effectiveValidation ||
        wasDetected != (effectiveDetected && validation.faceDetected);
    if (needsStateUpdate) {
      setState(() {
        _validation = effectiveValidation;
        _faceDetected = effectiveDetected && validation.faceDetected;
      });
    }

    _scheduleGuidanceUpdate(effectiveValidation.primaryGuidance);

    if (!effectiveValidation.allOk) {
      // Reset stability timer on any failed condition
      if (_stabilityStartTime != null || _stabilityProgress > 0) {
        _stabilityStartTime = null;
        if (mounted && !_isDisposed) {
          setState(() => _stabilityProgress = 0.0);
        }
        _autoRingController?.stop();
        _autoRingController?.value = 0.0;
      }
      // Cancel hold-steady if face is actually lost
      if (_holdSteady && !effectiveDetected) {
        _cancelCountdown();
        _resetStability();
      }
      return;
    }

    // All conditions pass -- advance stability clock
    _stabilityStartTime ??= DateTime.now();
    final elapsed = DateTime.now().difference(_stabilityStartTime!);
    final progress =
        (elapsed.inMilliseconds / _kStabilityHoldMs).clamp(0.0, 1.0);

    if ((progress - _stabilityProgress).abs() > 0.008) {
      setState(() => _stabilityProgress = progress);
      _autoRingController?.value = progress;
    }

    if (progress >= 1.0 && !_capturing && !_holdSteady) {
      debugPrint('[Confidence] ${_kStabilityHoldMs}ms stable -> capture');
      _triggerAutoCapture();
    }
  }

  /// =================================================
  /// TRIGGER AUTO CAPTURE
  /// =================================================
  void _triggerAutoCapture() {
    if (_capturing || _hasNavigated || _isDisposed || _holdSteady) return;
    if (!widget.isHair && !_faceDetected) return;

    setState(() {
      _holdSteady = true;
      _stabilityProgress = 1.0;
    });
    _autoRingController?.value = 1.0;

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || _isDisposed || _hasNavigated || _capturing) return;
      if (!widget.isHair && !_faceDetected) {
        _resetStability();
        return;
      }
      debugPrint('[Confidence] hold steady -> capture');
      _capture();
    });
  }

  /// =================================================
  /// RESET STABILITY
  /// =================================================
  void _resetStability() {
    _faceStableTimer?.cancel();
    _stabilityStartTime = null;
    _prevNosePos = null;
    _autoRingController?.stop();
    _autoRingController?.value = 0.0;
    if (mounted && !_isDisposed) {
      setState(() {
        _stabilityProgress = 0.0;
        _holdSteady = false;
        _countdown = 0;
      });
    }
  }

  /// =================================================
  /// GUIDANCE MESSAGE (debounced to avoid flicker)
  /// =================================================
  void _scheduleGuidanceUpdate(String message) {
    if (message == _guidanceMessage) return;
    _feedbackDebounceTimer?.cancel();
    _feedbackDebounceTimer = Timer(
      const Duration(milliseconds: _kFeedbackDebounceMs),
      () {
        if (mounted && !_isDisposed) {
          setState(() => _guidanceMessage = message);
        }
      },
    );
  }

  /// =================================================
  /// FACE DETECTION INIT (web retry until video ready)
  /// =================================================
  void _startFaceDetectionWithRetry([int attempt = 0]) {
    if (!kIsWeb || widget.isHair) return;
    if (!mounted || _isDisposed || attempt > 15) return;

    Future.delayed(Duration(milliseconds: attempt == 0 ? 500 : 800), () {
      if (!mounted || _isDisposed) return;
      Future<void>(() async {
        try {
          final started = await web_face.startFaceDetection();
          if (started) {
            debugPrint("Face detection started (attempt $attempt)");
            return;
          }
        } catch (e) {
          debugPrint("Face detection start error: $e");
        }
        debugPrint("No video element found (attempt $attempt), retrying...");
        _startFaceDetectionWithRetry(attempt + 1);
      });
    });
  }

  /// =================================================
  /// CANCEL COUNTDOWN / HOLD STEADY
  /// =================================================
  void _cancelCountdown() {
    debugPrint('[CaptureFlow] countdown cancelled');
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _autoCaptureTimer?.cancel();
    _autoCaptureTimer = null;
    _autoRingController?.stop();
    _autoRingController?.value = 0.0;
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
      if (kIsWeb) {
        web_face.stopFaceDetection().catchError((_) {});
      }
      _faceStableTimer?.cancel();
      _warmupTimer?.cancel();
      _nativeFaceSubscription?.cancel();
      _nativeFaceSubscription = null;
      unawaited(_stopNativeImageStream());
      setState(() {
        _initialized = false;
        _faceDetected = false;
        _countdown = 0;
        _holdSteady = false;
        _validation = const _ValidationStatus();
        _stabilityProgress = 0.0;
        _stabilityStartTime = null;
        _cameraWarmedUp = false;
        _controller = null;
      });
      camera.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  /// =================================================
  /// IMAGE STREAM
  /// =================================================
  Future<void> _startNativeImageStream(
    CameraController controller,
    FaceDetectionService service,
  ) async {
    if (kIsWeb || widget.isHair || _isStartingNativeImageStream) return;
    if (!controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    _isStartingNativeImageStream = true;
    try {
      await controller.startImageStream((CameraImage image) {
        service.processCameraFrame(image);
      });
    } catch (e) {
      debugPrint('[SkinAuto] startImageStream error: $e');
    } finally {
      _isStartingNativeImageStream = false;
    }
  }

  Future<void> _stopNativeImageStream() async {
    final controller = _controller;
    if (controller == null) return;
    if (!controller.value.isInitialized ||
        !controller.value.isStreamingImages) {
      return;
    }
    try {
      await controller.stopImageStream();
    } catch (e) {
      debugPrint('[SkinAuto] stopImageStream error: $e');
    }
  }

  /// =================================================
  /// CAPTURE -> SCANNING FLOW
  /// =================================================
  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !_initialized ||
        _capturing ||
        !controller.value.isInitialized ||
        _isDisposed ||
        _hasNavigated) {
      return;
    }
    if (!widget.isHair && !_faceDetected) {
      debugPrint('[CaptureFlow] capture blocked: no face detected');
      return;
    }
    try {
      if (!mounted || _isDisposed || _hasNavigated) return;
      debugPrint('[CaptureFlow] capture started');
      setState(() => _capturing = true);
      _autoCaptureTimer?.cancel();
      _autoRingController?.stop();

      if (!kIsWeb && !widget.isHair) {
        await _stopNativeImageStream();
      }

      final pic = await controller.takePicture();
      final bytes = await pic.readAsBytes();
      if (!mounted || _isDisposed || _hasNavigated) return;

      if (kIsWeb && !widget.isHair) {
        if (!_faceDetected) {
          debugPrint('[WEB] capture rejected: face lost before capture');
          await _rejectInvalidCapture(controller);
          return;
        }
      }

      _capturedBytes = bytes;
      _capturedFileName = pic.name;
      debugPrint('[CaptureFlow] capture success: ${bytes.lengthInBytes} bytes');

      _startScanningAnimation();
    } catch (e) {
      debugPrint("Capture error: $e");
      if (mounted && !_isDisposed) {
        setState(() => _capturing = false);
      }
      if (!kIsWeb && !widget.isHair) {
        final service = _nativeFaceDetectionService;
        if (service != null) {
          await _startNativeImageStream(controller, service);
        }
      }
    }
  }

  Future<void> _rejectInvalidCapture(CameraController controller) async {
    if (mounted && !_isDisposed && !_hasNavigated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No clear face detected. Reposition and try again.'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _capturing = false;
        _countdown = 0;
        _holdSteady = false;
        _phase = ScanPhase.live;
      });
      _resetStability();
    }

    if (kIsWeb || widget.isHair) {
      _faceStableTimer?.cancel();
      if (_faceDetected) {
        _faceStableTimer = Timer(const Duration(milliseconds: 1200), () {
          if (!mounted || _isDisposed || _hasNavigated) return;
          if (_phase != ScanPhase.live || _capturing || !_faceDetected) return;
          _startWebStabilityHold();
        });
      }
      return;
    }

    final service = _nativeFaceDetectionService;
    if (service != null) {
      await _startNativeImageStream(controller, service);
    }
  }

  /// =================================================
  /// SCANNING ANIMATION SEQUENCE
  /// =================================================
  Future<void> _startScanningAnimation() async {
    if (!mounted || _isDisposed || _hasNavigated) return;

    final navigator = Navigator.of(context);

    setState(() {
      _phase = ScanPhase.freeze;
      _scanText = '';
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || _isDisposed || _hasNavigated) return;

    setState(() {
      _phase = ScanPhase.mapping;
      _scanText = 'Mapping facial structure...';
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _isDisposed || _hasNavigated) return;

    setState(() {
      _phase = ScanPhase.analyzing;
      _scanText = 'Analyzing visible skin markers...';
    });
    const microLabels = [
      'Hydration',
      'Pigmentation',
      'Pore Visibility',
      'Acne Activity',
    ];
    for (int i = 0; i < 6; i++) {
      if (!mounted || _isDisposed || _hasNavigated) return;
      setState(() {
        _highlightIndex = i;
        _scanText = microLabels[i % microLabels.length];
      });
      await Future.delayed(const Duration(milliseconds: 380));
    }
    if (!mounted || _isDisposed || _hasNavigated) return;
    setState(() => _scanText = 'Analyzing visible skin markers...');
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted || _isDisposed || _hasNavigated) return;

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
        if (i % 5 == 0) _scanText = _getRandomSkinFact();
      });
    }

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || _isDisposed || _hasNavigated) return;

    if (!_hasNavigated && _capturedBytes != null) {
      _hasNavigated = true;
      navigator.pushReplacement(
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
    _faceStableTimer?.cancel();
    _warmupTimer?.cancel();
    _feedbackDebounceTimer?.cancel();
    if (_faceDetectedListenerSub != null) {
      web_face.removeFaceDetectedListener(_faceDetectedListenerSub!);
      _faceDetectedListenerSub = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    _nativeFaceSubscription?.cancel();
    _nativeFaceSubscription = null;
    unawaited(_nativeFaceDetectionService?.dispose());
    _nativeFaceDetectionService = null;
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
    if (!_initialized ||
        controller == null ||
        !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: _kBlush)),
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

    if (kIsWeb) {
      debugPrint(
        '[CameraPreview:web] previewSize=${size.width.toInt()}Ã—${size.height.toInt()}'
        ' | screen=${MediaQuery.of(context).size.width.toInt()}'
        'Ã—${MediaQuery.of(context).size.height.toInt()}'
        ' | dpr=${MediaQuery.of(context).devicePixelRatio}',
      );
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: CameraPreview(controller),
            ),
          ),
        ),
      );
    }

    // Native: swap w<->h for portrait aspect ratio
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
    final isLive = _phase == ScanPhase.live;
    final isScanning = _phase != ScanPhase.live;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // -- CAMERA --
          Positioned.fill(child: _buildCameraPreview()),

          // -- DIM OVERLAY (during scanning) --
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

          // -- BLUR OVERLAY (freeze only) --
          if (_phase == ScanPhase.freeze)
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

          // -- SOFT GRADIENT (live only) --
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
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.50),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // -- HEADER (live) --
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
                      color: _kIvory.withValues(alpha: 0.85),
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
                      color: _kIvory.withValues(alpha: 0.95),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

          // -- FACE GUIDE OVERLAY (live + freeze) --
          if (_phase == ScanPhase.live || _phase == ScanPhase.freeze)
            Align(
              alignment: const Alignment(0, -0.08),
              child: IgnorePointer(
                child: _FaceGuideOverlay(faceDetected: _faceDetected),
              ),
            ),

          // -- VALIDATION CHIPS (live) --
          if (isLive)
            Positioned(
              top: topPadding + 96,
              left: 0,
              right: 0,
              child: Center(
                child: _ValidationChips(validation: _validation),
              ),
            ),

          // -- CAPTURE BUTTON + STATUS PILL + BOTTOM LABEL (live) --
          if (isLive)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status pill
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _holdSteady
                        ? Container(
                            key: const ValueKey('hold'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _kSoftGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _kSoftGreen.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: _kSoftGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Hold steady...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _kSoftGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _faceDetected
                        ? Container(
                            key: const ValueKey('detected'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _validation.allOk
                                  ? _kValidGreenBg.withValues(alpha: 0.85)
                                  : _kIvory.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: _validation.allOk
                                  ? null
                                  : Border.all(
                                      color: _kIvory.withValues(alpha: 0.25),
                                    ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _validation.allOk
                                      ? Icons.check_circle
                                      : Icons.info_outline,
                                  size: 16,
                                  color: _validation.allOk
                                      ? _kSoftGreen
                                      : _kIvory.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _validation.allOk
                                      ? "Locking in..."
                                      : _guidanceMessage,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _validation.allOk
                                        ? _kSoftGreen
                                        : _kIvory.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                  const SizedBox(height: 12),
                  // Capture button
                  _CaptureButton(
                    enabled:
                        _initialized &&
                        !_capturing &&
                        _controller != null &&
                        _controller!.value.isInitialized &&
                        (widget.isHair || _faceDetected),
                    faceDetected: _faceDetected,
                    autoRingController: _autoRingController,
                    subLabel: _holdSteady
                        ? 'Hold still...'
                        : _faceDetected
                        ? (_validation.allOk
                            ? 'Locking in...'
                            : _guidanceMessage)
                        : 'Position your face in frame',
                    onTap:
                        (_initialized &&
                            !_capturing &&
                            _controller != null &&
                            _controller!.value.isInitialized &&
                            (widget.isHair || _faceDetected))
                        ? _capture
                        : null,
                  ),
                  const SizedBox(height: 8),
                  // Bottom label
                  Text(
                    _buildLiveBottomLabel(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _kIvory.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // -- SCANNING OVERLAY --
          if (isScanning) _buildScanOverlay(),
        ],
      ),
    );
  }

  /// =================================================
  /// LIVE BOTTOM LABEL
  /// =================================================
  String _buildLiveBottomLabel() {
    if (_holdSteady) return 'Capturing...';
    if (_faceDetected && _validation.allOk) return 'Locking confidence...';
    if (_faceDetected) return _guidanceMessage;

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
    return 'Finding face... ${_liveWaitSeconds}s  *  $tip';
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

            if (_phase == ScanPhase.mapping)
              SizedBox(
                width: screenW * 0.65,
                height: screenW * 0.65 * 1.3,
                child: CustomPaint(painter: _MeshPainter()),
              ),

            if (_phase == ScanPhase.analyzing)
              SizedBox(
                width: screenW * 0.65,
                height: screenW * 0.65 * 1.3,
                child: CustomPaint(
                  painter: _SkinMarkerPainter(highlightIndex: _highlightIndex),
                ),
              ),

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
                        color: _kIvory.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            const Spacer(flex: 2),

            if (_scanText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Text(
                  _scanText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'serif',
                    color: _kIvory.withValues(alpha: 0.85),
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
  final _ValidationStatus validation;
  const _ValidationChips({required this.validation});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chip(
          label: "Face aligned",
          valid: validation.faceDetected && validation.centeredOk,
        ),
        const SizedBox(width: 6),
        _Chip(
          label: "Good lighting",
          valid: validation.faceDetected && validation.lightingOk,
        ),
        const SizedBox(width: 6),
        _Chip(
          label: "Head straight",
          valid: validation.faceDetected && validation.poseOk,
        ),
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
        color: valid
            ? _kValidGreenBg.withValues(alpha: 0.85)
            : _kIvory.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: valid
            ? null
            : Border.all(color: _kBurgundy.withValues(alpha: 0.25), width: 0.8),
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
                            color: _kBlush.withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  // Stability ring progress
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
                            ? _kBlush.withValues(alpha: 0.9)
                            : _kIvory.withValues(alpha: 0.5),
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
                        colors: [_kBlush, _kRoseAccent],
                      ),
                      boxShadow: faceDetected
                          ? [
                              BoxShadow(
                                color: _kBlush.withValues(alpha: 0.4),
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
            color: _kIvory.withValues(alpha: 0.8),
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
      ..color = color.withValues(alpha: 0.7)
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
        ? _kBlush.withValues(alpha: 0.85)
        : const Color(0xFFFDF8F3).withValues(alpha: 0.6);

    if (faceDetected) {
      final glowPaint = Paint()
        ..color = _kBlush.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawOval(Offset.zero & size, glowPaint);
    }

    final ovalPaint = Paint()
      ..color = ovalColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceDetected ? 2.0 : 1.5;
    canvas.drawOval(Offset.zero & size, ovalPaint);

    final linePaint = Paint()
      ..color = ovalColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.08),
      Offset(size.width / 2, size.height * 0.92),
      linePaint,
    );

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
/// MESH PAINTER (Phase 1 -- Mapping)
/// =================================================
class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kIvory.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    const divisions = 8;
    for (int i = 1; i < divisions; i++) {
      final x = size.width * i / divisions;
      final y = size.height * i / divisions;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final ovalPaint = Paint()
      ..color = _kIvory.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(Offset.zero & size, ovalPaint);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

/// =================================================
/// SKIN MARKER PAINTER (Phase 2 -- Analyzing)
/// =================================================
class _SkinMarkerPainter extends CustomPainter {
  final int highlightIndex;
  _SkinMarkerPainter({required this.highlightIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final zones = [
      Offset(size.width * 0.50, size.height * 0.15),
      Offset(size.width * 0.25, size.height * 0.48),
      Offset(size.width * 0.75, size.height * 0.48),
      Offset(size.width * 0.50, size.height * 0.40),
      Offset(size.width * 0.50, size.height * 0.58),
      Offset(size.width * 0.50, size.height * 0.80),
    ];

    for (int i = 0; i < zones.length; i++) {
      final active = i <= highlightIndex;
      final paint = Paint()
        ..color = active ? _kBlush.withValues(alpha: 0.5) : _kIvory.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(zones[i], active ? 24 : 16, paint);

      if (active) {
        final ringPaint = Paint()
          ..color = _kBlush.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(zones[i], 32, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SkinMarkerPainter old) =>
      old.highlightIndex != highlightIndex;
}

/// =================================================
/// RING PROGRESS PAINTER (Phase 3 -- Calculating)
/// =================================================
class _RingProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = _kIvory.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
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

