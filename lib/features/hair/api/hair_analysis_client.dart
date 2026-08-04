import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

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

/// Thin client for the hosted hair analysis API.
class HairAnalysisClient {
  HairAnalysisClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<bool> healthCheck() async {
    try {
      final res = await _http
          .get(
            HairApiConfig.healthUri(),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return false;
      final decoded = json.decode(res.body);
      return decoded is Map && decoded['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// POST /analyze?include_images=true  (field: file)
  Future<HairSingleResult> analyzeSingle({
    required Uint8List bytes,
    required String fileName,
    bool includeImages = true,
  }) async {
    final uri = HairApiConfig.analyzeUri(includeImages: includeImages);
    final req = http.MultipartRequest('POST', uri);
    req.headers['Accept'] = 'application/json';
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: _safeName(fileName),
      ),
    );

    final streamed = await req.send().timeout(HairApiConfig.requestTimeout);
    final res = await http.Response.fromStream(streamed)
        .timeout(HairApiConfig.requestTimeout);

    return _parseSingle(res);
  }

  /// POST /analyze-multi  (field: files, repeated)
  Future<HairMultiResult> analyzeMulti({
    required List<({Uint8List bytes, String fileName})> files,
  }) async {
    if (files.isEmpty) {
      throw const HairAnalysisException('At least one image is required.');
    }

    final req = http.MultipartRequest('POST', HairApiConfig.analyzeMultiUri());
    req.headers['Accept'] = 'application/json';

    for (final f in files) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'files',
          f.bytes,
          filename: _safeName(f.fileName),
        ),
      );
    }

    final streamed = await req.send().timeout(HairApiConfig.requestTimeout);
    final res = await http.Response.fromStream(streamed)
        .timeout(HairApiConfig.requestTimeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HairAnalysisException(
        _errorMessage(res),
        statusCode: res.statusCode,
      );
    }

    final decoded = json.decode(res.body);
    if (decoded is! Map) {
      throw const HairAnalysisException('Invalid multi-analysis response.');
    }
    return HairMultiResult.fromJson(Map<String, dynamic>.from(decoded));
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
        if (decoded['message'] != null) return decoded['message'].toString();
      }
    } catch (_) {}
    return 'Analysis failed (${res.statusCode}). Please try again.';
  }

  String _safeName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'capture.jpg';
    return trimmed;
  }
}
