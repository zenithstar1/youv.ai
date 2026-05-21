import 'package:flutter/material.dart';

/// Represents a single skin-analysis session in the activity history.
class ActivityModel {
  final String id;
  final String analysisType;
  final DateTime date;
  final double acneScore;
  final double hydrationScore;
  final double? pigmentationScore;
  final double? wrinklesScore;
  final double? overallScore;
  final String? severity;
  final String? thumbnailAsset;
  final String? thumbnailUrl;
  final String status;

  const ActivityModel({
    required this.id,
    required this.analysisType,
    required this.date,
    required this.acneScore,
    required this.hydrationScore,
    this.pigmentationScore,
    this.wrinklesScore,
    this.overallScore,
    this.severity,
    this.thumbnailAsset,
    this.thumbnailUrl,
    this.status = 'completed',
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final scores = json['scores'] as Map<String, dynamic>? ?? {};
    return ActivityModel(
      id: json['analysis_id']?.toString() ?? json['id']?.toString() ?? '',
      analysisType: _formatAnalysisType(
          json['analysis_type']?.toString() ?? 'Skin Analysis'),
      date: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      acneScore: (scores['acne'] as num?)?.toDouble() ??
          (json['acne_score'] as num?)?.toDouble() ??
          0.0,
      hydrationScore: (scores['skin_health_index'] as num?)?.toDouble() ??
          (json['hydration_score'] as num?)?.toDouble() ??
          0.0,
      pigmentationScore: (scores['pigmentation'] as num?)?.toDouble() ??
          (json['pigmentation_score'] as num?)?.toDouble(),
      wrinklesScore: (scores['wrinkles'] as num?)?.toDouble() ??
          (json['wrinkles_score'] as num?)?.toDouble(),
      overallScore: (json['overall_score'] as num?)?.toDouble() ??
          (scores['overall'] as num?)?.toDouble(),
      severity: json['severity']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      status: json['status']?.toString() ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'analysis_type': analysisType,
        'created_at': date.toIso8601String(),
        'acne_score': acneScore,
        'hydration_score': hydrationScore,
        'pigmentation_score': pigmentationScore,
        'wrinkles_score': wrinklesScore,
        'overall_score': overallScore,
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
        acneScore: 72.5,
        hydrationScore: 68.0,
        pigmentationScore: 55.0,
        wrinklesScore: 80.0,
        overallScore: 72.5,
        thumbnailAsset: 'assets/images/face_outline.png',
        status: 'completed',
      ),
      ActivityModel(
        id: 'act_002',
        analysisType: 'Skin Analysis',
        date: DateTime(2025, 4, 22),
        acneScore: 60.0,
        hydrationScore: 82.5,
        overallScore: 71.0,
        thumbnailAsset: 'assets/images/face_outline.png',
        status: 'completed',
      ),
    ];
  }
}
