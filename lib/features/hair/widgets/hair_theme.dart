import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soft rose palette aligned with the rest of the app (analysis hub, skin, auth).
class HairTheme {
  static const pageBg = Color(0xFFFDEDED);
  static const pageBgDeep = Color(0xFFF6E4E6);
  static const accent = Color(0xFFD79096);
  static const blush = Color(0xFFE4B3B8);
  static const accentDark = Color(0xFF6B3A3A);
  static const textHigh = Color(0xFF3A2A22);
  static const textMuted = Color(0xFF8A7A72);
  static const textSoft = Color(0xFFA89B93);
  static const card = Color(0xFFFFFCF9);
  static const cardAlt = Color(0xFFFFFBF7);
  static const iconTile = Color(0xFFEED3D6);
  static const iconTileMuted = Color(0xFFF1ECE8);
  static const track = Color(0xFFF1ECE8);
  static const disabledFill = Color(0xFFEED3D6);
  static const warn = Color(0xFFC47A2C);
  static const ok = Color(0xFF4E7A4A);
  static const error = Color(0xFFC96B6B);

  static const ctaGradient = [Color(0xFFE4B3B8), Color(0xFFD79096)];

  static TextStyle eyebrow(double size) => GoogleFonts.lora(
        fontSize: size,
        letterSpacing: 2.2,
        fontWeight: FontWeight.w600,
        color: textSoft,
      );

  static TextStyle headline(double size) => GoogleFonts.lora(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: textHigh,
        height: 1.25,
      );

  static TextStyle body(double size) => GoogleFonts.lora(
        fontSize: size,
        color: textMuted,
        height: 1.45,
      );

  /// Small UI labels / badges (matches app nav / meta).
  static TextStyle label(double size, {FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: weight,
        color: color ?? accentDark,
      );

  static TextStyle cta(double size) => GoogleFonts.lora(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: Colors.white,
      );

  static BoxDecoration softCard({double radius = 22, bool elevated = true}) =>
      BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevated ? 0.08 : 0.05),
            blurRadius: elevated ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      );
}
