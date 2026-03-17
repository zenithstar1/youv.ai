import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_analysis_app/screens/analysis_type_screen.dart';
import 'package:skin_analysis_app/screens/LoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_analysis_app/utils/responsive.dart';

class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PostIntroExplanationScreen();
  }
}

// ======================================================
// POST-INTRO EXPLANATION SCREEN
// ======================================================

class _PostIntroExplanationScreen extends StatefulWidget {
  const _PostIntroExplanationScreen();

  @override
  State<_PostIntroExplanationScreen> createState() =>
      _PostIntroExplanationScreenState();
}

class _PostIntroExplanationScreenState
    extends State<_PostIntroExplanationScreen> {
  @override
  void initState() {
    super.initState();
    // Warm image cache after first frame to reduce route-transition jank.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(
        const AssetImage('assets/images/face_outline.png'),
        context,
      );
    });
  }

  Future<void> _navigateToAnalysis() async {
    // Small delay to allow button tap ripple/effect to process visually (if any)
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final isLoggedIn = prefs.getBool('isLogin') ?? false;

    if (!isLoggedIn) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (!mounted) return;

      if (result == true) {
        _goToAnalysisType();
      }
    } else {
      _goToAnalysisType();
    }
  }

  void _goToAnalysisType() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 80),
        pageBuilder: (_, __, ___) => const AnalysisTypeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color lowMutedText = Color(0xFFA89B93);
    const Color headlineText = Color(0xFF3A2A22);
    const Color mutedText = Color(0xFF8A7A72);

    // Responsive scaling helper
    final r = Responsive(context);
    final size = MediaQuery.of(context).size;
    // Scales the image based on height, but keeps strict min/max bounds
    final imageHeight = (size.height * 0.30).clamp(180.0, 320.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F0EC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              // Responsive horizontal & vertical padding
              padding: EdgeInsets.symmetric(
                horizontal: r.w(24),
                vertical: r.h(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: r.h(14)),
                  Text(
                    'AI FACIAL ANALYSIS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: r.sp(12), // responsive font
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: lowMutedText,
                    ),
                  ),
                  SizedBox(height: r.h(12)),
                  Text(
                    'Understand what is happening beneath your skin',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: r.sp(24), // responsive headline
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: headlineText,
                    ),
                  ),
                  SizedBox(height: r.h(12)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.w(12)),
                    child: Text(
                      'Your personalized report includes clinically referenced skin indicators and facial proportion analysis.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: r.sp(13), // responsive body text
                        height: 1.4,
                        color: mutedText.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
                  SizedBox(height: r.h(24)),

                  // Replaced Animated Image with the optimized Static version
                  _StaticFaceImage(height: imageHeight),

                  SizedBox(height: r.h(24)),
                  const _OnboardingValueCard(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Skin Health Index',
                    description:
                        'A structured visual analysis of hydration, pigmentation, acne activity, pore visibility, and visible aging patterns',
                    hookLine:
                        'See where your skin stands today \u2014 and what may need attention.',
                    backgroundColor: null,
                    titleColor: Color(0xFFD79096),
                  ),
                  SizedBox(height: r.h(12)),
                  const _OnboardingValueCard(
                    icon: Icons.balance_outlined,
                    title: 'Facial Symmetry Mapping',
                    description:
                        'AI-based proportion analysis referencing established aesthetic models to assess overall facial balance.',
                    hookLine:
                        'Discover how your natural proportions compare to ideal structural ratios.',
                    backgroundColor: null,
                    titleColor: Color(0xFFD79096),
                  ),
                  SizedBox(height: r.h(24)),

                  // Simplified, static CTA Button with HitTestBehavior.opaque
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _navigateToAnalysis,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: r.h(16)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4B3B8),
                        borderRadius: BorderRadius.circular(r.w(40)),
                        border: Border.all(
                          color: const Color(0xFFE0B5BA),
                          width: 0.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD79096,
                            ).withValues(alpha: 0.10),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                          const BoxShadow(
                            color: Color(0x14A6553F),
                            offset: Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ],
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF2D5D8), Color(0xFFEAC0C5)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Create My Analysis Profile',
                          style: GoogleFonts.lora(
                            fontSize: r.sp(15), // responsive button text
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: const Color(0xFF7A3030),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: r.h(16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// STATIC FACE IMAGE — Optimized, non-animated mesh
// ======================================================

class _StaticFaceImage extends StatelessWidget {
  const _StaticFaceImage({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final double frameW = height * 0.78;

    return SizedBox(
      height: height,
      width: frameW + 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/face_outline.png',
            height: height * 0.92,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.low,
          ),
          Positioned.fill(
            // RepaintBoundary caches the drawing so scrolling stays smooth
            child: RepaintBoundary(
              child: CustomPaint(painter: const _FaceMeshPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceMeshPainter extends CustomPainter {
  const _FaceMeshPainter();

  static const Color _lineHighlightColor = Color(0xFFF7CDD8);

  // All vertex positions as [relX, relY] within the painted area.
  static const List<List<double>> _v = [
    [0.50, 0.06], // 0
    [0.36, 0.10], [0.50, 0.10], [0.64, 0.10], // 1, 2, 3
    [0.26, 0.16],
    [0.38, 0.15],
    [0.50, 0.15],
    [0.62, 0.15],
    [0.74, 0.16], // 4 - 8
    [0.22, 0.22],
    [0.33, 0.21],
    [0.42, 0.21],
    [0.50, 0.20],
    [0.58, 0.21],
    [0.67, 0.21],
    [0.78, 0.22], // 9 - 15
    [0.18, 0.29],
    [0.28, 0.28],
    [0.35, 0.27],
    [0.41, 0.28],
    [0.50, 0.28],
    [0.59, 0.28],
    [0.65, 0.27],
    [0.72, 0.28],
    [0.82, 0.29], // 16 - 24
    [0.17, 0.35],
    [0.28, 0.33],
    [0.35, 0.32],
    [0.42, 0.33],
    [0.50, 0.34],
    [0.58, 0.33],
    [0.65, 0.32],
    [0.72, 0.33],
    [0.83, 0.35], // 25 - 33
    [0.18, 0.42],
    [0.30, 0.40],
    [0.42, 0.40],
    [0.50, 0.41],
    [0.58, 0.40],
    [0.70, 0.40],
    [0.82, 0.42], // 34 - 40
    [0.20, 0.49],
    [0.32, 0.47],
    [0.42, 0.46],
    [0.50, 0.48],
    [0.58, 0.46],
    [0.68, 0.47],
    [0.80, 0.49], // 41 - 47
    [0.22, 0.56],
    [0.34, 0.54],
    [0.42, 0.53],
    [0.50, 0.52],
    [0.58, 0.53],
    [0.66, 0.54],
    [0.78, 0.56], // 48 - 54
    [0.24, 0.62],
    [0.36, 0.60],
    [0.43, 0.58],
    [0.50, 0.57],
    [0.57, 0.58],
    [0.64, 0.60],
    [0.76, 0.62], // 55 - 61
    [0.26, 0.68],
    [0.37, 0.66],
    [0.44, 0.64],
    [0.50, 0.65],
    [0.56, 0.64],
    [0.63, 0.66],
    [0.74, 0.68], // 62 - 68
    [0.30, 0.74],
    [0.40, 0.72],
    [0.50, 0.73],
    [0.60, 0.72],
    [0.70, 0.74], // 69 - 73
    [0.35, 0.80], [0.50, 0.80], [0.65, 0.80], // 74 - 76
    [0.42, 0.86], [0.50, 0.87], [0.58, 0.86], // 77 - 79
  ];

  static const List<List<int>> _edges = [
    [0, 1],
    [0, 2],
    [0, 3],
    [1, 2],
    [2, 3],
    [1, 4],
    [1, 5],
    [2, 5],
    [2, 6],
    [2, 7],
    [3, 7],
    [3, 8],
    [4, 5],
    [5, 6],
    [6, 7],
    [7, 8],
    [4, 9],
    [4, 10],
    [5, 10],
    [5, 11],
    [6, 11],
    [6, 12],
    [6, 13],
    [7, 13],
    [7, 14],
    [8, 14],
    [8, 15],
    [9, 10],
    [10, 11],
    [11, 12],
    [12, 13],
    [13, 14],
    [14, 15],
    [9, 16],
    [9, 17],
    [10, 17],
    [10, 18],
    [11, 18],
    [11, 19],
    [12, 19],
    [12, 20],
    [13, 20],
    [13, 21],
    [14, 21],
    [14, 22],
    [15, 22],
    [15, 23],
    [15, 24],
    [16, 17],
    [17, 18],
    [18, 19],
    [19, 20],
    [20, 21],
    [21, 22],
    [22, 23],
    [23, 24],
    [16, 25],
    [16, 26],
    [17, 26],
    [17, 27],
    [18, 27],
    [18, 28],
    [19, 28],
    [19, 29],
    [20, 29],
    [21, 29],
    [21, 30],
    [22, 30],
    [22, 31],
    [23, 31],
    [23, 32],
    [24, 32],
    [24, 33],
    [25, 26],
    [26, 27],
    [27, 28],
    [28, 29],
    [29, 30],
    [30, 31],
    [31, 32],
    [32, 33],
    [25, 34],
    [25, 35],
    [26, 35],
    [27, 35],
    [27, 36],
    [28, 36],
    [29, 36],
    [29, 37],
    [29, 38],
    [30, 38],
    [31, 38],
    [31, 39],
    [32, 39],
    [33, 39],
    [33, 40],
    [34, 35],
    [35, 36],
    [36, 37],
    [37, 38],
    [38, 39],
    [39, 40],
    [34, 41],
    [34, 42],
    [35, 42],
    [36, 42],
    [36, 43],
    [37, 43],
    [37, 44],
    [37, 45],
    [38, 45],
    [38, 46],
    [39, 46],
    [40, 46],
    [40, 47],
    [41, 42],
    [42, 43],
    [43, 44],
    [44, 45],
    [45, 46],
    [46, 47],
    [41, 48],
    [41, 49],
    [42, 49],
    [43, 49],
    [43, 50],
    [44, 50],
    [44, 51],
    [44, 52],
    [45, 52],
    [45, 53],
    [46, 53],
    [47, 53],
    [47, 54],
    [48, 49],
    [49, 50],
    [50, 51],
    [51, 52],
    [52, 53],
    [53, 54],
    [48, 55],
    [48, 56],
    [49, 56],
    [50, 56],
    [50, 57],
    [51, 57],
    [51, 58],
    [51, 59],
    [52, 59],
    [52, 60],
    [53, 60],
    [54, 60],
    [54, 61],
    [55, 56],
    [56, 57],
    [57, 58],
    [58, 59],
    [59, 60],
    [60, 61],
    [55, 62],
    [55, 63],
    [56, 63],
    [57, 63],
    [57, 64],
    [58, 64],
    [58, 65],
    [58, 66],
    [59, 66],
    [59, 67],
    [60, 67],
    [61, 67],
    [61, 68],
    [62, 63],
    [63, 64],
    [64, 65],
    [65, 66],
    [66, 67],
    [67, 68],
    [62, 69],
    [63, 69],
    [63, 70],
    [64, 70],
    [65, 70],
    [65, 71],
    [65, 72],
    [66, 72],
    [67, 72],
    [67, 73],
    [68, 73],
    [69, 70],
    [70, 71],
    [71, 72],
    [72, 73],
    [69, 74],
    [70, 74],
    [70, 75],
    [71, 75],
    [72, 75],
    [72, 76],
    [73, 76],
    [74, 75],
    [75, 76],
    [74, 77],
    [75, 77],
    [75, 78],
    [75, 79],
    [76, 79],
    [77, 78],
    [78, 79],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final points = _v
        .map((v) => Offset(v[0] * w, v[1] * h))
        .toList(growable: false);

    final faceClip = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.47),
          width: w * 0.60,
          height: h * 0.82,
        ),
      );

    canvas.save();
    canvas.clipPath(faceClip);

    // Single fast paint pass, no blurs or calculations
    final paint = Paint()
      ..color = _lineHighlightColor.withValues(alpha: 0.40)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final edge in _edges) {
      canvas.drawLine(points[edge[0]], points[edge[1]], paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FaceMeshPainter oldDelegate) => false;
}

// ======================================================
// VALUE CARD — soft tinted background, rounded, no border
// ======================================================

class _OnboardingValueCard extends StatelessWidget {
  const _OnboardingValueCard({
    required this.icon,
    required this.title,
    required this.description,
    this.hookLine,
    this.backgroundColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? hookLine;
  final Color? backgroundColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    const Color descColor = Color(0xFF8A7A72);
    const Color iconColor = Color(0xFF8A7A72);
    // Responsive scaling for card internals
    final r = Responsive(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(12)),
      decoration: BoxDecoration(
        color:
            backgroundColor ?? const Color(0xFFD79096).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(r.w(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: r.w(18), color: iconColor),
          ),
          SizedBox(width: r.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lora(
                    fontSize: r.sp(14), // responsive card title
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? const Color(0xFF3A2A22),
                  ),
                ),
                SizedBox(height: r.h(3)),
                Text(
                  description,
                  style: GoogleFonts.lora(
                    fontSize: r.sp(12), // responsive card description
                    height: 1.4,
                    color: descColor,
                  ),
                ),
                if (hookLine != null) ...[
                  SizedBox(height: r.h(6)),
                  Text(
                    hookLine!,
                    style: GoogleFonts.lora(
                      fontSize: r.sp(11.5), // responsive hook text
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                      color: const Color(0xFFA89B93),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
