import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/hair_image_picker.dart';
import '../widgets/hair_oval_guide.dart';
import '../widgets/hair_theme.dart';

/// Live camera capture for the hair feature.
///
/// Pops a [HairPickedImage] on capture, or null when cancelled.
class HairCameraScreen extends StatefulWidget {
  final String title;
  final CameraLensDirection preferredLens;

  const HairCameraScreen({
    super.key,
    this.title = 'Take photo',
    this.preferredLens = CameraLensDirection.front,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ready
                  ? HairOvalGuide(
                      hint: 'Fit your head in the oval, then tap capture',
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.previewSize?.height ?? 720,
                          height: controller.value.previewSize?.width ?? 1280,
                          child: CameraPreview(controller),
                        ),
                      ),
                    )
                  : Center(
                      child: _initializing
                          ? const CircularProgressIndicator(
                              color: HairTheme.accent,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(28),
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
                                    onPressed: () async {
                                      final picked =
                                          await HairImagePickerHelper
                                              .fromGallery();
                                      if (!context.mounted) return;
                                      Navigator.pop(context, picked);
                                    },
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                    ),
                                    label: const Text('Use gallery instead'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
            ),
            Positioned(
              top: 8,
              left: 4,
              right: 4,
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
            if (ready)
              Positioned(
                left: 0,
                right: 0,
                bottom: 26,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _capturing ? null : _capture,
                      child: Container(
                        width: 78,
                        height: 78,
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
                              : Container(
                                  width: 58,
                                  height: 58,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: HairTheme.accent,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final picked =
                            await HairImagePickerHelper.fromGallery();
                        if (!context.mounted) return;
                        Navigator.pop(context, picked);
                      },
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
          ],
        ),
      ),
    );
  }
}
