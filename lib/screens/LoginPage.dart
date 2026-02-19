import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:skin_analysis_app/Bloc/auth_bloc.dart';
import 'package:skin_analysis_app/Bloc/auth_event.dart';
import 'package:skin_analysis_app/Bloc/auth_state.dart';
import 'settings_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(),
      child: const LoginPageContent(),
    );
  }
}

class LoginPageContent extends StatefulWidget {
  const LoginPageContent({super.key});

  @override
  State<LoginPageContent> createState() => _LoginPageContentState();
}

class _LoginPageContentState extends State<LoginPageContent> {
  bool _isLoading = false;
  String _errorMessage = '';

  void _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      if (userCredential.user != null) {
        final user = userCredential.user!;

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
        _errorMessage = 'Google sign-in failed: ${e.toString()}';
        _isLoading = false;
      });
    }
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

          // Return true to indicate successful login, allowing the calling screen
          // to continue with its intended action (e.g., send detailed report)
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
    
        } else if (state is AuthError) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.error;
          });
        }
      },
      child: Scaffold(
        // ======== TRUE FULL SCREEN BACKGROUND ========
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
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
          elevation: 0,
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,   // 👈 KEY FIX: full width
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFFD4999F),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Welcome!',
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

                  const SizedBox(height: 35),

                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
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

                  // Google Sign In Button — FULL WIDTH
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  Color(0xFFD4999F),
                                ),
                              ),
                            )
                          : Image.asset(
                              'images/google.png',
                              height: 24,
                              width: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.login,
                                  size: 24,
                                  color: Color(0xFFD4999F),
                                );
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFE2E2E2),
                          width: 1.2,
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Info text (clean, no border)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sign in with your Google account to access your skin analysis reports and detailed insights.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
