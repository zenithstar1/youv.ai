import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_analysis_app/Api/Apiservice.dart';

class ProfileService {
  static const Duration _timeout = Duration(seconds: 15);

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('_token');
  }

  static Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  /// Fetches profile from API. Caches result in SharedPreferences on success.
  /// Falls back to cached data if the API fails.
  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return _readCache();
    }

    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.dashboardBaseUrl}/user/profile'),
            headers: _authHeaders(token),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          await _writeCache(data);
          return data;
        }
        return _readCache();
      }

      if (response.statusCode == 401) {
        throw const ProfileException('Session expired. Please log in again.');
      }

      return _readCache();
    } on ProfileException {
      rethrow;
    } catch (_) {
      return _readCache();
    }
  }

  /// Returns the locally cached profile without hitting the network.
  static Future<Map<String, dynamic>?> getCachedProfile() => _readCache();

  /// Uploads a new avatar image. Returns the updated [avatar_url] or null.
  static Future<String?> uploadAvatar(XFile xFile) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final bytes = await xFile.readAsBytes();
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiService.dashboardBaseUrl}/user/avatar'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: xFile.name.isNotEmpty ? xFile.name : 'avatar.jpg',
        ),
      );

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final url = body['data']?['avatar_url'] as String?;
          if (url != null) {
            // Update the cached profile with the new avatar URL.
            final cached = await _readCache() ?? {};
            cached['avatar_url'] = url;
            await _writeCache(cached);
          }
          return url;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Cache helpers ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('userInfo');
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(json.decode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userInfo', json.encode(data));
  }
}

class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);

  @override
  String toString() => message;
}
