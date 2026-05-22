import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_analysis_app/Bloc/auth_bloc.dart';
import 'package:skin_analysis_app/Bloc/auth_event.dart';
import 'package:skin_analysis_app/Bloc/auth_state.dart';
import 'package:skin_analysis_app/utils/responsive.dart';
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
    final r = Responsive(context);
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;
    final topInset = MediaQuery.of(context).padding.top;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    // BUTTON SIZING (hybrid scaling like onboarding)
    final btnWidth = (W * (isTablet ? 0.42 : 0.56)).clamp(220.0, 360.0);
    final btnHeight = H * 0.065;    // 6.5% of screen height
    final btnRadius = btnWidth * 0.45;
    final actionWidth = (W * 0.82).clamp(230.0, 420.0);

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
                  flow: 'login',
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
            top: topInset + 16,
            left: W * 0.06,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
            ),
          ),

          // MAIN CONTENT AREA
          Positioned.fill(
            top: (topInset + (isTablet ? 92 : 82)).clamp(72.0, 160.0),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: W * 0.08),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // TITLE
                  Text(
                    "Welcome Back!",
                    style: GoogleFonts.lora(
                      fontSize: r.sp(28), // responsive title
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: H * 0.06),

                  // LABEL
                  Text(
                    "Phone Number",
                    style: GoogleFonts.lora(
                      fontSize: r.sp(17), // responsive label
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
                            fontSize: r.sp(18), // responsive input prefix
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
                            style: GoogleFonts.lora(fontSize: r.sp(18)),
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
                            flow: 'login',
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
                                    fontSize: r.sp(20), // responsive button text
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
                        fontSize: r.sp(16), // responsive
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  SizedBox(height: H * 0.03),

                  // CONTINUE WITH GOOGLE BUTTON
                  Center(
                    child: Container(
                      width: actionWidth,
                      height: r.h(53), // responsive button height
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
                              height: r.w(30), // responsive icon
                              width: r.w(30),
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: r.w(10)),
                          Flexible(
                            child: Text(
                              "Continue with Google",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lora(
                                fontSize: r.sp(isTablet ? 20 : 18), // responsive
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
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
                            fontSize: r.sp(16), // responsive
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign Up!",
                              style: GoogleFonts.lora(
                                fontSize: r.sp(16), // responsive
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
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

