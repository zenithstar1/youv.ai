import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class FaceRatioLine {
  final double x1, y1, x2, y2;
  const FaceRatioLine({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory FaceRatioLine.fromJson(Map<String, dynamic> m,
      {double ox = 0, double oy = 0}) {
    if (m.containsKey('start') && m.containsKey('end')) {
      final s = (m['start'] as List).map((e) => (e as num).toDouble()).toList();
      final e = (m['end'] as List).map((e) => (e as num).toDouble()).toList();
      return FaceRatioLine(
        x1: s[0] - ox,
        y1: s[1] - oy,
        x2: e[0] - ox,
        y2: e[1] - oy,
      );
    }
    return FaceRatioLine(
      x1: ((m['x1'] as num?)?.toDouble() ?? 0) - ox,
      y1: ((m['y1'] as num?)?.toDouble() ?? 0) - oy,
      x2: ((m['x2'] as num?)?.toDouble() ?? 0) - ox,
      y2: ((m['y2'] as num?)?.toDouble() ?? 0) - oy,
    );
  }
}

enum RatioMode {
  vertical,
  horizontal,
  eyes,
  faceBox,
  noseLipChin,
  lips,
  jaw,
}

class EyeBox {
  final Offset tl, tr, bl, br;
  final String golden, measured;
  const EyeBox({
    required this.tl,
    required this.tr,
    required this.bl,
    required this.br,
    required this.golden,
    required this.measured,
  });

  factory EyeBox.fromJson(Map<String, dynamic> box,
      {required String golden,
      required String measured,
      double ox = 0,
      double oy = 0}) {
    Offset _p(List v) =>
        Offset((v[0] as num).toDouble() - ox, (v[1] as num).toDouble() - oy);
    return EyeBox(
      tl: _p(box['top_left']),
      tr: _p(box['top_right']),
      bl: _p(box['bottom_left']),
      br: _p(box['bottom_right']),
      golden: golden,
      measured: measured,
    );
  }

  Rect get rect {
    final xs = [tl.dx, tr.dx, bl.dx, br.dx]..sort();
    final ys = [tl.dy, tr.dy, bl.dy, br.dy]..sort();
    return Rect.fromLTRB(xs.first, ys.first, xs.last, ys.last);
  }
}

class FaceBox {
  final Rect rect;
  final String golden, yours;
  const FaceBox(
      {required this.rect, required this.golden, required this.yours});
}

class JawPoints {
  final Offset leftJaw, rightJaw, chin, noseBottom;
  final double ideal, ratio;
  const JawPoints({
    required this.leftJaw,
    required this.rightJaw,
    required this.chin,
    required this.noseBottom,
    required this.ideal,
    required this.ratio,
  });
}

class FaceRatioData {
  // image
  final Uint8List? imageBytes;
  final double imageW, imageH;

  // crop (kept for reference; NOT applied to geometry)
  final double cropX, cropY;

  // vertical / horizontal
  final List<FaceRatioLine> verticalLines;
  final List<FaceRatioLine> horizontalLines;
  final List<double> verticalPerc;
  final List<double> horizontalPerc;
  final String idealVertical;
  final String idealHorizontal;

  // eyes
  final EyeBox? leftEye;
  final EyeBox? rightEye;

  // face box
  final FaceBox? faceBox;

  // nose-lip-chin
  final List<FaceRatioLine> noseLipChinLines;
  final String? noseLipChinIdeal;
  final String? noseLipChinRatio;

  // lips
  final List<FaceRatioLine> lipLines;
  final String? lipIdeal;
  final String? lipRatio;

  // jaw
  final JawPoints? jaw;

  FaceRatioData({
    required this.imageBytes,
    required this.imageW,
    required this.imageH,
    required this.cropX,
    required this.cropY,
    required this.verticalLines,
    required this.horizontalLines,
    required this.verticalPerc,
    required this.horizontalPerc,
    required this.idealVertical,
    required this.idealHorizontal,
    required this.leftEye,
    required this.rightEye,
    required this.faceBox,
    required this.noseLipChinLines,
    required this.noseLipChinIdeal,
    required this.noseLipChinRatio,
    required this.lipLines,
    required this.lipIdeal,
    required this.lipRatio,
    required this.jaw,
  });

  factory FaceRatioData.fromMap(Map<String, dynamic> m) {
    // crop (kept for reference)
    final crop = Map<String, dynamic>.from(m['crop'] ?? const {});
    final ox = (crop['x'] as num?)?.toDouble() ?? 0.0;
    final oy = (crop['y'] as num?)?.toDouble() ?? 0.0;

    // image (always full image)
    Uint8List? bytes;
    final b64 = m['image_base64']?.toString();
    if (b64 != null && b64.isNotEmpty) {
      final i = b64.indexOf(',');
      final pure = i != -1 ? b64.substring(i + 1) : b64;
      try {
        bytes = base64Decode(pure);
      } catch (_) {}
    }

    List<double> _pct(dynamic l) => (l as List? ?? [])
        .map((p) => double.tryParse(p.toString().replaceAll('%', '')) ?? 0.0)
        .toList();

    // --------- NO offset subtraction ----------
    // Vertical & Horizontal (full-image space)
    final vLines = (m['coordinates_vertical'] as List? ?? [])
        .map((e) =>
            FaceRatioLine.fromJson(Map<String, dynamic>.from(e))) // no -ox/-oy
        .toList();

    final hLines = (m['coordinates_horizontal'] as List? ?? [])
        .map((e) =>
            FaceRatioLine.fromJson(Map<String, dynamic>.from(e))) // no -ox/-oy
        .toList();

    // Nose–Lip–Chin (full-image space)
    final nlcNode = Map<String, dynamic>.from(m['nose_lip_chin'] ?? const {});
    final nlcLines = (nlcNode['coordinates_horizontal'] as List? ?? [])
        .map((e) =>
            FaceRatioLine.fromJson(Map<String, dynamic>.from(e))) // no -ox/-oy
        .toList();

    // --------- WITH offset subtraction ----------
    // Eyes (cropped-space from service)
    EyeBox? leftEye, rightEye;
    final eyes = m['eye_aspect_ratios'] ?? m['eye_aspect_ratio'];
    if (eyes is Map) {
      final me = Map<String, dynamic>.from(eyes);
      EyeBox? _eye(Map<String, dynamic>? raw) {
        if (raw == null) return null;
        final box = Map<String, dynamic>.from(raw['box_coordinates'] as Map);
        return EyeBox.fromJson(
          box,
          golden: (raw['golden_ratio'] ?? '').toString(),
          measured: (raw['measured_ratio'] ?? '').toString(),
          ox: ox, oy: oy, // subtract crop here
        );
      }

      leftEye = _eye(me['left_eye'] as Map<String, dynamic>?);
      rightEye = _eye(me['right_eye'] as Map<String, dynamic>?);
    }

    // Face box (cropped-space)
    FaceBox? faceBox;
    final faceNode = m['face_aspect_ratio'];
    if (faceNode is Map) {
      final f = Map<String, dynamic>.from(faceNode);
      final b = Map<String, dynamic>.from(f['box_coordinates'] ?? {});
      Offset _p(List v) => Offset(
            (v[0] as num).toDouble() - ox,
            (v[1] as num).toDouble() - oy,
          );
      if (b.isNotEmpty) {
        final tl = _p(b['top_left']);
        final tr = _p(b['top_right']);
        final bl = _p(b['bottom_left']);
        final br = _p(b['bottom_right']);
        final xs = [tl.dx, tr.dx, bl.dx, br.dx]..sort();
        final ys = [tl.dy, tr.dy, bl.dy, br.dy]..sort();
        faceBox = FaceBox(
          rect: Rect.fromLTRB(xs.first, ys.first, xs.last, ys.last),
          golden: (f['Golden ratio'] ?? '').toString(),
          yours: (f['Your Ratio'] ?? '').toString(),
        );
      }
    }

    // Lips (cropped-space)
    final lipsNode = Map<String, dynamic>.from(m['lip_ratio'] ?? const {});
    final lipLines = (lipsNode['coordinates_horizontal'] as List? ?? [])
        .map((e) => FaceRatioLine.fromJson(Map<String, dynamic>.from(e),
            ox: ox, oy: oy)) // subtract crop
        .toList();

    // Jaw (cropped-space)
    JawPoints? jaw;
    final jnode = Map<String, dynamic>.from(m['jaw_ratio'] ?? const {});
    if (jnode.isNotEmpty && jnode['coordinates'] is Map) {
      final c = Map<String, dynamic>.from(jnode['coordinates']);
      Offset _pt(List v) => Offset(
            (v[0] as num).toDouble() - ox,
            (v[1] as num).toDouble() - oy,
          );
      jaw = JawPoints(
        leftJaw: _pt(c['left_jaw'] as List),
        rightJaw: _pt(c['right_jaw'] as List),
        chin: _pt(c['chin'] as List),
        noseBottom: _pt(c['nose_bottom'] as List),
        ideal: (jnode['ideal_ratio'] as num?)?.toDouble() ?? 0,
        ratio: (jnode['ratio'] as num?)?.toDouble() ?? 0,
      );
    }

    return FaceRatioData(
      imageBytes: bytes,
      imageW: (m['image_width'] as num?)?.toDouble() ?? 0,
      imageH: (m['image_height'] as num?)?.toDouble() ?? 0,
      cropX: ox,
      cropY: oy,
      verticalLines: vLines,
      horizontalLines: hLines,
      verticalPerc:
          _pct(m['Vertical Face Ratio'] ?? m['vertical_sections_percent']),
      horizontalPerc: _pct(m['Horizontal Face Ratio'] ??
          m['Horizontal Faces Ratio'] ??
          m['horizontal_sections_percent']),
      idealVertical: (m['Vertical Golden Ratio'] ??
              m['ideal_vertical'] ??
              '20% : 20% : 20% : 20% : 20%')
          .toString(),
      idealHorizontal: (m['Horizontal Golden Ratio'] ??
              m['ideal_horizontal'] ??
              '33% : 33% : 33%')
          .toString(),
      leftEye: leftEye,
      rightEye: rightEye,
      faceBox: faceBox,
      noseLipChinLines: nlcLines,
      noseLipChinIdeal: (nlcNode['ideal_ratio'] ?? '').toString(),
      noseLipChinRatio: (nlcNode['ratio'] ?? '').toString(),
      lipLines: lipLines,
      lipIdeal: (lipsNode['ideal_ratio'] ?? '').toString(),
      lipRatio: (lipsNode['ratio'] ?? '').toString(),
      jaw: jaw,
    );
  }
}
