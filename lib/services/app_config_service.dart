import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:skin_analysis_app/config/api_config.dart';
import 'package:skin_analysis_app/models/app_config_response.dart';

class AppConfigService {
  static const Duration _timeout = Duration(seconds: 15);

  /// Fetches backend-controlled app config from GET /app/config.
  ///
  /// Parsing is handled by [AppConfigResponse.fromJson], which supports wrapped
  /// `{data:{...}}` responses too.
  Future<AppConfigResponse> getConfig() async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}/app/config');

    debugPrint('[AppConfigService] GET $uri');

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw AppConfigException(
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map) {
      throw const AppConfigException('Invalid response format');
    }

    return AppConfigResponse.fromJson(Map<String, dynamic>.from(decoded));
  }
}

class AppConfigException implements Exception {
  final String message;

  const AppConfigException(this.message);

  @override
  String toString() => message;
}