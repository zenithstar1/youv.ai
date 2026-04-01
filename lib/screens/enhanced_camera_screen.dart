import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../Models/head_pose_calculator.dart';
import '../widgets/auto_capture_guide_widget.dart';
import '../services/face_detection_service.dart';
import '../utils/web_face_detection.dart' as web_face;
import 'image_preview_screen.dart';

const _kBurgundy = Color(0xFF6B3A3A);
const _kIvory = Color(0xFFFDF8F3);
const _kBlush = Color(0xFFE8B4BA);
const _kSoftPink = Color(0xFFF3C7CF);
const _kRosePink = Color(0xFFDFA1AE);

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

  int _validFaceFrames = 0;

  /// Flicker tolerance: allow this many consecutive "not-ready" frames
  /// while the capture timer is running before actually stopping it.
  /// Prevents grayscale detection flicker from resetting the countdown.
  static const int _flickerGraceFrames = 4;
  int _notReadyStreak = 0;

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

  /// Whether timer-based auto capture is enabled.
  final bool enableAutoCapture;

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
  double _faceWidthRatio = 0.0;
  double _faceHeightRatio = 0.0;
  double _faceCenterOffsetX = 1.0;
  double _faceCenterOffsetY = 1.0;
  double _faceCenterXRatio = 0.5;
  double _faceCenterYRatio = 0.5;
  double _imageWidth = 1.0;
  double _imageHeight = 1.0;
  String _guidanceText = 'Align your face in the circle';

  /// Require eyes to align with the on-screen guide band before starting auto-capture.
  final bool requireEyesAlignedForCapture;

  /// Normalized y-band (0=top, 1=bottom) where the eye midpoint must sit.
  final double eyeBandMinYRatio;
  final double eyeBandMaxYRatio;

  /// Normalized margin to avoid capturing when the face box is clipped at frame edges.
  final double faceFrameMarginRatio;

  /// Guide-circle radius as a ratio of the image width (matches UI: ~70% width).
  final double guideCircleRadiusRatio;

  /// Extra slack for the circle containment check (1.0 = strict, >1 = looser).
  final double guideCircleSlackRatio;

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
    this.enableAutoCapture = true,
    this.targetFaceFillRatio = 0.58,
    this.minFaceFillRatio = 0.42,
    this.maxFaceFillRatio = 0.78,
    this.maxCenterOffsetRatio = 0.18,
    this.captureTimerMs = 600,
    this.hairPoseLossGraceMs = 700,
    this.frameThrottleInterval = 3, // Update UI on every Nth frame
    this.requireEyesAlignedForCapture = true,
    this.eyeBandMinYRatio = 0.31,
    this.eyeBandMaxYRatio = 0.44,
    this.faceFrameMarginRatio = 0.04,
    this.guideCircleRadiusRatio = 0.35,
    this.guideCircleSlackRatio = 1.06,
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

  /// Sets callbacks for auto-capture (nullable to allow clearing)
  void setCallbacks({VoidCallback? onCapture, VoidCallback? onStateChange}) {
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
    double faceCenterXRatio = 0.5,
    double faceCenterYRatio = 0.5,
    double imageWidth = 1.0,
    double imageHeight = 1.0,
  }) {
    if (kDebugMode)
      print(
        '[AUTO] updateFaceDetection: hasFace=$hasFace, fill=$faceWidthRatio/$faceHeightRatio, offsetX=$faceCenterOffsetX, offsetY=$faceCenterOffsetY, centerY=$faceCenterYRatio',
      );
    // Capture previous state BEFORE mutating angles.
    final wasCaptureReady = _isCaptureReady;
    bool shouldStopTimerImmediately = false;

    _faceFillRatio = faceWidthRatio > faceHeightRatio
        ? faceWidthRatio
        : faceHeightRatio;
    _faceWidthRatio = faceWidthRatio;
    _faceHeightRatio = faceHeightRatio;
    _faceCenterOffsetX = faceCenterOffsetX;
    _faceCenterOffsetY = faceCenterOffsetY;
    _faceCenterXRatio = faceCenterXRatio;
    _faceCenterYRatio = faceCenterYRatio;
    _imageWidth = imageWidth <= 0 ? 1.0 : imageWidth;
    _imageHeight = imageHeight <= 0 ? 1.0 : imageHeight;

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

    // _hasFace = hasFace;
    final isStructureValid = _isValidFaceStructure(landmarks);

    // Face must be large enough
    final isFaceSizeValid = _faceFillRatio > (kIsWeb ? 0.18 : 0.12);

    // Reject weird aspect ratios (hands etc.)
    final aspectRatio = faceWidthRatio / (faceHeightRatio + 0.001);
    final isAspectRatioValid = aspectRatio > 0.5 && aspectRatio < 2.2;

    // bool detectedFace =
    //     hasFace && isStructureValid && isFaceSizeValid && isAspectRatioValid;
    final relaxStructureChecks = useFaceFillCapture;
    bool detectedFace =
        hasFace &&
        isFaceSizeValid &&
        isAspectRatioValid &&
        (isStructureValid || (relaxStructureChecks && _faceFillRatio > 0.35));

    // Require stable detection across frames
    if (detectedFace) {
      _validFaceFrames++;
    } else {
      _validFaceFrames = 0;
    }

    // Only confirm face after few stable frames
    _hasFace = _validFaceFrames > (kIsWeb ? 1 : 0);

    _faceCenterYRatio = faceCenterYRatio;

    final hasValidPose =
        rawPitch.isFinite && rawYaw.isFinite && rawRoll.isFinite;

    final geometryFallbackReady =
        !useFaceFillCapture &&
        _hasFace &&
        _faceFillRatio >= 0.12 &&
        _faceFillRatio <= 0.98 &&
        _faceCenterOffsetX <= 0.42 &&
        _faceCenterOffsetY <= 0.44;

    // Some Android camera stacks intermittently provide invalid/empty Euler
    // values. Keep auto-capture functional using geometry fallback.
    if (!hasValidPose && !useFaceFillCapture) {
      _currentPitch = 0.0;
      _currentYaw = 0.0;
      _currentRoll = 0.0;
      _hasPose = false;
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
        _currentYaw.abs() <= maxYawDeviation &&
        _currentRoll.abs() <= maxRollDeviation;

    bool hasCapturePose;
    if (useFaceFillCapture) {
      final now = DateTime.now();
      final centeredForCircle =
          _faceCenterOffsetX <= maxCenterOffsetRatio &&
          _faceCenterOffsetY <= maxCenterOffsetRatio;
      final fillReady =
          _faceFillRatio >= minFaceFillRatio &&
          _faceFillRatio <= maxFaceFillRatio;
      final scalpFramingReady =
          _faceCenterYRatio >= 0.52 && _faceCenterYRatio <= 0.82;
      final landmarkPoseReady = _isHairLandmarkPoseReady(landmarks);
      final manualReferenceReady = _matchesManualHairReference(
        hasValidPose: hasValidPose,
      );

      final geometryPoseReady =
          _hasFace &&
          centeredForCircle &&
          fillReady &&
          scalpFramingReady &&
          landmarkPoseReady;

      if (geometryPoseReady) {
        _lastHairCapturePoseAt = now;
      }

      final withinPoseLossGrace =
          _lastHairCapturePoseAt != null &&
          now.difference(_lastHairCapturePoseAt!).inMilliseconds <=
              hairPoseLossGraceMs;

      hasCapturePose =
          geometryPoseReady || manualReferenceReady || withinPoseLossGrace;
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
      final eyesAligned = _areEyesAlignedToGuideLine(landmarks);
      final faceFullyInFrame = _isFaceFullyInFrame();
      final faceInOval = _isFaceInOvalGuide(landmarks);
      final criticalReady =
          faceFullyInFrame &&
          faceInOval &&
          (!requireEyesAlignedForCapture || eyesAligned);
      shouldStopTimerImmediately = !criticalReady;

      final strictPoseReady =
          hasValidPose &&
          isPerfectAngle &&
          hasCrownTilt &&
          isCenteredHead &&
          _poseQuality >= captureQualityThreshold &&
          faceInOval &&
          (!requireEyesAlignedForCapture || eyesAligned) &&
          faceFullyInFrame;

      hasCapturePose =
          strictPoseReady ||
          (geometryFallbackReady &&
              faceInOval &&
              (!requireEyesAlignedForCapture || eyesAligned) &&
              faceFullyInFrame);
      _isBestAngle =
          strictPoseReady ||
          (geometryFallbackReady &&
              faceInOval &&
              (!requireEyesAlignedForCapture || eyesAligned) &&
              faceFullyInFrame &&
              _faceCenterOffsetX <= 0.32 &&
              _faceCenterOffsetY <= 0.32);

      if (!faceFullyInFrame) {
        _guidanceText = 'Keep your full face inside the frame';
      } else if (!faceInOval) {
        _guidanceText = _ovalFitGuidance();
      } else if (requireEyesAlignedForCapture && !eyesAligned) {
        _guidanceText = 'Align your eyes with the guide lines';
      } else if (strictPoseReady) {
        _guidanceText = 'Great! Hold still for auto capture';
      } else if (geometryFallbackReady) {
        _guidanceText = 'Face aligned. Hold steady for capture';
      } else {
        _guidanceText = 'Align face to the guide lines';
      }
    }
    if (hasCapturePose) {
      _bestAngleSince ??= DateTime.now();
      _bestFrameStreak += 1;
    } else {
      _bestAngleSince = null;
      _bestFrameStreak = 0;
    }

    _isCaptureReady =
        hasCapturePose &&
        _bestAngleSince != null &&
        _bestFrameStreak >= requiredConsecutiveBestFrames &&
        DateTime.now().difference(_bestAngleSince!).inMilliseconds >=
            requiredStableMs;

    final isCaptureReadyNow = _isCaptureReady;

    // Always check for best-angle stable state changes (entering/leaving capture-ready zone)
    if (wasCaptureReady != isCaptureReadyNow) {
      if (enableAutoCapture) {
        if (isCaptureReadyNow) {
          _notReadyStreak = 0;
          _startCaptureTimer();
        } else {
          // Flicker tolerance: don't kill the timer on brief detection drops.
          // Only stop after several consecutive not-ready frames.
          _notReadyStreak++;
          final timerRunning = _captureTimer != null && _captureTimer!.isActive;
          if (shouldStopTimerImmediately) {
            _stopCaptureTimer();
            _notReadyStreak = 0;
          } else if (!timerRunning || _notReadyStreak > _flickerGraceFrames) {
            _stopCaptureTimer();
            _notReadyStreak = 0;
          }
        }
      } else {
        _stopCaptureTimer();
      }
      // Immediate update when angle changes
      _onStateChange?.call();
    } else {
      if (isCaptureReadyNow) _notReadyStreak = 0;
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
    if (!enableAutoCapture) {
      return;
    }

    if (_captureTimer != null && _captureTimer!.isActive) {
      return; // Timer already running
    }

    _remainingTime = captureTimerMs;

    _captureTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _remainingTime -= 100;

      if (_remainingTime <= 0) {
        _stopCaptureTimer();
        _triggerCapture();
      } else {
        _onStateChange?.call();
      }
    });

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
    debugPrint('[AUTO_CAPTURE] Timer completed — triggering capture');
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
    final pitchScore =
        1.0 -
        ((pitch - targetPitch).abs() / bestPitchTolerance).clamp(0.0, 1.0);
    final yawScore = 1.0 - (yaw.abs() / bestYawTolerance).clamp(0.0, 1.0);
    final rollScore = 1.0 - (roll.abs() / bestRollTolerance).clamp(0.0, 1.0);
    return (pitchScore * 0.5 + yawScore * 0.3 + rollScore * 0.2).clamp(
      0.0,
      1.0,
    );
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
    if (eyeDx < 40.0 || earDx < 80.0) {
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

  bool _isValidFaceStructure(List<List<double>> landmarks) {
    if (landmarks.length < 5) return false;

    final leftEye = landmarks[1];
    final rightEye = landmarks[2];
    final nose = landmarks[0];

    final eyeDistance = (leftEye[0] - rightEye[0]).abs();
    final noseToEyeY = (nose[1] - ((leftEye[1] + rightEye[1]) / 2)).abs();

    // Reject fake detections (hands, objects)
    if (eyeDistance < 20) return false;
    if (noseToEyeY < 5) return false;

    return true;
  }

  bool _isFaceFullyInFrame() {
    if (!_hasFace) return false;

    final halfW = (_faceWidthRatio / 2).clamp(0.0, 0.5);
    final halfH = (_faceHeightRatio / 2).clamp(0.0, 0.5);
    final minX = _faceCenterXRatio - halfW;
    final maxX = _faceCenterXRatio + halfW;
    final minY = _faceCenterYRatio - halfH;
    final maxY = _faceCenterYRatio + halfH;

    final m = faceFrameMarginRatio.clamp(0.0, 0.25);
    return minX >= m && maxX <= (1.0 - m) && minY >= m && maxY <= (1.0 - m);
  }

  bool _areEyesAlignedToGuideLine(List<List<double>> landmarks) {
    if (!_hasFace) return false;
    if (!requireEyesAlignedForCapture) return true;
    if (landmarks.length < 3) return false;

    List<double>? safePoint(int index) {
      if (index < 0 || index >= landmarks.length) return null;
      final p = landmarks[index];
      if (p.length < 2) return null;
      final x = p[0];
      final y = p[1];
      if (!x.isFinite || !y.isFinite) return null;
      return [x, y];
    }

    final nose = safePoint(0);
    final leftEye = safePoint(1);
    final rightEye = safePoint(2);
    if (nose == null || leftEye == null || rightEye == null) return false;

    final eyeDx = (leftEye[0] - rightEye[0]).abs();
    final eyeDy = (leftEye[1] - rightEye[1]).abs();
    if (eyeDx <= 1.0) return false;

    // Half-face/clipped detections often place an eye too close to the edges.
    final minEyeX = leftEye[0] < rightEye[0] ? leftEye[0] : rightEye[0];
    final maxEyeX = leftEye[0] > rightEye[0] ? leftEye[0] : rightEye[0];
    final edgePadX = _imageWidth * 0.05;
    if (minEyeX < edgePadX || maxEyeX > (_imageWidth - edgePadX)) return false;

    // Eyes should be roughly level for a frontal selfie.
    final eyesLevel = (eyeDy / eyeDx).clamp(0.0, 99.0);
    if (eyesLevel > 0.10) return false;

    // Eyes must land in the guide band (matches web logic).
    final eyeMidY = (leftEye[1] + rightEye[1]) / 2.0;
    final eyeMidYRatio = (eyeMidY / _imageHeight).clamp(0.0, 1.0);
    if (eyeMidYRatio < eyeBandMinYRatio || eyeMidYRatio > eyeBandMaxYRatio) {
      return false;
    }

    // Nose should be below eyes (sanity check).
    if (nose[1] <= eyeMidY) return false;

    return true;
  }

  /// Whether the detected face fits inside the oval/circle guide overlay.
  /// The guide covers ~70% of the screen width and is centered; this checks
  /// that the face is properly centered and sized to match.
  bool _isFaceInOvalGuide(List<List<double>> landmarks) {
    if (!_hasFace) return false;

    // Quick geometry gate (cheap, stable).
    final isCentered = _faceCenterOffsetX <= 0.15 && _faceCenterOffsetY <= 0.18;
    final isRightSize = _faceFillRatio >= 0.28 && _faceFillRatio <= 0.75;
    final isVerticalCenterOk =
        _faceCenterYRatio >= 0.40 && _faceCenterYRatio <= 0.64;
    if (!(isCentered && isRightSize && isVerticalCenterOk)) return false;

    // Stronger containment check: key landmarks (plus derived forehead/chin)
    // must be inside the on-screen guide circle. This blocks half-face and
    // "not fully inside oval" captures.
    if (landmarks.length < 7) return true;

    List<double>? pointAt(int index) {
      if (index < 0 || index >= landmarks.length) return null;
      final p = landmarks[index];
      if (p.length < 2) return null;
      final x = p[0];
      final y = p[1];
      if (!x.isFinite || !y.isFinite) return null;
      return [x, y];
    }

    final nose = pointAt(0);
    final leftEye = pointAt(1);
    final rightEye = pointAt(2);
    final leftCheek = pointAt(7);
    final rightCheek = pointAt(8);
    final mouthBottom = pointAt(9);

    if (nose == null ||
        leftEye == null ||
        rightEye == null ||
        mouthBottom == null) {
      return true;
    }

    final eyeMidX = (leftEye[0] + rightEye[0]) / 2.0;
    final eyeMidY = (leftEye[1] + rightEye[1]) / 2.0;

    final foreheadX = eyeMidX;
    final foreheadY = eyeMidY - ((nose[1] - eyeMidY) * 0.90);
    final chinX = mouthBottom[0];
    final chinY = mouthBottom[1] + ((mouthBottom[1] - nose[1]) * 0.65);

    final circleCx = _imageWidth / 2.0;
    final circleCy = _imageHeight / 2.0;
    final radius = (_imageWidth * guideCircleRadiusRatio).clamp(
      1.0,
      _imageWidth,
    );
    final slack = guideCircleSlackRatio.clamp(1.0, 1.30);
    final r2 = (radius * slack) * (radius * slack);

    bool inside(double x, double y) {
      final dx = x - circleCx;
      final dy = y - circleCy;
      return (dx * dx + dy * dy) <= r2;
    }

    final pointsToCheck = <List<double>>[
      leftEye,
      rightEye,
      nose,
      mouthBottom,
      [foreheadX, foreheadY],
      [chinX, chinY],
      if (leftCheek != null) leftCheek,
      if (rightCheek != null) rightCheek,
    ];

    var insideCount = 0;
    for (final p in pointsToCheck) {
      if (inside(p[0], p[1])) insideCount++;
    }

    // Require most points to be inside the guide circle (tolerate 1–2 noisy points).
    final requiredInside = (pointsToCheck.length * 0.75).ceil();
    return insideCount >= requiredInside;
  }

  /// Guidance text explaining how to fit face into the oval.
  String _ovalFitGuidance() {
    if (!_hasFace) return 'Position your face inside the oval';
    if (_faceFillRatio < 0.28) return 'Move closer to fill the oval';
    if (_faceFillRatio > 0.75) return 'Move back to fit inside the oval';
    if (_faceCenterYRatio < 0.40) return 'Lower your face into the oval';
    if (_faceCenterYRatio > 0.64) return 'Raise your face into the oval';
    if (_faceCenterOffsetX > 0.15 || _faceCenterOffsetY > 0.18) {
      return 'Center your face inside the oval';
    }
    return 'Align your face in the oval';
  }

  /// Dispose the controller
  void dispose() {
    _captureTimer?.cancel();
  }
}

/// Mobile-specific auto-capture controller.
///
/// Uses slightly relaxed thresholds compared to the web controller to account
/// for native camera frame-rate variability and different sensor
/// characteristics.  Extends [AutoCaptureController] so the UI code can
/// treat both identically.
class MobileAutoCaptureController extends AutoCaptureController {
  MobileAutoCaptureController({
    required bool isHair,
    required bool disableAutoCapture,
  }) : super(
         // Wider pitch range to accommodate MediaPipe's different Euler
         // angle calibration vs the old ML Kit values.
         minPitch: isHair ? 30.0 : 30.0,
         maxPitch: isHair ? 60.0 : 62.0,
         maxYawDeviation: isHair ? 16.0 : 16.0,
         maxRollDeviation: isHair ? 14.0 : 18.0,
         idealPitch: isHair ? 45.0 : 46.0,
         bestPitchTolerance: isHair ? 10.0 : 12.0,
         bestYawTolerance: isHair ? 12.0 : 12.0,
         bestRollTolerance: isHair ? 10.0 : 14.0,
         requiredStableMs: isHair ? 80 : 120,
         requiredConsecutiveBestFrames: 1,
         minPoseQualityForCapture: isHair ? 0.30 : 0.35,
         captureQualityRelaxation: isHair ? 0.15 : 0.25,
         smoothingFactor: isHair ? 0.45 : 0.40,
         useFaceFillCapture: isHair && !disableAutoCapture,
         enableAutoCapture: !disableAutoCapture,
         minFaceFillRatio: isHair ? 0.10 : 0.14,
         maxFaceFillRatio: isHair ? 1.0 : 0.95,
         targetFaceFillRatio: isHair ? 0.45 : 0.42,
         maxCenterOffsetRatio: isHair ? 0.52 : 0.38,
         captureTimerMs: isHair ? 250 : 350,
         hairPoseLossGraceMs: isHair ? 1500 : 0,
         frameThrottleInterval: 1,
       );
}

/// EnhancedCameraScreen with auto-capture logic and tilt guidance
class EnhancedCameraScreen extends StatefulWidget {
  /// Callback when image is captured
  final Function(Uint8List imageBytes, String fileName) onImageCaptured;

  /// Whether this is for hair analysis
  final bool isHair;

  /// Disable auto-capture feature
  final bool disableAutoCapture;

  const EnhancedCameraScreen({
    super.key,
    required this.onImageCaptured,
    this.isHair = false,
    this.disableAutoCapture = false,
  });

  @override
  State<EnhancedCameraScreen> createState() => _EnhancedCameraScreenState();
}

class _EnhancedCameraScreenState extends State<EnhancedCameraScreen> {
  late AutoCaptureController _autoCaptureController;

  // Real camera and face detection
  List<CameraDescription> _availableCameras = const [];
  CameraLensDirection _activeLensDirection = CameraLensDirection.front;
  CameraController? _cameraController;
  FaceDetectionService? _faceDetectionService;
  StreamSubscription<FaceDetectionFrame>? _landmarksSubscription;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isDisposed = false;
  bool _hasNavigated = false;
  Timer? _imageStreamWatchdog;
  DateTime? _lastAnalysisFrameAt;
  DateTime? _lastImageStreamStartAt;
  int _analysisRestartAttempts = 0;
  DateTime? _analysisRestartWindowStart;
  DateTime? _lastCameraReinitAt;
  bool _isReinitializingCamera = false;
  bool _isStartingImageStream = false;

  // Web-only: use JS face mesh detection (see `web/face_detector.js`) instead of ML Kit.
  Object? _webFaceDetectedListenerSub;
  Object? _webFaceMetricsListenerSub;
  bool _webEyesAligned = false;
  Timer? _webStableAlignmentTimer;
  Timer? _webAutoCaptureTimer;
  bool _webAutoCaptureLocked = false;
  int _webStableFrames = 0;
  bool _webFaceSizeOk = false;

  List<ResolutionPreset> _cameraResolutionFallbacks() {
    if (kIsWeb) {
      return const [ResolutionPreset.high, ResolutionPreset.medium];
    }

    // Android/iOS: start with veryHigh (1080p) for sharp captures.
    // MediaPipe native plugin downscales to 640px internally for detection,
    // so the higher stream resolution only improves final image quality.
    return const [
      ResolutionPreset.veryHigh,
      ResolutionPreset.high,
      ResolutionPreset.medium,
    ];
  }

  Future<CameraController> _buildInitializedControllerWithFallback(
    CameraDescription selectedCamera,
  ) async {
    Object? lastError;
    for (final preset in _cameraResolutionFallbacks()) {
      final controller = CameraController(
        selectedCamera,
        preset,
        enableAudio: false,
        // NV21 on Android: native format with consistent plane layout across
        // all vendors.  YUV420 has device-specific stride issues that break
        // ML Kit face detection on Samsung/MediaTek/Unisoc chipsets.
        imageFormatGroup: kIsWeb
            ? null
            : (defaultTargetPlatform == TargetPlatform.android
                  ? ImageFormatGroup.nv21
                  : (defaultTargetPlatform == TargetPlatform.iOS
                        ? ImageFormatGroup.bgra8888
                        : null)),
      );

      try {
        await controller.initialize();
        return controller;
      } catch (e) {
        lastError = e;
        await controller.dispose();
      }
    }

    throw Exception('Failed to initialize camera with all presets: $lastError');
  }

  bool _isValidFaceStructure(List<List<double>> landmarks) {
    if (landmarks.length < 5) return false;

    final leftEye = landmarks[1];
    final rightEye = landmarks[2];
    final nose = landmarks[0];

    final eyeDistance = (leftEye[0] - rightEye[0]).abs();
    final noseToEyeY = (nose[1] - ((leftEye[1] + rightEye[1]) / 2)).abs();

    // Reject fake detections (hands, objects)
    if (eyeDistance < 30) return false;
    if (noseToEyeY < 5) return false;

    return true;
  }

  double _calculateGuideSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;

    // Keep the guide proportional across phones/tablets so capture framing
    // remains visually consistent.
    final responsiveSize = shortestSide * 0.72;
    return responsiveSize.clamp(280.0, 520.0);
  }

  double _calculateGuideVerticalInset(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final responsiveInset = mediaQuery.size.height * 0.12;
    return (responsiveInset + (mediaQuery.padding.top * 0.4)).clamp(
      100.0,
      180.0,
    );
  }

  double _calculateGuideHorizontalInset(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final responsiveInset = mediaQuery.size.width * 0.04;
    return responsiveInset.clamp(16.0, 56.0);
  }

  @override
  void initState() {
    super.initState();
    final disableAutoCaptureForHair = widget.disableAutoCapture;

    // Platform split: web keeps finely-tuned thresholds, mobile uses relaxed
    // controller optimized for native Camera2 stream.
    if (kIsWeb) {
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
        useFaceFillCapture: widget.isHair && !widget.disableAutoCapture,
        enableAutoCapture: disableAutoCaptureForHair
            ? false
            : !widget.disableAutoCapture,
        minFaceFillRatio: widget.isHair ? 0.26 : 0.40,
        maxFaceFillRatio: widget.isHair ? 0.98 : 0.82,
        targetFaceFillRatio: widget.isHair ? 0.60 : 0.56,
        maxCenterOffsetRatio: widget.isHair ? 0.34 : 0.20,
        captureTimerMs: widget.isHair ? 450 : 600,
        hairPoseLossGraceMs: widget.isHair ? 900 : 0,
        frameThrottleInterval: widget.isHair ? 3 : 2,
      );
    } else {
      // Mobile: relaxed thresholds for Camera2 stream
      _autoCaptureController = MobileAutoCaptureController(
        isHair: widget.isHair,
        disableAutoCapture: disableAutoCaptureForHair,
      );
    }

    _autoCaptureController.setCallbacks(
      onCapture: _handleAutoCapture,
      onStateChange: () {
        if (mounted) {
          setState(() {});
        }
      },
    );

    if (kIsWeb && !widget.isHair) {
      _webFaceDetectedListenerSub = web_face.addFaceDetectedListener((
        detected,
      ) {
        if (!mounted || _isDisposed || _hasNavigated) return;
        debugPrint("WEB ALIGN: $detected");

        // Gate alignment on face-size metrics — reject when face is
        // too close, too far, or off-center.
        final effectiveAligned = detected && _webFaceSizeOk;

        final wasAligned = _webEyesAligned;
        if (wasAligned != effectiveAligned) {
          setState(() => _webEyesAligned = effectiveAligned);
        }
        _handleWebAlignmentChange(effectiveAligned);
      });

      // Subscribe to detailed face metrics from JS to check face size.
      _webFaceMetricsListenerSub = web_face.addFaceMetricsListener((metrics) {
        if (!mounted || _isDisposed || _hasNavigated) return;
        final fill = metrics.faceWidth > metrics.faceHeight
            ? metrics.faceWidth
            : metrics.faceHeight;
        final centered =
            metrics.centerOffsetX <= 0.15 && metrics.centerOffsetY <= 0.18;
        final sizeOk = fill >= 0.18 && fill <= 0.60;
        final verticalOk =
            metrics.faceCenterY >= 0.32 && metrics.faceCenterY <= 0.65;
        _webFaceSizeOk = metrics.detected && sizeOk && centered && verticalOk;
      });
    }

    // Initialize camera + face detection for both hair and face workflows.
    _initializeHairAnalysisCamera();
  }

  bool get _isWebAutoCaptureEnabled =>
      kIsWeb && !widget.isHair && !widget.disableAutoCapture;

  void _handleWebAlignmentChange(bool aligned) {
    // Keep this web-only so mobile capture flow remains unchanged.
    if (!kIsWeb || widget.isHair) return;

    if (!aligned) {
      _webStableFrames = 0;
      _webAutoCaptureLocked = false;
      _webStableAlignmentTimer?.cancel();
      _webStableAlignmentTimer = null;
      _webAutoCaptureTimer?.cancel();
      _webAutoCaptureTimer = null;
      return;
    }

    if (!_isWebAutoCaptureEnabled) return;
    if (_isCapturing || _hasNavigated || _isDisposed) return;
    if (_webAutoCaptureLocked) return;

    _webStableFrames++;

    // Require both short frame consistency and a minimum time window.
    if (_webStableAlignmentTimer == null) {
      _webStableAlignmentTimer = Timer(const Duration(milliseconds: 520), () {
        _webStableAlignmentTimer = null;
        if (!mounted || _isDisposed || _hasNavigated || _isCapturing) return;
        if (!_webEyesAligned || _webStableFrames < 3) return;

        _webAutoCaptureLocked = true;
        _webAutoCaptureTimer?.cancel();
        _webAutoCaptureTimer = Timer(const Duration(milliseconds: 180), () {
          if (!mounted || _isDisposed || _hasNavigated || _isCapturing) {
            _webAutoCaptureLocked = false;
            return;
          }
          if (_webEyesAligned) {
            debugPrint('[WEB] Auto capture triggered');
            _handleAutoCapture();
          } else {
            _webAutoCaptureLocked = false;
          }
        });
      });
    }
  }

  void _startWebFaceDetectionWithRetry([int attempt = 0]) {
    if (!kIsWeb || widget.isHair) return;
    if (!mounted || _isDisposed || attempt > 15) return;

    Future.delayed(Duration(milliseconds: attempt == 0 ? 500 : 800), () {
      if (!mounted || _isDisposed) return;
      Future<void>(() async {
        try {
          final started = await web_face.startFaceDetection();
          if (started) {
            if (kDebugMode) {
              debugPrint(
                '[WEB_FACE] Face detection started (attempt $attempt)',
              );
            }
            return;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('[WEB_FACE] startFaceDetection error: $e');
        }

        if (kDebugMode) {
          debugPrint(
            '[WEB_FACE] No video element found (attempt $attempt), retrying...',
          );
        }
        _startWebFaceDetectionWithRetry(attempt + 1);
      });
    });
  }

  /// Initializes camera and face detection.
  Future<void> _initializeHairAnalysisCamera() async {
    try {
      _isCameraInitialized = false;
      _stopImageStreamWatchdog();
      _isReinitializingCamera = true;

      if (kIsWeb && !widget.isHair) {
        _webStableAlignmentTimer?.cancel();
        _webStableAlignmentTimer = null;
        _webAutoCaptureTimer?.cancel();
        _webAutoCaptureTimer = null;
        _webAutoCaptureLocked = false;
        if (_webEyesAligned) {
          setState(() => _webEyesAligned = false);
        }
        // Best-effort cleanup so re-inits don't latch onto old video elements.
        web_face.stopFaceDetection().catchError((_) {});
      }

      // Get and cache available cameras
      if (_availableCameras.isEmpty) {
        _availableCameras = await availableCameras();
      }
      if (_availableCameras.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      final selectedCamera = _availableCameras.firstWhere(
        (camera) => camera.lensDirection == _activeLensDirection,
        orElse: () => _availableCameras.first,
      );

      _activeLensDirection = selectedCamera.lensDirection;

      await _landmarksSubscription?.cancel();
      _landmarksSubscription = null;
      await _cameraController?.dispose();
      _cameraController = null;

      // Native (Android/iOS): MediaPipe face detection from the camera image stream.
      if (!kIsWeb) {
        _faceDetectionService ??= FaceDetectionService();
        // initialize() now retries internally and won't throw — if it fails,
        // face detection just stays disabled and geometry fallback handles auto-capture.
        await _faceDetectionService!.initialize();
        // Configure image rotation based on camera sensor orientation.
        _faceDetectionService!.setSensorRotation(
          selectedCamera.sensorOrientation,
        );
      }

      // Initialize with high-quality-first fallback for better cross-device output.
      _cameraController = await _buildInitializedControllerWithFallback(
        selectedCamera,
      );

      // Brief stabilization pause on mobile for Camera2 session setup.
      if (!kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (!kIsWeb) {
        // Listen to face detection landmarks in both hair + non-hair flows.
        _landmarksSubscription = _faceDetectionService!.landmarksStream.listen((
          frame,
        ) {
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
            faceCenterXRatio: frame.faceCenterXRatio,
            faceCenterYRatio: frame.faceCenterYRatio,
            imageWidth: frame.imageWidth,
            imageHeight: frame.imageHeight,
          );
        });

        // Start image stream
        await _startSafeImageStream();

        // Start watchdog to monitor stream health
        _startImageStreamWatchdog();
      } else {
        // Web: JS-driven face alignment events (no CameraImage stream available).
        _startWebFaceDetectionWithRetry();
      }

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
    _isReinitializingCamera = false;
  }

  Future<void> _switchCamera() async {
    if (_isCapturing || _availableCameras.length < 2) {
      return;
    }

    final nextLens = _activeLensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    if (mounted) {
      setState(() {
        _activeLensDirection = nextLens;
      });
    }

    await _initializeHairAnalysisCamera();
  }

  /// Handles auto-capture trigger
  void _handleAutoCapture() {
    debugPrint(
      '[AUTO_CAPTURE] _handleAutoCapture: mounted=$mounted disposed=$_isDisposed navigated=$_hasNavigated capturing=$_isCapturing',
    );
    if (!mounted || _isDisposed || _hasNavigated) return;
    _takePicture();
  }

  /// Takes a picture from the camera
  Future<void> _takePicture() async {
    if (_isCapturing || _isDisposed || _hasNavigated) return;
    _isCapturing = true;

    bool shouldRestartStream = false;

    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      // Double-check we're still mounted before async operations
      if (!mounted || _isDisposed || _hasNavigated) {
        return;
      }

      if (_cameraController!.value.isStreamingImages) {
        shouldRestartStream = true;
        await _cameraController!.stopImageStream();
        // Camera2 needs a moment to switch from streaming to still capture
        // mode. Without this, takePicture() fails on many devices.
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Check again after async operation
      if (!mounted || _isDisposed || _hasNavigated) {
        return;
      }

      debugPrint('[CAPTURE] Taking picture...');
      // Take picture
      final XFile picture = await _cameraController!.takePicture();
      debugPrint('[CAPTURE] Picture taken: ${picture.path}');
      final imageBytes = await picture.readAsBytes();

      shouldRestartStream = false;

      // Final check before navigating
      if (!mounted || _isDisposed || _hasNavigated) {
        return;
      }

      // Mark as navigated to prevent multiple navigations
      _hasNavigated = true;

      // Navigate directly using this widget's context (which is still valid)
      if (mounted && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(
              imageBytes: imageBytes,
              fileName: picture.name,
              isHair: widget.isHair,
            ),
          ),
        );
      }

      // Exit immediately after navigation
      return;
    } catch (e) {
      // Only show error if we haven't navigated away
      if (mounted && !_isDisposed && !_hasNavigated && context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Capture failed: ${e.toString()}'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {
          // Ignore SnackBar errors if context is gone
        }
      }
    } finally {
      final canRestartStream =
          mounted &&
          !_isDisposed &&
          !_hasNavigated &&
          _cameraController != null &&
          _cameraController!.value.isInitialized;

      // Guarantee the analysis stream restarts after capture on mobile flows.
      // This is intentionally independent of `shouldRestartStream` to avoid the
      // pipeline getting stuck in "ImageAnalysis INACTIVE" states.
      if (!kIsWeb &&
          canRestartStream &&
          !_cameraController!.value.isStreamingImages) {
        await _restartSafeImageStream();
      }
      _isCapturing = false;
    }
  }

  Future<void> _startSafeImageStream() async {
    if (_cameraController == null || _isStartingImageStream) return;

    final controller = _cameraController!;

    // Wait until initialized (retry loop instead of early return)
    int initWaitAttempts = 0;
    while (!controller.value.isInitialized && initWaitAttempts < 40) {
      await Future.delayed(const Duration(milliseconds: 50));
      initWaitAttempts++;
    }

    if (!controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    _isStartingImageStream = true;

    // Ensure face detection service exists
    _faceDetectionService ??= FaceDetectionService();
    if (!_faceDetectionService!.isInitialized) {
      await _faceDetectionService!.initialize();
    }

    try {
      _lastImageStreamStartAt = DateTime.now();
      _lastAnalysisFrameAt = null;
      if (kDebugMode) print('[STREAM] Starting image stream');
      await controller.startImageStream((CameraImage image) {
        _lastAnalysisFrameAt = DateTime.now();
        final service = _faceDetectionService;
        if (service != null) {
          service.processCameraFrame(image);
        }
      });
      if (kDebugMode) print('[STREAM] Image stream started');
    } catch (e) {
      if (kDebugMode) print('startImageStream error: $e');
    } finally {
      _isStartingImageStream = false;
    }
  }

  Future<void> _restartSafeImageStream() async {
    final controller = _cameraController;
    if (controller == null || _isStartingImageStream) return;

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}

    if (!kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    await _startSafeImageStream();
  }

  void _startImageStreamWatchdog() {
    if (kIsWeb) {
      return;
    }
    _imageStreamWatchdog ??= Timer.periodic(const Duration(seconds: 1), (
      _,
    ) async {
      if (!mounted || _isDisposed || _hasNavigated || _isCapturing) {
        return;
      }
      if (_isReinitializingCamera || _isStartingImageStream) {
        return;
      }
      final controller = _cameraController;
      if (controller == null || !controller.value.isInitialized) {
        return;
      }
      final now = DateTime.now();
      final lastFrameAt = _lastAnalysisFrameAt;
      final lastStartAt = _lastImageStreamStartAt;
      final withinStartupGrace =
          lastStartAt != null &&
          now.difference(lastStartAt).inMilliseconds < 5000;
      final isStale = lastFrameAt == null
          ? !withinStartupGrace
          : now.difference(lastFrameAt).inMilliseconds > 3000;

      // Restart the stream if it stopped or frames have gone stale.
      if (!controller.value.isStreamingImages || isStale) {
        if (kDebugMode) {
          print(
            '[WATCHDOG] Restarting image stream: isStreaming=${controller.value.isStreamingImages}, '
            'lastFrameMs=${lastFrameAt == null ? -1 : now.difference(lastFrameAt).inMilliseconds}',
          );
        }
        _analysisRestartWindowStart ??= now;
        if (now.difference(_analysisRestartWindowStart!).inSeconds >= 5) {
          _analysisRestartWindowStart = now;
          _analysisRestartAttempts = 0;
        }
        _analysisRestartAttempts += 1;

        await _restartSafeImageStream();

        // If repeated restarts fail, reinitialize the camera once.
        final shouldReinit =
            _analysisRestartAttempts >= 3 &&
            !_isReinitializingCamera &&
            (_lastCameraReinitAt == null ||
                now.difference(_lastCameraReinitAt!).inSeconds >= 10);
        if (shouldReinit) {
          if (kDebugMode)
            print(
              '[WATCHDOG] Reinitializing camera after repeated stream restarts',
            );
          _lastCameraReinitAt = now;
          await _initializeHairAnalysisCamera();
        }
      }
    });
  }

  void _stopImageStreamWatchdog() {
    _imageStreamWatchdog?.cancel();
    _imageStreamWatchdog = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopImageStreamWatchdog();

    // Clear callbacks to prevent posthumous calls
    _autoCaptureController.setCallbacks(onCapture: null, onStateChange: null);

    if (kIsWeb && _webFaceDetectedListenerSub != null) {
      web_face.removeFaceDetectedListener(_webFaceDetectedListenerSub!);
      _webFaceDetectedListenerSub = null;
      if (_webFaceMetricsListenerSub != null) {
        web_face.removeFaceMetricsListener(_webFaceMetricsListenerSub!);
        _webFaceMetricsListenerSub = null;
      }
      _webStableAlignmentTimer?.cancel();
      _webStableAlignmentTimer = null;
      _webAutoCaptureTimer?.cancel();
      _webAutoCaptureTimer = null;
      web_face.stopFaceDetection().catchError((_) {});
    }

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
          kIsWeb ? _buildWebCameraPreview() : CameraPreview(_cameraController!)
        else
          Container(
            color: Colors.black87,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_kBurgundy),
                  ),
                  if (!widget.isHair) ...[
                    const SizedBox(height: 20),
                    Text(
                      _isCameraInitialized
                          ? '📷 Camera ready...'
                          : '⏳ Initializing camera & face detection...',
                      style: const TextStyle(color: _kIvory, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
        _buildStatusIndicator(),
        if (!widget.isHair) _buildGuidanceOverlay(),
        if (!widget.isHair) _buildEyeAlignmentHint(),
        _buildManualCaptureButton(),
        if (widget.isHair) _buildCameraSwitchButton(),
        _buildBackButton(),
      ],
    );
  }

  /// On web, CameraPreview stretches the <video> to fill its parent
  /// regardless of the stream's native aspect ratio. This wrapper
  /// constrains the preview to the camera's actual ratio and covers
  /// the screen by overflowing/clipping — preventing the face from
  /// appearing distorted/zoomed.
  Widget _buildWebCameraPreview() {
    final ctrl = _cameraController!;
    final previewSize = ctrl.value.previewSize;

    if (previewSize == null ||
        previewSize.width <= 0 ||
        previewSize.height <= 0) {
      return CameraPreview(ctrl);
    }

    // previewSize is landscape (e.g. 1280×720)
    final cameraAspect = previewSize.width / previewSize.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;
        final screenAspect = screenW / screenH;

        // Cover the screen while preserving aspect ratio
        double renderW, renderH;
        if (screenAspect > cameraAspect) {
          renderW = screenW;
          renderH = screenW / cameraAspect;
        } else {
          renderH = screenH;
          renderW = screenH * cameraAspect;
        }

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            maxWidth: renderW,
            maxHeight: renderH,
            child: SizedBox(
              width: renderW,
              height: renderH,
              child: CameraPreview(ctrl),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEyeAlignmentHint() {
    final aligned = kIsWeb
        ? _webEyesAligned
        : _autoCaptureController.isBestAngle;
    final show =
        _isCameraInitialized && !aligned && !_isCapturing && !_hasNavigated;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            offset: show ? Offset.zero : const Offset(0, -0.10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.40),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: const Text(
                'Align your eyes with the guide lines for auto capture',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the guidance overlay widget
  Widget _buildGuidanceOverlay() {
    final guideSize = _calculateGuideSize(context);
    final verticalInset = _calculateGuideVerticalInset(context);
    final horizontalInset = _calculateGuideHorizontalInset(context);

    return Positioned(
      top: verticalInset,
      bottom: verticalInset,
      left: horizontalInset,
      right: horizontalInset,
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
          guideSize: guideSize,
        ),
      ),
    );
  }

  /// Build the status indicator
  Widget _buildStatusIndicator() {
    if (widget.isHair) {
      return Positioned(
        top: 26,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Column(
            children: [
              Text(
                'HAIR ANALYSIS',
                style: TextStyle(
                  letterSpacing: 3,
                  color: _kIvory.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Capture your scalp\nfor best results',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  color: _kIvory.withValues(alpha: 0.95),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                                color: Colors.green.shade300.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Angle values
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                            color:
                                (_autoCaptureController.currentPitch >=
                                        _autoCaptureController.targetMinPitch &&
                                    _autoCaptureController.currentPitch <=
                                        _autoCaptureController.targetMaxPitch)
                                ? Colors.greenAccent
                                : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Angle: ${_autoCaptureController.currentYaw.toStringAsFixed(0)}°',
                          style: TextStyle(
                            color:
                                _autoCaptureController.currentYaw.abs() <=
                                    _autoCaptureController.targetMaxYawDeviation
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
    final isHairManualMode = widget.isHair;

    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Capture button with ring effect
          if (widget.isHair)
            GestureDetector(
              onTap: () async {
                await _takePicture();
              },
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kSoftPink.withValues(alpha: 0.25),
                  border: Border.all(
                    color: _kSoftPink.withValues(alpha: 0.9),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kSoftPink.withValues(alpha: 0.25),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kRosePink,
                      border: Border.all(
                        color: _kIvory.withValues(alpha: 0.7),
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
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
                  FloatingActionButton(
                    backgroundColor:
                        _autoCaptureController.isBestAngle || isHairManualMode
                        ? _kBurgundy
                        : Colors.grey.shade700,
                    elevation:
                        _autoCaptureController.isBestAngle || isHairManualMode
                        ? 8
                        : 4,
                    onPressed: () async {
                      _autoCaptureController.registerManualCaptureReference();
                      await _takePicture();
                    },
                    child: Icon(
                      Icons.camera_alt,
                      size: 28,
                      color:
                          _autoCaptureController.isBestAngle || isHairManualMode
                          ? _kIvory
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Info text
          Text(
            widget.isHair
                ? 'Tap shutter to capture'
                : (_autoCaptureController.isBestAngle
                      ? 'Tap or wait for auto-capture'
                      : 'Adjust position for auto-capture'),
            style: TextStyle(
              color: widget.isHair
                  ? _kSoftPink.withValues(alpha: 0.95)
                  : _kIvory.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSwitchButton() {
    return Positioned(
      bottom: 48,
      right: 24,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: widget.isHair
                ? _kRosePink.withValues(alpha: 0.9)
                : _kBurgundy.withValues(alpha: 0.88),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isHair
                  ? _kSoftPink.withValues(alpha: 0.95)
                  : _kIvory.withValues(alpha: 0.35),
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.cameraswitch,
              color: widget.isHair ? _kIvory : _kIvory,
              size: 26,
            ),
            onPressed: _availableCameras.length >= 2 ? _switchCamera : null,
          ),
        ),
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
            color: widget.isHair
                ? _kRosePink.withValues(alpha: 0.9)
                : _kBurgundy.withValues(alpha: 0.88),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isHair
                  ? _kSoftPink.withValues(alpha: 0.95)
                  : _kIvory.withValues(alpha: 0.35),
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: _kIvory, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}
