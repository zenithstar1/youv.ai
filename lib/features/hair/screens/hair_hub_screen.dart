import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/hair_theme.dart';
import 'hair_full_scan_screen.dart';
import 'hair_quick_scan_screen.dart';

/// Entry: choose Quick Scan (1 photo) or Full Scan (multi slots).
class HairHubScreen extends StatelessWidget {
  const HairHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: HairTheme.pageBg,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HairTheme.blush.withValues(alpha: 0.35),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HairTheme.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: HairTheme.textHigh,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    children: [
                      Center(
                        child: Text(
                          'HAIR & SCALP',
                          style: HairTheme.eyebrow(w * 0.032),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'See density, texture &\nscalp clarity',
                        textAlign: TextAlign.center,
                        style: HairTheme.headline(28),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Informational insights only — not a medical diagnosis.',
                        textAlign: TextAlign.center,
                        style: HairTheme.body(13.5),
                      ),
                      const SizedBox(height: 28),
                      _ModeCard(
                        badge: 'FAST',
                        icon: Icons.bolt_rounded,
                        title: 'Quick Scan',
                        subtitle:
                            'One clear photo for density, features, and scalp insights.',
                        meta: 'About 30–90 seconds',
                        gradient: const [Color(0xFFE8C4C8), Color(0xFFD79096)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HairQuickScanScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _ModeCard(
                        badge: 'DETAILED',
                        icon: Icons.auto_awesome_mosaic_outlined,
                        title: 'Full Scan',
                        subtitle:
                            'Front, left, right, and crown — skip any angle, min 2 photos.',
                        meta: 'Richer multi-view report',
                        gradient: const [Color(0xFFD4B5A0), Color(0xFFB8897A)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HairFullScanScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: HairTheme.blush.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: HairTheme.accentDark,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Use even lighting, keep hair dry, and fill the oval with your head for the clearest results.',
                                style: HairTheme.body(12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String badge;
  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModeCard({
    required this.badge,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: HairTheme.softCard(radius: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: HairTheme.pageBgDeep,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: HairTheme.accentDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: GoogleFonts.lora(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: HairTheme.textHigh,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(subtitle, style: HairTheme.body(13)),
                      const SizedBox(height: 10),
                      Text(
                        meta,
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: HairTheme.textSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: HairTheme.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
