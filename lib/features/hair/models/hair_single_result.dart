import 'dart:convert';
import 'dart:typed_data';

/// Parsed response from POST /api/analyze-hair
class HairSingleResult {
  final bool success;
  final String reportType;
  final String imageName;
  final String viewType;
  final double? qualityScore;
  final HairDensity? density;
  final String? densityAssessment;
  final HairDensity? crownDensity;
  final HairFeatures? features;
  final ScalpCondition? scalpCondition;
  final HairlineInfo? hairline;
  final Uint8List? densityOverlayBytes;
  final String? densityOverlayMime;
  final Map<String, dynamic> raw;

  const HairSingleResult({
    required this.success,
    required this.reportType,
    required this.imageName,
    required this.viewType,
    required this.qualityScore,
    required this.density,
    required this.densityAssessment,
    required this.crownDensity,
    required this.features,
    required this.scalpCondition,
    required this.hairline,
    required this.densityOverlayBytes,
    required this.densityOverlayMime,
    required this.raw,
  });

  factory HairSingleResult.fromJson(Map<String, dynamic> json) {
    final images = json['images'];
    Uint8List? overlayBytes;
    String? overlayMime;
    if (images is Map) {
      overlayMime = images['density_overlay_mime']?.toString();
      final b64 = images['density_overlay_base64']?.toString();
      if (b64 != null && b64.isNotEmpty) {
        try {
          overlayBytes = base64Decode(b64);
        } catch (_) {}
      }
    }

    return HairSingleResult(
      success: json['success'] == true,
      reportType: (json['report_type'] ?? '').toString(),
      imageName: (json['image_name'] ?? '').toString(),
      viewType: (json['view_type'] ?? '').toString(),
      qualityScore: _asDouble(json['quality_score']),
      density: HairDensity.tryParse(json['density']),
      densityAssessment: json['density_assessment']?.toString(),
      crownDensity: HairDensity.tryParse(json['crown_density']),
      features: HairFeatures.tryParse(json['features']),
      scalpCondition: ScalpCondition.tryParse(json['scalp_condition']),
      hairline: HairlineInfo.tryParse(json['hairline']),
      densityOverlayBytes: overlayBytes,
      densityOverlayMime: overlayMime,
      raw: Map<String, dynamic>.from(json),
    );
  }

  bool get lowQuality =>
      qualityScore != null && qualityScore! < 60;
}

class HairDensity {
  final double? densePct;
  final double? mediumPct;
  final double? thinPct;
  final double? confidence;
  final double? classificationConfidence;

  const HairDensity({
    this.densePct,
    this.mediumPct,
    this.thinPct,
    this.confidence,
    this.classificationConfidence,
  });

  static HairDensity? tryParse(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    return HairDensity(
      densePct: _asDouble(m['dense_pct']),
      mediumPct: _asDouble(m['medium_pct']),
      thinPct: _asDouble(m['thin_pct']),
      confidence: _asDouble(m['confidence']),
      classificationConfidence: _asDouble(m['classification_confidence']),
    );
  }
}

class HairFeatures {
  final String? hairTexture;
  final String? hairColor;
  final String? frizz;
  final String? shine;

  const HairFeatures({
    this.hairTexture,
    this.hairColor,
    this.frizz,
    this.shine,
  });

  static HairFeatures? tryParse(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    return HairFeatures(
      hairTexture: m['hair_texture']?.toString(),
      hairColor: m['hair_color']?.toString(),
      frizz: m['frizz']?.toString(),
      shine: m['shine']?.toString(),
    );
  }

  List<MapEntry<String, String>> get entries {
    final list = <MapEntry<String, String>>[];
    void add(String k, String? v) {
      if (v != null && v.trim().isNotEmpty) list.add(MapEntry(k, v));
    }

    add('Texture', hairTexture);
    add('Color', hairColor);
    add('Frizz', frizz);
    add('Shine', shine);
    return list;
  }
}

class ScalpCondition {
  final String? oiliness;
  final String? redness;
  final String? flakes;

  const ScalpCondition({
    this.oiliness,
    this.redness,
    this.flakes,
  });

  static ScalpCondition? tryParse(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    return ScalpCondition(
      oiliness: m['oiliness']?.toString(),
      redness: m['redness']?.toString(),
      flakes: m['flakes']?.toString(),
    );
  }

  List<MapEntry<String, String>> get entries {
    final list = <MapEntry<String, String>>[];
    void add(String k, String? v) {
      if (v != null && v.trim().isNotEmpty) list.add(MapEntry(k, v));
    }

    add('Oiliness', oiliness);
    add('Redness', redness);
    add('Flakes', flakes);
    return list;
  }
}

class HairlineInfo {
  final bool detected;
  final String? reason;
  final Map<String, dynamic> metrics;

  const HairlineInfo({
    required this.detected,
    this.reason,
    this.metrics = const {},
  });

  static HairlineInfo? tryParse(dynamic value) {
    if (value is! Map) return null;
    final m = Map<String, dynamic>.from(value);
    final detected = m['detected'] == true;
    final metrics = Map<String, dynamic>.from(m)
      ..remove('detected')
      ..remove('reason');
    return HairlineInfo(
      detected: detected,
      reason: m['reason']?.toString(),
      metrics: metrics,
    );
  }
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
