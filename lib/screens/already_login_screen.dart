import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlreadyLoginScreen extends StatefulWidget {
  const AlreadyLoginScreen({super.key});

  @override
  State<AlreadyLoginScreen> createState() => _AlreadyLoginScreenState();
}

class _AlreadyLoginScreenState extends State<AlreadyLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String _error = '';

  void _sendOtp() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    // Simulate OTP send
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _otpSent = true;
      _loading = false;
    });
  }

  void _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 1));
    if (_otpController.text == '123456') {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = 'Invalid OTP';
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
        child: Center(
          child: Container(
            width: W * 0.9,
            padding: EdgeInsets.symmetric(vertical: H * 0.08, horizontal: W * 0.06),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Login with Registered Mobile',
                  style: GoogleFonts.poppins(
                    fontSize: W * 0.06,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  enabled: !_otpSent,
                ),
                const SizedBox(height: 20),
                if (_otpSent)
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 30),
                _loading
                    ? const CircularProgressIndicator()
                    : _otpSent
                        ? ElevatedButton(
                            onPressed: _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B3A3A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Verify OTP'),
                          )
                        : ElevatedButton(
                            onPressed: _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B3A3A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Send OTP'),
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}