import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web Camera Widget - Only used on web platform
/// On mobile platforms, this returns a placeholder
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
    // This widget should only be built on web (guarded in image_capture_screen)
    // On mobile, show placeholder
    if (!kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Web camera widget should not appear on mobile',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // On web, this would be replaced with actual implementation
    // using dart:html and platform channels
    return const Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Web version would load here',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
