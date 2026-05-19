import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:skin_analysis_app/Api/Apiservice.dart';
import 'skin_analysis_redesigned.dart';
import '../Models/hair_analysis_model.dart' as hair;
import 'hair_api_service.dart';
import 'hair_result_screen.dart';
import 'package:skin_analysis_app/models/skin_analysis_model.dart';
import 'enhanced_camera_screen.dart';
import 'standard_camera_screen.dart';

class ImagePreviewScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String fileName;
  final bool isHair;

  const ImagePreviewScreen({
    super.key,
    required this.imageBytes,
    required this.fileName,
    this.isHair = false,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  bool _isAnalyzing = false;
  int _currentMessageIndex = 0;
  Timer? _messageTimer;
  Timer? _retakeOpacityTimer;
  bool _primaryPressed = false;
  bool _retakeDimmed = false;

  late final List<String> _loadingMessages;

  final List<String> _skinLoadingMessages = [
    "ANALYZING YOUR UNIQUE\nFACIAL FEATURES...",
    "CALCULATING SKIN HEALTH\nINDICATORS...",
    "PROCESSING FACIAL SYMMETRY...",
    "COMPUTING GOLDEN RATIOS...",
  ];

  final List<String> _hairLoadingMessages = [
    "ANALYZING SCALP HEALTH...",
    "DETECTING HAIR DENSITY...",
    "MEASURING THINNING PATTERNS...",
    "EVALUATING ROOT VISIBILITY...",
  ];

  @override
  void initState() {
    super.initState();

    _loadingMessages = widget.isHair
        ? _hairLoadingMessages
        : _skinLoadingMessages;
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _retakeOpacityTimer?.cancel();
    super.dispose();
  }

  // =================== FIREBASE UPLOAD ===================
  Future<String> _uploadImageToFirebase(Uint8List bytes, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return '';
    }

    final ref = FirebaseStorage.instance.ref().child(
      "user_images/${user.uid}/$type.jpg",
    );

    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  // =================== SAVE BEFORE/AFTER ===================
  Future<void> _saveBeforeAfterImage(String imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection("users_analysis")
        .doc(user.uid);

    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        "beforeImageUrl": imageUrl,
        "beforeTimestamp": DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await docRef.update({
        "afterImageUrl": imageUrl,
        "afterTimestamp": DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // =================== MAIN ANALYSIS ===================
  Future<void> _sendForAnalysis() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _currentMessageIndex = 0;
    });

    _startMessageCycling();

    try {
      // ---- HAIR FLOW ----
      if (widget.isHair) {
        final hairResponse = await HairApiService.analyzeHair(
          imageBytes: widget.imageBytes,
          fileName: widget.fileName,
        );

        final hairAnalysis = hair.HairAnalysisModel.fromJson(hairResponse);

        _uploadImageToFirebase(widget.imageBytes, 'latest_scan')
            .then((url) => _saveBeforeAfterImage(url))
            .catchError((e) => print('Background upload failed: $e'));

        _messageTimer?.cancel();
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HairResultScreen(analysis: hairAnalysis),
          ),
        );
        return;
      }

      // ---- SKIN FLOW ----
      final apiService = ApiService();
      final result = await apiService.analyzeSkinWithImageBytes(
        widget.imageBytes,
        widget.fileName,
      );

      final SkinAnalysisModel skinAnalysisData = result.analysis;
      final Map<String, dynamic>? symmetryData = result.symmetryData;

      _uploadImageToFirebase(widget.imageBytes, 'latest_scan')
          .then((url) => _saveBeforeAfterImage(url))
          .catchError((e) => print('Background upload failed: $e'));

      _messageTimer?.cancel();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SkinAnalysisRedesigned(
            analysisData: skinAnalysisData,
            imageBytes: widget.imageBytes,
            faceRatioJson: symmetryData,
          ),
        ),
      );
    } catch (e) {
      _messageTimer?.cancel();
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
      _showErrorDialog(e.toString());
    }
  }

  void _retakePhoto() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.isHair
            ? EnhancedCameraScreen(
                isHair: widget.isHair,
                onImageCaptured: (_, __) {},
              )
            : const StandardCameraScreen(
                lensDirection: CameraLensDirection.front,
                isHair: false,
              ),
      ),
    );
  }

  void _startMessageCycling() {
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Analysis Failed"),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendForAnalysis();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for edge-to-edge feel
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full Screen Image
          Image.memory(
            widget.imageBytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // 2. Conditional UI Layout
          if (_isAnalyzing)
            _buildAnalyzingOverlay()
          else
            _buildBottomControls(),
        ],
      ),
    );
  }

  // =================== UI WIDGETS ===================

  Widget _buildAnalyzingOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isHair
                              ? Colors.amber.shade300
                              : Colors.pink.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analyzing',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: Text(
                              _loadingMessages[_currentMessageIndex],
                              key: ValueKey<int>(_currentMessageIndex),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: widget.isHair
                                    ? Colors.amber.shade300
                                    : Colors.pink.shade200,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isHair
                          ? Colors.amber.shade300
                          : Colors.pink.shade300,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This analysis reflects visible features at the time of capture and is intended for awareness and education.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final h = MediaQuery.sizeOf(context).height;
    final imageToMicro = (h * 0.045).clamp(18.0, 34.0);
    final microToButton = (h * 0.025).clamp(12.0, 24.0);
    final buttonToRetake = (h * 0.018).clamp(12.0, 16.0);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: imageToMicro),
                  Text(
                    'Analyzed across 25+ skin parameters',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  SizedBox(height: microToButton),
                  _buildPrimaryButton(),
                  SizedBox(height: buttonToRetake),
                  _buildRetakeAction(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final boxShadow = [
      BoxShadow(
        color: const Color.fromRGBO(
          228,
          179,
          184,
          1,
        ).withValues(alpha: _primaryPressed ? 0.22 : 0.35),
        blurRadius: _primaryPressed ? 16 : 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: _primaryPressed ? 0.05 : 0.08),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];

    return GestureDetector(
      onTap: _sendForAnalysis,
      onTapDown: (_) => setState(() => _primaryPressed = true),
      onTapCancel: () => setState(() => _primaryPressed = false),
      onTapUp: (_) => setState(() => _primaryPressed = false),
      child: AnimatedScale(
        scale: _primaryPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 54,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFFE4B3B8), Color(0xFFD89AA1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: boxShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Analyze My Skin',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetakeAction() {
    return GestureDetector(
      onTap: () {
        _retakeOpacityTimer?.cancel();
        setState(() => _retakeDimmed = true);
        _retakeOpacityTimer = Timer(const Duration(milliseconds: 120), () {
          if (!mounted) return;
          setState(() => _retakeDimmed = false);
        });
        _retakePhoto();
      },
      child: AnimatedOpacity(
        opacity: _retakeDimmed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12), // 🔥 glass effect
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.refresh, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Retake Photo',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w700, // ✅ BOLD
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
