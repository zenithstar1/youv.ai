import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebCameraWidget extends StatefulWidget {
  final Function(Uint8List, String) onImageCaptured;
  final bool isHair;

  const WebCameraWidget({
    super.key,
    required this.onImageCaptured,
    this.isHair = false,
  });

  @override
  State<WebCameraWidget> createState() => _WebCameraWidgetState();
}

class _WebCameraWidgetState extends State<WebCameraWidget> {
  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  bool _isCameraActive = false;
  bool _isLoading = true;
  String? _error;
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'camera-video-${DateTime.now().millisecondsSinceEpoch}';
    _detectIOS();
    _initializeCamera();
  }

  void _detectIOS() {
    // iOS detection is not currently used
  }

  Future<void> _initializeCamera() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        setState(() {
          _error =
              'Camera not supported.\nPlease use Chrome, Safari, or Firefox.';
          _isLoading = false;
        });
        return;
      }

      final constraints = {
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      };

      _stream = await mediaDevices.getUserMedia(constraints);

      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..srcObject = _stream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)';

      await _videoElement!.onLoadedMetadata.first;
      await _videoElement!.play();

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _videoElement!,
      );

      if (mounted) {
        setState(() {
          _isCameraActive = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _captureImage() async {
    if (_videoElement == null) return;

    final width = _videoElement!.videoWidth;
    final height = _videoElement!.videoHeight;

    final canvas = html.CanvasElement(width: width, height: height);
    final ctx = canvas.context2D;

    ctx.translate(width, 0);
    ctx.scale(-1, 1);
    ctx.drawImageScaled(_videoElement!, 0, 0, width, height);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.95);
    final bytes = Uri.parse(dataUrl).data!.contentAsBytes();

    _stopCamera();
    widget.onImageCaptured(
      bytes,
      'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  void _stopCamera() {
    _stream?.getTracks().forEach((t) => t.stop());
    _videoElement?.pause();
    _videoElement?.srcObject = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    if (_isLoading || !_isCameraActive) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4999F)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: HtmlElementView(viewType: _viewType),
          ),

          // ✅ OVAL OVERLAY (HAIR vs SKIN)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: widget.isHair
                    ? HairOvalPainter()
                    : FaceOvalPainter(),
              ),
            ),
          ),

          // TOP INSTRUCTION BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      widget.isHair ? Icons.content_cut : Icons.face,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isHair
                          ? 'Align your scalp within the oval'
                          : 'Align your face within the oval',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wb_sunny,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          widget.isHair
                              ? 'Ensure scalp and roots are clearly visible'
                              : 'Ensure good lighting for best results',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline,
                      color: Colors.white, size: 26),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= FACE OVAL =================
class FaceOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, paint);

    final ovalRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.75,
      height: size.height * 0.55,
    );

    final cutout = Path()
      ..addRect(Offset.zero & size)
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(cutout, paint);

    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ================= HAIR OVAL =================
class HairOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, paint);

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.85,
      height: size.height * 0.35,
    );

    final cutout = Path()
      ..addRect(Offset.zero & size)
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(cutout, paint);

    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
