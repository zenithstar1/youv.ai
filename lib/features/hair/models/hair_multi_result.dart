import 'hair_single_result.dart';

/// Parsed response from POST /analyze-multi.
/// Shape varies; we keep [raw] and extract known summary fields when present.
class HairMultiResult {
  final bool success;
  final String reportType;
  final String? densityAssessment;
  final HairDensity? density;
  final HairFeatures? features;
  final ScalpCondition? scalpCondition;
  final List<HairPerImageSummary> perImage;
  final Map<String, dynamic> raw;

  const HairMultiResult({
    required this.success,
    required this.reportType,
    required this.densityAssessment,
    required this.density,
    required this.features,
    required this.scalpCondition,
    required this.perImage,
    required this.raw,
  });

  /// Builds a multi summary from sequential single-image analyses.
  factory HairMultiResult.fromSingles(List<HairSingleResult> singles) {
    final perImage = singles
        .map(
          (s) => HairPerImageSummary(
            imageName: s.imageName,
            viewType: s.viewType,
            qualityScore: s.qualityScore,
            densityAssessment: s.densityAssessment,
            density: s.density,
            raw: s.raw,
          ),
        )
        .toList();

    final primary = singles.isNotEmpty ? singles.first : null;
    return HairMultiResult(
      success: singles.every((s) => s.success),
      reportType: 'multi_view_hair_analysis',
      densityAssessment: primary?.densityAssessment,
      density: primary?.density,
      features: primary?.features,
      scalpCondition: primary?.scalpCondition,
      perImage: perImage,
      raw: {
        'success': true,
        'report_type': 'multi_view_hair_analysis',
        'results': singles.map((s) => s.raw).toList(),
      },
    );
  }

  factory HairMultiResult.fromJson(Map<String, dynamic> json) {
    final perImage = <HairPerImageSummary>[];

    void collectList(dynamic list) {
      if (list is! List) return;
      for (final item in list) {
        if (item is Map) {
          perImage.add(
            HairPerImageSummary.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    // Common keys used by multi-view reports.
    collectList(json['per_image']);
    collectList(json['per_images']);
    collectList(json['images_summary']);
    collectList(json['image_summaries']);
    collectList(json['views']);
    collectList(json['results']);
    if (json['images'] is List) collectList(json['images']);

    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : json['consolidated'] is Map
            ? Map<String, dynamic>.from(json['consolidated'] as Map)
            : json;

    return HairMultiResult(
      success: json['success'] != false,
      reportType: (json['report_type'] ?? 'multi_view_hair_analysis').toString(),
      densityAssessment: (summary['density_assessment'] ??
              json['density_assessment'])
          ?.toString(),
      density: HairDensity.tryParse(summary['density'] ?? json['density']),
      features: HairFeatures.tryParse(summary['features'] ?? json['features']),
      scalpCondition: ScalpCondition.tryParse(
        summary['scalp_condition'] ?? json['scalp_condition'],
      ),
      perImage: perImage,
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class HairPerImageSummary {
  final String? imageName;
  final String? viewType;
  final double? qualityScore;
  final String? densityAssessment;
  final HairDensity? density;
  final Map<String, dynamic> raw;

  const HairPerImageSummary({
    this.imageName,
    this.viewType,
    this.qualityScore,
    this.densityAssessment,
    this.density,
    required this.raw,
  });

  factory HairPerImageSummary.fromJson(Map<String, dynamic> json) {
    // Nested analysis payloads are common.
    final nested = json['analysis'] is Map
        ? Map<String, dynamic>.from(json['analysis'] as Map)
        : json;

    return HairPerImageSummary(
      imageName: (json['image_name'] ?? nested['image_name'] ?? json['name'])
          ?.toString(),
      viewType: (json['view_type'] ?? nested['view_type'])?.toString(),
      qualityScore: _asDouble(json['quality_score'] ?? nested['quality_score']),
      densityAssessment:
          (json['density_assessment'] ?? nested['density_assessment'])
              ?.toString(),
      density: HairDensity.tryParse(json['density'] ?? nested['density']),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
