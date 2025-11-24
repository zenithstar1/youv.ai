import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skin_analysis_app/Api/Apiservice.dart';
import 'skin_analysis_screen.dart';

class ImagePreviewScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String fileName;

  const ImagePreviewScreen({
    Key? key,
    required this.imageBytes,
    required this.fileName,
  }) : super(key: key);

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;
  int _currentMessageIndex = 0;
  Timer? _messageTimer;
  AnimationController? _scanLineController;
  Animation<double>? _scanLineAnimation;

  final List<String> _loadingMessages = [
    "YOU'VE BEEN FOUND GUILTY OF\nBEING TOO ATTRACTIVE.",
    "ATTRACTIVENESS ISN'T FIXED; THE\nINDEX JUST TRACKS THE JOURNEY.",
    "THE INDEX UNCOVERS HIDDEN\nAESTHETIC STRENGTHS THAT MOST\nPEOPLE OVERLOOK.",
    "ANALYZING YOUR UNIQUE\nFACIAL FEATURES...",
    "CALCULATING SKIN HEALTH\nINDICATORS...",
    "PROCESSING BEAUTY\nALGORITHMS...",
  ];

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController!, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _scanLineController?.dispose();
    super.dispose();
  }

  Future<void> _sendForAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _currentMessageIndex = 0;
    });

    _startMessageCycling();

    try {
      final apiService = ApiService();

      final analysisData = await apiService.analyzeSkinWithImageBytes(
        widget.imageBytes,
        widget.fileName,
      );

      _messageTimer?.cancel();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SkinAnalysisScreen(
              analysisData: analysisData,
              imageBytes: widget.imageBytes,
            ),
          ),
        );
      }
    } catch (e) {
      _messageTimer?.cancel();
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showErrorDialog(e.toString());
      }
    }
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
    final isServerBusy = error.contains('Server is busy');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isServerBusy ? Icons.cloud_off : Icons.error_outline,
              color: isServerBusy ? Colors.orange : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isServerBusy ? 'Server Busy' : 'Analysis Failed',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.replaceAll('Exception: ', ''),
              style: const TextStyle(fontSize: 14),
            ),
            if (isServerBusy) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'The server is experiencing high traffic. Please try again in a few moments.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _sendForAnalysis();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4999F),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6E8),
      body: SafeArea(
        child: _isAnalyzing
            ? _buildAnalyzingScreen()
            : Column(
                children: [
                  const SizedBox(height: 10), // Small top padding
                  // Image Area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        child: Image.memory(
                          widget.imageBytes,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Pink Bottom Area
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8B4BA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Well done! You\'re good to go',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 25),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildActionButton(
                                  'Retake',
                                  Colors.white,
                                  const Color(0xFFD4999F),
                                  () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 20),
                                _buildActionButton(
                                  'Send',
                                  const Color(0xFFD4999F),
                                  Colors.white,
                                  _sendForAnalysis,
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAnalyzingScreen() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final frameWidth = screenWidth * 0.7;
    final frameHeight = screenHeight * 0.55;

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
          ),

          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          Center(
            child: SizedBox(
              width: frameWidth,
              height: frameHeight,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  _buildCornerBracket(
                    Alignment.topLeft,
                    frameWidth,
                    frameHeight,
                  ),
                  _buildCornerBracket(
                    Alignment.topRight,
                    frameWidth,
                    frameHeight,
                  ),
                  _buildCornerBracket(
                    Alignment.bottomLeft,
                    frameWidth,
                    frameHeight,
                  ),
                  _buildCornerBracket(
                    Alignment.bottomRight,
                    frameWidth,
                    frameHeight,
                  ),

                  AnimatedBuilder(
                    animation: _scanLineAnimation!,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanLineAnimation!.value * frameHeight,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.pink[300]!.withOpacity(0.8),
                                Colors.pink[200]!,
                                Colors.pink[300]!.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink[200]!.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 120,
            left: 30,
            right: 30,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey<int>(_currentMessageIndex),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _loadingMessages[_currentMessageIndex],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 75,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_loadingMessages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentMessageIndex == index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentMessageIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 35,
                height: 35,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBracket(
    Alignment alignment,
    double frameWidth,
    double frameHeight,
  ) {
    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Positioned(
      top: isTop ? -1.5 : null,
      bottom: !isTop ? -1.5 : null,
      left: isLeft ? -1.5 : null,
      right: !isLeft ? -1.5 : null,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.white, width: 5)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: 5)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.white, width: 5)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: 5)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
