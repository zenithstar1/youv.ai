import 'dart:typed_data';

/// Stub for non-web platforms — hair JS capture runs on Flutter Web only.
class HairCaptureBridge {
  HairCaptureBridge._();

  static bool get isSupported => false;
  static bool get isAvailable => false;

  static ({String viewType, String containerId}) registerView() {
    return (viewType: 'hair-capture-unsupported', containerId: '');
  }

  static Future<bool> start({
    required String containerId,
    required void Function(HairCaptureState state) onUpdate,
    required void Function(Uint8List bytes, Map<String, double> pose)
        onCaptured,
    required void Function(String message) onError,
  }) async {
    onError('JS hair capture is only available on web.');
    return false;
  }

  static Future<void> stop() async {}
}

class HairCaptureState {
  final int step;
  final String phase;
  final String title;
  final String instruction;
  final String status;
  final List<String> lines;
  final double progress;
  final int? countdown;
  final double pitch;
  final double yaw;
  final double roll;
  final bool face;
  final bool lighting;
  final bool still;
  final bool pose;
  final bool sharp;

  const HairCaptureState({
    required this.step,
    required this.phase,
    required this.title,
    required this.instruction,
    required this.status,
    required this.lines,
    required this.progress,
    required this.countdown,
    required this.pitch,
    required this.yaw,
    required this.roll,
    required this.face,
    required this.lighting,
    required this.still,
    required this.pose,
    required this.sharp,
  });

  factory HairCaptureState.idle() => const HairCaptureState(
        step: 1,
        phase: 'face',
        title: 'Position your face',
        instruction: 'Starting camera…',
        status: 'Starting camera…',
        lines: [],
        progress: 0,
        countdown: null,
        pitch: 0,
        yaw: 0,
        roll: 0,
        face: false,
        lighting: false,
        still: false,
        pose: false,
        sharp: false,
      );
}
