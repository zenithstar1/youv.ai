import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_analysis_app/services/auth_service.dart';

import '../config/hair_api_config.dart';
import '../models/hair_multi_result.dart';
import '../models/hair_single_result.dart';

class HairAnalysisException implements Exception {
  final String message;
  final int? statusCode;

  const HairAnalysisException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Client for dashboard hair analysis: POST /api/analyze-hair
class HairAnalysisClient {
  HairAnalysisClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// POST /api/analyze-hair
  /// multipart: file, view_type, guest_id + Authorization Bearer
  Future<HairSingleResult> analyzeSingle({
    required Uint8List bytes,
    required String fileName,
    String viewType = 'Front View',
    String? guestId,
    @Deprecated('Ignored — new API does not use include_images')
    bool includeImages = false,
  }) async {
    final resolvedGuestId = guestId ?? await _resolveGuestId();
    final token = await AuthService.getAccessToken();
    if (token.isEmpty) {
      throw const HairAnalysisException(
        'Please log in to analyze hair.',
        statusCode: 401,
      );
    }

    Future<http.Response> sendOnce(String bearer) async {
      final req = http.MultipartRequest('POST', HairApiConfig.analyzeHairUri());
      req.headers['Accept'] = 'application/json';
      req.headers['Authorization'] = 'Bearer $bearer';
      req.fields['view_type'] = viewType;
      req.fields['guest_id'] = resolvedGuestId;
      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: _safeName(fileName),
        ),
      );

      final streamed = await _http.send(req).timeout(HairApiConfig.requestTimeout);
      return http.Response.fromStream(streamed)
          .timeout(HairApiConfig.requestTimeout);
    }

    var res = await sendOnce(token);
    if (res.statusCode == 401) {
      final refreshed = await AuthService.refreshAccessToken();
      if (refreshed) {
        final newToken = await AuthService.getAccessToken();
        if (newToken.isNotEmpty) {
          res = await sendOnce(newToken);
        }
      }
    }

    return _parseSingle(res);
  }

  /// Runs [analyzeSingle] per image and builds a multi-view summary.
  /// (Legacy /analyze-multi on the IP host is no longer used.)
  Future<HairMultiResult> analyzeMulti({
    required List<({Uint8List bytes, String fileName, String viewType})> files,
    String? guestId,
  }) async {
    if (files.isEmpty) {
      throw const HairAnalysisException('At least one image is required.');
    }

    final singles = <HairSingleResult>[];
    for (final f in files) {
      singles.add(
        await analyzeSingle(
          bytes: f.bytes,
          fileName: f.fileName,
          viewType: f.viewType,
          guestId: guestId,
        ),
      );
    }

    return HairMultiResult.fromSingles(singles);
  }

  HairSingleResult _parseSingle(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HairAnalysisException(
        _errorMessage(res),
        statusCode: res.statusCode,
      );
    }
    final decoded = json.decode(res.body);
    if (decoded is! Map) {
      throw const HairAnalysisException('Invalid analysis response.');
    }
    return HairSingleResult.fromJson(Map<String, dynamic>.from(decoded));
  }

  String _errorMessage(http.Response res) {
    try {
      final decoded = json.decode(res.body);
      if (decoded is Map) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
          return detail.toString();
        }
        if (decoded['message'] != null) return decoded['message'].toString();
      }
    } catch (_) {}
    if (res.statusCode == 401) {
      return 'Session expired. Please log in again.';
    }
    return 'Analysis failed (${res.statusCode}). Please try again.';
  }

  Future<String> _resolveGuestId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('userInfo');
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is Map) {
          for (final key in [
            'guest_id',
            'guestId',
            'id',
            'user_id',
            'userId',
            'phone',
            'mobile',
          ]) {
            final v = decoded[key];
            if (v != null && v.toString().trim().isNotEmpty) {
              return v.toString().trim();
            }
          }
        }
      }
    } catch (_) {}
    return 'guest_app';
  }

  String _safeName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'capture.jpg';
    return trimmed;
  }
}
