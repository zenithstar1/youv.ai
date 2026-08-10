import 'package:flutter/material.dart';
import 'package:skin_analysis_app/utils/analysis_score_parser.dart';

/// Represents a single skin-analysis session in the activity history.
class ActivityModel {
  final String id;
  final String analysisType;
  final DateTime date;
  final double? skinHealthIndex;
  final double acneScore;
  final double hydrationScore;
  final double? pigmentationScore;
  final double? poresScore;
  final double? wrinklesScore;
  final String? severity;
  final String? thumbnailAsset;
  final String? thumbnailUrl;
  final String status;

  const ActivityModel({
    required this.id,
    required this.analysisType,
    required this.date,
    this.skinHealthIndex,
    required this.acneScore,
    required this.hydrationScore,
    this.pigmentationScore,
    this.poresScore,
    this.wrinklesScore,
    this.severity,
    this.thumbnailAsset,
    this.thumbnailUrl,
    this.status = 'completed',
  });

  /// Legacy alias — prefer [skinHealthIndex].
  double? get overallScore => skinHealthIndex;

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['analysis_id']?.toString() ?? json['id']?.toString() ?? '',
      analysisType: _formatAnalysisType(
          json['analysis_type']?.toString() ?? 'Skin Analysis'),
      date: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      skinHealthIndex: AnalysisScoreParser.skinHealthIndex(json),
      acneScore: AnalysisScoreParser.categoryScore(
        json,
        'acne',
        legacyRootKey: 'acne_score',
      ),
      hydrationScore: AnalysisScoreParser.categoryScore(
        json,
        'hydration',
        legacyRootKey: 'hydration_score',
      ),
      pigmentationScore: AnalysisScoreParser.optionalCategoryScore(
        json,
        'pigmentation',
        legacyRootKey: 'pigmentation_score',
      ),
      poresScore: AnalysisScoreParser.optionalCategoryScore(
        json,
        'pores',
        legacyRootKey: 'pores_score',
      ),
      wrinklesScore: AnalysisScoreParser.optionalCategoryScore(
        json,
        'wrinkles',
        legacyRootKey: 'wrinkles_score',
      ),
      severity: json['severity']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      status: json['status']?.toString() ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'analysis_type': analysisType,
        'created_at': date.toIso8601String(),
        'skin_health_index': skinHealthIndex,
        'acne_score': acneScore,
        'hydration_score': hydrationScore,
        'pigmentation_score': pigmentationScore,
        'pores_score': poresScore,
        'wrinkles_score': wrinklesScore,
        'severity': severity,
        'thumbnail_url': thumbnailUrl,
        'status': status,
      };

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color get statusColor {
    switch (status) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'failed':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static String _formatAnalysisType(String raw) {
    switch (raw) {
      case 'skin_analysis':
        return 'Skin Analysis';
      case 'facial_symmetry':
        return 'Facial Symmetry';
      case 'batch_skin_analysis':
        return 'Batch Skin Analysis';
      default:
        // title-case snake_case fallback
        return raw.replaceAll('_', ' ').splitMapJoin(
              RegExp(r'\b\w'),
              onMatch: (m) => m.group(0)!.toUpperCase(),
              onNonMatch: (s) => s,
            );
    }
  }
}

class ActivityRepository {
  static List<ActivityModel> getMockActivities() {
    return [
      ActivityModel(
        id: 'act_001',
        analysisType: 'Skin Analysis',
        date: DateTime(2025, 5, 10),
        skinHealthIndex: 72.5,
        acneScore: 72.5,
        hydrationScore: 68.0,
        pigmentationScore: 55.0,
        poresScore: 61.0,
        wrinklesScore: 80.0,
        thumbnailAsset: 'assets/images/face_outline.png',
        status: 'completed',
      ),
      ActivityModel(
        id: 'act_002',
        analysisType: 'Skin Analysis',
        date: DateTime(2025, 4, 22),
        skinHealthIndex: 71.0,
        acneScore: 60.0,
        hydrationScore: 82.5,
        thumbnailAsset: 'assets/images/face_outline.png',
        status: 'completed',
      ),
    ];
  }
}
