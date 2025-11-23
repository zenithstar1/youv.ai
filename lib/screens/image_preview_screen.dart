import 'dart:typed_data';
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

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  bool _isAnalyzing = false;
  bool _showOverlay = true;
  int _currentAttempt = 0;
  int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    // Auto-hide overlay after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showOverlay = false);
      }
    });
  }

  Future<void> _sendForAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _currentAttempt = 0;
    });

    try {
      final apiService = ApiService();

      // Listen to attempts (simulated with periodic updates)
      _simulateProgress();

      final analysisData = await apiService.analyzeSkinWithImageBytes(
        widget.imageBytes,
        widget.fileName,
      );

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
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _simulateProgress() {
    // Simulate progress updates
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isAnalyzing) {
        setState(() => _currentAttempt = 1);
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isAnalyzing) {
        setState(() => _currentAttempt = 2);
      }
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _isAnalyzing) {
        setState(() => _currentAttempt = 3);
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to capture screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _sendForAnalysis(); // Retry
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isAnalyzing
            ? Center(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated circular progress
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              strokeWidth: 6,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFE8B4BA),
                              ),
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8B4BA).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFE8B4BA),
                              size: 40,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Analyzing your skin...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _getAnalysisMessage(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Progress indicator
                      if (_currentAttempt > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _currentAttempt <= _maxAttempts
                                ? 'Attempt $_currentAttempt of $_maxAttempts'
                                : 'Processing...',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),

                      // Processing steps
                      _buildProcessingStep(
                        Icons.face_retouching_natural,
                        'Detecting facial features',
                        _currentAttempt >= 1,
                      ),
                      const SizedBox(height: 12),
                      _buildProcessingStep(
                        Icons.analytics,
                        'Analyzing skin condition',
                        _currentAttempt >= 2,
                      ),
                      const SizedBox(height: 12),
                      _buildProcessingStep(
                        Icons.assessment,
                        'Generating results',
                        _currentAttempt >= 3,
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                children: [
                  // Image Display
                  Center(
                    child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                  ),

                  // Face Detection Overlay
                  if (_showOverlay)
                    Center(
                      child: Container(
                        width: 300,
                        height: 400,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            _buildCorner(true, true),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: _buildCorner(true, false),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: _buildCorner(false, true),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: _buildCorner(false, false),
                            ),
                            Positioned(
                              top: 200,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                color: Colors.pink[200],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Success message
                  Positioned(
                    bottom: 150,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          'Well done ! You\'re good to go',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Action Buttons
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          'Retake',
                          const Color(0xFFE8B4BA),
                          () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 20),
                        _buildActionButton(
                          'Send',
                          const Color(0xFFE8B4BA),
                          _sendForAnalysis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getAnalysisMessage() {
    if (_currentAttempt == 0) {
      return 'This may take a few moments';
    } else if (_currentAttempt == 1) {
      return 'Processing your image...';
    } else if (_currentAttempt == 2) {
      return 'Almost there...';
    } else {
      return 'Finalizing results...';
    }
  }

  Widget _buildProcessingStep(IconData icon, String text, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFFE8B4BA) : Colors.white30,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white30,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        if (isActive)
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE8B4BA)),
            ),
          ),
      ],
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
