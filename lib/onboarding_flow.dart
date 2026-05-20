import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_analysis_app/screens/analysis_type_screen.dart';
import 'package:skin_analysis_app/screens/LoginPage.dart';
import 'package:skin_analysis_app/screens/already_login_screen.dart';
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

class _PostIntroExplanationScreenState extends State<_PostIntroExplanationScreen> {
  @override
  void initState() {
    super.initState();
    // Warm image cache after first frame to reduce route-transition jank.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(const AssetImage('assets/images/face_animation.gif'), context);
    });
  }

  Future<void> _navigateToAnalysis() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final isLoggedIn = prefs.getBool('isLogin') ?? false;
    final hasRegistered = prefs.getBool('hasRegistered') ?? false;

    if (isLoggedIn) {
      // Session still active — skip login entirely.
      _goToAnalysisType();
    } else if (hasRegistered) {
      // User has registered before but session expired — go straight to OTP.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AlreadyLoginScreen()),
      );
    } else {
      // Brand-new user — show the sign-up / create account flow.
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (!mounted) return;
      if (result == true) {
        _goToAnalysisType();
      }
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

    final r = Responsive(context);
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final safeHeight = size.height - mq.padding.vertical;

    // Compact vertical spacing on short screens to reduce scrolling without
    // changing element ordering or structure.
    final verticalCompact = (safeHeight / 812.0).clamp(0.70, 1.0);
    double vh(double v) => r.h(v) * verticalCompact;

    // Scales the image based on safe height, but keeps strict min/max bounds.
    final imageHeight = (safeHeight * 0.30).clamp(160.0, 320.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F0EC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: r.w(24),
                vertical: vh(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: vh(14)),
                  Text(
                    'AI FACIAL ANALYSIS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: r.sp(12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: lowMutedText,
                    ),
                  ),
                  SizedBox(height: vh(12)),
                  Text(
                    'Understand what is happening beneath your skin',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: r.sp(24),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: headlineText,
                    ),
                  ),
                  SizedBox(height: vh(12)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.w(12)),
                    child: Text(
                      'Your personalized report includes clinically referenced skin indicators and facial proportion analysis.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: r.sp(13),
                        height: 1.4,
                        color: mutedText.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
                  SizedBox(height: vh(24)),
                   
                  // Replaced Animated Image with the optimized Static version
                  _FaceAnimationGif(height: imageHeight),
                   
                  SizedBox(height: vh(24)),
                  const _OnboardingValueCard(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Skin Health Index',
                    description:
                        // 'A structured visual analysis of hydration, pigmentation, acne activity, pore visibility, and visible aging patterns',
                        'See where your skin stands today \u2014 and what may need attention.',
                    // hookLine:
                    //     'See where your skin stands today \u2014 and what may need attention.',
                    backgroundColor: null,
                    titleColor: Color(0xFFD79096),
                  ),
                  SizedBox(height: vh(12)),
                  const _OnboardingValueCard(
                    icon: Icons.balance_outlined,
                    title: 'Facial Symmetry Mapping',
                    description:
                        // 'AI-based proportion analysis referencing established aesthetic models to assess overall facial balance.',
                        'Discover how your natural proportions compare to ideal structural ratios.',
                        
                    // hookLine:
                    //     'Discover how your natural proportions compare to ideal structural ratios.',
                    backgroundColor: null,
                    titleColor: Color(0xFFD79096),
                  ),
                  SizedBox(height: vh(24)),
                   
                  // Simplified, static CTA Button with HitTestBehavior.opaque
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _navigateToAnalysis,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: vh(16)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4B3B8),
                        borderRadius: BorderRadius.circular(r.w(40)),
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
                            fontSize: r.sp(15),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: const Color(0xFF7A3030),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: vh(16)),
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
// FACE ANIMATION — GIF (pre-rendered)
// ======================================================

class _FaceAnimationGif extends StatelessWidget {
  const _FaceAnimationGif({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final double frameW = height * 0.78;

    return SizedBox(
      height: height,
      width: frameW + 32,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // smooth edges
          child: Container(
            color: const Color(0xFFF9F0EC), // same as screen bg
            padding: const EdgeInsets.all(8), // space for blending
            child: Image.asset(
              'assets/images/face_animation.gif',
              height: height * 0.9,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
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
    final r = Responsive(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(12)),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFD79096).withValues(alpha: 0.06),
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
                    fontSize: r.sp(14),
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? const Color(0xFF3A2A22),
                  ),
                ),
                SizedBox(height: r.h(3)),
                Text(
                  description,
                  style: GoogleFonts.lora(
                    fontSize: r.sp(12),
                    height: 1.4,
                    color: descColor,
                  ),
                ),
                if (hookLine != null) ...[
                  SizedBox(height: r.h(6)),
                  Text(
                    hookLine!,
                    style: GoogleFonts.lora(
                      fontSize: r.sp(11.5),
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
