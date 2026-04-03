import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/image_capture_screen.dart';
import 'screens/LoginPage.dart'; // <-- change this to your actual login file name

class CaptureOptionScreen extends StatefulWidget {
  final bool isHair;

  const CaptureOptionScreen({super.key, this.isHair = false});

  @override
  State<CaptureOptionScreen> createState() => _CaptureOptionScreenState();
}

class _CaptureOptionScreenState extends State<CaptureOptionScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTipsPopup();
    });
  }

  void _showTipsPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Tips for getting the best results",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: () {
              final tips = widget.isHair
                  ? [
                      '• Use even, diffuse lighting (avoid harsh backlight)',
                      '• Part or lift hair to expose the scalp for clearer analysis',
                      '• Remove hats, clips or accessories that hide the scalp',
                    ]
                  : ['• Ensure good lighting', '• Remove hair from face'];

              return tips
                  .map(
                    (t) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text(t), const SizedBox(height: 8)],
                    ),
                  )
                  .toList();
            }(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Got it"),
            ),
          ],
        );
      },
    );
  }

  // ===== LOGIN CHECK BEFORE CAMERA =====
  void _goToCamera() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCaptureScreen(isHair: widget.isHair),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    const cardColor = Color(0xFF6B3A3A);

    return Scaffold(
      backgroundColor: const Color(0xFFFDEDED),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: W * 0.07),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 560 : double.infinity,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: H * 0.05),

                      // Tips card
                      GestureDetector(
                        onTap: _showTipsPopup,
                        child: Container(
                          height: H * 0.09,
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: W * 0.04),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.white,
                                size: W * 0.065,
                              ),
                              SizedBox(width: W * 0.03),
                              Expanded(
                                child: Text(
                                  "Tips for getting the best results",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: W * 0.042,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: W * 0.045,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: H * 0.08),

                      Text(
                        "Start your personalized facial scan",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: W * 0.05,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: H * 0.06),

                      // OPEN CAMERA (WITH LOGIN CHECK)
                      GestureDetector(
                        onTap: _goToCamera,
                        child: _PrimaryActionButton(
                          icon: Icons.camera_alt_outlined,
                          label: "Open Camera",
                          color: cardColor,
                          W: W,
                          H: H,
                        ),
                      ),

                      SizedBox(height: H * 0.03),

                      // UPLOAD (ALSO USES CAMERA SCREEN)
                      GestureDetector(
                        onTap: _goToCamera,
                        child: _SecondaryActionButton(
                          icon: Icons.image_outlined,
                          label: "Upload from device",
                          color: cardColor,
                          W: W,
                          H: H,
                        ),
                      ),

                      SizedBox(height: H * 0.04),

                      Container(
                        padding: EdgeInsets.all(W * 0.035),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: W * 0.03),
                            Expanded(
                              child: Text(
                                widget.isHair
                                    ? '• Use even, diffuse lighting\n• Part or lift hair to expose the scalp\n• Remove hats/clips that cover the scalp'
                                    : '• Ensure good lighting\n• Remove hair from face',
                                style: GoogleFonts.poppins(
                                  fontSize: W * 0.035,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: H * 0.03),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---- UI BUTTONS (UNCHANGED) ----
class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double W;
  final double H;

  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.W,
    required this.H,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: H * 0.028),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: W * 0.07),
          SizedBox(width: W * 0.03),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: W * 0.048,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double W;
  final double H;

  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.W,
    required this.H,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: W * 0.75,
      padding: EdgeInsets.symmetric(vertical: H * 0.020),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: W * 0.06),
          SizedBox(width: W * 0.03),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: W * 0.042,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
