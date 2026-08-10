import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skin_analysis_app/config/api_config.dart';

class AuthService {
  AuthService._();

  static const String authBaseUrl = ApiConfig.authBaseUrl;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _legacyTokenKey = '_token';
  static const String _webAccessTokenKey = 'auth_access_token_web';
  static const String _webRefreshTokenKey = 'auth_refresh_token_web';

  static Future<String> getAccessToken() async {
    final secureToken = await _secureStorage.read(key: _accessTokenKey);

    if (secureToken != null && secureToken.trim().isNotEmpty) {
      return secureToken.trim();
    }

    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      final webToken = prefs.getString(_webAccessTokenKey) ?? '';
      if (webToken.trim().isNotEmpty) {
        return webToken.trim();
      }
    }

    final legacyToken = prefs.getString(_legacyTokenKey) ?? '';
    if (legacyToken.trim().isNotEmpty) {
      await _secureStorage.write(
        key: _accessTokenKey,
        value: legacyToken.trim(),
      );
      await prefs.remove(_legacyTokenKey);
      return legacyToken.trim();
    }

    final userInfoToken = _extractTokenFromJson(prefs.getString('userInfo'));
    if (userInfoToken.isNotEmpty) {
      await _secureStorage.write(key: _accessTokenKey, value: userInfoToken);
      await _removeSensitiveFieldsFromCachedUser(prefs);
      return userInfoToken;
    }

    return '';
  }

  static Future<String> getRefreshToken() async {
    final token = await _secureStorage.read(key: _refreshTokenKey);
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final webRefresh = prefs.getString(_webRefreshTokenKey) ?? '';
      if (webRefresh.trim().isNotEmpty) {
        return webRefresh.trim();
      }
    }

    return '';
  }

  static Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogin = prefs.getBool('isLogin') ?? false;
    final token = await getAccessToken();
    return isLogin && token.isNotEmpty;
  }

  static Future<bool> restoreSession() async {
    if (!await hasActiveSession()) return false;

    if (!await isAccessTokenExpired()) return true;

    final refreshed = await refreshAccessToken();
    if (refreshed) return true;

    // Keep the session if a token is still stored — transient refresh
    // failures (network) should not force re-login on page refresh.
    return (await getAccessToken()).isNotEmpty;
  }

  static Future<void> saveSession(Map<String, dynamic> data) async {
  final accessToken = _extractAccessToken(data);
  final refreshToken = _extractRefreshToken(data);

  if (accessToken.isEmpty) {
    throw const AuthStorageException(
      'Login response did not include a token',
    );
  }

  await _secureStorage.write(
    key: _accessTokenKey,
    value: accessToken,
  );

  if (refreshToken.isNotEmpty) {
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: refreshToken,
    );
  }

  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool('isLogin', true);
  await prefs.setBool('hasRegistered', true);
  await prefs.remove(_legacyTokenKey);
  await prefs.setString(
    'userInfo',
    json.encode(_sanitizeUserData(data)),
  );
  await prefs.setBool(
    'isSubscribe',
    data['isSubscribed'] == true,
  );

  if (kIsWeb) {
    await prefs.setString(_webAccessTokenKey, accessToken);
    if (refreshToken.isNotEmpty) {
      await prefs.setString(_webRefreshTokenKey, refreshToken);
    }
  }
}

  static Future<void> clearSession({bool keepRegistration = true}) async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLogin', false);
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_webAccessTokenKey);
    await prefs.remove(_webRefreshTokenKey);
    if (!keepRegistration) {
      await prefs.setBool('hasRegistered', false);
    }
    await _removeSensitiveFieldsFromCachedUser(prefs);
  }

  static Future<void> logoutRemote() async {
    final token = await getAccessToken();
    if (token.isEmpty) return;

    try {
      await http.post(
        Uri.parse('$authBaseUrl/logout'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken.isEmpty) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$authBaseUrl/refresh'),
            headers: {'Accept': 'application/json'},
            body: {'refresh_token': refreshToken},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return false;

      final decoded = json.decode(response.body);
      if (decoded is! Map) return false;

      final data = decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : Map<String, dynamic>.from(decoded);
      final accessToken = _extractAccessToken(data);
      if (accessToken.isEmpty) return false;

      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      final nextRefreshToken = _extractRefreshToken(data);
      if (nextRefreshToken.isNotEmpty) {
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: nextRefreshToken,
        );
      }

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_webAccessTokenKey, accessToken);
        if (nextRefreshToken.isNotEmpty) {
          await prefs.setString(_webRefreshTokenKey, nextRefreshToken);
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isAccessTokenExpired() async {
    final token = await getAccessToken();
    if (token.isEmpty) return true;

    final parts = token.split('.');
    if (parts.length != 3) return false;

    try {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = json.decode(utf8.decode(base64Url.decode(normalized)));
      if (decoded is! Map || decoded['exp'] == null) return false;

      final exp = decoded['exp'];
      final expSeconds = exp is int ? exp : int.tryParse(exp.toString());
      if (expSeconds == null) return false;

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expSeconds * 1000,
        isUtc: true,
      );
      return DateTime.now().toUtc().isAfter(
        expiresAt.subtract(const Duration(minutes: 1)),
      );
    } catch (_) {
      return false;
    }
  }

  static String _extractAccessToken(Map<String, dynamic> data) {
    return (data['token'] ??
            data['access_token'] ??
            data['accessToken'] ??
            data['bearer_token'] ??
            '')
        .toString()
        .trim();
  }

  static String _extractRefreshToken(Map<String, dynamic> data) {
    return (data['refresh_token'] ??
            data['refreshToken'] ??
            data['refresh'] ??
            data['refreshTokenPlainText'] ??
            '')
        .toString()
        .trim();
  }

  static String _extractTokenFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) return '';
      return _extractAccessToken(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return '';
    }
  }

  static Map<String, dynamic> _sanitizeUserData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    const sensitiveKeys = {
      'token',
      'access_token',
      'accessToken',
      'bearer_token',
      'refresh_token',
      'refreshToken',
      'refresh',
      'refreshTokenPlainText',
    };
    for (final key in sensitiveKeys) {
      sanitized.remove(key);
    }
    return sanitized;
  }

  static Future<void> _removeSensitiveFieldsFromCachedUser(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString('userInfo');
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) return;
      await prefs.setString(
        'userInfo',
        json.encode(_sanitizeUserData(Map<String, dynamic>.from(decoded))),
      );
    } catch (_) {
      await prefs.remove('userInfo');
    }
  }
}

class AuthStorageException implements Exception {
  final String message;
  const AuthStorageException(this.message);

  @override
  String toString() => message;
}
