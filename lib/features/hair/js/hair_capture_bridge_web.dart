import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';

/// Web bridge to `window.HairCapture` (MediaPipe Face Landmarker module).
/// Flutter never processes camera frames — only receives status + image.
class HairCaptureBridge {
  HairCaptureBridge._();

  static var _viewSeq = 0;
  static bool get isSupported => kIsWeb;

  /// Registers an HtmlElementView host and returns its viewType + element id.
  static ({String viewType, String containerId}) registerView() {
    _viewSeq += 1;
    final containerId = 'hair-capture-host-$_viewSeq';
    final viewType = 'hair-capture-view-$_viewSeq';

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final root = html.DivElement()
        ..id = containerId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..style.borderRadius = '28px'
        ..style.backgroundColor = '#1a1212';
      return root;
    });

    return (viewType: viewType, containerId: containerId);
  }

  static bool get isAvailable {
    try {
      return js_util.hasProperty(html.window, 'HairCapture');
    } catch (_) {
      return false;
    }
  }

  static Future<bool> start({
    required String containerId,
    required void Function(HairCaptureState state) onUpdate,
    required void Function(Uint8List bytes, Map<String, double> pose)
        onCaptured,
    required void Function(String message) onError,
  }) async {
    if (!isAvailable) {
      onError('Hair capture module is not loaded.');
      return false;
    }

    // Wait until the platform view DOM node exists.
    html.Element? host;
    for (var i = 0; i < 50; i++) {
      host = html.document.getElementById(containerId);
      if (host != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (host == null) {
      onError('Camera view failed to mount.');
      return false;
    }

    final api = js_util.getProperty(html.window, 'HairCapture');

    // Set callbacks with allowInterop directly — jsify can drop functions.
    final opts = js_util.newObject();
    js_util.setProperty(opts, 'containerId', containerId);
    js_util.setProperty(opts, 'container', host);
    js_util.setProperty(
      opts,
      'onUpdate',
      js_util.allowInterop((dynamic raw) {
        onUpdate(HairCaptureState.fromJs(raw));
      }),
    );
    js_util.setProperty(
      opts,
      'onCaptured',
      js_util.allowInterop((dynamic raw) {
        final map = asMap(raw);
        final b64 = map['imageBase64']?.toString() ?? '';
        if (b64.isEmpty) {
          onError('Empty capture.');
          return;
        }
        final bytes = base64Decode(b64);
        final poseRaw = asMap(map['pose']);
        onCaptured(bytes, {
          'pitch': toDouble(poseRaw['pitch']),
          'yaw': toDouble(poseRaw['yaw']),
          'roll': toDouble(poseRaw['roll']),
        });
      }),
    );
    js_util.setProperty(
      opts,
      'onError',
      js_util.allowInterop((dynamic msg) {
        onError(msg?.toString() ?? 'Camera error');
      }),
    );

    final result = await js_util.promiseToFuture<dynamic>(
      js_util.callMethod(api, 'start', [opts]),
    );
    return result == true;
  }

  static Future<void> stop() async {
    if (!isAvailable) return;
    try {
      final api = js_util.getProperty(html.window, 'HairCapture');
      await js_util.promiseToFuture<dynamic>(
        js_util.callMethod(api, 'stop', []),
      );
    } catch (_) {}
  }

  static Map<String, dynamic> asMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    try {
      return Map<String, dynamic>.from(
        js_util.dartify(raw) as Map? ?? {},
      );
    } catch (_) {
      return {};
    }
  }

  static double toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
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

  factory HairCaptureState.fromJs(dynamic raw) {
    final map = HairCaptureBridge.asMap(raw);
    final checks = HairCaptureBridge.asMap(map['checks']);
    final pose = HairCaptureBridge.asMap(map['pose']);
    final linesRaw = map['lines'];
    final lines = <String>[];
    if (linesRaw is List) {
      for (final item in linesRaw) {
        lines.add(item.toString());
      }
    }

    int? countdown;
    final c = map['countdown'];
    if (c is num) countdown = c.toInt();

    final instruction = map['instruction']?.toString() ??
        map['status']?.toString() ??
        '';

    final stepRaw = map['step'];
    final step = stepRaw is num ? stepRaw.toInt() : 1;

    return HairCaptureState(
      step: step.clamp(1, 2),
      phase: map['phase']?.toString() ?? 'face',
      title: map['title']?.toString() ?? 'Quick Scan',
      instruction: instruction,
      status: map['status']?.toString() ?? instruction,
      lines: lines,
      progress: HairCaptureBridge.toDouble(map['progress']),
      countdown: countdown,
      pitch: HairCaptureBridge.toDouble(pose['pitch']),
      yaw: HairCaptureBridge.toDouble(pose['yaw']),
      roll: HairCaptureBridge.toDouble(pose['roll']),
      face: checks['face'] == true,
      lighting: checks['lighting'] == true,
      still: checks['still'] == true,
      pose: checks['pose'] == true,
      sharp: checks['sharp'] != false,
    );
  }
}
