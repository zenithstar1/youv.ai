import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_screens.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController loginPhoneController = TextEditingController();

  @override
  void dispose() {
    loginPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RESPONSIVE VALUES
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;

    // BUTTON SIZING (hybrid scaling like onboarding)
    final btnWidth = W * 0.50;      // 50% of screen width
    final btnHeight = H * 0.065;    // 6.5% of screen height
    final btnRadius = btnWidth * 0.45;

    return Scaffold(
      backgroundColor: const Color(0xFFFCE7E7),
      body: Stack(
        children: [
          // BACK ARROW
          Positioned(
            top: H * 0.07,
            left: W * 0.06,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
            ),
          ),

          // MAIN CONTENT AREA
          Positioned.fill(
            top: H * 0.12,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: W * 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    "Welcome Back!",
                    style: GoogleFonts.lora(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: H * 0.06),

                  // LABEL
                  Text(
                    "Phone Number",
                    style: GoogleFonts.lora(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: H * 0.01),

                  // UNDERLINE INPUT FIELD
                  Container(
                    padding: const EdgeInsets.only(bottom: 4),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "+91 - ",
                          style: GoogleFonts.lora(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: loginPhoneController,
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              counterText: "",
                              isCollapsed: true,
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.lora(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: H * 0.08),

                  // LOGIN BUTTON
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (loginPhoneController.text.length != 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Please enter a valid 10-digit phone number",
                                style: GoogleFonts.lora(),
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OtpScreen(
                              phoneNumber: "+91${loginPhoneController.text}",
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: btnWidth,
                        height: btnHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD79096),
                          borderRadius: BorderRadius.circular(btnRadius),
                          border: Border.all(color: const Color(0xFF510808), width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x6B510808),
                              offset: Offset(0, 14),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Log In",
                            style: GoogleFonts.lora(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: H * 0.04),

                  // OR
                  Center(
                    child: Text(
                      "or",
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  SizedBox(height: H * 0.03),

                  // CONTINUE WITH GOOGLE BUTTON
                  Center(
                    child: Container(
                      width: 286,
                      height: 53,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD79096),
                        borderRadius: BorderRadius.circular(158),
                        border: Border.all(color: const Color(0xFF510808), width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x6B510808),
                            offset: Offset(0, 14),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              "assets/images/google_chat.png",
                              height: 30,
                              width: 30,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Continue with Google",
                            style: GoogleFonts.lora(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: H * 0.05),

                  // SIGN UP LINK
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SignUpScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign Up!",
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF510808),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: H * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

