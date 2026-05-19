import 'package:flutter/material.dart';

/// Lightweight responsive scaling helper.
///
/// Instantiate at the top of build() methods:
///   final r = Responsive(context);
///
/// Then use its methods for proportional sizing:
///   fontSize: r.sp(14)                    // font scaling
///   SizedBox(height: r.h(24))             // vertical spacing
///   padding: EdgeInsets.all(r.w(16))      // horizontal scaling
///
/// Reference device: 375 × 812 (standard mobile phone).
/// Values scale proportionally with screen dimensions and are clamped
/// to prevent extremes on very small or very large screens.
class Responsive {
  Responsive(BuildContext context)
      : _size = MediaQuery.of(context).size,
        _padding = MediaQuery.of(context).padding;

  final Size _size;
  final EdgeInsets _padding;

  // Reference design dimensions (iPhone 13 / standard mobile)
  static const double _refW = 375.0;
  static const double _refH = 812.0;

  // ── Screen dimensions ──
  double get width => _size.width;
  double get height => _size.height;

  // ── Device type queries ──
  bool get isTablet => _size.shortestSide >= 600;
  bool get isSmallPhone => _size.shortestSide < 360;

  // ── Safe area insets ──
  double get topInset => _padding.top;
  double get bottomInset => _padding.bottom;

  /// Scale a value based on screen width ratio.
  /// Clamped to [0.75× .. 1.5×] of the design value to prevent extremes.
  double w(double v) {
    return (v * _size.width / _refW).clamp(v * 0.75, v * 1.5);
  }

  /// Scale a value based on screen height ratio.
  /// Clamped to [0.75× .. 1.5×] of the design value to prevent extremes.
  double h(double v) {
    return (v * _size.height / _refH).clamp(v * 0.75, v * 1.5);
  }

  /// Scale font size (width-based, tighter clamp for readability).
  /// Clamped to [0.82× .. 1.35×] so text remains legible on all screens.
  double sp(double v) {
    return (v * _size.width / _refW).clamp(v * 0.82, v * 1.35);
  }
}
