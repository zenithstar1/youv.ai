import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'image_preview_screen.dart';
import 'enhanced_camera_screen.dart';
import 'standard_camera_screen.dart';
import '../widgets/web_camera_widget.dart';
import '../Bloc/auth_bloc.dart';
import '../Bloc/auth_event.dart';

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
  bool _isLoggedIn = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsDialog();
    });
  }

  Future<void> _loadUserInfo() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs?.getBool('isLogin') ?? false;
      if (_isLoggedIn) {
        final userInfoJson = prefs?.getString('userInfo');
        if (userInfoJson != null && userInfoJson.isNotEmpty) {
          final userInfo = jsonDecode(userInfoJson);
          _userName = userInfo['name'] ?? 'User';
        }
      }
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await prefs?.clear();
      if (!mounted) return;
      context.read<AuthBloc>().add(LogoutRequested());
      setState(() {
        _isLoggedIn = false;
        _userName = '';
      });
    }
  }

  Future<void> _takePhoto() async {
    // Show positioning guide first
    if (!mounted) return;
    // Directly proceed to camera — positioning overlay removed per request.
    _proceedToCamera();
  }

  Future<void> _proceedToCamera() async {
    if (kIsWeb) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebCameraWidget(
            isHair: widget.isHair,
            onImageCaptured: (bytes, fileName) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ImagePreviewScreen(
                    imageBytes: bytes,
                    fileName: fileName,
                    isHair: widget.isHair,
                  ),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    // For hair analysis, automatically use enhanced camera with auto-capture
    if (widget.isHair) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedCameraScreen(
            isHair: widget.isHair,
            onImageCaptured: (bytes, fileName) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ImagePreviewScreen(
                    imageBytes: bytes,
                    fileName: fileName,
                    isHair: widget.isHair,
                  ),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    // Skin analysis uses standard camera flow only (no auto-align mode)
    if (!mounted) return;
    
    final cameraDevice = await showDialog<CameraDevice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Camera'),
        content: const Text('Choose which camera to use:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, CameraDevice.front),
            child: const Text('Front Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, CameraDevice.rear),
            child: const Text('Back Camera'),
          ),
        ],
      ),
    );

    if (cameraDevice == null) return;

    if (!mounted) return;
    final lensDirection = cameraDevice == CameraDevice.front
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StandardCameraScreen(
          lensDirection: lensDirection,
          onImageCaptured: (bytes, fileName) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ImagePreviewScreen(
                  imageBytes: bytes,
                  fileName: fileName,
                  isHair: widget.isHair,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _uploadFromDevice() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && mounted) {
      final file = result.files.first;
      if (file.bytes != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              imageBytes: file.bytes!,
              fileName: file.name,
              isHair: widget.isHair,
            ),
          ),
        );
      }
    }
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    const Icon(Icons.lightbulb_outline, color: Color(0xFF6B3E3E)),
    const SizedBox(width: 10),

    // 👇 THIS STOPS THE 13px OVERFLOW
    const Expanded(
      child: Text(
        "How to take a great shot",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: () {
            final skinTips = [
              {'icon': Icons.camera_alt_outlined, 'text': 'Allow camera access when prompted'},
              {'icon': Icons.wb_sunny_outlined, 'text': 'Use natural lighting or bright room light'},
              {'icon': Icons.face, 'text': 'Face the camera directly'},
              {'icon': Icons.center_focus_strong, 'text': 'Keep your face centered in the frame'},
              {'icon': Icons.sentiment_neutral, 'text': 'Use a neutral expression'},
              {'icon': Icons.no_photography_outlined, 'text': 'Remove makeup for accurate analysis'},
            ];

            final hairTips = [
              {'icon': Icons.camera_alt_outlined, 'text': 'Allow camera access when prompted'},
              {'icon': Icons.wb_sunny_outlined, 'text': 'Use even, diffuse lighting (avoid harsh backlight)'},
              {'icon': Icons.content_cut, 'text': 'Part or lift hair to expose the scalp clearly'},
              {'icon': Icons.center_focus_strong, 'text': 'Keep the head centered and steady'},
              {'icon': Icons.no_photography_outlined, 'text': 'Remove hats, clips or accessories that hide the scalp'},
              {'icon': Icons.water_drop, 'text': 'Capture dry hair (avoid wet or oily hair)'} ,
            ];

            final tips = widget.isHair ? hairTips : skinTips;

            return tips
                .map((t) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TipItem(icon: t['icon'] as IconData, text: t['text'] as String),
                        const SizedBox(height: 8),
                      ],
                    ))
                .toList();
          }(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Got it!",
              style: TextStyle(
                color: Color(0xFF6B3E3E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6E8),
      appBar: _isLoggedIn
          ? AppBar(
              title: Text('Welcome, $_userName'),
              actions: [
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                )
              ],
            )
          : null,
      body: SafeArea(
        child: Center(
          child: Padding(   // ✅ FIX: removed maxWidth constraint
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: _showInstructionsDialog,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B3E3E),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const ListTile(
                        leading: Icon(
                          Icons.lightbulb_outline,
                          color: Colors.white,
                        ),
                        title: Text(
                          "How to take a great shot",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  widget.isHair
                      ? 'Start your personalized hair scan'
                      : 'Start your personalized facial scan',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 40),

                _buildPrimaryButton(
                  icon: Icons.camera_alt,
                  label: 'Open Camera',
                  onTap: _takePhoto,
                ),

                const SizedBox(height: 20),

                _buildSecondaryButton(
                  icon: Icons.photo_library,
                  label: 'Upload from device',
                  onTap: _uploadFromDevice,
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.isHair
                              ? '• Use even, diffuse lighting\n• Part or lift hair to expose the scalp\n• Remove hats/clips that cover the scalp'
                              : '• Ensure good lighting\n• Remove hair from face',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF6B3E3E),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          width: double.infinity,   // ✅ FIXED (was 300)
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF6B3E3E)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF6B3E3E)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B3E3E),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6B3E3E)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
