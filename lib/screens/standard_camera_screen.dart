import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class StandardCameraScreen extends StatefulWidget {
  final CameraLensDirection lensDirection;
  final Function(Uint8List imageBytes, String fileName) onImageCaptured;

  const StandardCameraScreen({
    super.key,
    required this.lensDirection,
    required this.onImageCaptured,
  });

  @override
  State<StandardCameraScreen> createState() => _StandardCameraScreenState();
}

class _StandardCameraScreenState extends State<StandardCameraScreen> {
  List<CameraDescription> _availableCameras = [];
  CameraController? _cameraController;
  late CameraLensDirection _currentLensDirection;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _currentLensDirection = widget.lensDirection;
    _initializeCamera();
  }

  Future<void> _initializeCamera({CameraLensDirection? lensDirection}) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final targetLens = lensDirection ?? _currentLensDirection;
      final selectedCamera = _availableCameras.firstWhere(
        (camera) => camera.lensDirection == targetLens,
        orElse: () => _availableCameras.first,
      );

      _currentLensDirection = selectedCamera.lensDirection;

      if (_cameraController != null) {
        await _cameraController!.dispose();
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _switchCamera() async {
    if (_isInitializing || _isCapturing || _availableCameras.length < 2) {
      return;
    }

    final nextLens =
        _currentLensDirection == CameraLensDirection.front
            ? CameraLensDirection.back
            : CameraLensDirection.front;

    setState(() {
      _isInitialized = false;
    });
    await _initializeCamera(lensDirection: nextLens);
  }

  Future<void> _captureImage() async {
    if (_isCapturing || _cameraController == null) return;
    if (!_cameraController!.value.isInitialized) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final picture = await _cameraController!.takePicture();
      final bytes = await picture.readAsBytes();
      widget.onImageCaptured(bytes, picture.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Capture failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _isInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: _FaceGuideOverlay(),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                onPressed: _isInitialized && !_isCapturing ? _switchCamera : null,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  onPressed: _isInitialized && !_isCapturing
                      ? _captureImage
                      : null,
                  child: _isCapturing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceGuideOverlay extends StatelessWidget {
  const _FaceGuideOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final guideWidth = constraints.maxWidth * 0.64;
        final guideHeight = guideWidth * 1.25;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: constraints.maxHeight * 0.14,
              left: 0,
              right: 0,
              child: const Text(
                'Center your face in the circle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: guideWidth,
              height: guideHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(guideWidth),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
