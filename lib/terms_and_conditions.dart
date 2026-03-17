import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_analysis_app/utils/responsive.dart';

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  int selectedTab = 0; // 0 = Terms, 1 = Privacy

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context); // responsive helper
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;
    final topInset = MediaQuery.of(context).padding.top;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFCE7E7),

      body: Stack(
        children: [
          // BACK ARROW (same as your other screens)
          Positioned(
            top: topInset + 16,
            left: (W * 0.06).clamp(16.0, 36.0),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
            ),
          ),

          // TABS ROW (responsive & centered like Figma)
Positioned(
  top: topInset + (isTablet ? 74 : 66),
  left: 0,
  right: 0,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // TERMS TAB
      Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => selectedTab = 0),
            child: Text(
              "Terms and Conditions",
              style: GoogleFonts.lora(
                fontSize: r.sp(16), // responsive tab text
                fontWeight: selectedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: selectedTab == 0 ? W * 0.32 : 0,
            height: 2,
            color: const Color(0xFF510808),
          ),
        ],
      ),

      SizedBox(width: (W * 0.06).clamp(10.0, 40.0)),

      // PRIVACY TAB
      Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => selectedTab = 1),
            child: Text(
              "Privacy Policy",
              style: GoogleFonts.lora(
                fontSize: r.sp(16), // responsive tab text
                fontWeight: selectedTab == 1 ? FontWeight.w700 : FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: selectedTab == 1 ? W * 0.22 : 0,
            height: 2,
            color: const Color(0xFF510808),
          ),
        ],
      ),
    ],
  ),
),


          // MAIN CONTENT AREA
          Positioned.fill(
            top: topInset + (isTablet ? 170 : 156), // below tab section
            bottom: isTablet ? 140 : 128,            // space for bottom buttons
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: (W * 0.06).clamp(16.0, 36.0)),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    child: Text(
                      selectedTab == 0
                          ? "Put your Terms and Conditions text here.\n\nYou can write long content and it will scroll."
                          : "Put your Privacy Policy text here.\n\nYou can write long content and it will scroll.",
                      style: GoogleFonts.lora(
                        fontSize: r.sp(16), // responsive body text
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM BUTTONS (Decline + Agree)
          Positioned(
            bottom: (MediaQuery.of(context).padding.bottom + 18).clamp(18.0, 42.0),
            left: (W * 0.05).clamp(14.0, 32.0),
            right: (W * 0.05).clamp(14.0, 32.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: (W * 0.04).clamp(10.0, 22.0),
              runSpacing: 10,
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
  onTap: () {
    Navigator.pop(context); // returns null → checkbox stays unticked
  },
  child: Container(
    width: (W * (isTablet ? 0.24 : 0.4)).clamp(130.0, 220.0),
    height: r.h(50), // responsive button height
    decoration: BoxDecoration(
      color: const Color(0xFFD79096),
      borderRadius: BorderRadius.circular(50),
      border: Border.all(color: const Color(0xFF510808), width: 3),
      boxShadow: const [
        BoxShadow(
          color: Color(0x6B510808),
          offset: Offset(0, 12),
          blurRadius: 4,
        ),
      ],
    ),
    child: Center(
      child: Text(
        "Decline",
        style: GoogleFonts.lora(
          fontSize: r.sp(17), // responsive button text
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    ),
  ),
),


                // AGREE BUTTON
GestureDetector(
  onTap: () {
    Navigator.pop(context, true);   // sends TRUE back to SignUpScreen
  },
  child: Container(
    width: (W * (isTablet ? 0.3 : 0.5)).clamp(180.0, 300.0),
    height: r.h(50), // responsive button height
    decoration: BoxDecoration(
      color: const Color(0xFF510808),
      borderRadius: BorderRadius.circular(50),
      boxShadow: const [
        BoxShadow(
          color: Color(0x6B510808),
          offset: Offset(0, 12),
          blurRadius: 4,
        ),
      ],
    ),
    child: Center(
      child: Text(
        "Agree & Continue",
        style: GoogleFonts.lora(
          fontSize: r.sp(17), // responsive button text
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  ),
),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
