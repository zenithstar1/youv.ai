import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'start_journey_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  List<String> otp = ["", "", "", "", "", ""];
  int timer = 30;
  bool expired = false;
  late Timer countdown;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timer == 0) {
        setState(() => expired = true);
        t.cancel();
      } else {
        setState(() => timer--);
      }
    });
  }

  @override
  void dispose() {
    countdown.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFCE7E7),
      body: Stack(
        children: [
          // Back arrow
          Positioned(
            top: 60,
            left: 25,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
            ),
          ),

          // Main content
          Positioned.fill(
            top: 120,
            child: Column(
              children: [
                Text(
                  "Verify Code",
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Enter the 6-digit code sent to your number",
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 40),

                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 45,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black54),
                      ),
                      child: TextField(
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: const InputDecoration(
                          counterText: "",
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.lora(fontSize: 22),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            otp[i] = value;
                            if (i < 5) FocusScope.of(context).nextFocus();
                          } else {
                            otp[i] = "";
                            if (i > 0) FocusScope.of(context).previousFocus();
                          }
                          setState(() {});
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 10),

                Text(
                  expired ? "Expired" : "00:${timer.toString().padLeft(2, '0')}",
                  style: GoogleFonts.lora(fontSize: 14),
                ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive OTP? ",
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: expired
                          ? () {
                              setState(() {
                                timer = 30;
                                expired = false;
                              });
                              startTimer();
                            }
                          : null,
                      child: Text(
                        "Resend code",
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // VERIFY BUTTON (UPDATED LOGIC ONLY)
                GestureDetector(
                  onTap: () {
                    if (expired) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade900,
                          content: Text(
                            "This code has expired. Please request a new one",
                            style: GoogleFonts.lora(),
                          ),
                        ),
                      );
                      return;
                    }

                    // Require 6 digits (ANY OTP accepted)
                    if (otp.join().length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red.shade900,
                          content: Text(
                            "Please enter the 6-digit OTP",
                            style: GoogleFonts.lora(),
                          ),
                        ),
                      );
                      return;
                    }

                    // SUCCESS → Navigate to Start Journey screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StartJourneyScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: W * 0.42,
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
                        "Verify",
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
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
