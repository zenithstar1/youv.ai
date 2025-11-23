import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebCameraWidget extends StatefulWidget {
  final Function(Uint8List, String) onImageCaptured;

  const WebCameraWidget({Key? key, required this.onImageCaptured})
    : super(key: key);

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
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    print('Starting camera initialization...');

    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      print('MediaDevices available: ${mediaDevices != null}');

      if (mediaDevices == null) {
        setState(() {
          _error =
              'Camera not supported in this browser.\n\nPlease use Chrome, Firefox, or Edge.';
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

      print('Requesting camera access...');

      _stream = await mediaDevices
          .getUserMedia(constraints)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Camera access timeout. Please grant camera permissions.',
              );
            },
          );

      print('Camera stream obtained: ${_stream != null}');

      if (_stream == null) {
        throw Exception('Failed to get camera stream');
      }

      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..srcObject = _stream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)';

      print('Video element created');

      await _videoElement!.onLoadedMetadata.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Video metadata loading timeout');
        },
      );

      print('Video metadata loaded');

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _videoElement!,
      );

      print('View factory registered');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isCameraActive = true;
          _isLoading = false;
        });
        print('Camera active!');
      }
    } catch (e) {
      print('Camera initialization error: $e');

      String errorMessage = 'Failed to access camera: ';

      if (e.toString().contains('NotAllowedError') ||
          e.toString().contains('Permission denied')) {
        errorMessage +=
            '\n\nCamera permission denied.\nPlease allow camera access and refresh.';
      } else if (e.toString().contains('NotFoundError')) {
        errorMessage += '\n\nNo camera found.\nPlease connect a camera.';
      } else if (e.toString().contains('NotReadableError')) {
        errorMessage +=
            '\n\nCamera is already in use.\nPlease close other apps using the camera.';
      } else if (e.toString().contains('timeout')) {
        errorMessage += '\n\n$e';
      } else {
        errorMessage += '\n\n${e.toString()}';
      }

      if (mounted) {
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _captureImage() async {
    if (_videoElement == null || !_isCameraActive) {
      print('Cannot capture: camera not active');
      return;
    }

    try {
      print('Capturing image...');
      print(
        'Video dimensions: ${_videoElement!.videoWidth} x ${_videoElement!.videoHeight}',
      );

      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );

      if (canvas.width == 0 || canvas.height == 0) {
        throw Exception('Invalid video dimensions');
      }

      final context = canvas.context2D;

      context.translate(canvas.width!, 0);
      context.scale(-1, 1);
      context.drawImageScaled(
        _videoElement!,
        0,
        0,
        canvas.width!,
        canvas.height!,
      );

      final dataUrl = canvas.toDataUrl('image/jpeg', 0.95);
      print('Data URL created');

      final base64 = dataUrl.split(',')[1];
      final bytes = base64Decode(base64);
      final fileName = 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('Image captured: ${bytes.length} bytes');

      _stopCamera();

      widget.onImageCaptured(bytes, fileName);
    } catch (e) {
      print('Capture error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to capture image: ${e.toString()}';
        });
      }
    }
  }

  void _stopCamera() {
    print('Stopping camera...');
    if (_stream != null) {
      final tracks = _stream!.getTracks();
      print('Stopping ${tracks.length} tracks');
      for (var track in tracks) {
        track.stop();
      }
      _stream = null;
    }
    if (mounted) {
      setState(() {
        _isCameraActive = false;
      });
    }
  }

  @override
  void dispose() {
    print('Disposing camera widget');
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _isLoading = true;
                          });
                          _initializeCamera();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4999F),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoading || !_isCameraActive) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFFD4999F),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Initializing camera...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please allow camera access if prompted',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview - Full screen
          Positioned.fill(child: HtmlElementView(viewType: _viewType)),

          // Oval face guide overlay with pointer events disabled
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: FaceOvalPainter()),
            ),
          ),

          // Top instruction bar
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
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  ),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.face, color: Colors.white, size: 28),
                    SizedBox(height: 8),
                    Text(
                      'Align your face within the oval',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Make sure your face is well lit',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.only(bottom: 30, top: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          _stopCamera();
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close,
                          size: 28,
                          color: Colors.white,
                        ),
                        iconSize: 28,
                      ),
                    ),

                    // Capture button
                    GestureDetector(
                      onTap: _captureImage,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Tips button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          _showTipsDialog(context);
                        },
                        icon: const Icon(
                          Icons.info_outline,
                          size: 26,
                          color: Colors.white,
                        ),
                        iconSize: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.tips_and_updates, color: Color(0xFF6B3E3E)),
            SizedBox(width: 10),
            Text('Camera Tips'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            TipItem(
              icon: Icons.face,
              text: 'Center your face in the oval guide',
            ),
            SizedBox(height: 12),
            TipItem(
              icon: Icons.light_mode,
              text: 'Use good lighting (face the light)',
            ),
            SizedBox(height: 12),
            TipItem(
              icon: Icons.remove_red_eye,
              text: 'Look directly at the camera',
            ),
            SizedBox(height: 12),
            TipItem(
              icon: Icons.sentiment_neutral,
              text: 'Keep a neutral expression',
            ),
            SizedBox(height: 12),
            TipItem(
              icon: Icons.clean_hands,
              text: 'Remove glasses for better analysis',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B3E3E),
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the oval face guide with TRANSPARENT background
class FaceOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent dark overlay paint
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Calculate oval dimensions
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final ovalWidth = size.width * 0.75;
    final ovalHeight = size.height * 0.55;

    // Create oval rect
    final ovalRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: ovalWidth,
      height: ovalHeight,
    );

    // Create paths
    final fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final ovalPath = Path()..addOval(ovalRect);

    // Draw overlay with oval cutout (transparent in the middle)
    final cutoutPath = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      ovalPath,
    );

    canvas.drawPath(cutoutPath, overlayPaint);

    // Draw oval border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawOval(ovalRect, borderPaint);

    // Draw corner guides
    final cornerPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final cornerLength = 25.0;

    // Top-left corner
    canvas.drawLine(
      Offset(ovalRect.left - 10, ovalRect.top + cornerLength),
      Offset(ovalRect.left - 10, ovalRect.top - 10),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.left - 10, ovalRect.top - 10),
      Offset(ovalRect.left + cornerLength, ovalRect.top - 10),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(ovalRect.right - cornerLength, ovalRect.top - 10),
      Offset(ovalRect.right + 10, ovalRect.top - 10),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.right + 10, ovalRect.top - 10),
      Offset(ovalRect.right + 10, ovalRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(ovalRect.left - 10, ovalRect.bottom - cornerLength),
      Offset(ovalRect.left - 10, ovalRect.bottom + 10),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.left - 10, ovalRect.bottom + 10),
      Offset(ovalRect.left + cornerLength, ovalRect.bottom + 10),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(ovalRect.right - cornerLength, ovalRect.bottom + 10),
      Offset(ovalRect.right + 10, ovalRect.bottom + 10),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.right + 10, ovalRect.bottom + 10),
      Offset(ovalRect.right + 10, ovalRect.bottom - cornerLength),
      cornerPaint,
    );

    // Draw center dot for alignment
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), 3, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tip item widget for dialog
class TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const TipItem({Key? key, required this.icon, required this.text})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B3E3E), size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
