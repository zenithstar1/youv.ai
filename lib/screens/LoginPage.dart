import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skin_analysis_app/Bloc/auth_bloc.dart';
import 'package:skin_analysis_app/Bloc/auth_event.dart';
import 'package:skin_analysis_app/Bloc/auth_state.dart';
import 'dart:async';

import 'package:pinput/pinput.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // final _emailController = TextEditingController();
  // final _phoneController = TextEditingController();
  // final _otpController = TextEditingController();

  bool _isLoading = false;
  // bool _otpSent = false;
  String _errorMessage = '';
  // bool _useEmail = false; // Start with phone by default

  // Timer?  _timer;
  // int _countdown = 30;
  // bool _canResend = false;

  @override
  void dispose() {
    // _emailController.dispose();
    // _phoneController.dispose();
    // _otpController.dispose();
    // _timer?.cancel();
    super.dispose();
  }

  // void _startTimer() {
  //   _countdown = 30;
  //   _canResend = false;
  //   _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     if (_countdown > 0) {
  //       setState(() {
  //         _countdown--;
  //       });
  //     } else {
  //       setState(() {
  //         _canResend = true;
  //       });
  //       timer.cancel();
  //     }
  //   });
  // }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Generate a unique guest ID
      final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';

      // Create guest user info
      final guestInfo = {
        'name': 'Guest User',
        'email': '$guestId@guest.com',
        'phone': '',
        'is_guest': true,
        'guest_id': guestId,
      };

      // Store guest login data
      await prefs.setBool('isLogin', true);
      await prefs.setString('userInfo', jsonEncode(guestInfo));
      await prefs.setString('name', 'Guest User');
      await prefs.setString('email', '$guestId@guest. com');
      await prefs.setBool('isGuest', true);

      // Navigate back with success
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in as Guest'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Guest login failed.   Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // void _sendOTP() {
  //   final identifier = _useEmail
  //       ? _emailController. text.trim()
  //       : _phoneController.text.trim();

  //   if (identifier.isEmpty) {
  //     setState(() {
  //       _errorMessage = _useEmail
  //           ? 'Please enter your email address'
  //           :  'Please enter your phone number';
  //     });
  //     return;
  //   }

  //   if (_useEmail && ! _isValidEmail(identifier)) {
  //     setState(() {
  //       _errorMessage = 'Please enter a valid email address';
  //     });
  //     return;
  //   }

  //   // Use BLoC to send OTP
  //   BlocProvider.of<AuthBloc>(context).add(SendOtpRequested(phone: identifier));
  // }

  // void _resendOTP() {
  //   if (_canResend) {
  //     _sendOTP();
  //   }
  // }

  // void _verifyOTP() {
  //   final identifier = _useEmail
  //       ? _emailController.text.trim()
  //       : _phoneController.text.trim();
  //   final otp = _otpController. text.trim();

  //   if (otp.isEmpty) {
  //     setState(() {
  //       _errorMessage = 'Please enter the OTP';
  //     });
  //     return;
  //   }

  //   if (otp. length != 6) {
  //     setState(() {
  //       _errorMessage = 'Please enter a valid 6-digit OTP';
  //     });
  //     return;
  //   }

  //   // Use BLoC to verify OTP
  //   context.read<AuthBloc>().add(
  //     VerifyLoginMobile(
  //       phone: identifier,
  //       name: '',
  //       email: _useEmail ? identifier : '',
  //       password: '',
  //       otp: otp,
  //     ),
  //   );
  // }

  // void _handleGoogleLogin() async {
  //   try {
  //     final GoogleAuthProvider googleProvider = GoogleAuthProvider();
  //     final userCredential = await FirebaseAuth.instance. signInWithPopup(
  //       googleProvider,
  //     );

  //     if (userCredential.user != null) {
  //       final user = userCredential.user!;

  //       // Use BLoC to handle Google login
  //       BlocProvider.of<AuthBloc>(context).add(
  //         GoogleLoginRequested(
  //           googleToken: user.uid,
  //           email: user.email ??  '',
  //           displayName: user.displayName ?? '',
  //           uid: user.uid,
  //           photoURL: user.photoURL ?? '',
  //           phoneNumber: user.phoneNumber ?? '',
  //         ),
  //       );
  //     } else {
  //       setState(() {
  //         _errorMessage = 'Sign-in was cancelled';
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = 'Google sign-in failed:   ${e.toString()}';
  //     });
  //   }
  // }

  // bool _isValidEmail(String email) {
  //   return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8B4BA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4999F),
        title: const Text(
          'Guest Login',
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
                    'Welcome! ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Continue as guest to unlock your full skin analysis',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Guest Login Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGuestLogin,
                    icon: const Icon(Icons.person_outline),
                    label: const Text(
                      'Continue as Guest',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD4999F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),

                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 20),
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

                  const SizedBox(height: 30),

                  // Info message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'As a guest, you can view your skin analysis and receive a detailed PDF report via email.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // COMMENTED OUT SECTIONS:
                  // const SizedBox(height: 20),

                  // // Divider
                  // Row(
                  //   children: const [
                  //     Expanded(
                  //       child:  Divider(
                  //         color: Colors.white54,
                  //         thickness: 1.2,
                  //       ),
                  //     ),
                  //     Padding(
                  //       padding:  EdgeInsets.symmetric(horizontal: 16),
                  //       child: Text(
                  //         'OR',
                  //         style: TextStyle(
                  //           color: Colors.white70,
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //       ),
                  //     ),
                  //     Expanded(
                  //       child: Divider(
                  //         color: Colors.white54,
                  //         thickness:  1.2,
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  // const SizedBox(height: 20),

                  // // Toggle between Email and Phone
                  // Container(
                  //   padding:  const EdgeInsets.all(4),
                  //   decoration:  BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       Expanded(
                  //         child: GestureDetector(
                  //           onTap: () {
                  //             if (! _otpSent) {
                  //               setState(() {
                  //                 _useEmail = true;
                  //                 _errorMessage = '';
                  //               });
                  //             }
                  //           },
                  //           child: Container(
                  //             padding:  const EdgeInsets.symmetric(
                  //               vertical: 12,
                  //             ),
                  //             decoration: BoxDecoration(
                  //               color: _useEmail
                  //                   ? const Color(0xFFD4999F)
                  //                   : Colors.transparent,
                  //               borderRadius: BorderRadius.circular(10),
                  //             ),
                  //             child: Text(
                  //               'Email',
                  //               style:  TextStyle(
                  //                 color: _useEmail
                  //                     ? Colors.white
                  //                     : Colors.black54,
                  //                 fontWeight: FontWeight.w600,
                  //               ),
                  //               textAlign: TextAlign.center,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //       Expanded(
                  //         child: GestureDetector(
                  //           onTap: () {
                  //             if (!_otpSent) {
                  //               setState(() {
                  //                 _useEmail = false;
                  //                 _errorMessage = '';
                  //               });
                  //             }
                  //           },
                  //           child: Container(
                  //             padding: const EdgeInsets.symmetric(
                  //               vertical:  12,
                  //             ),
                  //             decoration:  BoxDecoration(
                  //               color: ! _useEmail
                  //                   ? const Color(0xFFD4999F)
                  //                   : Colors.transparent,
                  //               borderRadius:  BorderRadius.circular(10),
                  //             ),
                  //             child: Text(
                  //               'Phone',
                  //               style: TextStyle(
                  //                 color:  !_useEmail
                  //                     ? Colors.white
                  //                     : Colors.black54,
                  //                 fontWeight: FontWeight.w600,
                  //               ),
                  //               textAlign: TextAlign.center,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // const SizedBox(height: 20),

                  // // Login Form
                  // Container(
                  //   padding:  const EdgeInsets.all(20),
                  //   decoration:  BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(16),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Colors. black.withOpacity(0.1),
                  //         blurRadius: 10,
                  //         offset:  const Offset(0, 5),
                  //       ),
                  //     ],
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.stretch,
                  //     children:  [
                  //       Text(
                  //         _useEmail
                  //             ? 'Login with Email'
                  //             : 'Login with Phone',
                  //         style: const TextStyle(
                  //           fontSize: 18,
                  //           fontWeight: FontWeight.bold,
                  //           color:  Color(0xFFD4999F),
                  //         ),
                  //         textAlign: TextAlign.center,
                  //       ),
                  //       const SizedBox(height: 20),

                  //       // Email/Phone Input
                  //       TextField(
                  //         controller: _useEmail
                  //             ? _emailController
                  //             :  _phoneController,
                  //         enabled: ! _otpSent && ! _isLoading,
                  //         keyboardType: _useEmail
                  //             ?  TextInputType.emailAddress
                  //             : TextInputType. phone,
                  //         decoration: InputDecoration(
                  //           labelText: _useEmail
                  //               ? 'Email Address'
                  //               : 'Phone Number',
                  //           hintText: _useEmail
                  //               ? 'Enter your email'
                  //               :  'Enter your phone',
                  //           prefixIcon: Icon(
                  //             _useEmail
                  //                 ? Icons.email_outlined
                  //                 : Icons.phone_android,
                  //           ),
                  //           border: OutlineInputBorder(
                  //             borderRadius:  BorderRadius.circular(12),
                  //           ),
                  //           focusedBorder: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(12),
                  //             borderSide: const BorderSide(
                  //               color: Color(0xFFD4999F),
                  //               width:  2,
                  //             ),
                  //           ),
                  //         ),
                  //       ),

                  //       if (_otpSent) ...[
                  //         const SizedBox(height: 16),
                  //         // OTP Input with Pinput
                  //         Pinput(
                  //           controller: _otpController,
                  //           length: 6,
                  //           enabled: !_isLoading,
                  //           onCompleted: (value) {
                  //             _verifyOTP();
                  //           },
                  //           defaultPinTheme: PinTheme(
                  //             width: 50,
                  //             height: 55,
                  //             textStyle: const TextStyle(
                  //               fontSize: 18,
                  //               color: Colors.black,
                  //             ),
                  //             decoration: BoxDecoration(
                  //               borderRadius: BorderRadius.circular(8),
                  //               border:  Border.all(
                  //                 color: Colors.grey. shade300,
                  //               ),
                  //             ),
                  //           ),
                  //           focusedPinTheme: PinTheme(
                  //             width:  50,
                  //             height: 55,
                  //             textStyle: const TextStyle(
                  //               fontSize:  18,
                  //               color: Colors.black,
                  //             ),
                  //             decoration: BoxDecoration(
                  //               borderRadius: BorderRadius.circular(8),
                  //               border: Border.all(
                  //                 color: const Color(0xFFD4999F),
                  //                 width: 2,
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //         const SizedBox(height: 12),
                  //         Row(
                  //           mainAxisAlignment:
                  //               MainAxisAlignment.spaceBetween,
                  //           children: [
                  //             TextButton(
                  //               onPressed: _canResend ?  _resendOTP : null,
                  //               child: Text(
                  //                 _canResend
                  //                     ? 'Resend OTP'
                  //                     : 'Resend in ${_countdown}s',
                  //                 style: TextStyle(
                  //                   color: _canResend
                  //                       ? const Color(0xFFD4999F)
                  //                       : Colors.grey,
                  //                   fontSize: 13,
                  //                 ),
                  //               ),
                  //             ),
                  //             TextButton(
                  //               onPressed: _isLoading
                  //                   ? null
                  //                   : () {
                  //                       setState(() {
                  //                         _otpSent = false;
                  //                         _otpController.clear();
                  //                         _errorMessage = '';
                  //                         _timer?.cancel();
                  //                       });
                  //                     },
                  //               child: const Text(
                  //                 'Change',
                  //                 style:  TextStyle(
                  //                   color: Colors.blue,
                  //                   fontSize: 13,
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ],

                  //       if (_errorMessage.isNotEmpty) ...[
                  //         const SizedBox(height: 12),
                  //         Container(
                  //           padding: const EdgeInsets.all(12),
                  //           decoration: BoxDecoration(
                  //             color: Colors.red.shade50,
                  //             borderRadius: BorderRadius.circular(8),
                  //             border: Border.all(
                  //               color: Colors.red.shade200,
                  //             ),
                  //           ),
                  //           child: Row(
                  //             children: [
                  //               Icon(
                  //                 Icons.error_outline,
                  //                 color: Colors.red.shade700,
                  //                 size:  20,
                  //               ),
                  //               const SizedBox(width: 8),
                  //               Expanded(
                  //                 child:  Text(
                  //                   _errorMessage,
                  //                   style: TextStyle(
                  //                     color: Colors.red.shade700,
                  //                     fontSize: 13,
                  //                   ),
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ],

                  //       const SizedBox(height: 20),

                  //       // Action Button
                  //       ElevatedButton(
                  //         onPressed:  _isLoading
                  //             ? null
                  //             : (_otpSent ? _verifyOTP : _sendOTP),
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: const Color(0xFFD4999F),
                  //           foregroundColor: Colors.white,
                  //           padding: const EdgeInsets.symmetric(
                  //             vertical: 16,
                  //           ),
                  //           shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(12),
                  //           ),
                  //           elevation: 2,
                  //         ),
                  //         child: _isLoading
                  //             ?  const SizedBox(
                  //                 height: 20,
                  //                 width: 20,
                  //                 child: CircularProgressIndicator(
                  //                   strokeWidth: 2,
                  //                   color: Colors.white,
                  //                 ),
                  //               )
                  //             :  Text(
                  //                 _otpSent ?  'Verify OTP' : 'Send OTP',
                  //                 style: const TextStyle(
                  //                   fontSize: 16,
                  //                   fontWeight: FontWeight. w600,
                  //                 ),
                  //               ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // const SizedBox(height: 20),

                  // // Divider
                  // Row(
                  //   children: const [
                  //     Expanded(
                  //       child:  Divider(
                  //         color: Colors.white54,
                  //         thickness: 1.2,
                  //       ),
                  //     ),
                  //     Padding(
                  //       padding: EdgeInsets.symmetric(horizontal: 16),
                  //       child: Text(
                  //         'Or continue with',
                  //         style: TextStyle(
                  //           color: Colors.white70,
                  //           fontSize: 13,
                  //         ),
                  //       ),
                  //     ),
                  //     Expanded(
                  //       child: Divider(
                  //         color: Colors.white54,
                  //         thickness: 1.2,
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  // const SizedBox(height: 20),

                  // // Google Sign In Button
                  // OutlinedButton. icon(
                  //   onPressed: _isLoading ? null : _handleGoogleLogin,
                  //   icon: _isLoading
                  //       ? const SizedBox(
                  //           height: 22,
                  //           width:  22,
                  //           child: CircularProgressIndicator(
                  //             strokeWidth:  2,
                  //           ),
                  //         )
                  //       : Image.asset(
                  //           'assets/google_logo.png',
                  //           height: 22,
                  //           width: 22,
                  //           errorBuilder: (context, error, stackTrace) {
                  //             return const Icon(Icons.login, size: 22);
                  //           },
                  //         ),
                  //   label: Text(
                  //     _isLoading ? "Signing in..." : "Login with Google",
                  //     style: const TextStyle(
                  //       color: Color(0xFF444444),
                  //       fontWeight: FontWeight.w600,
                  //       fontSize: 16,
                  //     ),
                  //   ),
                  //   style: OutlinedButton.styleFrom(
                  //     padding: const EdgeInsets.symmetric(vertical: 13),
                  //     shape:  RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //     side: const BorderSide(
                  //       color: Color(0xFFE2E2E2),
                  //       width: 1. 2,
                  //     ),
                  //     backgroundColor: Colors.white,
                  //   ),
                  // ),

                  // const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
