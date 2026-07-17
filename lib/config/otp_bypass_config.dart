import 'api_config.dart';

/// Helpers for the reversible dev OTP bypass controlled by [ApiConfig].
class OtpBypassConfig {
  OtpBypassConfig._();

  static bool get enabled => ApiConfig.otpBypassEnabled;

  static String get code => ApiConfig.otpBypassCode;

  static const String invalidOtpMessage = 'Invalid OTP';

  static String _digitsOnly(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9]'), '');

  static bool matches(String raw) =>
      enabled && _digitsOnly(raw) == code;

  /// Client-side OTP format check before dispatching to [AuthBloc].
  static bool isValid(String raw) {
    final otp = _digitsOnly(raw);
    if (enabled) return otp == code;
    return otp.length == 6;
  }
}
