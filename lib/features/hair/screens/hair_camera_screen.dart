import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/hair_image_picker.dart';
import '../widgets/hair_oval_guide.dart';
import '../widgets/hair_pose_coach.dart';
import '../widgets/hair_theme.dart';

/// Live camera capture for the hair feature.
///
/// Pops a [HairPickedImage] on capture, or null when cancelled.
class HairCameraScreen extends StatefulWidget {
  final String title;
  final CameraLensDirection preferredLens;

  /// Head position asked for. Drives the coach animation, the guide shape and
  /// whether capture runs on a countdown.
  final HairCapturePose pose;

  const HairCameraScreen({
    super.key,
    this.title = 'Take photo',
    this.preferredLens = CameraLensDirection.front,
    this.pose = HairCapturePose.front,
  });

  @override
  State<HairCameraScreen> createState() => _HairCameraScreenState();
}

class _HairCameraScreenState extends State<HairCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _activeIndex = 0;
  bool _initializing = true;
  bool _capturing = false;
  String? _error;

  /// Coach overlay is shown once per capture for poses that need one.
  late bool _showCoach = widget.pose.needsCoach;
  int? _countdown;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startController(_activeIndex);
    }
  }

  Future<void> _bootstrap() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _error = 'No camera found on this device.';
        });
        return;
      }

      final preferred = cameras.indexWhere(
        (c) => c.lensDirection == widget.preferredLens,
      );
      _cameras = cameras;
      await _startController(preferred >= 0 ? preferred : 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Camera unavailable. Allow camera access or use gallery.';
      });
    }
  }

  Future<void> _startController(int index) async {
    if (index < 0 || index >= _cameras.length) return;

    final previous = _controller;
    _controller = null;
    await previous?.dispose();

    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _activeIndex = index;
        _initializing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Could not start the camera. Allow access or use gallery.';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _initializing = true);
    await _startController((_activeIndex + 1) % _cameras.length);
  }

  /// Poses where the user cannot watch the screen get a countdown so they can
  /// settle into position before the shutter fires.
  void _requestCapture() {
    if (_capturing || _countdown != null) return;
    if (!widget.pose.needsCoach) {
      _capture();
      return;
    }

    setState(() => _countdown = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = (_countdown ?? 1) - 1;
      if (next <= 0) {
        timer.cancel();
        setState(() => _countdown = null);
        _capture();
      } else {
        setState(() => _countdown = next);
      }
    });
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final shot = await controller.takePicture();
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      Navigator.pop(
        context,
        HairPickedImage(
          bytes: bytes,
          fileName: shot.name.isEmpty ? 'capture.jpg' : shot.name,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = 'Capture failed. Please try again.';
      });
    }
  }

  Future<void> _pickGallery() async {
    final picked = await HairImagePickerHelper.fromGallery();
    if (!mounted) return;
    Navigator.pop(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final crownFraming = widget.pose == HairCapturePose.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Preview
          if (ready)
            HairOvalGuide(
              hint: widget.pose.hint,
              hintBottomFraction: 0.22,
              ovalCenterFraction: crownFraming ? 0.40 : 0.42,
              ovalWidthFraction: crownFraming ? 0.74 : 0.68,
              ovalHeightFraction: crownFraming ? 0.42 : 0.48,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.previewSize?.height ?? 720,
                  height: controller.value.previewSize?.width ?? 1280,
                  child: CameraPreview(controller),
                ),
              ),
            )
          else
            Center(
              child: _initializing
                  ? const CircularProgressIndicator(
                      color: HairTheme.accent,
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam_off_outlined,
                            color: Colors.white70,
                            size: 48,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _error ?? 'Camera unavailable.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lora(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: _pickGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Use gallery instead'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

          // Top bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _cameras.length > 1 ? _switchCamera : null,
                    icon: const Icon(Icons.cameraswitch_outlined),
                    color: _cameras.length > 1 ? Colors.white : Colors.white24,
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          if (ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.pose.needsCoach) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HairPoseHint(pose: widget.pose, size: 72),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Text(
                              widget.pose.instruction,
                              style: GoogleFonts.lora(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.35,
                                shadows: const [
                                  Shadow(blurRadius: 8, color: Colors.black87),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    GestureDetector(
                      onTap: (_capturing || _countdown != null)
                          ? null
                          : _requestCapture,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: _capturing
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    color: Colors.white,
                                  ),
                                )
                              : _countdown != null
                              ? Text(
                                  '$_countdown',
                                  style: GoogleFonts.lora(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: HairTheme.accent,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _pickGallery,
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        size: 18,
                      ),
                      label: const Text('Choose from gallery'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Pose walkthrough, shown once before the user starts framing.
          if (_showCoach)
            HairPoseCoach(
              pose: widget.pose,
              onDismiss: () => setState(() => _showCoach = false),
            ),
        ],
      ),
    );
  }
}
