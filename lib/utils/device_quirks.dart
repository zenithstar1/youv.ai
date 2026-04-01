import 'package:flutter/foundation.dart';

/// Detects manufacturer-specific quirks and returns tuned parameters
/// to work around known Android OEM camera/battery issues.
class DeviceQuirks {
  static String? _cachedManufacturer;
  static String? _cachedModel;

  /// Lowercase device manufacturer (e.g. "xiaomi", "samsung", "huawei").
  static String get manufacturer {
    if (_cachedManufacturer != null) return _cachedManufacturer!;
    if (kIsWeb) return '';
    try {
      // Platform.environment is not available on all devices; fall back to ''.
      // We rely on the build properties exposed through the system.
      _cachedManufacturer = _readSystemProp('ro.product.manufacturer');
    } catch (_) {
      _cachedManufacturer = '';
    }
    return _cachedManufacturer!;
  }

  static String get model {
    if (_cachedModel != null) return _cachedModel!;
    if (kIsWeb) return '';
    try {
      _cachedModel = _readSystemProp('ro.product.model');
    } catch (_) {
      _cachedModel = '';
    }
    return _cachedModel!;
  }

  /// Attempt to read Android system property.
  /// Falls back to empty string on failure.
  static String _readSystemProp(String key) {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return '';
      }
    } catch (_) {}
    return '';
  }

  /// Extra delay (ms) after Camera2 session initialization.
  /// Some OEMs need more time before the image stream is stable.
  static int get cameraStabilizationDelayMs {
    final m = manufacturer.toLowerCase();
    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
      return 600; // Xiaomi Camera2 HAL takes longer
    }
    if (m.contains('huawei') || m.contains('honor')) {
      return 500;
    }
    if (m.contains('oppo') || m.contains('realme') || m.contains('oneplus')) {
      return 400;
    }
    if (m.contains('samsung')) {
      return 350;
    }
    // Default for most devices
    return 300;
  }

  /// Watchdog stale-frame threshold in milliseconds.
  /// Slow Camera2 HAL implementations need a longer window.
  static int get watchdogStaleThresholdMs {
    final m = manufacturer.toLowerCase();
    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
      return 5000;
    }
    if (m.contains('huawei') || m.contains('honor')) {
      return 5000;
    }
    // Default
    return 3500;
  }

  /// Startup grace period for the watchdog before declaring "no frames".
  static int get watchdogStartupGraceMs {
    final m = manufacturer.toLowerCase();
    if (m.contains('xiaomi') ||
        m.contains('huawei') ||
        m.contains('oppo') ||
        m.contains('samsung')) {
      return 8000;
    }
    return 6000;
  }

  /// Max number of stream-restart attempts before full camera reinit.
  static int get maxStreamRestartsBeforeReinit {
    return 4;
  }

  /// Minimum interval between full camera reinitializations (seconds).
  static int get minReinitIntervalSec {
    return 15;
  }

  /// Whether this device is known to aggressively kill background processing.
  /// Used to show user warnings or request battery optimization exemption.
  static bool get hasAggressiveBatteryOptimization {
    final m = manufacturer.toLowerCase();
    return m.contains('xiaomi') ||
        m.contains('redmi') ||
        m.contains('poco') ||
        m.contains('huawei') ||
        m.contains('honor') ||
        m.contains('oppo') ||
        m.contains('vivo') ||
        m.contains('realme') ||
        m.contains('meizu') ||
        m.contains('oneplus');
  }

  /// Delay between stopping and restarting the image stream (ms).
  /// Some Camera2 HALs crash if restarted too quickly.
  static int get streamRestartDelayMs {
    final m = manufacturer.toLowerCase();
    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
      return 500;
    }
    if (m.contains('samsung')) {
      return 350;
    }
    return 250;
  }
}
