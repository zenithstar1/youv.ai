import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terms_and_conditions.dart';
import 'package:flutter/gestures.dart';
import 'otp_screen.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final ValueNotifier<bool> agreeTerms = ValueNotifier(false);

  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE7E7),
      body: Stack(
        children: [
          // BACK ARROW
          Positioned(
            top: 60,
            left: 25,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
            ),
          ),

          // MAIN CONTENT
          Positioned.fill(
            top: 120,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    "Create Account",
                    style: GoogleFonts.lora(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // NAME LABEL
                  Text(
                    "Name",
                    style: GoogleFonts.lora(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildUnderlineField(),

                  const SizedBox(height: 35),

                  // AGE
                  Text(
                    "Age",
                    style: GoogleFonts.lora(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildUnderlineField(),

                  const SizedBox(height: 35),

                  // PHONE NUMBER
                  Text(
                    "Phone Number",
                    style: GoogleFonts.lora(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: phoneController, // <-- controller added
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              counterText: "",
                            ),
                            style: GoogleFonts.lora(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  // TERMS CHECKBOX
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: agreeTerms,
                        builder: (context, value, _) {
                          return GestureDetector(
                            onTap: () => agreeTerms.value = !value,
                            child: Container(
                              width: 29,
                              height: 27,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFD79096),
                                  width: 2,
                                ),
                                color: Colors.transparent,
                              ),
                              child: value
                                  ? const Icon(Icons.check,
                                      size: 18, color: Colors.black)
                                  : null,
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: "I agree with the ",
                            style: GoogleFonts.lora(
                                fontSize: 15, color: Colors.black),
                            children: [
                              TextSpan(
                                text: "Terms and Conditions",
                                style: GoogleFonts.lora(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1976D2),
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    final agreed = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TermsAndConditionsPage(),
                                      ),
                                    );
                                    if (agreed == true) {
                                      agreeTerms.value = true;
                                    }
                                    else {
  // User declined OR tapped back
  agreeTerms.value = false;
}
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 45),

                  // SIGN UP BUTTON
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // VALIDATE TERMS
                        if (!agreeTerms.value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Please agree to the Terms & Conditions",
                                style: GoogleFonts.lora(),
                              ),
                            ),
                          );
                          return;
                        }

                        // VALIDATE PHONE NUMBER
                        if (phoneController.text.length != 10) {
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

                        // NAVIGATE TO OTP SCREEN
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OtpScreen(
                              phoneNumber: "+91${phoneController.text}",
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 286,
                        height: 53,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD79096),
                          borderRadius: BorderRadius.circular(158),
                          border: Border.all(
                              color: const Color(0xFF510808), width: 3),
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
                            "Sign Up",
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

                  const SizedBox(height: 25),

                  // OR
                  Center(
                    child: Text(
                      "or",
                      style: GoogleFonts.lora(
                          fontSize: 16, color: Colors.black87),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // CONTINUE WITH GOOGLE BUTTON
                  Center(
                    child: Container(
                      width: 286,
                      height: 53,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD79096),
                        borderRadius: BorderRadius.circular(158),
                        border: Border.all(
                            color: const Color(0xFF510808), width: 3),
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

                  const SizedBox(height: 25),

                  // Already have account
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: "Log In!",
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF510808),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable underline field
  Widget buildUnderlineField() {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      child: TextField(
        style: GoogleFonts.lora(fontSize: 18),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
