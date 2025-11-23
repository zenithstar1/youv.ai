import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CaptureOptionScreen extends StatelessWidget {
  const CaptureOptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFDEDED), // soft pink background
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: W * 0.07),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: H * 0.05),

              /// ---- Top "How to take a great shot" Card ----
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: H * 0.018,
                  horizontal: W * 0.03,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF510808),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    /// left tiny box
                    Container(
                      width: W * 0.11,
                      height: W * 0.11,
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    SizedBox(width: W * 0.04),

                    /// Main text
                    Expanded(
                      child: Text(
                        "How to take a great shot",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: W * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    /// Arrow icon
                    Icon(
                      Icons.arrow_forward_outlined,
                      color: Colors.white,
                      size: W * 0.07,
                    ),
                  ],
                ),
              ),

              SizedBox(height: H * 0.14),

              /// ---- Middle Title ----
              Text(
                "Select the capture option",
                style: GoogleFonts.poppins(
                  fontSize: W * 0.055,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: H * 0.06),

              /// ---- Take a Photo Button ----
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: H * 0.022,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF510808),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          color: Colors.white, size: W * 0.07),
                      SizedBox(width: W * 0.03),
                      Text(
                        "Take a photo",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: W * 0.05,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: H * 0.04),

              /// ---- Upload from device Button ----
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: H * 0.022,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF510808),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined,
                          color: Colors.white, size: W * 0.07),
                      SizedBox(width: W * 0.03),
                      Text(
                        "Upload from device",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: W * 0.05,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
