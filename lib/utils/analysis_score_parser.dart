/// Parses analysis score fields from API payloads with consistent fallbacks.
class AnalysisScoreParser {
  AnalysisScoreParser._();

  static double? asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static Map<String, dynamic> scoresMap(Map<String, dynamic> json) {
    final nested = json['analysis'];
    if (nested is Map) {
      final scores = nested['scores'];
      if (scores is Map) {
        return Map<String, dynamic>.from(scores);
      }
    }

    final scores = json['scores'];
    if (scores is Map) {
      return Map<String, dynamic>.from(scores);
    }
    return {};
  }

  /// Preferred: `scores.skin_health_index`, then root `skin_health_index`,
  /// then `overall_score` / `scores.overall` for older API responses.
  static double? skinHealthIndex(Map<String, dynamic> json) {
    final scores = scoresMap(json);
    return asDouble(scores['skin_health_index']) ??
        asDouble(json['skin_health_index']) ??
        asDouble(json['overall_score']) ??
        asDouble(scores['overall']);
  }

  static double categoryScore(
    Map<String, dynamic> json,
    String scoresKey, {
    String? legacyRootKey,
    double fallback = 0.0,
  }) {
    final scores = scoresMap(json);
    return asDouble(scores[scoresKey]) ??
        (legacyRootKey != null ? asDouble(json[legacyRootKey]) : null) ??
        fallback;
  }

  static double? optionalCategoryScore(
    Map<String, dynamic> json,
    String scoresKey, {
    String? legacyRootKey,
  }) {
    final scores = scoresMap(json);
    return asDouble(scores[scoresKey]) ??
        (legacyRootKey != null ? asDouble(json[legacyRootKey]) : null);
  }
}
