import 'dart:math';
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_analysis_app/Api/Apiservice.dart';
import 'package:skin_analysis_app/Models/FaceRatioLine.dart';
import 'package:skin_analysis_app/utils/responsive.dart';
import 'package:skin_analysis_app/widgets/FaceRatioPainter.dart';
import '../models/skin_analysis_model.dart';

// ─────────────────────────────────────
//  Design System (from PM's React spec)
// ─────────────────────────────────────
class _DS {
  static const pageBg = Color(0xFFFDEDED);
  static const blush = Color(0xFFE4B3B8);
  static const blushDark = Color(0xFFC58A8F);
  static const white = Color(0xFFFFFFFF);
  static const textHigh = Color(0xFF1A0808);
  static const textMid = Color(0xFF3D2020);
  static const grey300 = Color(0xFFBDBDBD);
  static const grey400 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575);
  static const grey700 = Color(0xFF616161);
}

// Score thresholds matching React's THRESHOLDS
class _Threshold {
  final Color color;
  final String label;
  final String stability;

  const _Threshold(this.color, this.label, this.stability);
}

_Threshold getThreshold(double v) {
  if (v <= 30)
    return const _Threshold(Color(0xFFD32F2F), 'Bad', 'Low Stability');
  if (v <= 40)
    return const _Threshold(Color(0xFFF44336), 'Not Good', 'Low Stability');
  if (v <= 60)
    return const _Threshold(Color(0xFFFB8C00), 'Okay', 'Moderate Stability');
  if (v <= 80)
    return const _Threshold(
      Color(0xFFFBC02D),
      'Moderate',
      'Moderate Stability',
    );
  if (v <= 90)
    return const _Threshold(Color(0xFF7CB342), 'Great', 'Good Stability');
  return const _Threshold(Color(0xFF43A047), 'Excellent', 'High Stability');
}

// ─────────────────────────────────────
//  Metric data holder (dynamic from API)
// ─────────────────────────────────────
class _MetricData {
  final String label;
  final double value;
  final List<_IndicatorData> indicators;

  _MetricData({
    required this.label,
    required this.value,
    required this.indicators,
  });
}

class _IndicatorData {
  final String name;
  final double score;

  _IndicatorData({required this.name, required this.score});
}

// ─────────────────────────────────────
//  Animated Diagnostic Ring Widget
// ─────────────────────────────────────
class DiagnosticRing extends StatefulWidget {
  final double value;
  final double size;
  final bool isMain;
  final Color? overrideColor;
  final Duration delay;
  final double strokeWidth;

  const DiagnosticRing({
    super.key,
    required this.value,
    this.size = 64,
    this.isMain = false,
    this.overrideColor,
    this.delay = Duration.zero,
    this.strokeWidth = 0,
  });

  @override
  State<DiagnosticRing> createState() => _DiagnosticRingState();
}

class _DiagnosticRingState extends State<DiagnosticRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _triggered = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkVisibility();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_triggered) return;
    _scrollPosition?.removeListener(_onScroll);
    try {
      _scrollPosition = Scrollable.maybeOf(context)?.position;
    } catch (_) {
      _scrollPosition = null;
    }
    _scrollPosition?.addListener(_onScroll);
  }

  void _onScroll() => _checkVisibility();

  void _checkVisibility() {
    if (_triggered || !mounted) return;
    final ro = context.findRenderObject() as RenderBox?;
    if (ro == null || !ro.attached || !ro.hasSize) return;
    try {
      final pos = ro.localToGlobal(Offset.zero);
      final screenH = MediaQuery.of(context).size.height;
      if (pos.dy < screenH * 0.9 && pos.dy + ro.size.height > 0) {
        _trigger();
      }
    } catch (_) {
      _trigger(); // fallback: animate immediately if position check fails
    }
  }

  void _trigger() {
    if (_triggered) return;
    _triggered = true;
    _scrollPosition?.removeListener(_onScroll);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = getThreshold(widget.value);
    final color = widget.overrideColor ?? t.color;
    final sw = widget.strokeWidth > 0
        ? widget.strokeWidth
        : (widget.isMain ? 8.0 : 6.0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final progress = _anim.value * widget.value / 100;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: progress,
              color: color,
              strokeWidth: sw,
              bgColor: _DS.blush.withOpacity(0.25),
              showInnerRing: !widget.isMain && widget.size >= 78,
            ),
            child: Center(
              child: Opacity(
                opacity: _anim.value > 0.3 ? 1 : 0,
                child: Text(
                  widget.value.round().toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: widget.isMain ? 28 : (widget.size > 70 ? 20 : 16),
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Color bgColor;
  final bool showInnerRing;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.bgColor,
    this.showInnerRing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth * 2) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Glow behind progress arc (for scores above 60%)
    if (progress > 0.6) {
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Progress arc
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Inner ring (only for main/hero rings)
    if (showInnerRing) {
      final innerRadius = radius - strokeWidth - 3;
      if (innerRadius > 4) {
        canvas.drawCircle(
          center,
          innerRadius,
          Paint()
            ..color = bgColor.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: innerRadius),
          -pi / 2,
          2 * pi * progress,
          false,
          Paint()
            ..color = color.withOpacity(0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────
//  Section Rule (divider)
// ─────────────────────────────────────
class _SectionRule extends StatelessWidget {
  const _SectionRule();

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(24), vertical: r.h(24)),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              _DS.blush.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
//  Half Ring (semicircle gauge)
// ─────────────────────────────────────
class _HalfRing extends StatefulWidget {
  final double value; // 0–100
  final double size;
  final Color color;
  final double strokeWidth;

  const _HalfRing({
    required this.value,
    required this.size,
    required this.color,
    this.strokeWidth = 9,
  });

  @override
  State<_HalfRing> createState() => _HalfRingState();
}

class _HalfRingState extends State<_HalfRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _triggered = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_triggered) return;
    _scrollPosition?.removeListener(_check);
    try {
      _scrollPosition = Scrollable.maybeOf(context)?.position;
    } catch (_) {
      _scrollPosition = null;
    }
    _scrollPosition?.addListener(_check);
  }

  void _check() {
    if (_triggered || !mounted) return;
    final ro = context.findRenderObject() as RenderBox?;
    if (ro == null || !ro.attached || !ro.hasSize) return;
    try {
      final pos = ro.localToGlobal(Offset.zero);
      final screenH = MediaQuery.of(context).size.height;
      if (pos.dy < screenH * 0.9 && pos.dy + ro.size.height > 0) {
        _triggered = true;
        _scrollPosition?.removeListener(_check);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _ctrl.forward();
        });
      }
    } catch (_) {
      _triggered = true;
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_check);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final progress = _anim.value * widget.value / 100;
        return SizedBox(
          width: widget.size,
          height: widget.size * 0.55, // half height
          child: CustomPaint(
            painter: _HalfRingPainter(
              progress: progress,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
              bgColor: _DS.blush.withOpacity(0.25),
            ),
          ),
        );
      },
    );
  }
}

class _HalfRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Color bgColor;

  _HalfRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - strokeWidth / 2;
    final radius = (size.width - strokeWidth * 2) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background half arc
    canvas.drawArc(
      rect,
      pi,
      pi,
      false,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt,
    );

    // Glow
    if (progress > 0.5) {
      canvas.drawArc(
        rect,
        pi,
        pi * progress,
        false,
        Paint()
          ..color = color.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6
          ..strokeCap = StrokeCap.butt
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Progress half arc
    canvas.drawArc(
      rect,
      pi,
      pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(_HalfRingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────
//  Pulse Dot (animated opacity)
// ─────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.35,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(_opacity.value),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(_opacity.value * 0.25),
              blurRadius: 6,
              spreadRadius: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
//  Bouncing Chevron
// ─────────────────────────────────────
class _BouncingChevron extends StatefulWidget {
  @override
  State<_BouncingChevron> createState() => _BouncingChevronState();
}

class _BouncingChevronState extends State<_BouncingChevron>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _offset;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _offset = Tween<double>(
      begin: 0,
      end: 6,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.88), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 0.5), weight: 50),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _offset.value),
        child: Opacity(
          opacity: _opacity.value,
          child: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: _DS.grey400,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
//  Scroll-triggered Fade + Slide In
// ─────────────────────────────────────
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn> {
  bool _visible = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visible) return;
    _scrollPosition?.removeListener(_check);
    try {
      _scrollPosition = Scrollable.maybeOf(context)?.position;
    } catch (_) {
      _scrollPosition = null;
    }
    _scrollPosition?.addListener(_check);
  }

  void _check() {
    if (_visible || !mounted) return;
    final ro = context.findRenderObject() as RenderBox?;
    if (ro == null || !ro.attached || !ro.hasSize) return;
    try {
      final pos = ro.localToGlobal(Offset.zero);
      final screenH = MediaQuery.of(context).size.height;
      if (pos.dy < screenH * 0.88 && pos.dy + ro.size.height > 0) {
        _scrollPosition?.removeListener(_check);
        if (widget.delay == Duration.zero) {
          setState(() => _visible = true);
        } else {
          Future.delayed(widget.delay, () {
            if (mounted) setState(() => _visible = true);
          });
        }
      }
    } catch (_) {
      setState(() => _visible = true);
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _visible ? 0 : 20, 0),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────
//  Stage Label
// ─────────────────────────────────────
class _StageLabel extends StatelessWidget {
  final String number;
  final String title;
  final String sub;

  const _StageLabel({
    required this.number,
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.w(24), r.h(20), r.w(24), 0),
      child: Row(
        children: [
          Container(
            width: r.w(28),
            height: r.w(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _DS.blush.withOpacity(0.18),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: r.sp(13),
                  color: _DS.blush,
                ),
              ),
            ),
          ),
          SizedBox(width: r.w(12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sub.toUpperCase(),
                style: TextStyle(
                  fontSize: r.sp(10),
                  letterSpacing: 2.2,
                  color: _DS.grey400,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: r.sp(17),
                  fontWeight: FontWeight.w600,
                  color: _DS.textHigh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════
class SkinAnalysisRedesigned extends StatefulWidget {
  final SkinAnalysisModel? analysisData;
  final Uint8List? imageBytes;
  final Map<String, dynamic>? faceRatioJson;
  final Map<String, dynamic>? apiResponse;

  const SkinAnalysisRedesigned({
    super.key,
    this.analysisData,
    this.imageBytes,
    this.faceRatioJson,
    this.apiResponse,
  });

  @override
  State<SkinAnalysisRedesigned> createState() => _SkinAnalysisRedesignedState();
}

class _SkinAnalysisRedesignedState extends State<SkinAnalysisRedesigned> {
  late int selectedColorIndex;
  int? _activeMetricIdx;
  bool _sendingReport = false;
  String _reportMessage = '';
  bool _reportSent = false;
  bool _disclaimerExpanded = false;

  // Facial structure swipe
  late PageController _structurePageController;
  int _structurePage = 0;

  final List<RatioMode> _ratioModes = [
    RatioMode.vertical,
    RatioMode.horizontal,
    RatioMode.eyes,
    RatioMode.faceBox,
    RatioMode.noseLipChin,
    RatioMode.lips,
    RatioMode.jaw,
  ];

  final List<Color> fitzpatrickColors = [
    const Color(0xFFF6DDD2),
    const Color(0xFFEFD0BE),
    const Color(0xFFE2B79D),
    const Color(0xFFD09B7E),
    const Color(0xFFBC8063),
  ];

  @override
  void initState() {
    super.initState();
    selectedColorIndex =
        (widget.analysisData?.fitzpatrickType ?? 1).clamp(1, 5) - 1;
    _structurePageController = PageController(viewportFraction: 0.85);
  }

  @override
  void didUpdateWidget(covariant SkinAnalysisRedesigned oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldType = oldWidget.analysisData?.fitzpatrickType;
    final newType = widget.analysisData?.fitzpatrickType;
    if (newType != null && newType != oldType) {
      // Keep tone display in sync with latest analysis result (non-interactive).
      selectedColorIndex = newType.clamp(1, 5) - 1;
    }
  }

  @override
  void dispose() {
    _structurePageController.dispose();
    super.dispose();
  }

  // ─── DATA HELPERS ───
  List<_MetricData> _buildMetrics() {
    final d = widget.analysisData;
    if (d == null) return [];
    return [
      _MetricData(
        label: 'Acne',
        value: d.acneScore,
        indicators: _buildIndicators(_getAcneFactors()),
      ),
      _MetricData(
        label: 'Hydration',
        value: d.hydrationScore,
        indicators: _buildIndicators(_getHydrationFactors()),
      ),
      _MetricData(
        label: 'Wrinkles',
        value: d.wrinklesScore,
        indicators: _buildIndicators(_getWrinklesFactors()),
      ),
      _MetricData(
        label: 'Pigmentation',
        value: d.pigmentationScore,
        indicators: _buildIndicators(_getPigmentationFactors()),
      ),
      _MetricData(
        label: 'Pores',
        value: d.poresScore,
        indicators: _buildIndicators(_getPoresFactors()),
      ),
    ];
  }

  List<_IndicatorData> _buildIndicators(List<FactorItem> factors) {
    return factors
        .map(
          (f) => _IndicatorData(
            name: f.name,
            score: ((1 - f.value) * 100).clamp(0, 100),
          ),
        )
        .toList();
  }

  List<FactorItem> _getAcneFactors() {
    final f = widget.analysisData!.acneFactors;
    return [
      FactorItem(name: 'Active Acne', value: f.activeAcne),
      FactorItem(name: 'Comedones', value: f.comedones),
      FactorItem(name: 'Congestion', value: f.congestion),
      FactorItem(name: 'Cystic Acne', value: f.cysticAcne),
      FactorItem(name: 'Inflammation', value: f.inflammation),
      FactorItem(name: 'Oiliness', value: f.oiliness),
      FactorItem(name: 'Scarring', value: f.scarring),
    ];
  }

  List<FactorItem> _getHydrationFactors() {
    final f = widget.analysisData!.hydrationFactors;
    return [
      FactorItem(name: 'Fine Lines', value: f.fineLines),
      FactorItem(name: 'Flakiness', value: f.flakiness),
      FactorItem(name: 'Oil Balance', value: f.oilBalance),
      FactorItem(name: 'Radiance', value: f.radiance),
      FactorItem(name: 'Texture', value: f.texture),
    ];
  }

  List<FactorItem> _getWrinklesFactors() {
    final f = widget.analysisData!.wrinklesFactors;
    return [
      FactorItem(name: 'Overall Severity', value: f.overallSeverity),
      FactorItem(name: 'Depth', value: f.depth),
      FactorItem(name: 'Forehead Lines', value: f.foreheadLines),
      FactorItem(name: "Crow's Feet", value: f.crowsFeet),
      FactorItem(name: 'Frown Lines', value: f.frownLines),
      FactorItem(name: 'Nasolabial Folds', value: f.nasolabialFolds),
      FactorItem(name: 'Under Eye Wrinkles', value: f.underEyeWrinkles),
      FactorItem(name: 'Lip Lines', value: f.lipLines),
      FactorItem(name: 'Marionette Lines', value: f.marionelleLines),
      FactorItem(name: 'Neck Lines', value: f.neckLines),
      FactorItem(name: 'Static Wrinkles', value: f.staticWrinkles),
      FactorItem(name: 'Dynamic Wrinkles', value: f.dynamicWrinkles),
    ];
  }

  List<FactorItem> _getPigmentationFactors() {
    final f = widget.analysisData!.pigmentationFactors;
    return [
      FactorItem(name: 'Dark Spots', value: f.darkSpots),
      FactorItem(name: 'Hyperpigmentation', value: f.hyperpigmentation),
      FactorItem(name: 'Melanin Unevenness', value: f.melaninUnevenness),
      FactorItem(name: 'Overall Evenness', value: f.overallEvenness),
      FactorItem(name: 'Redness', value: f.redness),
      FactorItem(name: 'Under Eye Pigmentation', value: f.underEyePigmentation),
      FactorItem(name: 'UV Damage', value: f.uvDamage),
    ];
  }

  List<FactorItem> _getPoresFactors() {
    final f = widget.analysisData!.poresFactors;
    return [
      FactorItem(name: 'Visibility', value: f.visibility),
      FactorItem(name: 'Size', value: f.size),
      FactorItem(name: 'Enlarged Pores', value: f.enlargedPores),
      FactorItem(name: 'Clogged Pores', value: f.cloggedPores),
      FactorItem(name: 'T-Zone Prominence', value: f.tZoneProminence),
      FactorItem(name: 'Cheek Prominence', value: f.cheekProminence),
      FactorItem(name: 'Texture Roughness', value: f.textureRoughness),
    ];
  }

  // ─── SCORING (same exact logic as original) ───
  double _calculateSkinHealthScore() {
    if (widget.analysisData == null) return 0;
    final d = widget.analysisData!;

    // Use the detail scores with the weighted formula
    final acne = _calcAcneDetail();
    final hydration = _calcHydrationDetail();
    final pigmentation = _calcPigmentationDetail();
    final pores = _calcPoresDetail();
    final wrinkles = _calcWrinklesDetail();
    final aging = _calcAging((d.skinAge + d.eyeAge) / 2);

    return ((acne * 0.25) +
            (hydration * 0.20) +
            (pigmentation * 0.20) +
            (pores * 0.15) +
            (wrinkles * 0.15) +
            (aging * 0.05))
        .clamp(0, 100);
  }

  double _calcAcneDetail() {
    final f = widget.analysisData!.acneFactors;
    return (1 - f.activeAcne) * 100 * 0.25 +
        (1 - f.comedones) * 100 * 0.10 +
        (1 - f.congestion) * 100 * 0.10 +
        (1 - f.cysticAcne) * 100 * 0.20 +
        (1 - f.inflammation) * 100 * 0.15 +
        (1 - f.oiliness) * 100 * 0.05 +
        (1 - f.scarring) * 100 * 0.15;
  }

  double _calcHydrationDetail() {
    final f = widget.analysisData!.hydrationFactors;
    return (1 - f.fineLines) * 100 * 0.20 +
        (1 - f.flakiness) * 100 * 0.10 +
        (1 - f.oilBalance) * 100 * 0.15 +
        (1 - f.radiance) * 100 * 0.30 +
        (1 - f.texture) * 100 * 0.25;
  }

  double _calcPigmentationDetail() {
    final f = widget.analysisData!.pigmentationFactors;
    return (1 - f.darkSpots) * 100 * 0.15 +
        (1 - f.hyperpigmentation) * 100 * 0.20 +
        (1 - f.melaninUnevenness) * 100 * 0.15 +
        (1 - f.overallEvenness) * 100 * 0.25 +
        (1 - f.redness) * 100 * 0.05 +
        (1 - f.underEyePigmentation) * 100 * 0.10 +
        (1 - f.uvDamage) * 100 * 0.10;
  }

  double _calcPoresDetail() {
    final f = widget.analysisData!.poresFactors;
    return (1 - f.visibility) * 100 * 0.25 +
        (1 - f.size) * 100 * 0.20 +
        (1 - f.enlargedPores) * 100 * 0.20 +
        (1 - f.cloggedPores) * 100 * 0.15 +
        (1 - f.tZoneProminence) * 100 * 0.05 +
        (1 - f.cheekProminence) * 100 * 0.05 +
        (1 - f.textureRoughness) * 100 * 0.10;
  }

  double _calcWrinklesDetail() {
    final f = widget.analysisData!.wrinklesFactors;
    return (1 - f.overallSeverity) * 100 * 0.20 +
        (1 - f.depth) * 100 * 0.15 +
        (1 - f.foreheadLines) * 100 * 0.10 +
        (1 - f.crowsFeet) * 100 * 0.10 +
        (1 - f.frownLines) * 100 * 0.08 +
        (1 - f.nasolabialFolds) * 100 * 0.12 +
        (1 - f.underEyeWrinkles) * 100 * 0.08 +
        (1 - f.lipLines) * 100 * 0.05 +
        (1 - f.marionelleLines) * 100 * 0.04 +
        (1 - f.neckLines) * 100 * 0.02 +
        (1 - f.staticWrinkles) * 100 * 0.04 +
        (1 - f.dynamicWrinkles) * 100 * 0.02;
  }

  double _calcAging(double avgAge) {
    if (avgAge >= 20 && avgAge <= 25) return 100;
    if (avgAge > 25) return (100 - (avgAge - 25) * 2).clamp(0, 100);
    return (100 - (20 - avgAge) * 1).clamp(0, 100);
  }

  // ─── SYMMETRY (same logic) ───
  double _safeDiv(double a, double b) => b == 0 ? 0 : a / b;

  double? _parseRatio(String? s) {
    if (s == null) return null;
    final parts = s.split(':').map((e) => e.trim()).toList();
    if (parts.length != 2) return double.tryParse(s);
    final l = double.tryParse(parts[0]);
    final r = double.tryParse(parts[1]);
    if (l == null || r == null || l == 0) return null;
    return r / l;
  }

  double _scoreFromRatio(double? m, double? ideal) {
    if (m == null || ideal == null || ideal == 0) return 0;
    final err = (m - ideal).abs() / ideal;
    return (10.0 * (1.0 - (err > 1.5 ? 1.5 : err) / 1.5)).clamp(0, 10);
  }

  double _scoreFromUniform(List<double> vals) {
    if (vals.isEmpty) return 0;
    final n = vals.length;
    final sum = vals.fold(0.0, (a, b) => a + b);
    if (sum <= 0) return 0;
    final perc = (sum - 100).abs() < 2
        ? vals
        : vals.map((v) => v / sum * 100).toList();
    final ideal = 100.0 / n;
    final avgDev =
        perc.map((v) => (v - ideal).abs()).fold(0.0, (a, b) => a + b) / n;
    double norm = 1.0 - _safeDiv(avgDev, ideal);
    return (10.0 * norm.clamp(0, 1)).clamp(0, 10);
  }

  double _calcSymmetryScore() {
    if (widget.faceRatioJson == null) return 7.0;
    FaceRatioData? d;
    try {
      d = FaceRatioData.fromMap(widget.faceRatioJson!);
    } catch (_) {
      return 7.0;
    }

    final comps = <double>[];
    final wts = <double>[];

    if (d.verticalPerc.isNotEmpty) {
      comps.add(_scoreFromUniform(d.verticalPerc));
      wts.add(30);
    }
    if (d.horizontalPerc.isNotEmpty) {
      comps.add(_scoreFromUniform(d.horizontalPerc));
      wts.add(30);
    }
    final fg = _parseRatio(d.faceBox?.golden),
        fy = _parseRatio(d.faceBox?.yours);
    if (fg != null && fy != null) {
      comps.add(_scoreFromRatio(fy, fg));
      wts.add(10);
    }
    final nlcM = _parseRatio(d.noseLipChinRatio),
        nlcI = _parseRatio(d.noseLipChinIdeal);
    if (nlcM != null && nlcI != null) {
      comps.add(_scoreFromRatio(nlcM, nlcI));
      wts.add(10);
    }
    final lipM = _parseRatio(d.lipRatio), lipI = _parseRatio(d.lipIdeal);
    if (lipM != null && lipI != null) {
      comps.add(_scoreFromRatio(lipM, lipI));
      wts.add(10);
    }

    double? eyeS(EyeBox? e) {
      if (e == null) return null;
      final g = _parseRatio(e.golden), m = _parseRatio(e.measured);
      return (g != null && m != null) ? _scoreFromRatio(m, g) : null;
    }

    final ls = eyeS(d.leftEye), rs = eyeS(d.rightEye);
    final es = (ls != null && rs != null) ? (ls + rs) / 2 : (ls ?? rs);
    if (es != null) {
      comps.add(es);
      wts.add(5);
    }
    if (d.jaw != null && d.jaw!.ideal > 0 && d.jaw!.ratio > 0) {
      comps.add(_scoreFromRatio(d.jaw!.ratio, d.jaw!.ideal));
      wts.add(5);
    }

    if (comps.isEmpty) return 7.0;
    final tw = wts.fold(0.0, (a, b) => a + b);
    return comps
        .asMap()
        .entries
        .map((e) => e.value * (wts[e.key] / tw))
        .fold(0.0, (a, b) => a + b)
        .clamp(3.0, 9.5);
  }

  // ─── REPORT SENDING (same logic as original) ───
  Future<void> _sendDetailedReport() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final analysisId = prefs.getString('analysis_id');
    if (analysisId == null || analysisId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No analysis found. Please analyze your skin first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() {
      _sendingReport = true;
      _reportMessage = 'Generating PDF report...';
    });
    try {
      final result = await ApiService.sendDetailedReport(analysisId);
      if (!mounted) return;
      setState(() {
        _sendingReport = false;
        _reportSent = result['success'] == true;
        _reportMessage = result['message'] ?? '';
      });
      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report sent! Check your email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendingReport = false;
        _reportMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _ageLabel(int age) {
    if (age <= 0) return 'Unknown';
    final decade = (age ~/ 10) * 10;
    final within = age % 10;
    final part = within <= 3
        ? 'Early'
        : within <= 6
        ? 'Mid'
        : 'Late';
    return '$part ${decade}s';
  }

  String _labelForMode(RatioMode mode) {
    switch (mode) {
      case RatioMode.vertical:
        return "Vertical Sections";
      case RatioMode.horizontal:
        return "Horizontal Sections";
      case RatioMode.eyes:
        return "Eye Aspect Ratio";
      case RatioMode.faceBox:
        return "Face Aspect Ratio";
      case RatioMode.noseLipChin:
        return "Nose–Lip–Chin";
      case RatioMode.lips:
        return "Lips Ratio";
      case RatioMode.jaw:
        return "Jaw Ratio";
    }
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final skinHealth = _calculateSkinHealthScore();
    final symmetry = _calcSymmetryScore();
    final metrics = _buildMetrics();

    return Scaffold(
      backgroundColor: _DS.pageBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom app bar
            SliverToBoxAdapter(child: _buildTopBar()),
            // STAGE 1: Hero
            SliverToBoxAdapter(child: _buildHero(skinHealth, metrics)),
            // STAGE 2: Skin Map
            if (metrics.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionRule()),
              SliverToBoxAdapter(
                child: _FadeSlideIn(child: _buildSkinMap(metrics)),
              ),
            ],
            // STAGE 3: Key Opportunity
            if (metrics.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionRule()),
              SliverToBoxAdapter(
                child: _FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: _buildKeyOpportunity(metrics),
                ),
              ),
            ],
            // STAGE 4: Skin Profile
            const SliverToBoxAdapter(child: _SectionRule()),
            SliverToBoxAdapter(child: _FadeSlideIn(child: _buildSkinProfile())),
            // STAGE 5: Facial Structure
            SliverToBoxAdapter(
              child: _FadeSlideIn(child: _buildFacialStructureHeader(symmetry)),
            ),
            SliverToBoxAdapter(
              child: _FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: _buildSymmetryScore(symmetry),
              ),
            ),
            // STAGE 6: Structural Breakdown (swipe cards)
            SliverToBoxAdapter(
              child: _FadeSlideIn(child: _buildStructuralBreakdown()),
            ),
            // STAGE 7: Report CTA
            const SliverToBoxAdapter(child: _SectionRule()),
            SliverToBoxAdapter(child: _FadeSlideIn(child: _buildReportCTA())),
            // Disclaimer
            SliverToBoxAdapter(child: _buildDisclaimer()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ─── TOP BAR ───
  Widget _buildTopBar() {
    final r = Responsive(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.w(16), r.h(12), r.w(16), 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(r.w(8)),
              decoration: BoxDecoration(
                color: _DS.white,
                borderRadius: BorderRadius.circular(r.w(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: r.w(18),
                color: _DS.textHigh,
              ),
            ),
          ),
          SizedBox(width: r.w(12)),
          Text(
            'ANALYSIS RESULTS',
            style: TextStyle(
              fontSize: r.sp(10),
              letterSpacing: 2.4,
              color: _DS.grey400,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  STAGE 1: HERO
  // ═══════════════════════════════════════════
  Widget _buildHero(double score, List<_MetricData> metrics) {
    final r = Responsive(context);

    // Micro insight
    String microInsight = '';
    if (metrics.isNotEmpty) {
      final sorted = [...metrics]..sort((a, b) => b.value.compareTo(a.value));
      final best = sorted.first;
      final worst = [...metrics]..sort((a, b) => a.value.compareTo(b.value));
      final worstM = worst.first;

      // Higher score = better health in that area
      const positiveDesc = {
        'Acne': 'clear, blemish-free skin',
        'Hydration': 'excellent hydration levels',
        'Wrinkles': 'smooth, youthful skin texture',
        'Pigmentation': 'even, balanced skin tone',
        'Pores': 'refined, tight pore appearance',
      };
      const improveDesc = {
        'Acne': 'Blemish control',
        'Hydration': 'Moisture levels',
        'Wrinkles': 'Fine line prevention',
        'Pigmentation': 'Tone evenness',
        'Pores': 'Pore refinement',
      };

      final pos =
          positiveDesc[best.label] ??
          'great ${best.label.toLowerCase()} health';
      final neg = improveDesc[worstM.label] ?? worstM.label;
      microInsight = 'Your skin shows $pos. $neg could use a little attention.';
    }

    return Column(
      children: [
        // Hero image card with ambient glow
        Padding(
          padding: EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(20), 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Ambient glow behind card
              Positioned(
                left: -16,
                right: -16,
                top: -16,
                bottom: -16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(42),
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.16),
                      radius: 0.85,
                      colors: [
                        _DS.blush.withOpacity(0.30),
                        _DS.blush.withOpacity(0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              // Hero card
              Container(
                height: MediaQuery.of(context).size.height * 0.52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: _DS.blush,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: _DS.blush.withOpacity(0.18),
                      blurRadius: 40,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.55)),
                ),
                child: Stack(
                  children: [
                    // User photo
                    if (widget.imageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.memory(
                          widget.imageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),

                    // Radial light overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.28),
                            radius: 0.72,
                            colors: [
                              Colors.white.withOpacity(0.14),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.68],
                          ),
                        ),
                      ),
                    ),

                    // Top gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.white.withOpacity(0.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom gradient (deeper, multi-stop)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: const Alignment(0, -0.2),
                            colors: [
                              Colors.black.withOpacity(0.22),
                              Colors.black.withOpacity(0.08),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // AI badge with glass effect
                    Positioned(
                      top: 16,
                      left: 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: r.w(12),
                              vertical: r.h(5),
                            ),
                            decoration: BoxDecoration(
                              color: _DS.pageBg.withOpacity(0.72),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            child: Text(
                              'AI FACIAL ANALYSIS',
                              style: TextStyle(
                                fontSize: r.sp(10),
                                letterSpacing: 1.5,
                                color: _DS.grey600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Pulse dot
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.52 * 0.44,
                      left: 0,
                      right: 0,
                      child: Center(child: _PulseDot()),
                    ),

                    // Score overlay at bottom with glass effect
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                r.w(12),
                                r.h(12),
                                r.w(22),
                                r.h(12),
                              ),
                              decoration: BoxDecoration(
                                color: _DS.pageBg.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(60),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.14),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.72),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DiagnosticRing(
                                    value: score,
                                    size: 80,
                                    isMain: true,
                                    delay: const Duration(milliseconds: 400),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Skin Health',
                                          style: TextStyle(
                                            fontSize: r.sp(16),
                                            fontWeight: FontWeight.w600,
                                            color: _DS.textHigh,
                                          ),
                                        ),
                                        Text(
                                          'Index',
                                          style: TextStyle(
                                            fontSize: r.sp(13),
                                            fontStyle: FontStyle.italic,
                                            color: _DS.grey600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Based on multiple facial health parameters',
                                          style: TextStyle(
                                            fontSize: r.sp(10),
                                            color: _DS.grey400,
                                            fontWeight: FontWeight.w300,
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Micro insight card
        if (microInsight.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(20), r.h(14), r.w(20), 0),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.w(18),
                vertical: r.h(14),
              ),
              decoration: BoxDecoration(
                color: _DS.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                microInsight,
                style: TextStyle(
                  fontSize: r.sp(14),
                  color: _DS.textMid,
                  height: 1.65,
                ),
              ),
            ),
          ),

        // Scroll cue
        Padding(
          padding: EdgeInsets.only(top: r.h(14)),
          child: Column(
            children: [
              Text(
                'Scroll to understand your skin',
                style: TextStyle(
                  fontSize: r.sp(12),
                  color: _DS.grey400,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: r.h(4)),
              _BouncingChevron(),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  STAGE 2: SKIN MAP (Radar + Pillar Cards)
  // ═══════════════════════════════════════════
  Widget _buildSkinMap(List<_MetricData> metrics) {
    final r = Responsive(context);
    return Column(
      children: [
        const _StageLabel(
          number: '2',
          title: 'Understanding Your Skin',
          sub: 'The five pillars',
        ),
        SizedBox(height: r.h(16)),
        // Radar chart
        Padding(
          padding: EdgeInsets.symmetric(horizontal: r.w(20)),
          child: Container(
            decoration: BoxDecoration(
              color: _DS.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: _DS.blush.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Radar
                Padding(
                  padding: EdgeInsets.fromLTRB(r.w(8), r.h(24), r.w(8), 0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final radarSize = (constraints.maxWidth - 16).clamp(
                        180.0,
                        300.0,
                      );
                      return SizedBox(
                        height: radarSize,
                        child: Center(
                          child: CustomPaint(
                            size: Size(radarSize, radarSize),
                            painter: _RadarPainter(
                              metrics: metrics,
                              activeIdx: _activeMetricIdx,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Metric pillar cards: 3 top, 2 bottom
                Padding(
                  padding: EdgeInsets.fromLTRB(r.w(14), r.h(14), r.w(14), 0),
                  child: Row(
                    children: List.generate(min(3, metrics.length), (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 4,
                            right: i == 2 ? 0 : 4,
                          ),
                          child: _buildPillarCard(metrics[i], i),
                        ),
                      );
                    }),
                  ),
                ),
                if (metrics.length > 3)
                  Padding(
                    padding: EdgeInsets.fromLTRB(r.w(56), r.h(8), r.w(56), 0),
                    child: Row(
                      children: List.generate(min(2, metrics.length - 3), (i) {
                        final idx = i + 3;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 4,
                              right: i == 1 ? 0 : 4,
                            ),
                            child: _buildPillarCard(metrics[idx], idx),
                          ),
                        );
                      }),
                    ),
                  ),

                // Tap hint
                Padding(
                  padding: EdgeInsets.only(top: r.h(10), bottom: r.h(8)),
                  child: Text(
                    'Tap the cards to know more',
                    style: TextStyle(
                      fontSize: r.sp(11),
                      color: _DS.grey400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                // Active metric detail (animated)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child:
                      (_activeMetricIdx != null &&
                          _activeMetricIdx! < metrics.length)
                      ? _buildActiveMetricDetail(metrics[_activeMetricIdx!])
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillarCard(_MetricData m, int idx) {
    final r = Responsive(context);
    final t = getThreshold(m.value);
    final isActive = _activeMetricIdx == idx;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeMetricIdx = _activeMetricIdx == idx ? null : idx;
        });
      },
      child: AnimatedScale(
        scale: isActive ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(vertical: r.h(12), horizontal: r.w(6)),
          decoration: BoxDecoration(
            color: isActive ? Color.lerp(_DS.white, t.color, 0.06)! : _DS.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? t.color.withOpacity(0.4)
                  : _DS.blush.withOpacity(0.26),
              width: isActive ? 2.5 : 1.5,
            ),
            boxShadow: [
              if (isActive) ...[
                BoxShadow(
                  color: t.color.withOpacity(0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: t.color.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ] else
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DiagnosticRing(
                value: m.value,
                size: 72,
                delay: Duration(milliseconds: idx * 120),
              ),
              const SizedBox(height: 6),
              Text(
                m.label,
                style: TextStyle(
                  fontSize: r.sp(12),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? t.color : _DS.grey600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveMetricDetail(_MetricData m) {
    final r = Responsive(context);
    final t = getThreshold(m.value);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.w(16), r.h(8), r.w(16), 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(12)),
        decoration: BoxDecoration(
          color: _DS.pageBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: r.sp(10),
                      letterSpacing: 1,
                      color: _DS.grey400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.stability} · ${m.indicators.length} indicators assessed',
                    style: TextStyle(
                      fontSize: r.sp(11),
                      color: _DS.grey600,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showMetricModal(m),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: t.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: t.color.withOpacity(0.25)),
                ),
                child: Text(
                  'See why →',
                  style: TextStyle(
                    fontSize: r.sp(12),
                    fontWeight: FontWeight.w600,
                    color: t.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  STAGE 3: KEY OPPORTUNITY
  // ═══════════════════════════════════════════
  Widget _buildKeyOpportunity(List<_MetricData> metrics) {
    final r = Responsive(context);
    final sorted = [...metrics]..sort((a, b) => a.value.compareTo(b.value));
    final focus = sorted.first;
    final t = getThreshold(focus.value);

    // Bottom 3 indicators
    final worstIndicators = [...focus.indicators]
      ..sort((a, b) => a.score.compareTo(b.score));
    final bottom3 = worstIndicators.take(3).toList();

    return Column(
      children: [
        const _StageLabel(
          number: '3',
          title: 'Your Key Opportunity',
          sub: 'Focus insight',
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(20), 0),
          child: Container(
            decoration: BoxDecoration(
              color: _DS.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: t.color.withOpacity(0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border(top: BorderSide(color: t.color, width: 3)),
            ),
            padding: EdgeInsets.all(r.w(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRIMARY FOCUS AREA',
                            style: TextStyle(
                              fontSize: r.sp(10),
                              letterSpacing: 2,
                              color: _DS.grey400,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            focus.label,
                            style: TextStyle(
                              fontSize: r.sp(24),
                              fontWeight: FontWeight.w700,
                              color: _DS.textHigh,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${focus.label} appears slightly lower than your other skin indicators. Targeted attention here could meaningfully improve your overall score.',
                            style: TextStyle(
                              fontSize: r.sp(13),
                              color: _DS.grey600,
                              fontWeight: FontWeight.w300,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _showMetricModal(focus),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.w(22),
                                vertical: r.h(11),
                              ),
                              decoration: BoxDecoration(
                                color: t.color,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: t.color.withOpacity(0.30),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: t.color.withOpacity(0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Understand why →',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    DiagnosticRing(
                      value: focus.value,
                      size: 78,
                      delay: const Duration(milliseconds: 300),
                    ),
                  ],
                ),

                // Bottom indicator bars
                const SizedBox(height: 20),
                ...bottom3.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ind = entry.value;
                  final it = getThreshold(ind.score);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ind.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: _DS.grey600,
                              ),
                            ),
                            Text(
                              ind.score.round().toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: it.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: ind.score / 100),
                          duration: Duration(milliseconds: 900 + i * 100),
                          curve: Curves.easeOutQuad,
                          builder: (context, val, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: val,
                              minHeight: 4,
                              backgroundColor: Colors.black.withOpacity(0.07),
                              valueColor: AlwaysStoppedAnimation(it.color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Text(
                  '+${focus.indicators.length - 3} more indicators — tap "Understand why" to see all',
                  style: TextStyle(
                    fontSize: 11,
                    color: _DS.grey400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),

        // All metrics summary row
        Padding(
          padding: EdgeInsets.fromLTRB(r.w(20), r.h(12), r.w(20), 0),
          child: Container(
            padding: EdgeInsets.all(r.w(16)),
            decoration: BoxDecoration(
              color: _DS.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALL INDICATORS AT A GLANCE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.6,
                    color: _DS.grey400,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: metrics.map((m) {
                    final tc = getThreshold(m.value);
                    // Short labels for compact view
                    const shortLabels = {
                      'Pigmentation': 'Pigmentation',
                      'Hydration': 'Hydration',
                      'Wrinkles': 'Wrinkles',
                    };
                    final label = shortLabels[m.label] ?? m.label;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          children: [
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: tc.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: tc.color.withOpacity(0.18),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  m.value.round().toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: tc.color,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              label,
                              style: TextStyle(fontSize: 9, color: _DS.grey400),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  STAGE 4: SKIN PROFILE
  // ═══════════════════════════════════════════
  Widget _buildSkinProfile() {
    final r = Responsive(context);
    final d = widget.analysisData;

    return Column(
      children: [
        const _StageLabel(
          number: '4',
          title: 'Skin Profile',
          sub: 'Biometric summary',
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(20), 0),
          child: Container(
            padding: EdgeInsets.all(r.w(22)),
            decoration: BoxDecoration(
              color: _DS.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 3-col attributes
                Row(
                  children: [
                    _profileTile(
                      '🧬',
                      d != null ? _ageLabel(d.skinAge) : '-',
                      'Skin Age',
                    ),
                    const SizedBox(width: 10),
                    _profileTile(
                      '👁',
                      d != null ? _ageLabel(d.eyeAge) : '-',
                      'Eye Age',
                    ),
                    const SizedBox(width: 10),
                    _profileTile('✦', d?.skinType ?? '-', 'Skin Type'),
                  ],
                ),

                const SizedBox(height: 20),

                // Tone row
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0x0D000000))),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SKIN TONE',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.8,
                          color: _DS.grey400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(fitzpatrickColors.length, (i) {
                          final isSelected = selectedColorIndex == i;
                          return Expanded(
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: fitzpatrickColors[i],
                                    border: Border.all(
                                      color: isSelected
                                          ? _DS.blushDark
                                          : Colors.white,
                                      width: isSelected ? 3 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? fitzpatrickColors[i].withOpacity(
                                                0.4,
                                              )
                                            : Colors.black.withOpacity(0.08),
                                        blurRadius: isSelected ? 10 : 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 5),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w300,
                                    color: isSelected
                                        ? _DS.textHigh
                                        : _DS.grey400,
                                  ),
                                  child: Text('${i + 1}'),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          'Fitzpatrick Type ${selectedColorIndex + 1}',
                          key: ValueKey(selectedColorIndex),
                          style: TextStyle(
                            fontSize: 13,
                            color: _DS.textMid,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileTile(String icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: _DS.pageBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _DS.textHigh,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: _DS.grey400,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  STAGE 5: FACIAL STRUCTURE HEADER + SCORE
  // ═══════════════════════════════════════════
  Widget _buildFacialStructureHeader(double symmetry) {
    final r = Responsive(context);
    return Container(
      margin: EdgeInsets.only(top: r.h(24)),
      padding: EdgeInsets.fromLTRB(r.w(24), r.h(28), r.w(24), r.h(24)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_DS.blushDark, const Color(0xFFA87070)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
            ),
          ),
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SECOND AI MODULE',
                style: TextStyle(
                  fontSize: r.sp(10),
                  letterSpacing: 2.2,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Facial Structure Analysis',
                style: TextStyle(
                  fontSize: r.sp(20),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A separate model analyzes your facial geometry and proportions.',
                style: TextStyle(
                  fontSize: r.sp(12),
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.75),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymmetryScore(double symmetry) {
    final r = Responsive(context);
    final pct = symmetry * 10;
    final scoreText = symmetry.toStringAsFixed(2);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(20)),
      child: Column(
        children: [
          // Score card (rounded bottom only)
          Container(
            padding: EdgeInsets.fromLTRB(r.w(20), r.h(28), r.w(20), r.h(24)),
            decoration: BoxDecoration(
              color: _DS.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: _DS.blush.withOpacity(0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                _HalfRing(
                  value: pct,
                  size: 240,
                  color: _DS.blush,
                  strokeWidth: 32,
                ),
                const SizedBox(height: 10),
                // Show score / 10 under ring
                Text(
                  scoreText,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: _DS.textHigh,
                  ),
                ),
                Text(
                  '/ 10',
                  style: TextStyle(fontSize: 15, color: _DS.grey400),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Symmetry Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _DS.textHigh,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  symmetry >= 8.5
                      ? 'Excellent facial symmetry!'
                      : symmetry >= 7.0
                      ? 'Good facial balance and harmony'
                      : 'Room for enhancement',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFB8C00),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _DS.pageBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Your facial proportions show good balance. This score is calculated using golden ratio standards across five facial measurements.',
                    style: TextStyle(
                      fontSize: 11,
                      color: _DS.grey700,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Skin Balance Index pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _DS.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SKIN BALANCE INDEX',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: _DS.grey400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _DS.blush,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _DS.blush.withOpacity(0.13),
                  ),
                  child: const Icon(Icons.star, color: _DS.blush, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  STAGE 6: STRUCTURAL BREAKDOWN (swipe)
  // ═══════════════════════════════════════════
  Widget _buildStructuralBreakdown() {
    final r = Responsive(context);
    FaceRatioData? faceData;
    if (widget.faceRatioJson != null) {
      try {
        faceData = FaceRatioData.fromMap(widget.faceRatioJson!);
      } catch (_) {}
    }
    if (faceData == null) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(r.w(24), r.h(24), r.w(24), r.h(14)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STRUCTURAL BREAKDOWN',
                style: TextStyle(
                  fontSize: r.sp(10),
                  letterSpacing: 2,
                  color: _DS.grey400,
                ),
              ),
              Text(
                'Swipe to explore ↔',
                style: TextStyle(
                  fontSize: r.sp(11),
                  color: _DS.grey400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: PageView.builder(
            controller: _structurePageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _structurePage = i),
            itemCount: _ratioModes.length,
            itemBuilder: (context, index) {
              final mode = _ratioModes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: _DS.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: _structurePage == index
                          ? _DS.blush.withOpacity(0.3)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _labelForMode(mode),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _DS.grey700,
                              ),
                            ),
                            Text(
                              '${index + 1}/${_ratioModes.length}',
                              style: TextStyle(
                                fontSize: 10,
                                color: _DS.grey400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Face overlay image
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (faceData!.imageBytes != null)
                                  FittedBox(
                                    fit: BoxFit.contain,
                                    child: SizedBox(
                                      width: faceData.imageW,
                                      height: faceData.imageH,
                                      child: Image.memory(
                                        faceData.imageBytes!,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                if (faceData.imageBytes != null)
                                  FittedBox(
                                    fit: BoxFit.contain,
                                    child: SizedBox(
                                      width: faceData.imageW,
                                      height: faceData.imageH,
                                      child: CustomPaint(
                                        painter: PrettyRatioPainter(
                                          faceData,
                                          mode,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Mode badge
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _DS.blush.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      _labelForMode(mode),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: _DS.blush,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Info row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                        child: _buildRatioInfo(faceData, mode),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Dot indicators
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_ratioModes.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _structurePage == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _structurePage == i ? _DS.blush : _DS.grey300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildRatioInfo(FaceRatioData data, RatioMode mode) {
    String info = '';
    switch (mode) {
      case RatioMode.vertical:
        if (data.verticalPerc.isNotEmpty)
          info = data.verticalPerc
              .map((p) => '${p.toStringAsFixed(1)}%')
              .join(' · ');
        break;
      case RatioMode.horizontal:
        if (data.horizontalPerc.isNotEmpty)
          info = data.horizontalPerc
              .map((p) => '${p.toStringAsFixed(1)}%')
              .join(' · ');
        break;
      case RatioMode.eyes:
        info =
            'Left: ${data.leftEye?.measured ?? "–"} | Right: ${data.rightEye?.measured ?? "–"}';
        break;
      case RatioMode.faceBox:
        if (data.faceBox != null)
          info =
              'Yours: ${data.faceBox!.yours}  ·  Golden: ${data.faceBox!.golden}';
        break;
      case RatioMode.noseLipChin:
        info =
            'Ratio: ${data.noseLipChinRatio ?? "–"}  ·  Ideal: ${data.noseLipChinIdeal ?? "–"}';
        break;
      case RatioMode.lips:
        info =
            'Ratio: ${data.lipRatio ?? "–"}  ·  Ideal: ${data.lipIdeal ?? "–"}';
        break;
      case RatioMode.jaw:
        if (data.jaw != null)
          info =
              'Ratio: ${data.jaw!.ratio.toStringAsFixed(2)}  ·  Ideal: ${data.jaw!.ideal.toStringAsFixed(2)}';
        break;
    }
    if (info.isEmpty) return const SizedBox.shrink();
    return Text(
      info,
      style: TextStyle(
        fontSize: 11,
        color: _DS.grey600,
        fontWeight: FontWeight.w300,
      ),
      textAlign: TextAlign.center,
    );
  }

  // ═══════════════════════════════════════════
  //  STAGE 7: REPORT CTA
  // ═══════════════════════════════════════════
  Widget _buildReportCTA() {
    final r = Responsive(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.w(20), 0, r.w(20), 0),
      child: Container(
        padding: EdgeInsets.fromLTRB(r.w(24), r.h(36), r.w(24), r.h(28)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_DS.blush, _DS.blushDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _DS.blush.withOpacity(0.40),
              blurRadius: 56,
              offset: const Offset(0, 24),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: r.w(56),
              height: r.w(56),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.10),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: r.w(28),
              ),
            ),
            SizedBox(height: r.h(14)),
            Text(
              'Save Your Full Skin Analysis',
              style: TextStyle(
                fontSize: r.sp(22),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: r.h(8)),
            Text(
              'Includes detailed breakdowns, insights, and future scan comparisons.',
              style: TextStyle(
                fontSize: r.sp(13),
                fontWeight: FontWeight.w300,
                color: Colors.white.withOpacity(0.82),
                height: 1.65,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: r.h(18)),

            // Primary CTA
            GestureDetector(
              onTap: _sendingReport ? null : _sendDetailedReport,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: r.h(16)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_sendingReport)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _DS.blushDark,
                        ),
                      )
                    else
                      Icon(Icons.save_outlined, size: 16, color: _DS.blush),
                    const SizedBox(width: 10),
                    Text(
                      _reportSent
                          ? 'Report Sent ✓'
                          : (_sendingReport
                                ? 'Sending...'
                                : 'Save My Analysis'),
                      style: TextStyle(
                        fontSize: r.sp(16),
                        fontWeight: FontWeight.w700,
                        color: _DS.blushDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Track changes over time with future scans.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Secondary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 13,
                    color: Colors.white.withOpacity(0.65),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'The account you created will track your progress over time.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.72),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  DISCLAIMER
  // ═══════════════════════════════════════════
  Widget _buildDisclaimer() {
    final r = Responsive(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.w(20), r.h(24), r.w(20), 0),
      child: Container(
        decoration: BoxDecoration(
          color: _DS.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () =>
                  setState(() => _disclaimerExpanded = !_disclaimerExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'About this analysis',
                      style: TextStyle(fontSize: 13, color: _DS.grey600),
                    ),
                    AnimatedRotation(
                      turns: _disclaimerExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: _DS.grey400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_disclaimerExpanded) ...[
              Divider(height: 1, color: Colors.black.withOpacity(0.05)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final txt in [
                      'This AI-generated analysis is for informational and entertainment purposes only.',
                      'Results do not represent a medical diagnosis, dermatological assessment, or professional beauty advice.',
                      'Factors such as lighting and camera quality may influence outcomes.',
                      'Consult a qualified healthcare professional for medical or cosmetic concerns.',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '· $txt',
                          style: TextStyle(
                            fontSize: 12,
                            color: _DS.grey700,
                            fontWeight: FontWeight.w300,
                            height: 1.65,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  METRIC DETAIL BOTTOM SHEET
  // ═══════════════════════════════════════════
  void _showMetricModal(_MetricData metric) {
    final t = getThreshold(metric.value);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: _DS.pageBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 13),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _DS.blush,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INDICATOR ANALYSIS',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.8,
                              color: _DS.grey400,
                            ),
                          ),
                          Text(
                            metric.label,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _DS.textHigh,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: t.color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: t.color.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                metric.value.round().toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: t.color,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                t.label,
                                style: TextStyle(fontSize: 12, color: t.color),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _DS.blush.withOpacity(0.16),
                            ),
                            child: const Center(
                              child: Text(
                                '✕',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _DS.grey600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Indicators list
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 44),
                  shrinkWrap: true,
                  itemCount: metric.indicators.length,
                  itemBuilder: (context, i) {
                    final ind = metric.indicators[i];
                    final it = getThreshold(ind.score);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ind.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _DS.grey700,
                                ),
                              ),
                              Text(
                                ind.score.round().toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: it.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: ind.score / 100),
                            duration: const Duration(milliseconds: 850),
                            curve: Curves.easeOutQuad,
                            builder: (context, val, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: val,
                                minHeight: 5,
                                backgroundColor: Colors.black.withOpacity(0.07),
                                valueColor: AlwaysStoppedAnimation(it.color),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────
//  Radar Chart Painter
// ─────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final List<_MetricData> metrics;
  final int? activeIdx;

  _RadarPainter({required this.metrics, this.activeIdx});

  @override
  void paint(Canvas canvas, Size size) {
    if (metrics.isEmpty) return;
    final n = metrics.length;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(size.width, size.height) * 0.34;
    const levels = 4;

    Offset pt(double rv, int i) {
      final angle = (2 * pi * i) / n - pi / 2;
      return Offset(cx + rv * cos(angle), cy + rv * sin(angle));
    }

    // Grid rings
    for (int l = 1; l <= levels; l++) {
      final rv = maxR * (l / levels);
      final path = Path();
      for (int i = 0; i < n; i++) {
        final p = pt(rv, i);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = _DS.blush.withOpacity(0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Spokes
    for (int i = 0; i < n; i++) {
      final isActive = activeIdx == i;
      final p = pt(maxR, i);
      canvas.drawLine(
        Offset(cx, cy),
        p,
        Paint()
          ..color = isActive
              ? getThreshold(metrics[i].value).color.withOpacity(0.9)
              : _DS.blush.withOpacity(0.5)
          ..strokeWidth = isActive ? 2.0 : 1.2,
      );
    }

    // Data polygon
    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final rv = (metrics[i].value / 100) * maxR;
      final p = pt(rv, i);
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();
    // Soft glow behind polygon
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = _DS.blushDark.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = _DS.blushDark.withOpacity(0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = _DS.blushDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    // Highlighted spoke line from center to data point (drawn on top of polygon)
    if (activeIdx != null && activeIdx! < n) {
      final m = metrics[activeIdx!];
      final tc = getThreshold(m.value);
      final rv = (m.value / 100) * maxR;
      final dataP = pt(rv, activeIdx!);
      final fullP = pt(maxR, activeIdx!);
      // Line from center to full radius
      canvas.drawLine(
        Offset(cx, cy),
        fullP,
        Paint()
          ..color = tc.color.withOpacity(0.5)
          ..strokeWidth = 2.0,
      );
      // Glow dot at data point
      canvas.drawCircle(
        dataP,
        12,
        Paint()
          ..color = tc.color.withOpacity(0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(dataP, 10, Paint()..color = tc.color.withOpacity(0.15));
      canvas.drawCircle(dataP, 6, Paint()..color = tc.color);
    }

    // Dots & labels
    for (int i = 0; i < n; i++) {
      final rv = (metrics[i].value / 100) * maxR;
      final p = pt(rv, i);
      final isActive = activeIdx == i;
      final tc = getThreshold(metrics[i].value);
      final hasSelection = activeIdx != null;

      // Dot (skip active dot — already drawn above)
      if (!isActive) {
        canvas.drawCircle(
          p,
          hasSelection ? 3 : 4,
          Paint()..color = tc.color.withOpacity(hasSelection ? 0.4 : 1.0),
        );
      }

      // Label
      final labelPt = pt(maxR + 28, i);
      final labelColor = isActive
          ? tc.color
          : (hasSelection ? _DS.grey400 : _DS.grey600);
      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${metrics[i].label}\n',
              style: TextStyle(
                fontSize: isActive ? 16 : 15,
                color: labelColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            TextSpan(
              text: '${metrics[i].value.round()}',
              style: TextStyle(
                fontSize: isActive ? 18 : 17,
                color: tc.color.withOpacity(
                  isActive ? 1.0 : (hasSelection ? 0.5 : 0.75),
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
        textAlign: labelPt.dx < cx - 5
            ? TextAlign.right
            : labelPt.dx > cx + 5
            ? TextAlign.left
            : TextAlign.center,
      );
      textPainter.layout();
      final dx = labelPt.dx < cx - 5
          ? labelPt.dx - textPainter.width
          : labelPt.dx > cx + 5
          ? labelPt.dx
          : labelPt.dx - textPainter.width / 2;
      textPainter.paint(
        canvas,
        Offset(dx, labelPt.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.activeIdx != activeIdx || old.metrics != metrics;
}
