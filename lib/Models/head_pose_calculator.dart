import 'dart:math' as math;

/// MediaPipe landmarks indices for head pose calculation
class MediaPipeLandmarks {
  static const int forehead = 10; // Landmark 10: Forehead
  static const int noseTip = 1; // Landmark 1: Nose Tip
  static const int chin = 152; // Landmark 152: Chin

  // Fallback for ML Kit's limited landmarks (10 points)
  static const int nose = 0; // Nose
  static const int leftEye = 1; // Left eye
  static const int rightEye = 2; // Right eye
  static const int leftEar = 3; // Left ear
  static const int rightEar = 4; // Right ear
  static const int mouthLeft = 5; // Left mouth
  static const int mouthRight = 6; // Right mouth
}

/// HeadPoseCalculator computes head pose angles (pitch, yaw) from face landmarks
class HeadPoseCalculator {
  static bool _hasValidPoint(List<List<double>> landmarks, int index) {
    if (index < 0 || index >= landmarks.length) return false;
    if (landmarks[index].length < 2) return false;
    return landmarks[index][0].isFinite && landmarks[index][1].isFinite;
  }

  /// Returns pitch angle in degrees [0, 90].
  ///
  /// If ML Kit Euler X is available, it is preferred because it is more stable
  /// than deriving pitch from sparse landmarks.
  static double calculatePitch(
    List<List<double>> landmarks, {
    double? headEulerAngleX,
  }) {
    if (headEulerAngleX != null && headEulerAngleX.isFinite) {
      return headEulerAngleX.abs().clamp(0.0, 90.0);
    }

    if (landmarks.isEmpty) return double.nan;

    try {
      if (landmarks.length >= 153) {
        return _calculatePitchMediaPipe(landmarks);
      } else if (landmarks.length >= 7) {
        return _calculatePitchMLKit(landmarks);
      }
      return double.nan;
    } catch (_) {
      return double.nan;
    }
  }

  static double _calculatePitchMediaPipe(List<List<double>> landmarks) {
    final foreheadY = landmarks[MediaPipeLandmarks.forehead][1];
    final noseTipY = landmarks[MediaPipeLandmarks.noseTip][1];
    final chinY = landmarks[MediaPipeLandmarks.chin][1];

    final distanceForeheadToNose = (noseTipY - foreheadY).abs();
    final distanceNoseToChin = (chinY - noseTipY).abs();

    if (distanceNoseToChin == 0) return double.nan;

    final ratio = distanceForeheadToNose / distanceNoseToChin;
    final pitchRadians = math.atan(ratio);
    final pitchDegrees = pitchRadians * 180 / math.pi;

    return pitchDegrees.clamp(0.0, 90.0);
  }

  static double _calculatePitchMLKit(List<List<double>> landmarks) {
    if (!_hasValidPoint(landmarks, 0) ||
        !_hasValidPoint(landmarks, 1) ||
        !_hasValidPoint(landmarks, 2) ||
        !_hasValidPoint(landmarks, 5) ||
        !_hasValidPoint(landmarks, 6)) {
      return double.nan;
    }

    final noseY = landmarks[0][1];
    final leftEyeY = landmarks[1][1];
    final rightEyeY = landmarks[2][1];
    final mouthLeftY = landmarks[5][1];
    final mouthRightY = landmarks[6][1];

    final avgEyeY = (leftEyeY + rightEyeY) / 2;
    final avgMouthY = (mouthLeftY + mouthRightY) / 2;

    final eyeToNose = (noseY - avgEyeY).abs();
    final noseToMouth = (avgMouthY - noseY).abs();

    if (noseToMouth == 0) return double.nan;

    final ratio = eyeToNose / noseToMouth;
    final pitchRadians = math.atan(ratio);
    final pitchDegrees = pitchRadians * 180 / math.pi;

    // Small scale-up keeps historical behavior while staying bounded.
    return (pitchDegrees * 1.1).clamp(0.0, 90.0);
  }

  /// Returns yaw angle in degrees [-45, 45].
  ///
  /// If ML Kit Euler Y is available, it is preferred.
  static double calculateYaw(
    List<List<double>> landmarks, {
    double? headEulerAngleY,
  }) {
    if (headEulerAngleY != null && headEulerAngleY.isFinite) {
      return headEulerAngleY.clamp(-45.0, 45.0);
    }

    if (landmarks.isEmpty) return double.nan;

    try {
      if (landmarks.length >= 153) {
        return _calculateYawMediaPipe(landmarks);
      } else if (landmarks.length >= 5) {
        return _calculateYawMLKit(landmarks);
      }
      return double.nan;
    } catch (_) {
      return double.nan;
    }
  }

  static double _calculateYawMediaPipe(List<List<double>> landmarks) {
    final noseTipX = landmarks[MediaPipeLandmarks.noseTip][0];
    final leftEarX =
        landmarks.length > 234 ? landmarks[234][0] : landmarks[0][0];
    final rightEarX =
        landmarks.length > 454 ? landmarks[454][0] : landmarks[0][0];

    final centerX = (leftEarX + rightEarX) / 2;
    final offsetX = noseTipX - centerX;
    final frameWidth = (rightEarX - leftEarX).abs();

    if (frameWidth == 0) return double.nan;

    final normalizedOffset = offsetX / frameWidth;
    return (normalizedOffset * 90).clamp(-45.0, 45.0);
  }

  static double _calculateYawMLKit(List<List<double>> landmarks) {
    if (!_hasValidPoint(landmarks, 0) ||
        !_hasValidPoint(landmarks, 3) ||
        !_hasValidPoint(landmarks, 4)) {
      return double.nan;
    }

    final noseX = landmarks[0][0];
    final leftEarX = landmarks[3][0];
    final rightEarX = landmarks[4][0];

    final faceCenter = (leftEarX + rightEarX) / 2;
    final offsetX = noseX - faceCenter;
    final faceWidth = (rightEarX - leftEarX).abs();

    if (faceWidth == 0) return double.nan;

    final normalizedOffset = offsetX / faceWidth;
    return (normalizedOffset * 90).clamp(-45.0, 45.0);
  }

  /// Returns roll angle in degrees [-45, 45].
  static double calculateRoll({double? headEulerAngleZ}) {
    if (headEulerAngleZ == null || !headEulerAngleZ.isFinite) {
      return 0.0;
    }
    return headEulerAngleZ.clamp(-45.0, 45.0);
  }

  /// True only when pose is finite and in target range.
  static bool isInTargetPose({
    required double pitch,
    required double yaw,
    double roll = 0.0,
    double minPitch = 42.0,
    double maxPitch = 48.0,
    double maxYawDeviation = 5.0,
    double maxRollDeviation = 8.0,
  }) {
    if (!pitch.isFinite || !yaw.isFinite || !roll.isFinite) {
      return false;
    }

    return pitch >= minPitch &&
        pitch <= maxPitch &&
        yaw.abs() <= maxYawDeviation &&
        roll.abs() <= maxRollDeviation;
  }
}

