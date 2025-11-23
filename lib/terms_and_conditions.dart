import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  int selectedTab = 0; // 0 = Terms, 1 = Privacy

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFCE7E7),

      body: Stack(
        children: [
          // BACK ARROW (same as your other screens)
          Positioned(
            top: 60,
            left: 25,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
            ),
          ),

          // TABS ROW (responsive & centered like Figma)
Positioned(
  top: 60 + H * 0.04,
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
                fontSize: 16,
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

      SizedBox(width: W * 0.08),

      // PRIVACY TAB
      Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => selectedTab = 1),
            child: Text(
              "Privacy Policy",
              style: GoogleFonts.lora(
                fontSize: 16,
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
            top: 60 + H * 0.04 + 60, // below tab section
            bottom: 120,             // space for bottom buttons
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SingleChildScrollView(
                child: Text(
                  selectedTab == 0
                      ? "Put your Terms and Conditions text here.\n\nYou can write long content and it will scroll."
                      : "Put your Privacy Policy text here.\n\nYou can write long content and it will scroll.",
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM BUTTONS (Decline + Agree)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
  onTap: () {
    Navigator.pop(context); // returns null → checkbox stays unticked
  },
  child: Container(
    width: W * 0.32,
    height: 50,
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
          fontSize: 17,
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
    width: W * 0.42,
    height: 50,
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
          fontSize: 17,
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
