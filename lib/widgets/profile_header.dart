import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive.dart';

/// Reusable profile avatar + name + subtitle header.
///
/// Accepts optional [imageUrl] for a future network avatar, falls back to
/// an elegant initials-based placeholder built from [name].
class ProfileHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? imageUrl;

  const ProfileHeader({
    super.key,
    required this.name,
    this.subtitle = '',
    this.imageUrl,
  });

  /// Extracts up to two initials from [name] (e.g. "Ayesha Khan" → "AK").
  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Column(
      children: [
        // ── Avatar ──────────────────────────────────────────────────────────
        Container(
          width: r.w(90),
          height: r.w(90),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFE4B3B8), Color(0xFFD79096)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD79096).withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _InitialsText(_initials, r),
                  ),
                )
              : _InitialsText(_initials, r),
        ),

        SizedBox(height: r.h(14)),

        // ── Name ─────────────────────────────────────────────────────────────
        Text(
          name.isNotEmpty ? name : 'Your Name',
          style: GoogleFonts.lora(
            fontSize: r.sp(22),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3B1F1F),
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),

        if (subtitle.isNotEmpty) ...[
          SizedBox(height: r.h(4)),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: r.sp(13),
              color: const Color(0xFF8A7A72),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _InitialsText extends StatelessWidget {
  final String initials;
  final Responsive r;
  const _InitialsText(this.initials, this.r);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.lora(
          fontSize: r.sp(32),
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
