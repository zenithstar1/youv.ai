import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'image_preview_screen.dart';
import '../widgets/web_camera_widget.dart';

class ImageCaptureScreen extends StatefulWidget {
  const ImageCaptureScreen({Key? key}) : super(key: key);

  @override
  State<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _takePhoto() async {
    if (kIsWeb) {
      // Use custom web camera widget
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebCameraWidget(
            onImageCaptured: (bytes, fileName) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ImagePreviewScreen(imageBytes: bytes, fileName: fileName),
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Use native camera for mobile
      setState(() => _isLoading = true);
      try {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
          preferredCameraDevice: CameraDevice.front,
        );

        if (photo != null) {
          final bytes = await photo.readAsBytes();
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ImagePreviewScreen(imageBytes: bytes, fileName: photo.name),
              ),
            );
          }
        }
      } catch (e) {
        print('Camera error: $e');
        if (mounted) {
          _showErrorDialog(
            'Camera Error',
            'Failed to access camera: ${e.toString()}',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _uploadFromDevice() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImagePreviewScreen(
                  imageBytes: file.bytes!,
                  fileName: file.name,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        _showErrorDialog(
          'Upload Error',
          'Failed to upload image: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B3E3E),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.lightbulb_outline, color: Color(0xFF6B3E3E)),
            SizedBox(width: 10),
            Expanded(child: Text('How to take a great shot')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kIsWeb) ...[
                const InstructionItem(
                  icon: Icons.web,
                  text: 'Allow camera access when prompted by browser',
                ),
                const SizedBox(height: 12),
              ],
              const InstructionItem(
                icon: Icons.light_mode,
                text: 'Use natural lighting or bright room light',
              ),
              const SizedBox(height: 12),
              const InstructionItem(
                icon: Icons.face,
                text: 'Face the camera directly',
              ),
              const SizedBox(height: 12),
              const InstructionItem(
                icon: Icons.center_focus_strong,
                text: 'Keep your face centered in the frame',
              ),
              const SizedBox(height: 12),
              const InstructionItem(
                icon: Icons.sentiment_neutral,
                text: 'Use a neutral expression',
              ),
              const SizedBox(height: 12),
              const InstructionItem(
                icon: Icons.clean_hands,
                text: 'Remove makeup for accurate analysis',
              ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6E8),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6B3E3E),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Loading...'),
                  ],
                ),
              )
            : Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 500 : double.infinity,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Status Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            TimeOfDay.now().format(context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: const [
                              Icon(Icons.signal_cellular_4_bar, size: 18),
                              SizedBox(width: 5),
                              Icon(Icons.wifi, size: 18),
                              SizedBox(width: 5),
                              Icon(Icons.battery_full, size: 18),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Instructions Button
                      GestureDetector(
                        onTap: _showInstructionsDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B3E3E),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 15),
                                  Text(
                                    'How to take a great\nshot',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Title
                      const Text(
                        'Select the capture option',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Take a photo button
                      _buildActionButton(
                        icon: Icons.camera_alt,
                        label: 'Take a photo',
                        onTap: _takePhoto,
                      ),

                      const SizedBox(height: 20),

                      // Upload from device button
                      _buildActionButton(
                        icon: Icons.photo_library,
                        label: 'Upload from device',
                        onTap: _uploadFromDevice,
                      ),

                      const Spacer(),

                      // Web-specific info
                      if (kIsWeb) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Click "Take a photo" to open live camera',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF6B3E3E),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InstructionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const InstructionItem({Key? key, required this.icon, required this.text})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B3E3E), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
