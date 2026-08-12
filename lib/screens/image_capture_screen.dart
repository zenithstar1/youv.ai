import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'image_preview_screen.dart';
import 'standard_camera_screen.dart';
// ...existing code...

class ImageCaptureScreen extends StatefulWidget {
  final bool isHair;

  const ImageCaptureScreen({
    super.key,
    this.isHair = false,
  });

  @override
  State<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  SharedPreferences? prefs;

  bool _instructionsShown = false;
  bool _navigated = false;

  bool _isLoggedIn = false;
  String _userName = '';

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserInfo();

    if (!mounted) return;

    /// wait until first frame renders
  WidgetsBinding.instance.addPostFrameCallback((_) {
  if (_navigated) return;

  if (widget.isHair) {
    _instructionsShown = true;
    _showInstructionsDialog();
  } else {
    _takePhoto(); // open camera immediately for face
  }
});
  }

  // ================= USER =================

  Future<void> _loadUserInfo() async {
    prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = prefs?.getBool('isLogin') ?? false;
      if (_isLoggedIn) {
        final json = prefs?.getString('userInfo');
        if (json != null) {
          _userName = jsonDecode(json)['name'] ?? 'User';
        }
      }
    });
  }

  // ================= CAMERA FLOW =================

  Future<void> _takePhoto() async {
    if (!mounted || _navigated) return;

    setState(() => _navigated = true);

    /// prevents white overlay
    await Future.delayed(const Duration(milliseconds: 60));

    if (!mounted) return;
    _proceedToCamera();
  }

  Future<void> _proceedToCamera() async {
    // Hair uses upload only — no camera page.
    if (widget.isHair) {
      setState(() => _navigated = false);
      await _uploadFromDevice();
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StandardCameraScreen(
          lensDirection: CameraLensDirection.front,
          isHair: widget.isHair, // Pass isHair for navigation
        ),
      ),
    );
  }

  // ================= UPLOAD =================

  Future<void> _uploadFromDevice() async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && mounted) {
      final file = result.files.first;

      if (file.bytes != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(
              imageBytes: file.bytes!,
              fileName: file.name,
              isHair: widget.isHair,
            ),
          ),
        );
      }
    }
  }

  // ================= INSTRUCTIONS =================

  void _showInstructionsDialog() {
    /// prevents duplicate dialogs
    if (!mounted ||
        _navigated ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Color(0xFF6B3E3E)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "How to take a great shot",
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.isHair
              ? const [
                  _TipItem(icon: Icons.wb_sunny_outlined, text: 'Use even lighting'),
                  _TipItem(icon: Icons.content_cut, text: 'Expose scalp clearly'),
                  _TipItem(icon: Icons.center_focus_strong, text: 'Keep head centered'),
                  _TipItem(icon: Icons.water_drop, text: 'Hair should be dry'),
                ]
              : const [
                  _TipItem(icon: Icons.face, text: 'Face camera directly'),
                  _TipItem(icon: Icons.wb_sunny_outlined, text: 'Use bright lighting'),
                  _TipItem(icon: Icons.sentiment_neutral, text: 'Neutral expression'),
                  _TipItem(icon: Icons.no_photography_outlined, text: 'Remove makeup'),
                ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.isHair) {
                _uploadFromDevice();
              } else {
                _takePhoto();
              }
            },
            child: const Text(
              "Got it!",
              style: TextStyle(
                  color: Color(0xFF6B3E3E),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI =================

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: _navigated ? Colors.black : const Color(0xFFF5E6E8),
    body: _buildBody(),
  );
}

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          Icon(
            widget.isHair ? Icons.content_cut : Icons.face,
            size: 80,
            color: const Color(0xFF6B3E3E),
          ),

          const SizedBox(height: 20),

          Text(
            widget.isHair
                ? "Upload Hair Image"
                : "Capture Face Image",
            style: GoogleFonts.lora(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A2A22),
            ),
          ),

          const SizedBox(height: 40),

          if (!widget.isHair) ...[
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Photo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B3E3E),
                minimumSize: const Size(double.infinity, 55),
              ),
            ),
            const SizedBox(height: 16),
          ],

          OutlinedButton.icon(
            onPressed: _uploadFromDevice,
            icon: const Icon(Icons.upload),
            label: const Text("Upload from Device"),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: const Color(0xFF6B3E3E),
              side: const BorderSide(color: Color(0xFF6B3E3E)),
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B3E3E)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}