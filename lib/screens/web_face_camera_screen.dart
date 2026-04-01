import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'dart:async';

import '../utils/web_face_detection.dart' as web_face;
import '../widgets/oval_face_guide_painter.dart';
import 'image_preview_screen.dart';

const _kBurgundy = Color(0xFF6B3A3A);
const _kIvory = Color(0xFFFDF8F3);

/// A responsive web camera screen with an elliptical face guide overlay,
/// real-time face-positioning feedback, and auto-capture.
///
/// Designed for web; relies on the JS face detection bridge
/// (`web/face_detector.js`) for MediaPipe FaceMesh metrics.
class WebFaceCameraScreen extends StatefulWidget {
  final Function(Uint8List imageBytes, String fileName) onImageCaptured;

  const WebFaceCameraScreen({super.key, required this.onImageCaptured});

  @override
  State<WebFaceCameraScreen> createState() => _WebFaceCameraScreenState();
}

class _WebFaceCameraScreenState extends State<WebFaceCameraScreen> {
  // ── Camera ──────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _hasNavigated = false;
  bool _isDisposed = false;

  // ── Face detection ──────────────────────────────────────────────────────
  Object? _faceDetectedListener;
  Object? _faceMetricsListener;
  web_face.FaceMetrics _metrics = const web_face.FaceMetrics();
  bool _faceDetected = false;

  // ── Auto-capture ────────────────────────────────────────────────────────
  int _stableFrames = 0;
  Timer? _stabilityTimer;
  Timer? _countdownTimer;
  bool _isCountingDown = false;
  int _countdownMs = 0;
  static const int _countdownDurationMs = 900;
  static const int _stabilityDelayMs = 500;

  // ── Feedback ────────────────────────────────────────────────────────────
  String _guidanceText = 'Position your face in the oval';
  bool _isAligned = false;

  // ── Thresholds (normalised 0-1 relative to video frame) ─────────────────
  static const double _minFaceFill = 0.22;
  static const double _maxFaceFill = 0.58;
  static const double _maxCenterOffsetX = 0.12;
  static const double _maxCenterOffsetY = 0.15;
  static const double _minFaceCenterY = 0.35;
  static const double _maxFaceCenterY = 0.62;

  // ── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelAutoCapture();

    if (_faceDetectedListener != null) {
      web_face.removeFaceDetectedListener(_faceDetectedListener!);
    }
    if (_faceMetricsListener != null) {
      web_face.removeFaceMetricsListener(_faceMetricsListener!);
    }
    web_face.stopFaceDetection().catchError((_) {});

    _cameraController?.dispose();
    super.dispose();
  }

  // ── Camera init ─────────────────────────────────────────────────────────

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras available');

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      CameraController? controller;
      for (final preset in [ResolutionPreset.high, ResolutionPreset.medium]) {
        controller = CameraController(frontCamera, preset, enableAudio: false);
        try {
          await controller.initialize();
          break;
        } catch (_) {
          await controller.dispose();
          controller = null;
        }
      }

      if (controller == null) throw Exception('Failed to initialize camera');
      _cameraController = controller;

      // Face detection listeners
      _faceDetectedListener = web_face.addFaceDetectedListener((detected) {
        if (!mounted || _isDisposed || _hasNavigated) return;
        if (_faceDetected != detected) {
          setState(() => _faceDetected = detected);
        }
      });

      _faceMetricsListener = web_face.addFaceMetricsListener((metrics) {
        if (!mounted || _isDisposed || _hasNavigated) return;
        _metrics = metrics;
        _evaluateFacePosition();
      });

      _startFaceDetectionWithRetry();

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _startFaceDetectionWithRetry([int attempt = 0]) {
    if (!mounted || _isDisposed || attempt > 15) return;
    Future.delayed(Duration(milliseconds: attempt == 0 ? 500 : 800), () async {
      if (!mounted || _isDisposed) return;
      try {
        final started = await web_face.startFaceDetection();
        if (started) return;
      } catch (_) {}
      _startFaceDetectionWithRetry(attempt + 1);
    });
  }

  // ── Face position evaluation ────────────────────────────────────────────

  void _evaluateFacePosition() {
    if (!mounted || _isDisposed || _hasNavigated || _isCapturing) return;

    final m = _metrics;
    final faceFill = m.faceWidth > m.faceHeight ? m.faceWidth : m.faceHeight;

    bool aligned = false;
    String guidance;

    if (!m.detected) {
      guidance = 'Position your face in the oval';
    } else if (faceFill > _maxFaceFill) {
      guidance = 'Move back';
    } else if (faceFill < _minFaceFill) {
      guidance = 'Move closer';
    } else if (m.faceCenterY < _minFaceCenterY) {
      guidance = 'Move your face down slightly';
    } else if (m.faceCenterY > _maxFaceCenterY) {
      guidance = 'Move your face up slightly';
    } else if (m.centerOffsetX > _maxCenterOffsetX) {
      guidance = 'Align your face in the oval';
    } else if (m.centerOffsetY > _maxCenterOffsetY) {
      guidance = 'Align your face in the oval';
    } else {
      aligned = true;
      guidance = 'Perfect! Hold steady...';
    }

    _isAligned = aligned;
    setState(() => _guidanceText = guidance);

    if (aligned) {
      _stableFrames++;
      _handleAlignmentStable();
    } else {
      _stableFrames = 0;
      _cancelAutoCapture();
    }
  }

  // ── Auto-capture timer ──────────────────────────────────────────────────

  void _handleAlignmentStable() {
    if (_isCountingDown || _isCapturing || _hasNavigated) return;

    _stabilityTimer ??= Timer(
      const Duration(milliseconds: _stabilityDelayMs),
      () {
        _stabilityTimer = null;
        if (!mounted || _isDisposed || _hasNavigated || _isCapturing) return;
        if (!_isAligned || _stableFrames < 3) return;
        _startCountdown();
      },
    );
  }

  void _startCountdown() {
    if (_isCountingDown || _isCapturing) return;

    setState(() {
      _isCountingDown = true;
      _countdownMs = _countdownDurationMs;
    });

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted || _isDisposed || _hasNavigated) {
        timer.cancel();
        return;
      }
      _countdownMs -= 100;
      if (_countdownMs <= 0) {
        timer.cancel();
        setState(() => _isCountingDown = false);
        _triggerAutoCapture();
      } else {
        setState(() {});
      }
    });
  }

  void _cancelAutoCapture() {
    _stabilityTimer?.cancel();
    _stabilityTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_isCountingDown && mounted) {
      setState(() {
        _isCountingDown = false;
        _countdownMs = 0;
      });
    } else {
      _isCountingDown = false;
      _countdownMs = 0;
    }
  }

  void _triggerAutoCapture() {
    if (_isCapturing || _hasNavigated || _isDisposed || !mounted) return;
    HapticFeedback.mediumImpact();
    _takePicture();
  }

  // ── Capture ─────────────────────────────────────────────────────────────

  Future<void> _takePicture() async {
    if (_isCapturing || _isDisposed || _hasNavigated) return;
    _isCapturing = true;

    try {
      final ctrl = _cameraController;
      if (ctrl == null || !ctrl.value.isInitialized) return;
      if (!mounted || _isDisposed || _hasNavigated) return;

      final picture = await ctrl.takePicture();
      final imageBytes = await picture.readAsBytes();

      if (!mounted || _isDisposed || _hasNavigated) return;
      _hasNavigated = true;

      if (mounted && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(
              imageBytes: imageBytes,
              fileName: picture.name,
              isHair: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted && !_isDisposed && !_hasNavigated && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      _isCapturing = false;
    }
  }

  // ── Oval geometry ───────────────────────────────────────────────────────

  Rect _computeOvalRect(Size screen) {
    double ovalWidth;
    if (screen.width < 600) {
      // Mobile portrait
      ovalWidth = screen.width * 0.68;
    } else if (screen.width < 1000) {
      // Tablet / small desktop
      ovalWidth = screen.width * 0.46;
    } else {
      // Large desktop
      ovalWidth = screen.width * 0.26;
    }
    ovalWidth = ovalWidth.clamp(220.0, 420.0);

    // Ellipse taller than wide to match a typical face aspect ratio
    final ovalHeight = (ovalWidth * 1.35).clamp(300.0, 560.0);
    final centerX = screen.width / 2;
    // Positioned slightly above vertical center for bottom button space
    final centerY = screen.height * 0.42;

    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: ovalWidth,
      height: ovalHeight,
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final ovalRect = _computeOvalRect(screenSize);

    final countdownProgress = _isCountingDown
        ? ((_countdownDurationMs - _countdownMs) / _countdownDurationMs).clamp(
            0.0,
            1.0,
          )
        : null;

    final borderColor = _isAligned
        ? (_isCountingDown ? Colors.green.shade400 : Colors.green.shade300)
        : (_faceDetected ? Colors.amber.shade300 : Colors.white);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview (fills screen, aspect handled by platform)
          if (_isCameraInitialized && _cameraController != null)
            _buildCameraPreview()
          else
            _buildLoadingIndicator(),

          // Oval overlay + dark surround
          SizedBox.expand(
            child: CustomPaint(
              painter: OvalFaceGuidePainter(
                ovalRect: ovalRect,
                borderColor: borderColor,
                borderWidth: _isAligned ? 3.5 : 2.5,
                overlayOpacity: 0.55,
                countdownProgress: countdownProgress,
              ),
            ),
          ),

          // Guidance text (below oval)
          Positioned(
            left: 24,
            right: 24,
            top: ovalRect.bottom + 24,
            child: _buildGuidanceText(),
          ),

          // Manual capture button
          _buildCaptureButton(),

          // Back / close button
          _buildBackButton(),
        ],
      ),
    );
  }

  // ── Sub-widgets ─────────────────────────────────────────────────────────

  Widget _buildCameraPreview() {
    final ctrl = _cameraController!;
    final previewSize = ctrl.value.previewSize;

    // Maintain aspect ratio: cover the screen without stretching
    if (previewSize != null &&
        previewSize.width > 0 &&
        previewSize.height > 0) {
      // previewSize is landscape (width > height), swap for portrait
      final cameraAspect = previewSize.height / previewSize.width;

      return LayoutBuilder(
        builder: (context, constraints) {
          final screenAspect = constraints.maxHeight / constraints.maxWidth;

          // Cover the entire area – crop overflow
          final scale = screenAspect > cameraAspect
              ? constraints.maxHeight / (constraints.maxWidth * cameraAspect)
              : constraints.maxWidth / (constraints.maxHeight / cameraAspect);

          return ClipRect(
            child: Transform.scale(
              scale: scale.clamp(1.0, 2.0),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1 / cameraAspect,
                  child: CameraPreview(ctrl),
                ),
              ),
            ),
          );
        },
      );
    }

    // Fallback: let the widget stretch
    return CameraPreview(ctrl);
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_kBurgundy),
            ),
            SizedBox(height: 20),
            Text(
              'Initializing camera...',
              style: TextStyle(color: _kIvory, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(_guidanceText),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _isAligned
              ? Colors.green.shade900.withValues(alpha: 0.7)
              : Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isAligned
                ? Colors.green.shade400.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          _guidanceText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _isAligned ? Colors.green.shade200 : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _cancelAutoCapture();
              _takePicture();
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isAligned ? _kBurgundy : Colors.grey.shade700,
                border: Border.all(
                  color: _isAligned
                      ? Colors.green.shade400.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 3,
                ),
                boxShadow: [
                  if (_isAligned)
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                size: 28,
                color: _isAligned ? _kIvory : Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isAligned
                ? 'Tap or wait for auto-capture'
                : 'Adjust position for auto-capture',
            style: TextStyle(
              color: _kIvory.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: _kBurgundy.withValues(alpha: 0.88),
            shape: BoxShape.circle,
            border: Border.all(color: _kIvory.withValues(alpha: 0.35)),
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
