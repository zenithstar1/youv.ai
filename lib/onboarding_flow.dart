import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_analysis_app/screens/image_capture_screen.dart';
import 'login_screens.dart';

class OnboardingFlow extends StatefulWidget {
  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late PageController controller;
  int currentPage = 0;

  final List<Widget> pages = [];

  @override
  void initState() {
    super.initState();

    controller = PageController();

    pages.addAll([
      SecondScreen(),
      ThirdScreen(),
      FourthScreen(),
      SecondScreen(), // duplicate for looping
    ]);

    controller.addListener(() {
      if (!controller.hasClients) return;
      setState(() {
        currentPage = controller.page!.round() % 3;
      });
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;

      int next = (controller.page ?? 0).round() + 1;

      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );

      if (next == 3) {
        await Future.delayed(const Duration(milliseconds: 360));
        controller.jumpToPage(0);
      }

      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: pages.map((page) {
          int index = pages.indexOf(page);
          return Wrapper(index: index % 3, child: page);
        }).toList(),
      ),
    );
  }
}

class Wrapper extends StatelessWidget {
  final int index;
  final Widget child;

  const Wrapper({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return child is HasBottomCard
        ? (child as HasBottomCard).withPageIndex(index)
        : child;
  }
}

abstract class HasBottomCard {
  Widget withPageIndex(int index);
}

// ======================================================
// SCREEN 1 — ATTRACTIVENESS INDEX
// ======================================================

class SecondScreen extends StatelessWidget implements HasBottomCard {
  @override
  Widget build(BuildContext context) => const SizedBox();

  @override
  Widget withPageIndex(int pageIndex) {
    return Builder(
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final h = size.height;

        return Stack(
          children: [
            Positioned(
              top: h * 0.10,
              left: 0,
              right: 0,
              child: Image.asset(
                "assets/images/face_grid.png",
                height: h * 0.42,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: h * 0.06,
              left: 0,
              right: 0,
              child: buildBottomCard(
                context,
                h,
                "Attractiveness Index",
                "Reveal your Aesthetic score with AI",
                "Get intelligent insights that help you understand your facial features and elevate your aesthetic confidence.",
                pageIndex,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ======================================================
// SCREEN 2 — CONSULTATION
// ======================================================

class ThirdScreen extends StatelessWidget implements HasBottomCard {
  @override
  Widget build(BuildContext context) => const SizedBox();

  @override
  Widget withPageIndex(int pageIndex) {
    return Builder(
      builder: (context) {
        final h = MediaQuery.of(context).size.height;

        return Stack(
          children: [
            Positioned(
              top: h * 0.10,
              left: 0,
              right: 0,
              child: Image.asset(
                "assets/images/consultation.png",
                height: h * 0.48,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: h * 0.06,
              left: 0,
              right: 0,
              child: buildBottomCard(
                context,
                h,
                "Expert Consultation",
                "Access premium aesthetic services",
                "Connect with experts for personalized guidance tailored to your skin and confidence goals.",
                pageIndex,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ======================================================
// SCREEN 3 — REPORT
// ======================================================

class FourthScreen extends StatelessWidget implements HasBottomCard {
  @override
  Widget build(BuildContext context) => const SizedBox();

  @override
  Widget withPageIndex(int pageIndex) {
    return Builder(
      builder: (context) {
        final h = MediaQuery.of(context).size.height;

        return Stack(
          children: [
            Positioned(
              top: h * 0.08,
              left: 0,
              right: 0,
              child: Image.asset(
                "assets/images/phone.png",
                height: h * 0.50,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: h * 0.06,
              left: 0,
              right: 0,
              child: buildBottomCard(
                context,
                h,
                "Personalized Report",
                "Receive your full analysis on WhatsApp",
                "Get a complete, easy-to-read report delivered instantly for your convenience.",
                pageIndex,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ======================================================
// SHARED BOTTOM CARD (Responsive Hybrid)
// ======================================================

Widget buildBottomCard(
  BuildContext context,
  double h,
  String title,
  String subtitle,
  String description,
  int pageIndex,
) {
  return Container(
    height: h * 0.45,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(40),
        topRight: Radius.circular(40),
      ),
      gradient: const LinearGradient(
        colors: [Color(0xFFD79096), Color(0xFFEEC8CC), Color(0x1FFFFFFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.lora(
            fontSize: 24,
            color: Colors.black,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 15),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                subtitle,
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: GoogleFonts.lora(fontSize: 14, height: 1.35),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            dot(isActive: pageIndex == 0),
            const SizedBox(width: 6),
            dot(isActive: pageIndex == 1),
            const SizedBox(width: 6),
            dot(isActive: pageIndex == 2),
          ],
        ),

        SizedBox(height: h * 0.05),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: ResponsiveButtons(),
        ),
      ],
    ),
  );
}

// ======================================================
// RESPONSIVE BUTTONS (Hybrid scaling)
// ======================================================

class ResponsiveButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final buttonWidth = size.width * 0.27;
    final buttonHeight = size.height * 0.047;
    final borderRadius = buttonHeight * 0.75;

    Widget buildButton(String label, {VoidCallback? onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: buttonWidth,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF1D9DB),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: const Color(0xFFD79096), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x6BA6553F),
                offset: Offset(0, 10),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF510808),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Opacity(opacity: 0, child: buildButton("SKIP")),
        buildButton(
          "CONTINUE",
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 200),
                pageBuilder: (_, __, ___) => ImageCaptureScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  final tween = Tween(
                    begin: Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeInOut));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ======================================================
// DOT
// ======================================================

Widget dot({required bool isActive}) {
  return AnimatedContainer(
    duration: Duration(milliseconds: 200),
    width: isActive ? 20 : 6,
    height: 6,
    decoration: BoxDecoration(
      color: isActive ? Color(0xFF510808) : Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(3),
    ),
  );
}
