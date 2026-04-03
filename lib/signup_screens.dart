import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_analysis_app/Bloc/auth_bloc.dart';
import 'package:skin_analysis_app/Bloc/auth_event.dart';
import 'package:skin_analysis_app/Bloc/auth_state.dart';
import 'package:skin_analysis_app/utils/responsive.dart';
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
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context); // responsive scaling helper
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;
    final topInset = MediaQuery.of(context).padding.top;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
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
                builder: (_) =>
                    OtpScreen(phoneNumber: "+91${phoneController.text.trim()}"),
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
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // BACK ARROW
              Positioned(
                top: topInset + 16,
                left: (W * 0.06).clamp(16.0, 36.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
              ),

              // MAIN CONTENT
              Positioned.fill(
                top: (topInset + (isTablet ? 92 : 82)).clamp(72.0, 160.0),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: (W * 0.08).clamp(16.0, 40.0),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TITLE
                          Text(
                            "Create Account",
                            style: GoogleFonts.lora(
                              fontSize: r.sp(28), // responsive title
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),

                          SizedBox(height: r.h(40)), // responsive spacing
                          // NAME LABEL
                          Text(
                            "Name",
                            style: GoogleFonts.lora(
                              fontSize: r.sp(17), // responsive label
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: r.h(8)),
                          buildUnderlineField(r),

                          SizedBox(height: r.h(35)), // responsive spacing
                          // AGE
                          Text(
                            "Age",
                            style: GoogleFonts.lora(
                              fontSize: r.sp(17), // responsive label
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: r.h(8)),
                          buildUnderlineField(r),

                          SizedBox(height: r.h(35)), // responsive spacing
                          // PHONE NUMBER
                          Text(
                            "Phone Number",
                            style: GoogleFonts.lora(
                              fontSize: r.sp(17), // responsive label
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: r.h(8)),

                          Container(
                            padding: const EdgeInsets.only(bottom: 4),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "+91 - ",
                                  style: GoogleFonts.lora(
                                    fontSize: r.sp(18), // responsive
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller:
                                        phoneController, // <-- controller added
                                    keyboardType: TextInputType.number,
                                    maxLength: 10,
                                    decoration: const InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      counterText: "",
                                    ),
                                    style: GoogleFonts.lora(fontSize: r.sp(18)),
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
                                      width: r.w(29), // responsive checkbox
                                      height: r.w(27),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFFD79096),
                                          width: 2,
                                        ),
                                        color: Colors.transparent,
                                      ),
                                      child: value
                                          ? const Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Colors.black,
                                            )
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
                                      fontSize: r.sp(15),
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: "Terms and Conditions",
                                        style: GoogleFonts.lora(
                                          fontSize: r.sp(15), // responsive
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
                                            } else {
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
                              onTap: _isSendingOtp
                                  ? null
                                  : () {
                                      // VALIDATE TERMS
                                      if (!agreeTerms.value) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                          phone: phoneController.text.trim(),
                                          flow: 'signup',
                                        ),
                                      );
                                    },
                              child: Container(
                                width: actionWidth,
                                height: r.h(53), // responsive button height
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD79096),
                                  borderRadius: BorderRadius.circular(158),
                                  border: Border.all(
                                    color: const Color(0xFF510808),
                                    width: 3,
                                  ),
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
                                          "Sign Up",
                                          style: GoogleFonts.lora(
                                            fontSize: r.sp(20), // responsive
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: r.h(25)), // responsive spacing
                          // OR
                          Center(
                            child: Text(
                              "or",
                              style: GoogleFonts.lora(
                                fontSize: r.sp(16),
                                color: Colors.black87,
                              ), // responsive
                            ),
                          ),

                          SizedBox(height: r.h(25)), // responsive spacing
                          // CONTINUE WITH GOOGLE BUTTON
                          Center(
                            child: Container(
                              width: actionWidth,
                              height: r.h(53), // responsive button height
                              decoration: BoxDecoration(
                                color: const Color(0xFFD79096),
                                borderRadius: BorderRadius.circular(158),
                                border: Border.all(
                                  color: const Color(0xFF510808),
                                  width: 3,
                                ),
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
                                        fontSize: r.sp(
                                          isTablet ? 20 : 18,
                                        ), // responsive
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: r.h(25)), // responsive spacing
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
                                    fontSize: r.sp(16), // responsive
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Log In!",
                                      style: GoogleFonts.lora(
                                        fontSize: r.sp(16), // responsive
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

                          SizedBox(
                            height: r.h(50),
                          ), // responsive bottom spacing
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

  // Reusable underline field with responsive font
  Widget buildUnderlineField(Responsive r) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      child: TextField(
        style: GoogleFonts.lora(fontSize: r.sp(18)), // responsive input text
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
