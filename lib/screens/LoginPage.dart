import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:skin_analysis_app/Bloc/auth_bloc.dart';
import 'package:skin_analysis_app/Bloc/auth_event.dart';
import 'package:skin_analysis_app/Bloc/auth_state.dart';
import 'dart:async';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Provide AuthBloc here
    return BlocProvider(
      create: (context) => AuthBloc(),
      child: const LoginPageContent(),
    );
  }
}

class LoginPageContent extends StatefulWidget {
  const LoginPageContent({Key? key}) : super(key: key);

  @override
  State<LoginPageContent> createState() => _LoginPageContentState();
}

class _LoginPageContentState extends State<LoginPageContent> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOTP() {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
      });
      return;
    }

    // Use BLoC to send OTP
    context.read<AuthBloc>().add(SendOtpRequested(phone: phone));
  }

  void _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // For Flutter Web, use signInWithPopup
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithPopup(googleProvider);

      if (userCredential.user != null) {
        final user = userCredential.user!;

        // Use BLoC to handle Google login
        if (mounted) {
          context.read<AuthBloc>().add(
            GoogleLoginRequested(
              googleToken: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? '',
              uid: user.uid,
              photoURL: user.photoURL ?? '',
              phoneNumber: user.phoneNumber ?? '',
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Sign-in was cancelled';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-in failed:   ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showOtpPopup(String phoneNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: _OtpPopupWidget(
            phoneNumber: phoneNumber,
            onOtpSubmit: (otp) {
              context.read<AuthBloc>().add(
                VerifyLoginMobile(
                  phone: phoneNumber,
                  name: '',
                  email: '',
                  password: '',
                  otp: otp,
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
            _errorMessage = '';
          });
        } else if (state is AuthMessage) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Show OTP popup
          _showOtpPopup(_phoneController.text.trim());
        } else if (state is AuthAuthenticated) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is AuthError) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.error;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE8B4BA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFD4999F),
          title: const Text(
            'Login',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo or Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFFD4999F),
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      'Welcome!  ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Login to unlock your full skin analysis',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Login Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Login with Phone',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4999F),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Phone Input
                          TextField(
                            controller: _phoneController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: 'Enter your phone',
                              prefixIcon: const Icon(Icons.phone_android),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD4999F),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Send OTP Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _sendOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4999F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login / Register with OTP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(color: Colors.white54, thickness: 1.2),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.white54, thickness: 1.2),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Google Sign In Button
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Image.asset(
                              'assets/google_logo.png',
                              height: 22,
                              width: 22,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.login, size: 22);
                              },
                            ),
                      label: Text(
                        _isLoading
                            ? "Signing in..."
                            : "Login/Register with Google",
                        style: const TextStyle(
                          color: Color(0xFF444444),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFE2E2E2),
                          width: 1.2,
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// OTP Popup Widget
class _OtpPopupWidget extends StatefulWidget {
  final void Function(String otp) onOtpSubmit;
  final String phoneNumber;

  const _OtpPopupWidget({required this.onOtpSubmit, required this.phoneNumber});

  @override
  State<_OtpPopupWidget> createState() => _OtpPopupWidgetState();
}

class _OtpPopupWidgetState extends State<_OtpPopupWidget> {
  String enteredOtp = "";
  Timer? _timer;
  int _countdown = 30;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdown = 30;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _resendOtp() {
    if (_canResend) {
      context.read<AuthBloc>().add(SendOtpRequested(phone: widget.phoneNumber));
      _startTimer();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("OTP resent successfully!")));
    }
  }

  void _verifyOtp() {
    if (enteredOtp.length == 6) {
      setState(() {
        _isVerifying = true;
      });
      Navigator.of(context).pop();
      widget.onOtpSubmit(enteredOtp);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 6-digit OTP")),
      );
    }
  }

  void _cancelOtp() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFD4999F);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          setState(() {
            _isVerifying = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error)));
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We sent a 6-digit code to ${widget.phoneNumber}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Pinput(
              length: 6,
              onChanged: (value) => enteredOtp = value,
              onCompleted: (value) {
                enteredOtp = value;
                _verifyOtp();
              },
              defaultPinTheme: PinTheme(
                width: 45,
                height: 55,
                textStyle: const TextStyle(fontSize: 18, color: Colors.black),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 45,
                height: 55,
                textStyle: const TextStyle(fontSize: 18, color: Colors.black),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _canResend ? _resendOtp : null,
                  child: Text(
                    _canResend ? 'Resend OTP' : 'Resend in ${_countdown}s',
                    style: TextStyle(
                      color: _canResend ? primaryColor : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _cancelOtp,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Verify',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
