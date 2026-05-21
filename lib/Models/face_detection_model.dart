class FaceBox {
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;

  FaceBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence = 1.0,
  });

  factory FaceBox.fromJson(Map<String, dynamic> json) {
    return FaceBox(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  // Check if face is well-positioned (centered and appropriate size)
  bool get isWellPositioned {
    const double minSize = 0.15; // Face should be at least 15% of frame
    const double maxSize = 0.8; // Face shouldn't be more than 80% of frame
    const double centerTolerance = 0.3; // Allow 30% deviation from center

    // Check size
    if (width < minSize ||
        height < minSize ||
        width > maxSize ||
        height > maxSize) {
      return false;
    }

    // Check if face is roughly centered
    double centerX = x + width / 2;
    double centerY = y + height / 2;

    if ((centerX - 0.5).abs() > centerTolerance ||
        (centerY - 0.5).abs() > centerTolerance) {
      return false;
    }

    return true;
  }
}

class FaceDetectionResult {
  final List<FaceBox> faces;
  final int timestamp;
  final double videoWidth;
  final double videoHeight;

  FaceDetectionResult({
    required this.faces,
    required this.timestamp,
    required this.videoWidth,
    required this.videoHeight,
  });

  factory FaceDetectionResult.fromJson(Map<String, dynamic> json) {
    return FaceDetectionResult(
      faces:
          (json['boxes'] as List).map((box) => FaceBox.fromJson(box)).toList(),
      timestamp: json['timestamp'] as int,
      videoWidth: (json['videoWidth'] as num).toDouble(),
      videoHeight: (json['videoHeight'] as num).toDouble(),
    );
  }

  bool get hasWellPositionedFace {
    return faces.any((face) => face.isWellPositioned);
  }

  FaceBox? get bestFace {
    if (faces.isEmpty) return null;

    // Sort by confidence and size, prefer well-positioned faces
    final sortedFaces = List<FaceBox>.from(faces);
    sortedFaces.sort((a, b) {
      if (a.isWellPositioned && !b.isWellPositioned) return -1;
      if (!a.isWellPositioned && b.isWellPositioned) return 1;

      // Both are well-positioned or both aren't, sort by confidence
      return b.confidence.compareTo(a.confidence);
    });

    return sortedFaces.first;
  }
}
