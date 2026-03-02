import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_analysis_app/screens/analysis_type_screen.dart';
import 'package:skin_analysis_app/screens/LoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _PostIntroExplanationScreenState extends State<_PostIntroExplanationScreen> {
  bool _ctaPressed = false;

  @override
  void initState() {
    super.initState();
    // Warm image cache after first frame to reduce route-transition jank.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(const AssetImage('assets/images/face_outline.png'), context);
    });
  }

  Future<void> _navigateToAnalysis() async {

  setState(() => _ctaPressed = false);

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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F0EC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final compactScale =
                (availableHeight / 820.0).clamp(0.78, 1.0).toDouble();
            final imageHeight = (availableHeight * 0.30).clamp(180.0, 320.0);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24 * compactScale,
                vertical: 20 * compactScale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 14 * compactScale),
                  Text(
                    'AI FACIAL ANALYSIS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 11 * compactScale,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: lowMutedText,
                    ),
                  ),
                  SizedBox(height: 12 * compactScale),
                  Text(
                    'Understand what is happening beneath your skin',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 24 * compactScale,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: headlineText,
                    ),
                  ),
                  SizedBox(height: 10 * compactScale),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12 * compactScale),
                    child: Text(
                      'Your personalized report includes clinically referenced skin indicators and facial proportion analysis.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 12.5 * compactScale,
                        height: 1.4,
                        color: mutedText.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * compactScale),
                  _AnimatedFaceImage(
                    height: imageHeight,
                  ),
                  SizedBox(height: 16 * compactScale),
                  _OnboardingValueCard(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Skin Health Index',
                    description:
                        'A structured visual analysis of hydration, pigmentation, acne activity, pore visibility, and visible aging patterns',
                    hookLine:
                        'See where your skin stands today \u2014 and what may need attention.',
                    backgroundColor: null,
                    titleColor: const Color(0xFFD79096),
                  ),
                  SizedBox(height: 10 * compactScale),
                  _OnboardingValueCard(
                    icon: Icons.balance_outlined,
                    title: 'Facial Symmetry Mapping',
                    description:
                        'AI-based proportion analysis referencing established aesthetic models to assess overall facial balance.',
                    hookLine:
                        'Discover how your natural proportions compare to ideal structural ratios.',
                    backgroundColor: null,
                    titleColor: const Color(0xFFD79096),
                  ),
                  SizedBox(height: 16 * compactScale),
                  GestureDetector(
                    onTapDown: (_) => setState(() => _ctaPressed = true),
                    onTapUp: (_) {
                      setState(() => _ctaPressed = false);
                      _navigateToAnalysis();
                    },
                    onTapCancel: () => setState(() => _ctaPressed = false),
                    child: AnimatedScale(
                      scale: _ctaPressed ? 0.96 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: 12 * compactScale,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4B3B8),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: const Color(0xFFE0B5BA),
                            width: 0.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD79096).withValues(alpha: 0.10),
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
                            colors: [
                              Color(0xFFF2D5D8),
                              Color(0xFFEAC0C5),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Create My Analysis Profile',
                            style: GoogleFonts.lora(
                              fontSize: 15 * compactScale,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: const Color(0xFF7A3030),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * compactScale),
                  // ...existing code for secondary link...
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ======================================================
// ANIMATED FACE IMAGE — triangulated face mesh overlay
// ======================================================

class _AnimatedFaceImage extends StatefulWidget {
  const _AnimatedFaceImage({
    required this.height,
  });

  final double height;

  @override
  State<_AnimatedFaceImage> createState() => _AnimatedFaceImageState();
}

class _AnimatedFaceImageState extends State<_AnimatedFaceImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _glowController.repeat(reverse: true);
      }
    });
    _glowAnim = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double frameW = widget.height * 0.78;
    final image = Image.asset(
      'assets/images/face_outline.png',
      height: widget.height * 0.92,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.low,
    );

    return AnimatedBuilder(
      animation: _glowAnim,
      child: image,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          width: frameW + 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              child!,
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _FaceMeshPainter(glowValue: _glowAnim.value),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FaceMeshPainter extends CustomPainter {
  const _FaceMeshPainter({required this.glowValue});

  final double glowValue;

  static const Color _lineColor = Color(0xFFDDA4B4);
  static const Color _lineHighlightColor = Color(0xFFF7CDD8);
  static const Color _glowColor = Color(0xFFF3B8C8);

  // All vertex positions as [relX, relY] within the painted area.
  // Coordinates: 0.5 = center X, 0.0 = top, 1.0 = bottom.
  static const List<List<double>> _v = [
    // Row 0: Crown (top of head)
    [0.50, 0.06], // 0

    // Row 1: Upper forehead
    [0.36, 0.10], // 1
    [0.50, 0.10], // 2
    [0.64, 0.10], // 3

    // Row 2: Mid forehead
    [0.26, 0.16], // 4
    [0.38, 0.15], // 5
    [0.50, 0.15], // 6
    [0.62, 0.15], // 7
    [0.74, 0.16], // 8

    // Row 3: Lower forehead / brow
    [0.22, 0.22], // 9
    [0.33, 0.21], // 10
    [0.42, 0.21], // 11
    [0.50, 0.20], // 12
    [0.58, 0.21], // 13
    [0.67, 0.21], // 14
    [0.78, 0.22], // 15

    // Row 4: Eyes level
    [0.18, 0.29], // 16 - left temple
    [0.28, 0.28], // 17 - left eye outer
    [0.35, 0.27], // 18 - left eye top
    [0.41, 0.28], // 19 - left eye inner
    [0.50, 0.28], // 20 - between eyes
    [0.59, 0.28], // 21 - right eye inner
    [0.65, 0.27], // 22 - right eye top
    [0.72, 0.28], // 23 - right eye outer
    [0.82, 0.29], // 24 - right temple

    // Row 5: Below eyes
    [0.17, 0.35], // 25
    [0.28, 0.33], // 26 - left eye bottom outer
    [0.35, 0.32], // 27 - left eye bottom
    [0.42, 0.33], // 28 - left eye bottom inner
    [0.50, 0.34], // 29 - nose bridge
    [0.58, 0.33], // 30 - right eye bottom inner
    [0.65, 0.32], // 31 - right eye bottom
    [0.72, 0.33], // 32 - right eye bottom outer
    [0.83, 0.35], // 33

    // Row 6: Nose / upper cheeks
    [0.18, 0.42], // 34
    [0.30, 0.40], // 35 - left cheek upper
    [0.42, 0.40], // 36
    [0.50, 0.41], // 37 - nose mid
    [0.58, 0.40], // 38
    [0.70, 0.40], // 39 - right cheek upper
    [0.82, 0.42], // 40

    // Row 7: Nose tip / mid cheeks
    [0.20, 0.49], // 41
    [0.32, 0.47], // 42
    [0.42, 0.46], // 43 - left nostril
    [0.50, 0.48], // 44 - nose tip
    [0.58, 0.46], // 45 - right nostril
    [0.68, 0.47], // 46
    [0.80, 0.49], // 47

    // Row 8: Upper lip / lower cheeks
    [0.22, 0.56], // 48
    [0.34, 0.54], // 49
    [0.42, 0.53], // 50 - left mouth area
    [0.50, 0.52], // 51 - upper lip center
    [0.58, 0.53], // 52 - right mouth area
    [0.66, 0.54], // 53
    [0.78, 0.56], // 54

    // Row 9: Mouth
    [0.24, 0.62], // 55
    [0.36, 0.60], // 56 - left mouth corner
    [0.43, 0.58], // 57 - upper lip left
    [0.50, 0.57], // 58 - upper lip center
    [0.57, 0.58], // 59 - upper lip right
    [0.64, 0.60], // 60 - right mouth corner
    [0.76, 0.62], // 61

    // Row 10: Below mouth / lower lip
    [0.26, 0.68], // 62
    [0.37, 0.66], // 63
    [0.44, 0.64], // 64 - lower lip left
    [0.50, 0.65], // 65 - lower lip center
    [0.56, 0.64], // 66 - lower lip right
    [0.63, 0.66], // 67
    [0.74, 0.68], // 68

    // Row 11: Jaw
    [0.30, 0.74], // 69
    [0.40, 0.72], // 70
    [0.50, 0.73], // 71 - chin upper
    [0.60, 0.72], // 72
    [0.70, 0.74], // 73

    // Row 12: Lower jaw
    [0.35, 0.80], // 74
    [0.50, 0.80], // 75 - chin mid
    [0.65, 0.80], // 76

    // Row 13: Chin
    [0.42, 0.86], // 77
    [0.50, 0.87], // 78 - chin tip
    [0.58, 0.86], // 79
  ];

  // Edge connections [from, to] forming triangulated mesh
  static const List<List<int>> _edges = [
    // Crown to upper forehead
    [0, 1], [0, 2], [0, 3],
    // Upper forehead horizontal + down
    [1, 2], [2, 3],
    [1, 4], [1, 5], [2, 5], [2, 6], [2, 7], [3, 7], [3, 8],
    // Mid forehead
    [4, 5], [5, 6], [6, 7], [7, 8],
    [4, 9], [4, 10], [5, 10], [5, 11], [6, 11], [6, 12], [6, 13],
    [7, 13], [7, 14], [8, 14], [8, 15],
    // Lower forehead
    [9, 10], [10, 11], [11, 12], [12, 13], [13, 14], [14, 15],
    [9, 16], [9, 17], [10, 17], [10, 18], [11, 18], [11, 19],
    [12, 19], [12, 20], [13, 20], [13, 21], [14, 21], [14, 22],
    [15, 22], [15, 23], [15, 24],
    // Eyes row
    [16, 17], [17, 18], [18, 19], [19, 20], [20, 21], [21, 22],
    [22, 23], [23, 24],
    // Eyes to below-eyes
    [16, 25], [16, 26], [17, 26], [17, 27], [18, 27], [18, 28],
    [19, 28], [19, 29], [20, 29], [21, 29], [21, 30], [22, 30],
    [22, 31], [23, 31], [23, 32], [24, 32], [24, 33],
    // Below eyes
    [25, 26], [26, 27], [27, 28], [28, 29], [29, 30], [30, 31],
    [31, 32], [32, 33],
    // Below-eyes to nose/cheeks
    [25, 34], [25, 35], [26, 35], [27, 35], [27, 36], [28, 36],
    [29, 36], [29, 37], [29, 38], [30, 38], [31, 38], [31, 39],
    [32, 39], [33, 39], [33, 40],
    // Nose/cheeks
    [34, 35], [35, 36], [36, 37], [37, 38], [38, 39], [39, 40],
    // Nose/cheeks to nose-tip row
    [34, 41], [34, 42], [35, 42], [36, 42], [36, 43], [37, 43],
    [37, 44], [37, 45], [38, 45], [38, 46], [39, 46], [40, 46],
    [40, 47],
    // Nose tip row
    [41, 42], [42, 43], [43, 44], [44, 45], [45, 46], [46, 47],
    // To upper lip row
    [41, 48], [41, 49], [42, 49], [43, 49], [43, 50], [44, 50],
    [44, 51], [44, 52], [45, 52], [45, 53], [46, 53], [47, 53],
    [47, 54],
    // Upper lip row
    [48, 49], [49, 50], [50, 51], [51, 52], [52, 53], [53, 54],
    // To mouth row
    [48, 55], [48, 56], [49, 56], [50, 56], [50, 57], [51, 57],
    [51, 58], [51, 59], [52, 59], [52, 60], [53, 60], [54, 60],
    [54, 61],
    // Mouth row
    [55, 56], [56, 57], [57, 58], [58, 59], [59, 60], [60, 61],
    // To below mouth
    [55, 62], [55, 63], [56, 63], [57, 63], [57, 64], [58, 64],
    [58, 65], [58, 66], [59, 66], [59, 67], [60, 67], [61, 67],
    [61, 68],
    // Below mouth row
    [62, 63], [63, 64], [64, 65], [65, 66], [66, 67], [67, 68],
    // To jaw
    [62, 69], [63, 69], [63, 70], [64, 70], [65, 70], [65, 71],
    [65, 72], [66, 72], [67, 72], [67, 73], [68, 73],
    // Jaw
    [69, 70], [70, 71], [71, 72], [72, 73],
    // To lower jaw
    [69, 74], [70, 74], [70, 75], [71, 75], [72, 75], [72, 76],
    [73, 76],
    // Lower jaw
    [74, 75], [75, 76],
    // To chin
    [74, 77], [75, 77], [75, 78], [75, 79], [76, 79],
    // Chin
    [77, 78], [78, 79],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final points = _v
        .map((v) => Offset(v[0] * w, v[1] * h))
        .toList(growable: false);

    // Uniform glow across full mesh so whole net lights up together.
    final glowProximity = List<double>.filled(points.length, 1.0);

    // Keep mesh strictly over face region.
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
    _drawEdges(canvas, points, glowProximity);
    canvas.restore();
  }

  void _drawEdges(Canvas canvas, List<Offset> points, List<double> glowProximity) {
    for (final edge in _edges) {
      final a = edge[0];
      final b = edge[1];
      final proximity = (glowProximity[a] + glowProximity[b]) / 2.0;

      final baseAlpha = 0.20 + (0.14 * glowValue);
      final highlightBoost = proximity * (0.18 + 0.10 * glowValue);
      final alpha = (baseAlpha + highlightBoost).clamp(0.0, 1.0);

      final color = Color.lerp(_lineColor, _lineHighlightColor, proximity)!;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..strokeWidth = 0.75 + proximity * 0.9
        ..style = PaintingStyle.stroke;

      final glowEdgePaint = Paint()
        ..color = _glowColor.withValues(
          alpha: (0.06 + 0.10 * glowValue).clamp(0.0, 1.0),
        )
        ..strokeWidth = 1.6 + 0.5 * glowValue
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
      canvas.drawLine(points[a], points[b], glowEdgePaint);

      canvas.drawLine(points[a], points[b], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FaceMeshPainter oldDelegate) {
    return oldDelegate.glowValue != glowValue;
  }
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFD79096).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? const Color(0xFF3A2A22),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.lora(
                    fontSize: 11,
                    height: 1.4,
                    color: descColor,
                  ),
                ),
                if (hookLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    hookLine!,
                    style: GoogleFonts.lora(
                      fontSize: 10.5,
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




