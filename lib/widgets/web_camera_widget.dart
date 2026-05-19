import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web Camera Widget - For web platform only
/// Mobile devices should use EnhancedCameraScreen instead
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
  @override
  Widget build(BuildContext context) {
    // This widget is only for web platform
    // Mobile platforms should never reach here (checked in image_capture_screen.dart)
    if (!kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text( 'Web camera is not available on mobile.\nUse EnhancedCameraScreen with real camera instead.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Web platform placeholder
    // In production, integrate with dart:html for web implementation
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }
}
