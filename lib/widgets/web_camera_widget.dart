import 'dart:typed_data';
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
  bool _isIOS = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'camera-video-${DateTime.now().millisecondsSinceEpoch}';
    _detectIOS();
    _initializeCamera();
  }

  void _detectIOS() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    _isIOS =
        userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
    print('Is iOS device: $_isIOS');
  }

  Future<void> _initializeCamera() async {
    print('Starting camera initialization...');

    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      print('MediaDevices available: ${mediaDevices != null}');

      if (mediaDevices == null) {
        setState(() {
          _error =
              'Camera not supported in this browser.\n\nPlease use Safari, Chrome, or Firefox.';
          _isLoading = false;
        });
        return;
      }

      // Enhanced constraints for better quality and exposure
      final constraints = _isIOS
          ? {
              'video': {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
                'aspectRatio': 1.777777778,
                'frameRate': {'ideal': 30},
              },
              'audio': false,
            }
          : {
              'video': {
                'facingMode': 'user',
                'width': {'ideal': 1920, 'min': 640},
                'height': {'ideal': 1080, 'min': 480},
                'aspectRatio': 1.777777778,
                'frameRate': {'ideal': 30, 'min': 24},
              },
              'audio': false,
            };

      print('Requesting camera access with enhanced constraints...');

      try {
        _stream = await mediaDevices.getUserMedia(constraints);
      } catch (e) {
        print('Failed with enhanced constraints, trying basic...');
        // Fallback to simpler constraints
        _stream = await mediaDevices.getUserMedia({
          'video': {
            'facingMode': 'user',
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
          },
          'audio': false,
        });
      }

      print('Camera stream obtained: ${_stream != null}');

      if (_stream == null) {
        throw Exception('Failed to get camera stream');
      }

      // Create video element with enhanced settings
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..setAttribute('webkit-playsinline', 'true')
        ..srcObject = _stream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)'
        ..style.filter =
            'brightness(1.1) contrast(1.05)' // Slight enhancement
        ..style.backgroundColor = '#000000';

      print('Video element created with enhanced settings');

      // Wait for metadata to load
      await _videoElement!.onLoadedMetadata.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Video metadata loading timeout');
        },
      );

      print('Video metadata loaded');

      // Explicitly start video playback
      try {
        await _videoElement!.play();
        print('Video play() called successfully');
      } catch (e) {
        print('Video play() error (may be normal): $e');
      }

      // Register view factory
      try {
        ui_web.platformViewRegistry.registerViewFactory(
          _viewType,
          (int viewId) => _videoElement!,
        );
        print('View factory registered');
      } catch (e) {
        print('View factory registration error: $e');
      }

      // Give camera extra time to adjust exposure and white balance
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        setState(() {
          _isCameraActive = true;
          _isLoading = false;
        });
        print('Camera active with enhanced settings!');
      }
    } catch (e) {
      print('Camera initialization error: $e');

      String errorMessage = 'Failed to access camera:\n\n';

      if (e.toString().contains('NotAllowedError') ||
          e.toString().contains('Permission denied')) {
        errorMessage += 'Camera permission denied.\n\n';
        if (_isIOS) {
          errorMessage += 'On iOS:\n';
          errorMessage += '1. Go to Settings > Safari > Camera\n';
          errorMessage += '2. Select "Allow"\n';
          errorMessage += '3. Refresh this page';
        } else {
          errorMessage += 'Please allow camera access and refresh.';
        }
      } else if (e.toString().contains('NotFoundError')) {
        errorMessage +=
            'No camera found.\nPlease ensure your device has a working camera.';
      } else if (e.toString().contains('NotReadableError')) {
        errorMessage +=
            'Camera is already in use.\nPlease close other apps using the camera.';
      } else if (e.toString().contains('OverconstrainedError')) {
        errorMessage +=
            'Camera settings not supported.\nRetrying with basic settings...';
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _initializeCamera();
        }
        return;
      } else {
        errorMessage += e.toString();
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

      // Give camera a moment to ensure best exposure
      await Future.delayed(const Duration(milliseconds: 200));

      print(
        'Video dimensions: ${_videoElement!.videoWidth} x ${_videoElement!.videoHeight}',
      );

      final width = _videoElement!.videoWidth;
      final height = _videoElement!.videoHeight;

      if (width == 0 || height == 0) {
        throw Exception('Video not ready. Please wait a moment and try again.');
      }

      final canvas = html.CanvasElement(width: width, height: height);

      final context = canvas.context2D;

      // Apply slight brightness/contrast enhancement during capture
      context.filter = 'brightness(1.05) contrast(1.03)';

      // Mirror the image
      context.translate(canvas.width!, 0);
      context.scale(-1, 1);
      context.drawImageScaled(
        _videoElement!,
        0,
        0,
        canvas.width!,
        canvas.height!,
      );

      // Convert to high-quality JPEG
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.95);
      print('Data URL created, length: ${dataUrl.length}');

      final base64 = dataUrl.split(',')[1];

      final bytes = Uint8List.fromList(
        Uri.parse('data:image/jpeg;base64,$base64').data!.contentAsBytes(),
      );

      final fileName = 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('Image captured: ${bytes.length} bytes');

      _stopCamera();

      widget.onImageCaptured(bytes, fileName);
    } catch (e) {
      print('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
    if (_videoElement != null) {
      _videoElement!.pause();
      _videoElement!.srcObject = null;
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
                    style: const TextStyle(color: Colors.white, fontSize: 14),
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
                Text(
                  _isIOS
                      ? 'Please allow camera access in Safari settings'
                      : 'Camera is warming up for best quality',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
          // Camera preview with enhanced visibility
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: HtmlElementView(viewType: _viewType),
            ),
          ),

          // Oval face guide overlay
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
                  children: [
                    const Icon(Icons.face, color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    const Text(
                      'Align your face within the oval',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.wb_sunny, color: Colors.white70, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Ensure good lighting for best results',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                          textAlign: TextAlign.center,
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
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
          children: [
            const TipItem(
              icon: Icons.wb_sunny,
              text: 'Face a window or bright light source',
            ),
            const SizedBox(height: 12),
            const TipItem(
              icon: Icons.lightbulb,
              text: 'Turn on room lights for better visibility',
            ),
            const SizedBox(height: 12),
            const TipItem(
              icon: Icons.face,
              text: 'Center your face in the oval guide',
            ),
            const SizedBox(height: 12),
            const TipItem(
              icon: Icons.remove_red_eye,
              text: 'Look directly at the camera',
            ),
            const SizedBox(height: 12),
            const TipItem(
              icon: Icons.sentiment_neutral,
              text: 'Keep a neutral expression',
            ),
            const SizedBox(height: 12),
            const TipItem(
              icon: Icons.clean_hands,
              text: 'Remove glasses for better analysis',
            ),
            if (_isIOS) ...[
              const SizedBox(height: 12),
              const TipItem(
                icon: Icons.settings,
                text: 'Enable camera in Settings > Safari',
              ),
            ],
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

class FaceOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final ovalWidth = size.width * 0.75;
    final ovalHeight = size.height * 0.55;

    final ovalRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: ovalWidth,
      height: ovalHeight,
    );

    final ovalPath = Path()..addOval(ovalRect);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        ovalPath,
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawOval(ovalRect, borderPaint);

    final cornerPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final cornerLength = 25.0;

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

    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), 3, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
