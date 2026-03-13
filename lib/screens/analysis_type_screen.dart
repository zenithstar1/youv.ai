import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'image_capture_screen.dart';



class AnalysisTypeScreen extends StatelessWidget {
  const AnalysisTypeScreen({super.key});

@override
Widget build(BuildContext context) {
  final W = MediaQuery.of(context).size.width;
  final H = MediaQuery.of(context).size.height;

  return Scaffold(
    backgroundColor: const Color(0xFFFDEDED),
    body: SafeArea(
      child: Column(
        children: [

          /// ================= HEADER SECTION =================
          SizedBox(height: H * 0.05),

          Center(
            child: Text(
              "AI FACIAL ANALYSIS",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: W * 0.032,
                letterSpacing: 1.5,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 18),

          /// ================= SCROLLABLE CONTENT =================
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [

                    /// HEADLINE
                    Text(
                      "Choose your focus today",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A2A22),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// SUBTEXT
                    Text(
                      "Your personalized report will be generated based on your selection.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 14.5,
                        height: 1.4,
                        color: const Color(0xFF8A7A72),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      "Both options take less than 60 seconds.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFA89B93),
                      ),
                    ),

                    SizedBox(height: H * 0.06),

                    /// SKIN CARD
                    _AnalysisCard(
                      isPrimary: true,
                      icon: Icons.face_6_outlined,
                      title: "Comprehensive Skin Analysis",
                      subtitle:
                          "Hydration • Acne • Pigmentation • Texture",
                      description:
                          "Full facial skin evaluation with detailed scoring.",
                      onTap: () {
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
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.camera_alt_outlined, color: Color(0xFF6B3E3E)),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Allow camera access when prompted',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.wb_sunny_outlined, color: Color(0xFF6B3E3E)),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Use natural lighting or bright room light',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.face, color: Color(0xFF6B3E3E)),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Face the camera directly',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.center_focus_strong, color: Color(0xFF6B3E3E)),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Keep your face centered in the frame',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.sentiment_neutral, color: Color(0xFF6B3E3E)),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Use a neutral expression',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.no_photography_outlined, color: Color(0xFF6B3E3E)),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Remove makeup for accurate analysis',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  // Open camera instantly after popup
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ImageCaptureScreen(),
                                    ),
                                  );
                                },
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
                      },
                    ),

                    const SizedBox(height: 22),

                    /// HAIR CARD
                    _AnalysisCard(
                      isPrimary: false,
                      icon: Icons.content_cut,
                      title: "Hair Health Overview",
                      statusText: "Coming Soon",
                      subtitle:
                          "Density • Thinning • Scalp",
                      description:
                          "Scalp and hair density screening.",
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hair Health Overview is coming soon.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: H * 0.08),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _AnalysisCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? statusText;
  final String subtitle;
  final String description;
  final bool isPrimary;
  final VoidCallback onTap;

  const _AnalysisCard({
    required this.icon,
    required this.title,
    this.statusText,
    required this.subtitle,
    required this.description,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<_AnalysisCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.97 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isPrimary ? 26 : 22,
            vertical: widget.isPrimary ? 28 : 22,
          ),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? const Color(0xFFFFFCF9)
                : const Color(0xFFFFFBF7),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                    widget.isPrimary ? 0.12 : 0.05),
                blurRadius: widget.isPrimary ? 26 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// ICON
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.isPrimary
                      ? const Color(0xFFEED3D6)
                      : const Color(0xFFF1ECE8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 28,
                  color: widget.isPrimary
                      ? const Color(0xFFD79096)
                      : const Color(0xFF9C8F87),
                ),
              ),

              const SizedBox(width: 18),

              /// TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.lora(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A2A22),
                        height: 1.2,
                      ),
                    ),
                    if (widget.statusText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.statusText!,
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD79096),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        color: const Color(0xFF8A7A72),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.description,
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        height: 1.45,
                        color: const Color(0xFFA89B93),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Color(0xFFB0A39A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}