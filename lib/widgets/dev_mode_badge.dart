import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_analysis_app/config/otp_bypass_config.dart';

/// Small overlay shown app-wide while [OtpBypassConfig.enabled] is true.
class DevModeBadge extends StatelessWidget {
  const DevModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!OtpBypassConfig.enabled) return const SizedBox.shrink();

    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xE61A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFB74D), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DEV MODE',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFFB74D),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'OTP: ${OtpBypassConfig.code}',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
