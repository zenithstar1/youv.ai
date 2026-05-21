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
  int _nativeValidFaceFrames = 0;
  int _nativeMissedFaceFrames = 0;

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

    if (kIsWeb && !widget.isHair) {
      _faceDetectedListenerSub = web_face.addFaceDetectedListener((detected) {
        if (!mounted || _isDisposed || _phase != ScanPhase.live) return;

        final wasDetected = _faceDetected;
        if (wasDetected != detected) {
          debugPrint('[FaceDetection] event: $detected');
        }
        setState(() {
          _faceDetected = detected;
        });

        if (detected && !wasDetected) {
          // Face detected → wait before starting countdown
          _faceStableTimer?.cancel();

          _faceStableTimer = Timer(const Duration(milliseconds: 1200), () {
            if (_faceDetected && !_capturing) {
              _startCountdown();
            }
          });
        } else if (!detected && wasDetected) {
          // Face lost → cancel everything
          _faceStableTimer?.cancel();
          _cancelCountdown();
        }
      });
    } else {
      _faceDetected = false;
    }
  }

  void _scheduleNativeAutoCapture() {
    if (kIsWeb || widget.isHair) return;
    if (!_faceDetected) return;
    _autoCaptureTimer?.cancel();
    _autoCaptureTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted ||
          _isDisposed ||
          _hasNavigated ||
          _capturing ||
          !_initialized ||
          !_faceDetected ||
          _phase != ScanPhase.live ||
          _countdown > 0 ||
          _holdSteady) {
        return;
      }
      debugPrint('[SkinAuto] starting native countdown');
      _startCountdown();
    });
  }

  /// =================================================
  /// WAIT FEEDBACK TIMER
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
      // Start face detection after camera is fully set up and rendered
      _startFaceDetectionWithRetry();
      await _startNativeFaceDetection(controller, cam);
    } catch (e) {
      debugPrint("Camera init error: $e");
    }

    _initializing = false;
  }

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

      final candidateDetected = _isAcceptableLiveSkinFace(frame);
      if (candidateDetected) {
        _nativeValidFaceFrames += 1;
        _nativeMissedFaceFrames = 0;
      } else {
        _nativeValidFaceFrames = 0;
        _nativeMissedFaceFrames += 1;
      }

      // During countdown/hold-steady we must be strict: the moment the face
      // is not fitted in the oval, drop detection and cancel.
      final strictNow = _countdown > 0 || _holdSteady;
      final detected = strictNow
          ? candidateDetected
          : (_faceDetected
                ? _nativeMissedFaceFrames < 3
                : _nativeValidFaceFrames >= 2);
      final wasDetected = _faceDetected;
      if (wasDetected != detected) {
        debugPrint('[SkinAuto] native face state: $detected');
      }

      if (wasDetected != detected) {
        setState(() {
          _faceDetected = detected;
        });
      }

      if (detected && !wasDetected) {
        _faceStableTimer?.cancel();
        _faceStableTimer = Timer(const Duration(milliseconds: 900), () {
          if (_faceDetected && !_capturing) {
            _scheduleNativeAutoCapture();
          }
        });
      } else if (!detected && wasDetected) {
        _faceStableTimer?.cancel();
        _cancelCountdown();
      }
    });

    await _startNativeImageStream(controller, service);
  }

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

  bool _isAcceptableLiveSkinFace(FaceDetectionFrame frame) {
    if (!frame.hasFace) return false;

    final faceWidthRatio = frame.faceWidthRatio;
    final faceHeightRatio = frame.faceHeightRatio;
    final fillRatio = math.max(faceWidthRatio, faceHeightRatio);
    final aspectRatio = faceWidthRatio / math.max(faceHeightRatio, 0.001);

    // Reject clipped / half faces: bounding box must be fully inside the frame
    // with a small margin (prevents "half-face still counts as detected").
    const frameMargin = 0.04;
    final halfW = (faceWidthRatio / 2).clamp(0.0, 0.5);
    final halfH = (faceHeightRatio / 2).clamp(0.0, 0.5);
    final minX = frame.faceCenterXRatio - halfW;
    final maxX = frame.faceCenterXRatio + halfW;
    final minY = frame.faceCenterYRatio - halfH;
    final maxY = frame.faceCenterYRatio + halfH;
    final bboxInFrame =
        minX >= frameMargin &&
        maxX <= (1.0 - frameMargin) &&
        minY >= frameMargin &&
        maxY <= (1.0 - frameMargin);
    if (!bboxInFrame) return false;

    // Must be positioned to fit the on-screen oval guide (centered overlay).
    // These constraints intentionally bias towards "only capture when fitted".
    if (frame.faceCenterYRatio < 0.42 || frame.faceCenterYRatio > 0.60) {
      return false;
    }

    if (faceWidthRatio < 0.10 || faceWidthRatio > 0.88) return false;
    if (faceHeightRatio < 0.14 || faceHeightRatio > 0.96) return false;
    if (fillRatio < 0.14) return false;
    if (aspectRatio < 0.35 || aspectRatio > 1.75) return false;
    if (frame.faceCenterOffsetX > 0.42 || frame.faceCenterOffsetY > 0.45) {
      return false;
    }

    if (frame.landmarks.length < 3) return false;
    final nose = frame.landmarks[0];
    final leftEye = frame.landmarks[1];
    final rightEye = frame.landmarks[2];
    final hasMouthLandmarks =
        frame.landmarks.length >= 7 &&
        frame.landmarks[5].length >= 2 &&
        frame.landmarks[6].length >= 2 &&
        frame.landmarks[5][0].isFinite &&
        frame.landmarks[5][1].isFinite &&
        frame.landmarks[6][0].isFinite &&
        frame.landmarks[6][1].isFinite;
    final mouthLeft = hasMouthLandmarks ? frame.landmarks[5] : null;
    final mouthRight = hasMouthLandmarks ? frame.landmarks[6] : null;

    final hasCoreLandmarks = [nose, leftEye, rightEye].every(
      (point) => point.length >= 2 && point[0].isFinite && point[1].isFinite,
    );
    if (!hasCoreLandmarks) return false;

    final eyeDx = (leftEye[0] - rightEye[0]).abs();
    final eyeDy = (leftEye[1] - rightEye[1]).abs();
    if (eyeDx <= 6) return false;

    final eyesLevel = eyeDy / eyeDx;
    final noseCenteredToEyes =
        (nose[0] - ((leftEye[0] + rightEye[0]) / 2)).abs() / eyeDx;

    final eyeMidY = (leftEye[1] + rightEye[1]) / 2;

    // Eyes must align with the guide-eye markers (two horizontal lines).
    final eyeMidYRatio = (eyeMidY / math.max(frame.imageHeight, 1.0)).clamp(
      0.0,
      1.0,
    );
    if (eyeMidYRatio < 0.30 || eyeMidYRatio > 0.46) return false;

    if (eyesLevel > 0.18) return false;
    if (noseCenteredToEyes > 0.90) return false;
    if (nose[1] <= eyeMidY) return false;

    if (hasMouthLandmarks && mouthLeft != null && mouthRight != null) {
      final mouthMidY = (mouthLeft[1] + mouthRight[1]) / 2;
      final mouthWidth = (mouthRight[0] - mouthLeft[0]).abs();
      if (mouthMidY <= nose[1]) return false;
      if (mouthWidth < eyeDx * 0.08 || mouthWidth > eyeDx * 2.00) {
        return false;
      }
    }

    return true;
  }

  /// =================================================
  /// FACE DETECTION INIT (with retry until video is found)
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
  /// COUNTDOWN LOGIC: 3 → 2 → 1 → Hold steady → Capture
  /// =================================================
  void _startCountdown() {
    if (_capturing || _hasNavigated || _isDisposed || _countdown > 0) return;
    if (!widget.isHair && !_faceDetected) return;

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
      if (!_faceDetected && _countdown == 0 && !_holdSteady) {
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
            final stableBeforeCapture = await _verifyFaceContinuous(
              const Duration(milliseconds: 280),
            );
            if (mounted &&
                !_isDisposed &&
                !_hasNavigated &&
                stableBeforeCapture &&
                !_capturing) {
              debugPrint('[CaptureFlow] hold steady complete -> capture');
              _capture();
            } else {
              debugPrint(
                '[CaptureFlow] hold steady failed, cancelling countdown',
              );
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
      if (kIsWeb) {
        web_face.stopFaceDetection().catchError((_) {});
      }
      _faceStableTimer?.cancel();
      _nativeFaceSubscription?.cancel();
      _nativeFaceSubscription = null;
      unawaited(_stopNativeImageStream());
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
    if (controller == null ||
        !_initialized ||
        _capturing ||
        !controller.value.isInitialized ||
        _isDisposed ||
        _hasNavigated) {
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

      if (!kIsWeb && !widget.isHair) {
        await _stopNativeImageStream();
      }

      final pic = await controller.takePicture();
      // Post-capture face re-validation removed: the user already passed
      // live face detection + countdown timer, so re-checking the still
      // JPEG is redundant and fails on devices with different JPEG
      // rotation/mirroring/encoding.  The live detection is the gate.
      final bytes = await pic.readAsBytes();
      if (!mounted || _isDisposed || _hasNavigated) return;

      if (kIsWeb && !widget.isHair) {
        // ✅ Use already confirmed live detection
        if (!_faceDetected) {
          debugPrint('[WEB] capture rejected: face lost before capture');
          await _rejectInvalidCapture(controller);
          return;
        }
      }

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
    }

    if (kIsWeb || widget.isHair) {
      _faceStableTimer?.cancel();
      if (_faceDetected) {
        _faceStableTimer = Timer(const Duration(milliseconds: 1200), () {
          if (!mounted || _isDisposed || _hasNavigated) return;
          if (_phase != ScanPhase.live || _capturing || !_faceDetected) return;
          _startCountdown();
        });
      }
      return;
    }

    final service = _nativeFaceDetectionService;
    if (service != null) {
      await _startNativeImageStream(controller, service);
    }
  }

  Future<bool> _capturedImageHasFace(String imagePath) async {
    try {
      // Use MediaPipe via the shared FaceDetectionService to validate the
      // captured image.  The service applies the same geometric thresholds
      // that the old ML Kit validator used.
      final service = _nativeFaceDetectionService;
      if (service != null && service.isInitialized) {
        return await service.validateCapturedImage(imagePath);
      }
      // Fallback: accept if service isn't available (web, init failure)
      return true;
    } catch (e) {
      debugPrint('[CaptureFlow] final-image face validation error: $e');
      return false;
    }
  }

  Future<Size?> _readEncodedImageSize(String imagePath) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(imagePath);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = Size(
        descriptor.width.toDouble(),
        descriptor.height.toDouble(),
      );
      descriptor.dispose();
      buffer.dispose();
      return size;
    } catch (e) {
      debugPrint('[CaptureFlow] image size read failed: $e');
      return null;
    }
  }

  /// =================================================
  /// SCANNING ANIMATION SEQUENCE
  /// =================================================
  Future<void> _startScanningAnimation() async {
    if (!mounted || _isDisposed || _hasNavigated) return;

    // Capture the NavigatorState BEFORE any await.  After an await boundary
    // the widget may have been deactivated, making context.findAncestorStateOfType
    // (called internally by Navigator.of(context)) throw even if mounted == true.
    final navigator = Navigator.of(context);

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

    // Navigate — use the pre-captured NavigatorState so we never call
    // Navigator.of(context) after an await boundary on a potentially
    // deactivated context.
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
      // ─── WEB ───────────────────────────────────────────────────────────────
      // Problem: CameraPreview wraps its child in AspectRatio(stream_ratio).
      // On a portrait phone (390×844) with a 720×1280 stream, AspectRatio
      // gives 390×693 — leaving a 151px black gap at the bottom.
      // With a landscape stream (1280×720) the gap is 625px.
      //
      // Fix: give FittedBox a SizedBox sized to the stream dimensions so it
      // has a concrete child size to scale from.  FittedBox.cover then scales
      // to fill the viewport, and ClipRect clips any overflow.
      //
      // The SizedBox dims match the stream dims exactly, so object-fit:cover
      // inside the video element sees a 1:1 match and adds no extra scaling
      // (no double-scaling issue).  Do NOT swap w↔h for web — the plugin
      // already reports portrait dims when getUserMedia returns a portrait stream.
      debugPrint(
        '[CameraPreview:web] previewSize=${size.width.toInt()}×${size.height.toInt()}'
        ' | screen=${MediaQuery.of(context).size.width.toInt()}'
        '×${MediaQuery.of(context).size.height.toInt()}'
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

    // ─── NATIVE ────────────────────────────────────────────────────────────
    // The camera sensor reports frames in its natural (often landscape)
    // orientation.  Swap w↔h to obtain the correct portrait aspect ratio for
    // the Flutter layout, then FittedBox.cover fills the screen.
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

          // ── CAPTURE BUTTON + STATUS PILL + BOTTOM LABEL (live) ──
          // Anchored to bottom so it never overlaps the face oval on short screens
          if (isLive)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Face detected / countdown / hold steady pill
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
                              color: _kSoftGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _kSoftGreen.withOpacity(0.4),
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
                              border: Border.all(
                                color: _kBlush.withOpacity(0.6),
                                width: 2,
                              ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _kValidGreenBg.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: _kSoftGreen,
                                ),
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
                    subLabel: (_countdown > 0 || _holdSteady)
                        ? 'Hold still…'
                        : _faceDetected
                        ? 'Auto-capturing…'
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
                      color: _kIvory.withOpacity(0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
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
                child: CustomPaint(painter: _MeshPainter()),
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
        color: valid
            ? _kValidGreenBg.withOpacity(0.85)
            : _kIvory.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: valid
            ? null
            : Border.all(color: _kBurgundy.withOpacity(0.25), width: 0.8),
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
                        colors: [_kBlush, _kRoseAccent],
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
      Offset(size.width * 0.50, size.height * 0.15), // forehead
      Offset(size.width * 0.25, size.height * 0.48), // left cheek
      Offset(size.width * 0.75, size.height * 0.48), // right cheek
      Offset(size.width * 0.50, size.height * 0.40), // under-eye
      Offset(size.width * 0.50, size.height * 0.58), // T-zone
      Offset(size.width * 0.50, size.height * 0.80), // chin
    ];

    for (int i = 0; i < zones.length; i++) {
      final active = i <= highlightIndex;
      final paint = Paint()
        ..color = active ? _kBlush.withOpacity(0.5) : _kIvory.withOpacity(0.1)
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
  bool shouldRepaint(_SkinMarkerPainter old) =>
      old.highlightIndex != highlightIndex;
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
