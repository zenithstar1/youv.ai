import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'LoginPage.dart';
import 'analysis_type_screen.dart';

class AlreadyLoginScreen extends StatefulWidget {
  const AlreadyLoginScreen({super.key});

  @override
  State<AlreadyLoginScreen> createState() => _AlreadyLoginScreenState();
}

class _AlreadyLoginScreenState extends State<AlreadyLoginScreen> {
  final TextEditingController _mobileController =
      TextEditingController(text: "+91 ");
  final TextEditingController _otpController = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;
  String _error = '';

  /// rebuild UI while typing
  @override
  void initState() {
    super.initState();
    _mobileController.addListener(() {
      setState(() {});
    });
  }

  /// validation getter (single source of truth)
  bool get allFilled {
    final digits =
        _mobileController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10;
  }

  /// send OTP
  void _sendOtp() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _otpSent = true;
      _loading = false;
    });
  }

  /// verify OTP
  void _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    await Future.delayed(const Duration(seconds: 1));

    if (_otpController.text == "123456") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AnalysisTypeScreen(),
        ),
      );
    } else {
      setState(() {
        _error = "Invalid OTP";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFDEDED),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              /// ================= HEADER =================
              SizedBox(height: H * 0.06),

              Text(
                "AI FACIAL ANALYSIS",
                style: GoogleFonts.poppins(
                  fontSize: W * 0.032,
                  letterSpacing: 1.5,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: H * 0.012),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: W * 0.08),
                child: Text(
                  "Log in to Your Analysis Profile",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: W * 0.055,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),

              SizedBox(height: H * 0.015),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: W * 0.10),
                child: Text(
                  "Verify your number to access your saved profile and continue your scan.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: W * 0.035,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              SizedBox(height: H * 0.035),

              /// ================= IMAGE =================
              Padding(
                padding: EdgeInsets.symmetric(horizontal: W * 0.12),
                child: Image.asset(
                  "assets/images/face_outline.png",
                  height: H * 0.22,
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: H * 0.045),

              /// ================= FORM CARD =================
              Center(
                child: Container(
                  width: W * 0.9,
                  padding: EdgeInsets.symmetric(
                    vertical: H * 0.06,
                    horizontal: W * 0.06,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      /// MOBILE LABEL
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Mobile Number",
                          style: GoogleFonts.poppins(
                            fontSize: W * 0.038,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// MOBILE FIELD
                      TextField(
                        controller: _mobileController,
                        keyboardType: TextInputType.number,
                        enabled: !_otpSent,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          hintText: 'Enter your mobile number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.secondary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "We’ll send a one-time verification code.",
                          style: GoogleFonts.poppins(
                            fontSize: W * 0.032,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),

                      /// OTP FIELD
                      if (_otpSent) ...[
                        const SizedBox(height: 20),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Enter OTP",
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ],

                      /// ERROR TEXT
                      if (_error.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 12),
                          child: Text(
                            _error,
                            style:
                                const TextStyle(color: Colors.red),
                          ),
                        ),

                      SizedBox(height: H * 0.04),

                      /// ================= CTA BUTTON =================
                      _loading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: !_otpSent
                                    ? (allFilled ? _sendOtp : null)
                                    : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: allFilled
                                      ? const Color(0xFFE4B3B8)
                                      : Colors.grey.shade400,
                                  elevation: allFilled ? 2 : 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(
                                  _otpSent
                                      ? "Verify OTP"
                                      : "Verify & Continue",
                                  style: GoogleFonts.poppins(
                                    fontSize: W * 0.045,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(height: 12),

                      /// SECONDARY ACTION
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: Text(
                          "New here? Create Profile",
                          style: GoogleFonts.poppins(
                            fontSize: W * 0.032,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: H * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}