import 'package:skin_analysis_app/config/api_config.dart';

/// Hair analysis API host. Change [baseUrl] when the server moves.
class HairApiConfig {
  HairApiConfig._();

  // Previous direct IP backend (CORS / cleartext issues on Flutter web):
  // static const String baseUrl = 'http://147.93.18.158:8001';

  /// Dashboard hair analysis API (authenticated).
  static const String baseUrl = ApiConfig.apiBaseUrl;

  static const Duration requestTimeout = Duration(seconds: 120);

  /// POST /api/analyze-hair  (multipart: file, view_type, guest_id)
  static Uri analyzeHairUri() => Uri.parse('$baseUrl/analyze-hair');

  // --- Legacy IP endpoints (kept for reference) ---
  // static Uri healthUri() => Uri.parse('$baseUrl/health');
  // static Uri analyzeUri({bool includeImages = true}) => Uri.parse(
  //       '$baseUrl/analyze',
  //     ).replace(
  //       queryParameters: {
  //         'include_images': includeImages ? 'true' : 'false',
  //       },
  //     );
  // static Uri analyzeMultiUri() => Uri.parse('$baseUrl/analyze-multi');
}
