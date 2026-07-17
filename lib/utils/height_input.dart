/// Parses flexible height strings (matching backend registration rules).
class HeightInput {
  HeightInput._();

  /// Characters allowed while typing: digits, `.`, `'`, `m`, `c` (for cm).
  static final RegExp allowedInput = RegExp(r"[0-9.'mMcC]");

  /// Converts user input to centimeters, or null if unrecognised.
  ///
  /// Examples:
  /// - `5'9` / `5.9` → 5 ft 9 in
  /// - `175` / `175cm` → 175 cm
  /// - `1.75` / `1.75m` → 1.75 m
  /// - `6` → 6 ft
  static double? parseToCentimeters(String raw) {
    var input = raw.trim().toLowerCase().replaceAll(' ', '');
    if (input.isEmpty) return null;

    final cmSuffix = RegExp(r'^(\d+(?:\.\d+)?)cm$').firstMatch(input);
    if (cmSuffix != null) return double.parse(cmSuffix.group(1)!);

    final mSuffix = RegExp(r'^(\d+(?:\.\d+)?)m$').firstMatch(input);
    if (mSuffix != null) return double.parse(mSuffix.group(1)!) * 100;

    final ftInches = RegExp(r"""^(\d+)[''](\d+)"?$""").firstMatch(input);
    if (ftInches != null) {
      return _feetInchesToCm(
        int.parse(ftInches.group(1)!),
        int.parse(ftInches.group(2)!),
      );
    }

    final feetDotInches = RegExp(r'^(\d+)\.(\d+)$').firstMatch(input);
    if (feetDotInches != null) {
      final inches = int.parse(feetDotInches.group(2)!);
      if (inches < 12) {
        return _feetInchesToCm(
          int.parse(feetDotInches.group(1)!),
          inches,
        );
      }
    }

    final value = double.tryParse(input);
    if (value == null) return null;

    // 1.75 → metres
    if (value > 0 && value < 3) return value * 100;

    // 6 → feet (whole numbers 4–8)
    if (value == value.roundToDouble() && value >= 4 && value <= 8) {
      return value * 30.48;
    }

    // 175 → cm
    if (value >= 30) return value;

    return value;
  }

  static String? normalizeForApi(String raw) {
    final cm = parseToCentimeters(raw);
    if (cm == null) return null;
    final rounded = (cm * 10).roundToDouble() / 10;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(1);
  }

  static double _feetInchesToCm(int feet, int inches) =>
      (feet * 12 + inches) * 2.54;
}
