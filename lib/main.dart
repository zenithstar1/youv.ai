import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
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
        ],
      ),
    );
  }
}
