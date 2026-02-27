import 'dart:typed_data';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'image_preview_screen.dart';

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
  State<StandardCameraScreen> createState() =>
      _StandardCameraScreenState();
}

class _StandardCameraScreenState extends State<StandardCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;

  bool _initialized = false;
  bool _capturing = false;
  bool _initializing = false;
  bool _isDisposed = false;
  bool _hasNavigated = false;

  late CameraLensDirection _lens;

  /// =================================================
  /// INIT
  /// =================================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _lens = widget.lensDirection;
    _initCamera();
  }

  /// =================================================
  /// CAMERA INIT (SAFE VERSION)
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
    } catch (e) {
      debugPrint("Camera init error: $e");
    }

    _initializing = false;
  }

  /// =================================================
  /// APP LIFECYCLE FIX (ANDROID CAMERA BUG FIX)
  /// =================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _controller;

    if (camera == null || !camera.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      camera.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  /// =================================================
  /// CAPTURE
  /// =================================================
  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !_initialized || _capturing || !controller.value.isInitialized || _isDisposed || _hasNavigated) {
      debugPrint("Camera not ready for capture.");
      if (mounted && !_isDisposed && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera not ready. Please wait or restart app.")),
        );
      }
      return;
    }
    try {
      if (!mounted || _isDisposed || _hasNavigated) return;
      setState(() => _capturing = true);
      final pic = await controller.takePicture();
      final bytes = await pic.readAsBytes();
      if (!mounted || _isDisposed || _hasNavigated) return;
      
      _hasNavigated = true;
      
      // Navigate directly using this widget's context
      if (mounted && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(
              imageBytes: bytes,
              fileName: pic.name,
              isHair: widget.isHair,
            ),
          ),
        );
      }
      
      // Exit immediately
      return;
    } catch (e) {
      debugPrint("Capture error: $e");
      if (mounted && !_isDisposed && !_hasNavigated && context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Capture failed: ${e.toString()}")),
          );
        } catch (_) {
          // Ignore SnackBar errors
        }
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _capturing = false);
      }
    }
  }

  /// =================================================
  /// DISPOSE
  /// =================================================
  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// =================================================
  /// CAMERA PREVIEW (SAFE FULLSCREEN)
  /// =================================================
  Widget _buildCameraPreview() {
    final controller = _controller;

    if (!_initialized || controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.value.previewSize == null) {
      debugPrint("Camera previewSize is null, retrying initialization...");
      Future.microtask(() {
        if (mounted) _initCamera();
      });
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Camera error: Preview not available. Retrying...", style: TextStyle(color: Colors.red)),
          ],
        ),
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// CAMERA
          Positioned.fill(child: _buildCameraPreview()),

          /// DARK GRADIENT
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(.35),
                      Colors.transparent,
                      Colors.black.withOpacity(.35),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// HEADER
          Positioned(
            top: topPadding + 24,
            left: 0,
            right: 0,
            child: const Column(
              children: [
                Text(
                  "SKIN ANALYSIS",
                  style: TextStyle(
                    letterSpacing: 3,
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Position your face\nwithin the frame",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "serif",
                    fontSize: 26,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          /// FACE GUIDE
          const Positioned.fill(
            child: IgnorePointer(child: _FaceGuideOverlay()),
          ),

          /// STATUS PANEL
          const Align(
            alignment: Alignment(0, -0.35),
            child: _StatusPanel(),
          ),

          /// CAPTURE BUTTON
          Align(
            alignment: const Alignment(0, 0.75),
            child: Opacity(
              opacity: (_initialized && !_capturing && _controller != null && _controller!.value.isInitialized) ? 1.0 : 0.5,
              child: GestureDetector(
                onTap: (_initialized && !_capturing && _controller != null && _controller!.value.isInitialized)
                    ? _capture
                    : null,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 2),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFE7BABA),
                          Color(0xFFD79A9A),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// FOOTER TEXT
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              "Ensure neutral expression • Remove glasses • Good lighting",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// =================================================
/// STATUS PANEL
/// =================================================
class _StatusPanel extends StatelessWidget {
  const _StatusPanel();

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
  }
}

class _StatusRow extends StatelessWidget {
  final String text;
  const _StatusRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style:
                const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}

/// =================================================
/// FACE GUIDE
/// =================================================
class _FaceGuideOverlay extends StatelessWidget {
  const _FaceGuideOverlay();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.72;

    return Center(
      child: SizedBox(
        width: width,
        height: width * 0.78,
        child: CustomPaint(
          painter: _FacePainter(),
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(Offset.zero & size, paint);

    canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint);

    canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}