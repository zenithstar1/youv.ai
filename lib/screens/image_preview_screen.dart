import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

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

class _ImagePreviewScreenState extends State<ImagePreviewScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;
  int _currentMessageIndex = 0;
  Timer? _messageTimer;
  AnimationController? _scanLineController;

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

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _scanLineController?.dispose();
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

  // =================== SYMMETRY API ===================
  Future<Map<String, dynamic>?> _callSymmetryAPI(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final uri = Uri.parse(
        'https://anujakkulkarni-symmetry.hf.space/analyze?draw=0',
      );
      final req = http.MultipartRequest('POST', uri);

      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: http_parser.MediaType('image', 'jpeg'),
        ),
      );

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // =================== MAIN ANALYSIS ===================
  Future<void> _sendForAnalysis() async {
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
        setState(() => _isAnalyzing = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HairResultScreen(analysis: hairAnalysis),
          ),
        );
        return;
      }

      // ---- SKIN FLOW ----
      final apiService = ApiService();

      final results = await Future.wait([
        apiService.analyzeSkinWithImageBytes(
          widget.imageBytes,
          widget.fileName,
        ),
        _callSymmetryAPI(widget.imageBytes, widget.fileName),
      ]);

      final skinAnalysisResult = results[0];
      final symmetryResult = results[1];

      SkinAnalysisModel? skinAnalysisData;
      Map<String, dynamic>? symmetryData;

      if (skinAnalysisResult is SkinAnalysisModel) {
        skinAnalysisData = skinAnalysisResult;
      } else if (skinAnalysisResult is Map<String, dynamic>) {
        skinAnalysisData = SkinAnalysisModel.fromJson(skinAnalysisResult);
      } else {
        throw Exception("Invalid skin API response format");
      }

      if (symmetryResult is Map<String, dynamic>) {
        symmetryData = symmetryResult;
      }

      _uploadImageToFirebase(widget.imageBytes, 'latest_scan')
          .then((url) => _saveBeforeAfterImage(url))
          .catchError((e) => print('Background upload failed: $e'));

      _messageTimer?.cancel();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SkinAnalysisRedesigned(
              analysisData: skinAnalysisData,
              imageBytes: widget.imageBytes,
              faceRatioJson: symmetryData,
            ),
          ),
        );
      }
    } catch (e) {
      _messageTimer?.cancel();
      setState(() => _isAnalyzing = false);
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
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCircularButton(
              icon: Icons.refresh_rounded,
              onTap: _retakePhoto,
            ),
            const SizedBox(width: 40),
            _buildCircularButton(
              icon: Icons.check_rounded,
              onTap: _sendForAnalysis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.3),
          border: Border.all(color: Colors.white, width: 2.0),
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
