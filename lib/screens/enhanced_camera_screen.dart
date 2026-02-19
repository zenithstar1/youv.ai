import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../Models/head_pose_calculator.dart';
import '../widgets/auto_capture_guide_widget.dart';
import '../services/face_detection_service.dart';

/// AutoCaptureController manages the auto-capture logic for the camera screen
class AutoCaptureController {
  static bool _hasGlobalHairReference = false;
  static double _globalHairRefPitch = 45.0;
  static double _globalHairRefYaw = 0.0;
  static double _globalHairRefRoll = 0.0;
  static double _globalHairRefFill = 0.40;
  static double _globalHairRefCenterOffsetX = 0.20;
  static double _globalHairRefCenterOffsetY = 0.20;
  static double _globalHairRefCenterYRatio = 0.66;

  /// Current pitch angle from face detection
  double _currentPitch = 0.0;
  
  /// Current yaw angle from face detection
  double _currentYaw = 0.0;

  /// Current roll angle from face detection
  double _currentRoll = 0.0;
  
  /// Timer for the auto-capture countdown
  Timer? _captureTimer;
  
  /// Remaining time in milliseconds for auto-capture
  int _remainingTime = 0;
  
  /// Callback when capture should be triggered
  VoidCallback? _onCapture;
  
  /// Callback for state updates (pitch, yaw, timer, etc.)
  VoidCallback? _onStateChange;
  
  /// Minimum pitch for auto-capture (default: 42 degrees)
  final double minPitch;
  
  /// Maximum pitch for auto-capture (default: 48 degrees)
  final double maxPitch;
  
  /// Maximum yaw deviation for auto-capture (default: 5 degrees)
  final double maxYawDeviation;

  /// Maximum roll deviation for auto-capture (default: 8 degrees)
  final double maxRollDeviation;

  /// Preferred pitch target for best-angle capture (null uses midpoint of min/max pitch).
  final double? idealPitch;

  /// Tight tolerances used for best-angle capture gating.
  final double bestPitchTolerance;
  final double bestYawTolerance;
  final double bestRollTolerance;

  /// Required hold time at best angle before countdown can start.
  final int requiredStableMs;

  /// Required consecutive frames in capture pose before countdown can start.
  final int requiredConsecutiveBestFrames;

  /// Minimum normalized quality score [0..1] for best-angle lock.
  final double minPoseQualityForCapture;

  /// How much capture threshold can be relaxed below best-angle quality.
  final double captureQualityRelaxation;

  /// EMA smoothing factor for head pose updates [0..1].
  final double smoothingFactor;

  /// Hair-mode capture based on filling the guide circle and centering face.
  final bool useFaceFillCapture;

  /// Target normalized face fill (max of width/height ratio in frame).
  final double targetFaceFillRatio;
  final double minFaceFillRatio;
  final double maxFaceFillRatio;

  /// Maximum normalized center offset for capture readiness.
  final double maxCenterOffsetRatio;
  
  /// Auto-capture timer duration in milliseconds
  final int captureTimerMs;

  /// Grace window to tolerate brief hair-pose detection drops.
  final int hairPoseLossGraceMs;

  /// Frame throttling - only update UI every N frames (30fps / 15 = 2 updates per second = smoother without jank)
  final int frameThrottleInterval;
  int _frameCount = 0;
  bool _hasPose = false;
  bool _isBestAngle = false;
  bool _isCaptureReady = false;
  double _poseQuality = 0.0;
  DateTime? _bestAngleSince;
  int _bestFrameStreak = 0;
  DateTime? _lastHairCapturePoseAt;
  bool _hasManualHairReference = false;
  double _manualRefPitch = 45.0;
  double _manualRefYaw = 0.0;
  double _manualRefRoll = 0.0;
  double _manualRefFill = 0.40;
  double _manualRefCenterOffsetX = 0.20;
  double _manualRefCenterOffsetY = 0.20;
  double _manualRefCenterYRatio = 0.66;
  bool _hasFace = false;
  double _faceFillRatio = 0.0;
  double _faceCenterOffsetX = 1.0;
  double _faceCenterOffsetY = 1.0;
  double _faceCenterYRatio = 0.5;
  String _guidanceText = 'Align your face in the circle';

  AutoCaptureController({
    this.minPitch = 42.0,
    this.maxPitch = 48.0,
    this.maxYawDeviation = 5.0,
    this.maxRollDeviation = 8.0,
    this.idealPitch,
    this.bestPitchTolerance = 3.0,
    this.bestYawTolerance = 4.0,
    this.bestRollTolerance = 6.0,
    this.requiredStableMs = 450,
    this.requiredConsecutiveBestFrames = 1,
    this.minPoseQualityForCapture = 0.72,
    this.captureQualityRelaxation = 0.12,
    this.smoothingFactor = 0.28,
    this.useFaceFillCapture = false,
    this.targetFaceFillRatio = 0.58,
    this.minFaceFillRatio = 0.42,
    this.maxFaceFillRatio = 0.78,
    this.maxCenterOffsetRatio = 0.18,
    this.captureTimerMs = 600,
    this.hairPoseLossGraceMs = 700,
    this.frameThrottleInterval = 3, // Update UI on every Nth frame
  }) {
    if (useFaceFillCapture && _hasGlobalHairReference) {
      _hasManualHairReference = true;
      _manualRefPitch = _globalHairRefPitch;
      _manualRefYaw = _globalHairRefYaw;
      _manualRefRoll = _globalHairRefRoll;
      _manualRefFill = _globalHairRefFill;
      _manualRefCenterOffsetX = _globalHairRefCenterOffsetX;
      _manualRefCenterOffsetY = _globalHairRefCenterOffsetY;
      _manualRefCenterYRatio = _globalHairRefCenterYRatio;
    }
  }

  /// Gets the current pitch angle
  double get currentPitch => _currentPitch;

  /// Gets the current yaw angle
  double get currentYaw => _currentYaw;

  /// Gets the current roll angle
  double get currentRoll => _currentRoll;

  /// Exposes target bounds for UI rendering.
  double get targetMinPitch => minPitch;
  double get targetMaxPitch => maxPitch;
  double get targetMaxYawDeviation => maxYawDeviation;
  double get targetMaxRollDeviation => maxRollDeviation;

  /// Gets the remaining capture timer in milliseconds
  int get remainingTime => _remainingTime;

  /// Checks if face is in perfect angle
  bool get isPerfectAngle {
    return HeadPoseCalculator.isInTargetPose(
      pitch: _currentPitch,
      yaw: _currentYaw,
      roll: _currentRoll,
      minPitch: minPitch,
      maxPitch: maxPitch,
      maxYawDeviation: maxYawDeviation,
      maxRollDeviation: maxRollDeviation,
    );
  }

  /// Is the capture timer currently active
  bool get isCountingDown => _captureTimer?.isActive ?? false;
  bool get isCaptureReady => _isCaptureReady;
  double get poseQuality => _poseQuality;
  double get faceFillRatio => _faceFillRatio;
  double get faceCenterOffsetX => _faceCenterOffsetX;
  double get faceCenterOffsetY => _faceCenterOffsetY;
  String get guidanceText => _guidanceText;

  /// True when pose is inside the strict best-angle window.
  bool get isBestAngle => _isBestAngle;

  /// True when best-angle has remained stable for enough duration.
  bool get isBestAngleStable => _isCaptureReady;

  /// Sets callbacks for auto-capture
  void setCallbacks({
    required VoidCallback onCapture,
    required VoidCallback onStateChange,
  }) {
    _onCapture = onCapture;
    _onStateChange = onStateChange;
  }

  void registerManualCaptureReference() {
    if (!useFaceFillCapture || !_hasFace) {
      return;
    }

    _hasManualHairReference = true;
    _manualRefPitch = _currentPitch;
    _manualRefYaw = _currentYaw;
    _manualRefRoll = _currentRoll;
    _manualRefFill = _faceFillRatio;
    _manualRefCenterOffsetX = _faceCenterOffsetX;
    _manualRefCenterOffsetY = _faceCenterOffsetY;
    _manualRefCenterYRatio = _faceCenterYRatio;

    _hasGlobalHairReference = true;
    _globalHairRefPitch = _manualRefPitch;
    _globalHairRefYaw = _manualRefYaw;
    _globalHairRefRoll = _manualRefRoll;
    _globalHairRefFill = _manualRefFill;
    _globalHairRefCenterOffsetX = _manualRefCenterOffsetX;
    _globalHairRefCenterOffsetY = _manualRefCenterOffsetY;
    _globalHairRefCenterYRatio = _manualRefCenterYRatio;
  }

  /// Updates face detection data (landmarks from MediaPipe)
  /// Throttled to reduce UI rebuild frequency
  void updateFaceDetection(
    List<List<double>> landmarks, {
    double? headEulerAngleX,
    double? headEulerAngleY,
    double? headEulerAngleZ,
    bool hasFace = false,
    double faceWidthRatio = 0.0,
    double faceHeightRatio = 0.0,
    double faceCenterOffsetX = 1.0,
    double faceCenterOffsetY = 1.0,
    double faceCenterYRatio = 0.5,
  }) {

    // Capture previous state BEFORE mutating angles.
    final wasCaptureReady = _isCaptureReady;

    final rawPitch = HeadPoseCalculator.calculatePitch(
      landmarks,
      headEulerAngleX: headEulerAngleX,
    );
    final rawYaw = HeadPoseCalculator.calculateYaw(
      landmarks,
      headEulerAngleY: headEulerAngleY,
    );
    final rawRoll = HeadPoseCalculator.calculateRoll(
      headEulerAngleZ: headEulerAngleZ,
    );

    _hasFace = hasFace;
    _faceFillRatio = faceWidthRatio > faceHeightRatio
        ? faceWidthRatio
        : faceHeightRatio;
    _faceCenterOffsetX = faceCenterOffsetX;
    _faceCenterOffsetY = faceCenterOffsetY;
    _faceCenterYRatio = faceCenterYRatio;

    final hasValidPose = rawPitch.isFinite && rawYaw.isFinite && rawRoll.isFinite;

    // For non-hair mode, invalid pose must never trigger capture.
    // For hair mode, keep previous pose and continue with geometry-based gating.
    if (!hasValidPose && !useFaceFillCapture) {
      _currentPitch = 0.0;
      _currentYaw = 0.0;
      _currentRoll = 0.0;
      _hasPose = false;
      _isBestAngle = false;
      _isCaptureReady = false;
      _poseQuality = 0.0;
      _bestAngleSince = null;
      _bestFrameStreak = 0;
      _guidanceText = 'Place scalp area inside the circle';
      _stopCaptureTimer();
      _onStateChange?.call();
      return;
    }


    if (hasValidPose) {
      if (!_hasPose) {
        _currentPitch = rawPitch;
        _currentYaw = rawYaw;
        _currentRoll = rawRoll;
        _hasPose = true;
      } else {
        _currentPitch = _applySmoothing(_currentPitch, rawPitch);
        _currentYaw = _applySmoothing(_currentYaw, rawYaw);
        _currentRoll = _applySmoothing(_currentRoll, rawRoll);
      }
    } else if (!_hasPose) {
      _currentPitch = 0.0;
      _currentYaw = 0.0;
      _currentRoll = 0.0;
    }

    final targetPitch = idealPitch ?? ((minPitch + maxPitch) / 2);
    _poseQuality = _calculatePoseQuality(
      pitch: _currentPitch,
      yaw: _currentYaw,
      roll: _currentRoll,
      targetPitch: targetPitch,
    );

    final captureQualityThreshold =
      (minPoseQualityForCapture - captureQualityRelaxation).clamp(0.0, 1.0);
    final hasCrownTilt =
      (_currentPitch - targetPitch).abs() <= bestPitchTolerance;
    final isCenteredHead =
      _currentYaw.abs() <= maxYawDeviation && _currentRoll.abs() <= maxRollDeviation;

    bool hasCapturePose;
    if (useFaceFillCapture) {
      final now = DateTime.now();
      final centeredForCircle =
        _faceCenterOffsetX <= maxCenterOffsetRatio &&
        _faceCenterOffsetY <= maxCenterOffsetRatio;
      final fillReady =
        _faceFillRatio >= minFaceFillRatio && _faceFillRatio <= maxFaceFillRatio;
      final scalpFramingReady =
        _faceCenterYRatio >= 0.54 && _faceCenterYRatio <= 0.80;
      final landmarkPoseReady = _isHairLandmarkPoseReady(landmarks);
      final manualReferenceReady = _matchesManualHairReference(
        hasValidPose: hasValidPose,
      );

      final geometryPoseReady = _hasFace &&
        centeredForCircle &&
        fillReady &&
        scalpFramingReady &&
        landmarkPoseReady;

      if (geometryPoseReady) {
        _lastHairCapturePoseAt = now;
      }

      final withinPoseLossGrace =
        _lastHairCapturePoseAt != null &&
        now.difference(_lastHairCapturePoseAt!).inMilliseconds <= hairPoseLossGraceMs;

      hasCapturePose = geometryPoseReady || manualReferenceReady || withinPoseLossGrace;
      _isBestAngle = hasCapturePose;

      if (geometryPoseReady) {
        _guidanceText = _buildHairGuidance(
          hasFace: _hasFace,
          fillRatio: _faceFillRatio,
          centerOffsetX: _faceCenterOffsetX,
          centerOffsetY: _faceCenterOffsetY,
          centerYRatio: _faceCenterYRatio,
          pitch: _currentPitch,
          yaw: _currentYaw,
          roll: _currentRoll,
        );
      } else if (manualReferenceReady) {
        _guidanceText = 'Matched your saved angle. Hold steady...';
      } else if (withinPoseLossGrace) {
        _guidanceText = 'Hold steady... capturing';
      } else {
        _guidanceText = landmarkPoseReady
            ? _buildHairGuidance(
                hasFace: _hasFace,
                fillRatio: _faceFillRatio,
                centerOffsetX: _faceCenterOffsetX,
                centerOffsetY: _faceCenterOffsetY,
                centerYRatio: _faceCenterYRatio,
                pitch: _currentPitch,
                yaw: _currentYaw,
                roll: _currentRoll,
              )
            : 'Keep face straight with slight head tilt';
      }
    } else {
      hasCapturePose =
        isPerfectAngle &&
        hasCrownTilt &&
        isCenteredHead &&
        _poseQuality >= captureQualityThreshold;
      _isBestAngle = isPerfectAngle && _poseQuality >= minPoseQualityForCapture;
      _guidanceText = _isBestAngle
        ? 'Great! Hold still for auto capture'
        : 'Adjust tilt angle';
    }
    if (hasCapturePose) {
      _bestAngleSince ??= DateTime.now();
      _bestFrameStreak += 1;
    } else {
      _bestAngleSince = null;
      _bestFrameStreak = 0;
    }

    _isCaptureReady = hasCapturePose &&
        _bestAngleSince != null &&
        _bestFrameStreak >= requiredConsecutiveBestFrames &&
        DateTime.now().difference(_bestAngleSince!).inMilliseconds >=
            requiredStableMs;

    final isCaptureReadyNow = _isCaptureReady;

    // Always check for best-angle stable state changes (entering/leaving capture-ready zone)
    if (wasCaptureReady != isCaptureReadyNow) {
      if (isCaptureReadyNow) {
        _startCaptureTimer();
      } else {
        _stopCaptureTimer();
      }
      // Immediate update when angle changes
      _onStateChange?.call();
    } else {
      // Only update UI periodically to reduce repaints
      _frameCount++;
      if (_frameCount >= frameThrottleInterval) {
        _frameCount = 0;
        _onStateChange?.call();
      }
    }
  }

  String _buildHairGuidance({
    required bool hasFace,
    required double fillRatio,
    required double centerOffsetX,
    required double centerOffsetY,
    required double centerYRatio,
    required double pitch,
    required double yaw,
    required double roll,
  }) {
    if (!hasFace) {
      return 'Place scalp area inside the circle';
    }
    if (fillRatio < minFaceFillRatio) {
      return 'Move closer so scalp fills the circle';
    }
    if (fillRatio > maxFaceFillRatio) {
      return 'Move a little back to fit inside the circle';
    }
    if (centerOffsetX > maxCenterOffsetRatio) {
      return 'Center your head in the circle';
    }
    if (centerOffsetY > maxCenterOffsetRatio) {
      return 'Adjust camera height to center your head';
    }
    if (centerYRatio < 0.52) {
      return 'Lower your face a bit to show more scalp';
    }
    if (centerYRatio > 0.82) {
      return 'Raise your face slightly in the circle';
    }
    return 'Perfect scalp view! Hold still for auto capture';
  }

  /// Starts the auto-capture timer
  void _startCaptureTimer() {
    if (_captureTimer != null && _captureTimer!.isActive) {
      return; // Timer already running
    }

    _remainingTime = captureTimerMs;

    _captureTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        _remainingTime -= 100;

        if (_remainingTime <= 0) {
          _stopCaptureTimer();
          _triggerCapture();
        } else {
          _onStateChange?.call();
        }
      },
    );

    _onStateChange?.call();
  }

  /// Stops the auto-capture timer
  void _stopCaptureTimer() {
    _captureTimer?.cancel();
    _captureTimer = null;
    _remainingTime = 0;
    _onStateChange?.call();
  }

  /// Triggers the capture and provides haptic feedback
  void _triggerCapture() async {
    // Haptic feedback
    await HapticFeedback.mediumImpact();
    _onCapture?.call();
  }

  /// Manually trigger capture with haptic feedback
  Future<void> triggerManualCapture() async {
    await HapticFeedback.mediumImpact();
    _stopCaptureTimer();
    _onCapture?.call();
  }

  double _applySmoothing(double previous, double next) {
    final alpha = smoothingFactor.clamp(0.0, 1.0);
    return (previous * (1 - alpha)) + (next * alpha);
  }

  double _calculatePoseQuality({
    required double pitch,
    required double yaw,
    required double roll,
    required double targetPitch,
  }) {
    final pitchScore = 1.0 -
        ((pitch - targetPitch).abs() / bestPitchTolerance).clamp(0.0, 1.0);
    final yawScore = 1.0 - (yaw.abs() / bestYawTolerance).clamp(0.0, 1.0);
    final rollScore = 1.0 - (roll.abs() / bestRollTolerance).clamp(0.0, 1.0);
    return (pitchScore * 0.5 + yawScore * 0.3 + rollScore * 0.2)
        .clamp(0.0, 1.0);
  }

  bool _isHairLandmarkPoseReady(List<List<double>> landmarks) {
    if (landmarks.length < 7) {
      return true;
    }

    List<double>? pointAt(int index) {
      if (index < 0 || index >= landmarks.length) return null;
      final p = landmarks[index];
      if (p.length < 2 || !p[0].isFinite || !p[1].isFinite) return null;
      return p;
    }

    final nose = pointAt(0);
    final leftEye = pointAt(1);
    final rightEye = pointAt(2);
    final leftEar = pointAt(3);
    final rightEar = pointAt(4);

    if (nose == null ||
        leftEye == null ||
        rightEye == null ||
        leftEar == null ||
        rightEar == null) {
      return true;
    }

    final eyeDx = (leftEye[0] - rightEye[0]).abs();
    final eyeDy = (leftEye[1] - rightEye[1]).abs();
    final earDx = (leftEar[0] - rightEar[0]).abs();
    if (eyeDx < 28.0 || earDx < 56.0) {
      return false;
    }

    final rollRatio = eyeDy / eyeDx;
    final earMidX = (leftEar[0] + rightEar[0]) / 2.0;
    final yawOffsetRatio = (nose[0] - earMidX).abs() / (earDx / 2.0);
    final eyeMidY = (leftEye[1] + rightEye[1]) / 2.0;
    final noseDrop = nose[1] - eyeMidY;

    final rollReady = rollRatio <= 0.26;
    final yawReady = yawOffsetRatio <= 0.60;
    final slightTiltReady = noseDrop >= (eyeDx * 0.10);

    return rollReady && yawReady && slightTiltReady;
  }

  bool _matchesManualHairReference({required bool hasValidPose}) {
    if (!_hasManualHairReference || !_hasFace) {
      return false;
    }

    final fillMin = (_manualRefFill - 0.12).clamp(0.0, 1.0);
    final fillMax = (_manualRefFill + 0.20).clamp(0.0, 1.0);
    final fillReady = _faceFillRatio >= fillMin && _faceFillRatio <= fillMax;

    final centerXReady =
        _faceCenterOffsetX <= (_manualRefCenterOffsetX + 0.10).clamp(0.0, 1.0);
    final centerYReady =
        _faceCenterOffsetY <= (_manualRefCenterOffsetY + 0.10).clamp(0.0, 1.0);
    final centerYRatioReady =
        (_faceCenterYRatio - _manualRefCenterYRatio).abs() <= 0.14;

    final geometryReady =
        fillReady && centerXReady && centerYReady && centerYRatioReady;

    if (!geometryReady) {
      return false;
    }

    if (!hasValidPose) {
      return true;
    }

    final pitchReady = (_currentPitch - _manualRefPitch).abs() <= 10.0;
    final yawReady = (_currentYaw - _manualRefYaw).abs() <= 12.0;
    final rollReady = (_currentRoll - _manualRefRoll).abs() <= 12.0;
    return pitchReady && yawReady && rollReady;
  }

  /// Dispose the controller
  void dispose() {
    _captureTimer?.cancel();
  }
}

/// EnhancedCameraScreen with auto-capture logic and tilt guidance
class EnhancedCameraScreen extends StatefulWidget {
  /// Callback when image is captured
  final Function(Uint8List imageBytes, String fileName) onImageCaptured;
  
  /// Whether this is for hair analysis
  final bool isHair;

  const EnhancedCameraScreen({
    super.key,
    required this.onImageCaptured,
    this.isHair = false,
  });

  @override
  State<EnhancedCameraScreen> createState() => _EnhancedCameraScreenState();
}

class _EnhancedCameraScreenState extends State<EnhancedCameraScreen> {
  late AutoCaptureController _autoCaptureController;

  // Real camera and face detection
  CameraController? _cameraController;
  FaceDetectionService? _faceDetectionService;
  StreamSubscription<FaceDetectionFrame>? _landmarksSubscription;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    
    // Hair-density profile:
    // - Slight forward tilt to expose scalp density without extreme chin tuck.
    // - Stricter yaw/roll to avoid side captures.
    final minPitch = widget.isHair ? 40.0 : 40.0;
    final maxPitch = widget.isHair ? 50.0 : 52.0;
    
    _autoCaptureController = AutoCaptureController(
      minPitch: minPitch,
      maxPitch: maxPitch,
      maxYawDeviation: widget.isHair ? 6.0 : 6.0,
      maxRollDeviation: widget.isHair ? 4.0 : 8.0,
      idealPitch: widget.isHair ? 45.0 : 46.0,
      bestPitchTolerance: widget.isHair ? 3.0 : 3.5,
      bestYawTolerance: widget.isHair ? 4.0 : 4.0,
      bestRollTolerance: widget.isHair ? 2.0 : 6.0,
      requiredStableMs: widget.isHair ? 250 : 450,
      requiredConsecutiveBestFrames: widget.isHair ? 1 : 1,
      minPoseQualityForCapture: widget.isHair ? 0.66 : 0.70,
      captureQualityRelaxation: widget.isHair ? 0.00 : 0.12,
      smoothingFactor: widget.isHair ? 0.32 : 0.25,
      useFaceFillCapture: widget.isHair,
      minFaceFillRatio: widget.isHair ? 0.26 : 0.40,
      maxFaceFillRatio: widget.isHair ? 0.98 : 0.82,
      targetFaceFillRatio: widget.isHair ? 0.60 : 0.56,
      maxCenterOffsetRatio: widget.isHair ? 0.34 : 0.20,
      captureTimerMs: widget.isHair ? 450 : 600,
      hairPoseLossGraceMs: widget.isHair ? 900 : 0,
      frameThrottleInterval: widget.isHair ? 3 : 2,
    );
    
    _autoCaptureController.setCallbacks(
      onCapture: _handleAutoCapture,
      onStateChange: () {
        if (mounted) {
          setState(() {});
        }
      },
    );

    // Initialize camera + face detection for both hair and face workflows.
    _initializeHairAnalysisCamera();
  }

  /// Initializes camera and face detection.
  Future<void> _initializeHairAnalysisCamera() async {
    try {

      // Initialize face detection service
      _faceDetectionService = FaceDetectionService();
      await _faceDetectionService!.initialize();

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Configure ML Kit image rotation based on camera sensor orientation.
      _faceDetectionService!.setSensorRotation(frontCamera.sensorOrientation);

      // Initialize camera controller
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Listen to face detection landmarks
      _landmarksSubscription = _faceDetectionService!.landmarksStream.listen(
        (frame) {
          _autoCaptureController.updateFaceDetection(
            frame.landmarks,
            headEulerAngleX: frame.headEulerAngleX,
            headEulerAngleY: frame.headEulerAngleY,
            headEulerAngleZ: frame.headEulerAngleZ,
            hasFace: frame.hasFace,
            faceWidthRatio: frame.faceWidthRatio,
            faceHeightRatio: frame.faceHeightRatio,
            faceCenterOffsetX: frame.faceCenterOffsetX,
            faceCenterOffsetY: frame.faceCenterOffsetY,
            faceCenterYRatio: frame.faceCenterYRatio,
          );
        },
        onError: (error) {
        },
      );

      // Start image stream for face detection
      await _startFaceDetectionImageStream();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handles auto-capture trigger
  void _handleAutoCapture() {
    _takePicture();
  }

  /// Takes a picture from the camera
  Future<void> _takePicture() async {
    if (_isCapturing) return;
    _isCapturing = true;

    bool shouldRestartStream = false;

    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }

      if (_cameraController!.value.isStreamingImages) {
        shouldRestartStream = true;
        await _cameraController!.stopImageStream();
      }

      // Take picture
      final XFile picture = await _cameraController!.takePicture();
      final imageBytes = await picture.readAsBytes();

      shouldRestartStream = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${widget.isHair ? 'Hair' : 'Skin'} photo captured! Processing...',
            ),
            duration: const Duration(milliseconds: 500),
            backgroundColor: Colors.green.shade700,
          ),
        );

        // Call the callback with the captured image
        widget.onImageCaptured(imageBytes, picture.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (shouldRestartStream &&
          mounted &&
          _cameraController != null &&
          _cameraController!.value.isInitialized &&
          !_cameraController!.value.isStreamingImages) {
        await _startFaceDetectionImageStream();
      }
      _isCapturing = false;
    }
  }

  Future<void> _startFaceDetectionImageStream() async {
    if (_cameraController == null || _faceDetectionService == null) {
      return;
    }
    if (_cameraController!.value.isStreamingImages) {
      return;
    }
    await _cameraController!.startImageStream((CameraImage image) {
      _faceDetectionService!.processCameraFrame(image);
    });
  }

  @override
  void dispose() {
    _landmarksSubscription?.cancel();
    _autoCaptureController.dispose();
    _cameraController?.dispose();
    _faceDetectionService?.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildHairAnalysisUI(),
    );
  }

  /// Build UI for hair analysis (real camera with face detection)
  Widget _buildHairAnalysisUI() {
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Real camera preview
        if (_isCameraInitialized && _cameraController != null)
          CameraPreview(_cameraController!)
        else
          Container(
            color: Colors.black87,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isCameraInitialized ? '📷 Camera ready...' : '⏳ Initializing camera & face detection...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // DEBUG INFO
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      border: Border.all(color: Colors.yellow),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🐛 DEBUG INFO',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'isHair: ${widget.isHair}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          'Initialized: $_isCameraInitialized',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          'Controller: ${_cameraController != null ? 'OK' : 'NULL'}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          'FaceDetection: ${_faceDetectionService != null ? 'OK' : 'NULL'}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        _buildStatusIndicator(),
        _buildGuidanceOverlay(),
        _buildManualCaptureButton(),
        _buildBackButton(),
      ],
    );
  }

  /// Build the guidance overlay widget
  Widget _buildGuidanceOverlay() {
    return Positioned(
      top: 120,
      bottom: 120,
      left: 16,
      right: 16,
      child: Center(
        child: AutoCaptureGuideWidget(
          currentPitch: _autoCaptureController.currentPitch,
          currentYaw: _autoCaptureController.currentYaw,
          isPerfectAngle: _autoCaptureController.isBestAngle,
          isCountingDown: _autoCaptureController.isCountingDown,
          remainingTime: _autoCaptureController.remainingTime,
          minTargetPitch: _autoCaptureController.targetMinPitch,
          maxTargetPitch: _autoCaptureController.targetMaxPitch,
          maxYawDeviation: _autoCaptureController.targetMaxYawDeviation,
          guidanceText: _autoCaptureController.guidanceText,
          isHairMode: widget.isHair,
          faceFillRatio: _autoCaptureController.faceFillRatio,
          captureTimerMs: _autoCaptureController.captureTimerMs,
          guideSize: 280,
        ),
      ),
    );
  }

  /// Build the status indicator
  Widget _buildStatusIndicator() {
    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minimalistic status indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _autoCaptureController.isBestAngle
                  ? Colors.green.shade800.withValues(alpha: 0.8)
                    : Colors.black54,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _autoCaptureController.isBestAngle
                      ? Colors.green.shade400.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _autoCaptureController.isBestAngle
                              ? '✓ Position perfect'
                              : '○ Tap to adjust',
                          style: TextStyle(
                            color: _autoCaptureController.isBestAngle
                                ? Colors.green.shade300
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (_autoCaptureController.isCountingDown)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Capturing in ${(_autoCaptureController.remainingTime / 1000).toStringAsFixed(1)}s',
                              style: TextStyle(
                                color: Colors.green.shade300.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Angle values
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tilt: ${_autoCaptureController.currentPitch.toStringAsFixed(0)}°',
                          style: TextStyle(
                            color: (_autoCaptureController.currentPitch >= _autoCaptureController.targetMinPitch &&
                                    _autoCaptureController.currentPitch <= _autoCaptureController.targetMaxPitch)
                                ? Colors.greenAccent
                                : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Angle: ${_autoCaptureController.currentYaw.toStringAsFixed(0)}°',
                          style: TextStyle(
                            color: _autoCaptureController.currentYaw.abs() <= _autoCaptureController.targetMaxYawDeviation
                                ? Colors.greenAccent
                                : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the manual capture button
  Widget _buildManualCaptureButton() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Capture button with ring effect
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _autoCaptureController.isBestAngle
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring (shows if ready to capture)
                if (_autoCaptureController.isBestAngle)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green.shade400.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                // Main button
                FloatingActionButton(
                  backgroundColor: _autoCaptureController.isBestAngle
                      ? Colors.green.shade400
                      : Colors.grey.shade700,
                  elevation: _autoCaptureController.isBestAngle ? 8 : 4,
                  onPressed: () async {
                    _autoCaptureController.registerManualCaptureReference();
                    await _takePicture();
                  },
                  child: Icon(
                    Icons.camera_alt,
                    size: 28,
                    color: _autoCaptureController.isBestAngle
                        ? Colors.white
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Info text
          Text(
            _autoCaptureController.isBestAngle
                ? 'Tap or wait for auto-capture'
                : 'Adjust position for auto-capture',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the back button
  Widget _buildBackButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}


