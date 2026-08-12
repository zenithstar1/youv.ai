import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skin_analysis_app/utils/responsive.dart';
import '../Bloc/auth_bloc.dart';
import '../Bloc/auth_event.dart';
import '../Bloc/auth_state.dart';
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
  int _timer = 0;
  late final AuthBloc _authBloc;

  /// rebuild UI while typing
  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc();
    _mobileController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _authBloc.close();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _normalizedPhone() {
    final digits = _mobileController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// validation getter (single source of truth)
  bool get allFilled {
    final digits =
        _mobileController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10;
  }

  /// send OTP
  void _sendOtp() async {
    final phone = _normalizedPhone();
    if (phone.length != 10) {
      setState(() => _error = 'Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() => _timer = 30);
    _startTimer();

    _authBloc.add(
      SendOtpRequested(
        phone: phone,
        flow: 'login',
        scannerUrl: kIsWeb ? Uri.base.toString() : '',
      ),
    );
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_timer > 0 && mounted) {
        setState(() => _timer--);
        _startTimer();
      }
    });
  }

  /// resend OTP
  void _resendOtp() {
    setState(() => _timer = 30);
    _startTimer();
    _authBloc.add(
      SendOtpRequested(
        phone: _normalizedPhone(),
        flow: 'login',
        scannerUrl: kIsWeb ? Uri.base.toString() : '',
      ),
    );
  }

  /// verify OTP
  void _verifyOtp() {
    final phone = _normalizedPhone();
    if (_otpController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter OTP');
      return;
    }

    _authBloc.add(
      VerifyLoginMobile(
        phone: phone,
        name: '',
        email: '',
        password: '',
        otp: _otpController.text.trim(),
        scannerUrl: kIsWeb ? Uri.base.toString() : '',
        latitude: '',
        longitude: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;
    final r = Responsive(context);

    return BlocProvider.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() {
              _loading = true;
              _error = '';
            });
          } else if (state is AuthMessage) {
            setState(() {
              _loading = false;
              _otpSent = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AuthAuthenticated) {
            setState(() => _loading = false);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const AnalysisTypeScreen(),
              ),
              (_) => false,
            );
          } else if (state is AuthError) {
            setState(() {
              _loading = false;
              _error = state.error;
            });
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF9F0EC),
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

                      SizedBox(height: r.h(8)),

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

                      SizedBox(height: r.h(6)),

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
                        SizedBox(height: r.h(20)),
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
                        SizedBox(height: r.h(12)),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _timer == 0 ? _resendOtp : null,
                            child: Text(
                              _timer == 0 ? 'Resend OTP' : 'Resend in $_timer s',
                              style: GoogleFonts.poppins(
                                fontSize: W * 0.032,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],

                      /// ERROR TEXT
                      if (_error.isNotEmpty)
                        Padding(
                          padding:
                              EdgeInsets.only(top: r.h(12)),
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
                              height: r.h(48),
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

                      SizedBox(height: r.h(12)),

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
        ),
      ),
    );
  }
}
