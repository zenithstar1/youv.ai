/// Hair analysis API host. Change [baseUrl] when the server moves.
class HairApiConfig {
  HairApiConfig._();

  /// Live hair/scalp analysis backend.
  static const String baseUrl = 'http://147.93.18.158:8001';

  static const Duration requestTimeout = Duration(seconds: 120);

  static Uri healthUri() => Uri.parse('$baseUrl/health');

  static Uri analyzeUri({bool includeImages = true}) => Uri.parse(
        '$baseUrl/analyze',
      ).replace(
        queryParameters: {
          'include_images': includeImages ? 'true' : 'false',
        },
      );

  static Uri analyzeMultiUri() => Uri.parse('$baseUrl/analyze-multi');
}
