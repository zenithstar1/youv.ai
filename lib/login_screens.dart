import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_analysis_app/Bloc/auth_bloc.dart';
import 'package:skin_analysis_app/Bloc/auth_event.dart';
import 'package:skin_analysis_app/Bloc/auth_state.dart';
import 'signup_screens.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController loginPhoneController = TextEditingController();
  late final AuthBloc _authBloc;
  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc();
  }

  @override
  void dispose() {
    _authBloc.close();
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

    return BlocProvider.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() => _isSendingOtp = true);
          } else {
            if (_isSendingOtp) {
              setState(() => _isSendingOtp = false);
            }
          }

          if (state is AuthMessage) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpScreen(
                  phoneNumber: "+91${loginPhoneController.text.trim()}",
                ),
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error, style: GoogleFonts.lora())),
            );
          }
        },
        child: Scaffold(
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
                      onTap: _isSendingOtp ? null : () {
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
                        context.read<AuthBloc>().add(
                          SendOtpRequested(
                            phone: loginPhoneController.text.trim(),
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
                          child: _isSendingOtp
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
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
        ),
      ),
    );
  }
}

