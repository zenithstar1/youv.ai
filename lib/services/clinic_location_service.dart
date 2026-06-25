import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:skin_analysis_app/config/api_config.dart';

class ClinicLocation {
  final int id;
  final String name;
  final String city;
  final String state;
  final String label;

  const ClinicLocation({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.label,
  });

  factory ClinicLocation.fromJson(Map<String, dynamic> json) {
    final name = (json['name']?.toString() ?? '').trim();
    final city = (json['city']?.toString() ?? '').trim();
    final state = (json['state']?.toString() ?? '').trim();
    final label = (json['label']?.toString() ?? '').trim();

    return ClinicLocation(
      id: _readClinicId(json['id']),
      name: name,
      city: city,
      state: state,
      label: label.isNotEmpty
          ? label
          : [name, city, state].where((part) => part.isNotEmpty).join(' · '),
    );
  }
}

int _readClinicId(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class ClinicLocationsResult {
  final List<ClinicLocation> clinics;
  final ClinicLocation? matchedClinic;
  final String? portalLabel;
  final int? clinicId;

  const ClinicLocationsResult({
    required this.clinics,
    required this.matchedClinic,
    required this.portalLabel,
    required this.clinicId,
  });

  String? get displayLabel =>
      matchedClinic?.label.isNotEmpty == true
          ? matchedClinic!.label
          : portalLabel;
}

class ClinicLocationService {
  static const Duration _timeout = Duration(seconds: 15);

  /// Fetches clinic/location options for registration from
  /// [GET /clinic-locations](https://narayana.youv.ai/dashboard/api/clinic-locations).
  static Future<ClinicLocationsResult?> fetch({String scannerUrl = ''}) async {
    try {
      final query = <String, String>{};
      if (kIsWeb) {
        query['portal_host'] = Uri.base.host;
      }
      if (scannerUrl.isNotEmpty) {
        query['scanner_url'] = scannerUrl;
      }

      final uri = Uri.parse('${ApiConfig.apiBaseUrl}/clinic-locations')
          .replace(queryParameters: query.isEmpty ? null : query);

      debugPrint('[ClinicLocationService] GET $uri');

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint(
          '[ClinicLocationService] HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map) return null;
      final body = Map<String, dynamic>.from(decoded);

      if (!_isSuccess(body['success'])) {
        debugPrint('[ClinicLocationService] success=false: $body');
        return null;
      }

      final portal = body['portal'] is Map
          ? Map<String, dynamic>.from(body['portal'] as Map)
          : null;
      final portalLabel = _labelFromPortal(portal);

      final clinics = _parseClinicList(body['data']);

      final matchedId = _readInt(portal?['clinic_id']) ??
          _readInt(portal?['primary_clinic_id']);

      ClinicLocation? matched;
      if (matchedId != null) {
        for (final clinic in clinics) {
          if (clinic.id == matchedId) {
            matched = clinic;
            break;
          }
        }
      }
      matched ??= clinics.length == 1 ? clinics.first : null;

      final clinicId = matched?.id ?? matchedId;

      if (clinics.isEmpty && clinicId == null && portalLabel == null) {
        return null;
      }

      return ClinicLocationsResult(
        clinics: clinics,
        matchedClinic: matched,
        portalLabel: portalLabel,
        clinicId: clinicId,
      );
    } catch (error, stack) {
      debugPrint('[ClinicLocationService] fetch failed: $error');
      debugPrint('$stack');
      return null;
    }
  }

  static List<ClinicLocation> _parseClinicList(dynamic raw) {
    if (raw is! List) return const [];

    final clinics = <ClinicLocation>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final clinic = ClinicLocation.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (clinic.id > 0) {
        clinics.add(clinic);
      }
    }
    return clinics;
  }

  static bool _isSuccess(dynamic value) {
    if (value == true) return true;
    if (value is num) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static String? _labelFromPortal(Map<String, dynamic>? portal) {
    if (portal == null) return null;

    final registrationLink = (portal['registration_link']?.toString() ?? '')
        .trim();
    if (registrationLink.isNotEmpty) return registrationLink;

    final portalHost = (portal['portal_host']?.toString() ?? '').trim();
    if (portalHost.isNotEmpty) return portalHost;

    final registrationUrl = (portal['registration_url']?.toString() ?? '')
        .trim();
    if (registrationUrl.isNotEmpty) {
      return Uri.tryParse(registrationUrl)?.host ?? registrationUrl;
    }

    return null;
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
