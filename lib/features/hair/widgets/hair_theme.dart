import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soft rose palette + typography for hair screens.
/// Fonts match skin analysis: Google Fonts Lora throughout (no Montserrat).
class HairTheme {
  static const pageBg = Color(0xFFFDEDED);
  static const pageBgDeep = Color(0xFFF6E4E6);
  static const accent = Color(0xFFD79096);
  static const blush = Color(0xFFE4B3B8);
  static const accentDark = Color(0xFF6B3E3E);
  static const textHigh = Color(0xFF3A2A22);
  static const textMuted = Color(0xFF8A7A72);
  static const textSoft = Color(0xFFA89B93);
  static const card = Color(0xFFFFFCF9);
  static const warn = Color(0xFFC47A2C);
  static const ok = Color(0xFF4E7A4A);

  /// Small caps eyebrow — same pattern as “AI FACIAL ANALYSIS”.
  static TextStyle eyebrow(double size) => GoogleFonts.lora(
        fontSize: size,
        letterSpacing: 2.0,
        fontWeight: FontWeight.w600,
        color: textSoft,
      );

  static TextStyle headline(double size) => GoogleFonts.lora(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: textHigh,
        height: 1.25,
      );

  static TextStyle title(double size) => GoogleFonts.lora(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: textHigh,
        height: 1.2,
      );

  static TextStyle body(double size) => GoogleFonts.lora(
        fontSize: size,
        color: textMuted,
        height: 1.4,
      );

  static TextStyle bodyEmphasis(double size) => GoogleFonts.lora(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: textHigh,
        height: 1.3,
      );

  static TextStyle italicNote(double size) => GoogleFonts.lora(
        fontSize: size,
        fontStyle: FontStyle.italic,
        color: textSoft,
        height: 1.35,
      );

  static TextStyle button(double size) => GoogleFonts.lora(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle label(double size) => GoogleFonts.lora(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: accentDark,
      );

  static BoxDecoration softCard({double radius = 22}) => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD79096).withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      );
}
