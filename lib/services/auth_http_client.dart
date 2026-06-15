import 'package:http/http.dart' as http;

import 'auth_service.dart';

class AuthHttpClient {
  AuthHttpClient._();

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _sendWithRetry(
      () async => http.get(
        uri,
        headers: await _headers(headers),
      ),
      timeout,
    );
  }

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _sendWithRetry(
      () async => http.post(
        uri,
        headers: await _headers(headers),
        body: body,
      ),
      timeout,
    );
  }

  static Future<http.Response> sendMultipart(
    http.MultipartRequest request, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    Future<http.Response> send() async {
      final token = await AuthService.getAccessToken();
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      final streamed = await request.send().timeout(timeout);
      return http.Response.fromStream(streamed);
    }

    final response = await send();
    if (response.statusCode != 401) return response;

    final refreshed = await AuthService.refreshAccessToken();
    if (!refreshed) {
      await AuthService.clearSession();
      return response;
    }

    return response;
  }

  static Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() send,
    Duration timeout,
  ) async {
    var response = await send().timeout(timeout);
    if (response.statusCode != 401) return response;

    final refreshed = await AuthService.refreshAccessToken();
    if (!refreshed) {
      await AuthService.clearSession();
      return response;
    }

    response = await send().timeout(timeout);
    if (response.statusCode == 401) {
      await AuthService.clearSession();
    }
    return response;
  }

  static Future<Map<String, String>> _headers(
    Map<String, String>? headers,
  ) async {
    final token = await AuthService.getAccessToken();
    return {
      if (headers != null) ...headers,
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
