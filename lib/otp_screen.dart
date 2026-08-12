import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_analysis_app/Bloc/auth_bloc.dart';
import 'package:skin_analysis_app/Bloc/auth_event.dart';
import 'package:skin_analysis_app/Bloc/auth_state.dart';
import 'package:skin_analysis_app/utils/responsive.dart';
import 'screens/analysis_type_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String flow;
  final String name;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.flow = 'login',
    this.name = '',
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  List<String> otp = ["", "", "", "", "", ""];
  int timer = 60;
  bool expired = false;
  late Timer countdown;
  late final AuthBloc _authBloc;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc();
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
    _authBloc.close();
    super.dispose();
  }

  Future<void> _onVerify(BuildContext context) async {
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

    final rawPhone = widget.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final phone = rawPhone.length > 10
        ? rawPhone.substring(rawPhone.length - 10)
        : rawPhone;

    if (!context.mounted) return;
    _authBloc.add(VerifyLoginMobile(
      phone: phone,
      otp: otp.join(),
      name: widget.name,
      email: '',
      password: '',
      scannerUrl: kIsWeb ? Uri.base.toString() : '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;
    final topInset = MediaQuery.of(context).padding.top;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final otpBoxWidth = (W * 0.11).clamp(36.0, 58.0);
    final otpBoxHeight = (otpBoxWidth * 1.2).clamp(48.0, 64.0);
    final otpGap = (W * 0.012).clamp(3.0, 8.0);

    return BlocProvider.value(
      value: _authBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() => _isVerifying = true);
          } else {
            if (_isVerifying) setState(() => _isVerifying = false);
          }

          if (state is AuthAuthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AnalysisTypeScreen()),
            );
          } else if (state is AuthMessage) {
            // OTP resent — reset timer
            countdown.cancel();
            setState(() {
              timer = 60;
              expired = false;
            });
            startTimer();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: GoogleFonts.lora())),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade900,
                content: Text(state.error, style: GoogleFonts.lora()),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFCE7E7),
          body: Stack(
            children: [
              Positioned(
                top: topInset + 16,
                left: (W * 0.06).clamp(16.0, 36.0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
                ),
              ),

              Positioned.fill(
                top: (topInset + (isTablet ? 92 : 82)).clamp(72.0, 160.0),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: (W * 0.08).clamp(16.0, 40.0)),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        children: [
                          Text(
                            "Verify Code",
                            style: GoogleFonts.lora(
                              fontSize: r.sp(24),
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),

                          SizedBox(height: r.h(10)),

                          Text(
                            "Enter the 6-digit code sent to your number",
                            style: GoogleFonts.lora(
                              fontSize: r.sp(15),
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: r.h(40)),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (i) {
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: otpGap),
                                width: otpBoxWidth,
                                height: otpBoxHeight,
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
                                  style: GoogleFonts.lora(fontSize: isTablet ? 24 : 20),
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
                            style: GoogleFonts.lora(fontSize: r.sp(14)),
                          ),

                          SizedBox(height: r.h(15)),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't receive OTP? ",
                                style: GoogleFonts.lora(
                                  fontSize: r.sp(14),
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: expired
                                    ? () {
                                        final rawPhone = widget.phoneNumber
                                            .replaceAll(RegExp(r'[^0-9]'), '');
                                        final phone = rawPhone.length > 10
                                            ? rawPhone.substring(rawPhone.length - 10)
                                            : rawPhone;
                                        _authBloc.add(SendOtpRequested(
                                          phone: phone,
                                          flow: widget.flow,
                                          scannerUrl: kIsWeb ? Uri.base.toString() : '',
                                        ));
                                      }
                                    : null,
                                child: Text(
                                  "Resend code",
                                  style: GoogleFonts.lora(
                                    fontSize: r.sp(14),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: r.h(40)),

                          GestureDetector(
                            onTap: _isVerifying ? null : () => _onVerify(context),
                            child: Container(
                              width: (W * (isTablet ? 0.34 : 0.5)).clamp(180.0, 280.0),
                              height: r.h(50),
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
                                child: _isVerifying
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        "Verify",
                                        style: GoogleFonts.lora(
                                          fontSize: r.sp(18),
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: H * 0.04),
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
