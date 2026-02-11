import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'image_capture_screen.dart';

enum AnalysisType { skin, hair }

class AnalysisTypeScreen extends StatelessWidget {
  const AnalysisTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6E8), // light pink
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                Text(
                  "Choose your analysis",
                  style: GoogleFonts.lora(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF510808),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Select what you'd like to analyze today",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 40),

                _AnalysisCard(
                  icon: Icons.face,
                  title: "Skin Analysis",
                  subtitle: "Face • Acne • Glow",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ImageCaptureScreen(),
                        // later: pass AnalysisType.skin
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                _AnalysisCard(
  icon: Icons.content_cut,
  title: "Hair Analysis",
  subtitle: "Density • Thinning • Scalp",
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ImageCaptureScreen(isHair: true),
      ),
    );
  },
),


                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AnalysisCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFD4999F),
              Color(0xFFEEC8CC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: const Color(0xFF6B3E3E),
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lora(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF510808),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Color(0xFF6B3E3E),
            ),
          ],
        ),
      ),
    );
  }
}
