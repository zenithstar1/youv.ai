/// Central API host configuration for the Narayana dashboard backend.
class ApiConfig {
  ApiConfig._();

  /// Optional compile-time override, e.g. for `flutter run` against a tenant.
  static const String _overrideOrigin = String.fromEnvironment(
    'API_ORIGIN',
    defaultValue: '',
  );

  /// App path segment served behind each tenant host.
  static const String appPath = '/dashboard';

  /// Fallback when not on web and no [API_ORIGIN] is set (e.g. Android builds).
  static const String fallbackOrigin = 'https://narayana.youv.ai$appPath';

  /// Dashboard origin, e.g. https://narayana.youv.ai/dashboard
  static const String dashboardOrigin = 'https://narayana.youv.ai/dashboard';

  /// REST API base, e.g. https://narayana.youv.ai/dashboard/api
  static const String apiBaseUrl = '$dashboardOrigin/api';

  /// Auth API base, e.g. https://narayana.youv.ai/dashboard/api/auth
  static const String authBaseUrl = '$apiBaseUrl/auth';

  // ---------------------------------------------------------------------------
  // DEV OTP bypass — set [otpBypassEnabled] to false to restore normal OTP flow.
  // ---------------------------------------------------------------------------
  static const bool otpBypassEnabled = false;
  static const String otpBypassCode = '1234';
}
