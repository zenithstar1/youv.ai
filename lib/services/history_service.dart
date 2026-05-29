import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_analysis_app/Api/Apiservice.dart';

/// Wraps the paginated response from GET /analysis-history.
class HistoryResult {
  final List<Map<String, dynamic>> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const HistoryResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  static const HistoryResult empty = HistoryResult(
    items: [],
    currentPage: 1,
    lastPage: 1,
    total: 0,
  );
}

class HistoryService {
  static const Duration _timeout = Duration(seconds: 15);

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('_token');
  }

  /// Fetches a page of analysis history for the logged-in user.
  ///
  /// [page] is 1-based. [perPage] is clamped to a max of 50 by the backend.
  static Future<HistoryResult> getHistory({
    int page = 1,
    int perPage = 15,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return HistoryResult.empty;
    }

    try {
      final uri = Uri.parse('${ApiService.dashboardBaseUrl}/analysis-history').replace(
        queryParameters: {
          'page': '$page',
          'per_page': '$perPage',
        },
      );

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(_timeout);

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final raw = body['data'];
          final items = (raw is List)
              ? raw
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : <Map<String, dynamic>>[];

          final pagination =
              (body['pagination'] as Map<String, dynamic>?) ?? {};
          final currentPage = (pagination['current_page'] as int?) ?? 1;
          final lastPage = (pagination['last_page'] as int?) ?? 1;
          final total =
              (pagination['total'] as int?) ?? items.length;

          return HistoryResult(
            items: items,
            currentPage: currentPage,
            lastPage: lastPage,
            total: total,
          );
        }
        return HistoryResult.empty;
      }

      if (response.statusCode == 401) {
        throw const HistoryException('Session expired. Please log in again.');
      }

      return HistoryResult.empty;
    } on HistoryException {
      rethrow;
    } catch (_) {
      return HistoryResult.empty;
    }
  }

  /// Fetches a single analysis detail by ID.
  static Future<Map<String, dynamic>?> getDetail(int analysisId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse('${ApiService.dashboardBaseUrl}/analysis-history/$analysisId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class HistoryException implements Exception {
  final String message;
  const HistoryException(this.message);

  @override
  String toString() => message;
}
