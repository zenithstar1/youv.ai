import 'package:flutter/material.dart';

/// Represents a single skin-analysis session in the activity history.
///
/// All fields are nullable so that partial data from future API responses
/// can be gracefully displayed without crashing.
class ActivityModel {
  final String id;
  final String analysisType;
  final DateTime date;
  final double acneScore;
  final double hydrationScore;
  final double? pigmentationScore;
  final double? wrinklesScore;
  final String? thumbnailAsset; // local asset path (dummy)
  final String? thumbnailUrl;   // remote URL (future backend)
  final String status;          // 'completed' | 'pending' | 'failed'

  const ActivityModel({
    required this.id,
    required this.analysisType,
    required this.date,
    required this.acneScore,
    required this.hydrationScore,
    this.pigmentationScore,
    this.wrinklesScore,
    this.thumbnailAsset,
    this.thumbnailUrl,
    this.status = 'completed',
  });

  // ── Factory: parse from backend JSON ──────────────────────────────────────
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id']?.toString() ?? '',
      analysisType: json['analysis_type'] ?? 'Skin Analysis',
      date: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      acneScore: (json['acne_score'] as num?)?.toDouble() ?? 0.0,
      hydrationScore: (json['hydration_score'] as num?)?.toDouble() ?? 0.0,
      pigmentationScore: (json['pigmentation_score'] as num?)?.toDouble(),
      wrinklesScore: (json['wrinkles_score'] as num?)?.toDouble(),
      thumbnailUrl: json['thumbnail_url'],
      status: json['status'] ?? 'completed',
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
        'thumbnail_url': thumbnailUrl,
        'status': status,
      };

  /// Human-readable date string (e.g. "15 Jan 2025").
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Color-coded status chip color.
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
}

// ── Dummy / Mock data ─────────────────────────────────────────────────────────
//
// Replace `ActivityRepository.getMockActivities()` with a real API call when
// the backend is ready.  The repository pattern below makes that swap trivial.

class ActivityRepository {
  /// Returns mock analysis history for development / demo purposes.
  ///
  /// BACKEND INTEGRATION: Replace the body of this method with:
  ///   final response = await ApiService.getAnalysisHistory(token);
  ///   return (response['data'] as List).map(ActivityModel.fromJson).toList();
  static List<ActivityModel> getMockActivities() {
    return [
      ActivityModel(
        id: 'act_001',
        analysisType: 'Comprehensive Facial Analysis',
        date: DateTime(2025, 5, 10),
        acneScore: 72.5,
        hydrationScore: 68.0,
        pigmentationScore: 55.0,
        wrinklesScore: 80.0,
        thumbnailAsset: 'assets/images/face_outline.png',
        status: 'completed',
      ),
      ActivityModel(
        id: 'act_002',
        analysisType: 'Skin Hydration Check',
        date: DateTime(2025, 4, 22),
        acneScore: 60.0,
        hydrationScore: 82.5,
        pigmentationScore: 50.0,
        thumbnailAsset: 'assets/images/face_outline.png',
        status: 'completed',
      ),
      ActivityModel(
        id: 'act_003',
        analysisType: 'Comprehensive Facial Analysis',
        date: DateTime(2025, 3, 15),
        acneScore: 45.0,
        hydrationScore: 74.0,
        pigmentationScore: 48.0,
        wrinklesScore: 85.0,
        thumbnailAsset: 'assets/images/face_outline.png',
        status: 'completed',
      ),
      ActivityModel(
        id: 'act_004',
        analysisType: 'Acne Focus Scan',
        date: DateTime(2025, 2, 28),
        acneScore: 38.0,
        hydrationScore: 65.0,
        thumbnailAsset: 'assets/images/face_outline.png',
        status: 'completed',
      ),
      ActivityModel(
        id: 'act_005',
        analysisType: 'Comprehensive Facial Analysis',
        date: DateTime(2025, 1, 5),
        acneScore: 30.0,
        hydrationScore: 78.0,
        pigmentationScore: 42.0,
        wrinklesScore: 90.0,
        thumbnailAsset: 'assets/images/face_outline.png',
        status: 'completed',
      ),
    ];
  }
}
