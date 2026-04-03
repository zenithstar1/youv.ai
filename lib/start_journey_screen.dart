import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'capture_option_screen.dart';

class StartJourneyScreen extends StatelessWidget {
  const StartJourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortestSide >= 600;
    final frameWidth = isTablet ? (W * 0.62).clamp(380.0, 560.0) : W;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: Container(
            width: frameWidth,
            height: H,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              image: const DecorationImage(
                image: AssetImage("assets/images/lady.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Stack(
                children: [
                  /// ---- HEADLINE in same visual position ----
                  Positioned(
                    left: frameWidth * 0.10,
                    top: H * 0.46,
                    child: SizedBox(
                      width: frameWidth * 0.75,
                      child: Text(
                        "Start Your\nJourney to\nHealthy Skin",
                        style: GoogleFonts.poppins(
                          fontSize:
                              frameWidth * 0.095, // same scale as screenshot
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  /// ---- CHECK NOW BUTTON (exact same placement) ----
                  Positioned(
                    top: H * 0.76,
                    left: (frameWidth - (frameWidth * 0.63)) / 2,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CaptureOptionScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: frameWidth * 0.63,
                        height: H * 0.085,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBC826E),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: const Color(0xFF523637),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF523637),
                              offset: Offset(0, 10),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Check Now",
                            style: GoogleFonts.lora(
                              fontSize: frameWidth * 0.07,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// ---- PRIVACY ROW (same visual spot) ----
                  Positioned(
                    bottom: H * 0.085,
                    left: frameWidth * 0.09,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.privacy_tip_outlined,
                          color: Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Your Privacy Choices",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: frameWidth * 0.035,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 25),
                        Text(
                          "Notice at Collection",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: frameWidth * 0.035,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ---- POWERED BY ----
                  Positioned(
                    bottom: H * 0.03,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        "Powered By YOUV.AI",
                        style: GoogleFonts.poppins(
                          fontSize: frameWidth * 0.04,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
