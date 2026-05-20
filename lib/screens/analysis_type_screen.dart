import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_analysis_app/utils/responsive.dart';
import 'image_capture_screen.dart';
import 'profile_screen.dart';

class AnalysisTypeScreen extends StatefulWidget {
  const AnalysisTypeScreen({super.key});

  @override
  State<AnalysisTypeScreen> createState() => _AnalysisTypeScreenState();
}

class _AnalysisTypeScreenState extends State<AnalysisTypeScreen> {
  String _initials = '';

  @override
  void initState() {
    super.initState();
    _loadInitials();
  }

  Future<void> _loadInitials() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('userInfo') ?? '{}';
    try {
      final info = json.decode(raw) as Map<String, dynamic>;
      final name = (info['name'] ?? '').toString().trim();
      if (name.isNotEmpty && mounted) {
        final parts = name.split(RegExp(r'\s+'));
        final initials = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : parts[0][0].toUpperCase();
        setState(() => _initials = initials);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final W = MediaQuery.of(context).size.width;
    final H = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFFDEDED),
      body: Stack(
        children: [
          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                /// ================= HEADER SECTION =================
                SizedBox(height: H * 0.05),

                Center(
                  child: Text(
                    "AI FACIAL ANALYSIS",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: W * 0.032,
                      letterSpacing: 1.5,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// ================= SCROLLABLE CONTENT =================
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: r.w(24)),
                      child: Column(
                        children: [
                          /// HEADLINE
                          Text(
                            "Choose your focus today",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lora(
                              fontSize: r.sp(28),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3A2A22),
                            ),
                          ),

                          SizedBox(height: r.h(10)),

                          /// SUBTEXT
                          Text(
                            "Your personalized report will be generated based on your selection.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lora(
                              fontSize: r.sp(14.5),
                              height: 1.4,
                              color: const Color(0xFF8A7A72),
                            ),
                          ),

                          SizedBox(height: r.h(14)),

                          Text(
                            "Both options take less than 60 seconds.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lora(
                              fontSize: r.sp(12.5),
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFFA89B93),
                            ),
                          ),

                          SizedBox(height: H * 0.06),

                          /// SKIN CARD
                          _AnalysisCard(
                            isPrimary: true,
                            icon: Icons.face_6_outlined,
                            title: "Comprehensive Facial Analysis",
                            subtitle: "Hydration • Acne • Pigmentation • Texture",
                            description:
                                "Full facial skin evaluation with detailed scoring.",
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.lightbulb_outline,
                                          color: Color(0xFF6B3E3E)),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          "How to take a great shot",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      _TipRow(
                                        icon: Icons.camera_alt_outlined,
                                        text:
                                            'Allow camera access when prompted',
                                      ),
                                      SizedBox(height: 8),
                                      _TipRow(
                                        icon: Icons.wb_sunny_outlined,
                                        text:
                                            'Use natural lighting or bright room light',
                                      ),
                                      SizedBox(height: 8),
                                      _TipRow(
                                        icon: Icons.face,
                                        text: 'Face the camera directly',
                                      ),
                                      SizedBox(height: 8),
                                      _TipRow(
                                        icon: Icons.center_focus_strong,
                                        text:
                                            'Keep your face centered in the frame',
                                      ),
                                      SizedBox(height: 8),
                                      _TipRow(
                                        icon: Icons.sentiment_neutral,
                                        text: 'Use a neutral expression',
                                      ),
                                      SizedBox(height: 8),
                                      _TipRow(
                                        icon: Icons.no_photography_outlined,
                                        text:
                                            'Remove makeup for accurate analysis',
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ImageCaptureScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Got it!",
                                        style: TextStyle(
                                          color: Color(0xFF6B3E3E),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 22),

                          /// HAIR CARD
                          _AnalysisCard(
                            isPrimary: false,
                            icon: Icons.content_cut,
                            title: "Hair Health Overview",
                            statusText: "Coming Soon",
                            subtitle: "Density • Thinning • Scalp",
                            description: "Scalp and hair density screening.",
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Hair Health Overview is coming soon.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: H * 0.08),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Profile avatar button (always visible) ────────────────────────
          Positioned(
            top: topPad + 14,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE4B3B8), Color(0xFFD79096)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B1F1F).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Center(
                  child: _initials.isNotEmpty
                      ? Text(
                          _initials,
                          style: GoogleFonts.lora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tip row used inside the photo-guide dialog ────────────────────────────────

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6B3E3E)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}

// ── Analysis option card ──────────────────────────────────────────────────────

class _AnalysisCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? statusText;
  final String subtitle;
  final String description;
  final bool isPrimary;
  final VoidCallback onTap;

  const _AnalysisCard({
    required this.icon,
    required this.title,
    this.statusText,
    required this.subtitle,
    required this.description,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<_AnalysisCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.97 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: r.w(widget.isPrimary ? 26 : 22),
            vertical: r.h(widget.isPrimary ? 28 : 22),
          ),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? const Color(0xFFFFFCF9)
                : const Color(0xFFFFFBF7),
            borderRadius: BorderRadius.circular(r.w(26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: widget.isPrimary ? 0.12 : 0.05),
                blurRadius: widget.isPrimary ? 26 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: r.w(56),
                height: r.w(56),
                decoration: BoxDecoration(
                  color: widget.isPrimary
                      ? const Color(0xFFEED3D6)
                      : const Color(0xFFF1ECE8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: r.w(28),
                  color: widget.isPrimary
                      ? const Color(0xFFD79096)
                      : const Color(0xFF9C8F87),
                ),
              ),
              SizedBox(width: r.w(18)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.lora(
                        fontSize: r.sp(19),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A2A22),
                        height: 1.2,
                      ),
                    ),
                    if (widget.statusText != null) ...[
                      SizedBox(height: r.h(6)),
                      Text(
                        widget.statusText!,
                        style: GoogleFonts.lora(
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD79096),
                        ),
                      ),
                    ],
                    SizedBox(height: r.h(6)),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.lora(
                        fontSize: r.sp(13),
                        color: const Color(0xFF8A7A72),
                      ),
                    ),
                    SizedBox(height: r.h(10)),
                    Text(
                      widget.description,
                      style: GoogleFonts.lora(
                        fontSize: r.sp(13),
                        height: 1.45,
                        color: const Color(0xFFA89B93),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: r.w(10)),
              Icon(
                Icons.arrow_forward_ios,
                size: r.w(18),
                color: const Color(0xFFB0A39A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
