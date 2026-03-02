import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'onboarding_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAlg92sDvJb8xmuMt8yA9MtjbWrHMWV1oY",
      authDomain: "youvai-56995.firebaseapp.com",
      projectId: "project-377693730311",
      // Corrected storage bucket format (use your Firebase Storage bucket)
      storageBucket: "youvai-56995.appspot.com",
      messagingSenderId: "377693730311",
      appId: "1:377693730311:web:24dfc047db461c18c3dca2",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _videoController;
  late final AnimationController _glowController;
  late final Animation<double> _glowPulse;
  bool _showGetStarted = false;
  bool _hasShownAtMidpoint = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowPulse = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    _videoController = VideoPlayerController.asset('assets/videos/intro.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..addListener(_onVideoProgress);

    _videoController.initialize().then((_) {
      if (!mounted) return;
      _videoController.play();
      setState(() {});
    });
  }

  void _onVideoProgress() {
    if (_hasShownAtMidpoint) return;

    final value = _videoController.value;
    if (!value.isInitialized) return;

    const revealAt = Duration(milliseconds: 2170);
    if (value.position >= revealAt && mounted) {
      _hasShownAtMidpoint = true;
      setState(() {
        _showGetStarted = true;
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _videoController
      ..removeListener(_onVideoProgress)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final screenAspect = w / h;
    final isSmallPhone = shortestSide < 360;
    final isTablet = shortestSide >= 600;

    final buttonWidth =
      (w * (isTablet ? 0.46 : (isSmallPhone ? 0.78 : 0.66))).clamp(200.0, 420.0);
    final buttonHeight =
      (h * (isTablet ? 0.07 : 0.072)).clamp(isSmallPhone ? 48.0 : 52.0, 74.0);
    final bottomOffset =
      (h * (isTablet ? 0.06 : 0.05)).clamp(14.0, 56.0);
    final sidePadding = (w * 0.08).clamp(14.0, 40.0);

    final isVideoReady = _videoController.value.isInitialized;
    final videoAspect = isVideoReady ? _videoController.value.aspectRatio : (16 / 9);
    final aspectDelta = (screenAspect - videoAspect).abs();
    final useContainForSafety = aspectDelta > 0.42;
    final adaptiveVideoFit = useContainForSafety ? BoxFit.contain : BoxFit.cover;

    return Scaffold(
      body: Stack(
        children: [
          // -------- VIDEO BACKGROUND (FULL SCREEN) --------
          Positioned.fill(
            child: ClipRect(
              child: isVideoReady
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF0F0A0A), Color(0xFF241618)],
                            ),
                          ),
                        ),
                        SizedBox.expand(
                          child: FittedBox(
                            fit: adaptiveVideoFit,
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: _videoController.value.size.width,
                              height: _videoController.value.size.height,
                              child: VideoPlayer(_videoController),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const ColoredBox(color: Colors.black),
            ),
          ),

          // -------- GET STARTED BUTTON (VISIBLE AFTER FIRST LOOP) --------
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomOffset,
            child: IgnorePointer(
              ignoring: !_showGetStarted,
              child: AnimatedOpacity(
                opacity: _showGetStarted ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sidePadding),
                  child: SafeArea(
                    top: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 520 : 460),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "See what your face reveals in seconds",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: (h * (isTablet ? 0.017 : 0.018))
                                  .clamp(isSmallPhone ? 13.0 : 14.0, 20.0),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: const Color(0xE6FFFFFF),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: (h * 0.010).clamp(6.0, 11.0)),
                          GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OnboardingFlow()),
                          );
                        },
                        child: AnimatedBuilder(
                          animation: _glowPulse,
                          builder: (context, child) {
                            final pulse = _glowPulse.value;
                            final glowScale = isSmallPhone ? 0.65 : (isTablet ? 0.9 : 1.0);
                            final glowOpacity = (0.16 + (0.20 * pulse)) * glowScale;
                            final glowBlur = (10.0 + (14.0 * pulse)) * glowScale;
                            final glowSpread = (0.6 + (2.0 * pulse)) * glowScale;

                            return Container(
                              width: buttonWidth,
                              height: buttonHeight,
                              decoration: BoxDecoration(
                                color: const Color(0x99FFFFFF),
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(
                                  color: const Color(0xCCA6553F),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF5C36A)
                                        .withOpacity(glowOpacity),
                                    blurRadius: glowBlur,
                                    spreadRadius: glowSpread,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Start Your Scan",
                                  style: GoogleFonts.montserrat(
                                    fontSize: (h * (isTablet ? 0.018 : 0.02))
                                        .clamp(isSmallPhone ? 14.0 : 15.0, 21.0),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.25,
                                    color: const Color(0xFF7A3F47),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_showGetStarted)
            Positioned(
              left: 0,
              right: 0,
              top: (h * 0.38).clamp(160.0, 320.0),
              child: Center(
                child: SizedBox(
                  width: (w * 0.97).clamp(isSmallPhone ? 320.0 : 340.0, isTablet ? 760.0 : 620.0),
                  height: (h * 0.26).clamp(isSmallPhone ? 170.0 : 190.0, isTablet ? 360.0 : 300.0),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),
              ),
            ),

          /*
          // -------- BACKGROUND IMAGE (FULL SCREEN) --------
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.6, 0.85, 1.0],
                  colors: [
                    Colors.white,
                    Colors.white,
                    Color.fromARGB(180, 255, 255, 255),
                    Color.fromARGB(40, 255, 255, 255),
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                "assets/images/download (40).jpeg",
                fit: BoxFit.cover,
                alignment: const Alignment(-0.15, 0),
              ),
            ),
          ),

          // -------- SOFT PINK OVERLAY --------
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.00, 0.24, 1.00],
                  colors: [
                    Color(0x00D79096),
                    Color(0x80D79096),
                    Color(0x1FE20000),
                  ],
                ),
              ),
            ),
          ),

          // -------- TEXT --------
          Positioned(
            top: h * 0.55,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Welcome To",
                  style: GoogleFonts.lora(
                    fontSize: h * 0.028,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: h * 0.01),
                Text(
                  "YOUV.AI",
                  style: GoogleFonts.lora(
                    fontSize: h * 0.045,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: h * 0.02),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                  child: Text(
                    "Embark on your skin-health journey, explore your unique features, and elevate aesthetic confidence with every insight",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: h * 0.018,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // -------- GET STARTED BUTTON --------
          Positioned(
            bottom: h * 0.1,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OnboardingFlow()),
                  );
                },
                child: Container(
                  width: w * 0.55,
                  height: h * 0.075,
                  decoration: BoxDecoration(
                    color: const Color(0x80ECA383),
                    borderRadius: BorderRadius.circular(36),
                    border:
                        Border.all(color: const Color(0xFFA6553F), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "Get Started",
                      style: GoogleFonts.lora(
                        fontSize: h * 0.028,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF510808),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          */
        ],
      ),
    );
  }
}
