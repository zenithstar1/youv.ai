/// Central API host configuration for the Narayana dashboard backend.
class ApiConfig {
  ApiConfig._();

  /// Dashboard origin, e.g. https://narayana.youv.ai/dashboard
  static const String dashboardOrigin = 'https://demo.youv.ai/dashboard';

  /// REST API base, e.g. https://narayana.youv.ai/dashboard/api
  static const String apiBaseUrl = '$dashboardOrigin/api';

  /// Auth API base, e.g. https://narayana.youv.ai/dashboard/api/auth
  static const String authBaseUrl = '$apiBaseUrl/auth';
}
