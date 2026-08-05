import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/hair_analysis_client.dart';
import '../js/hair_capture_bridge.dart';
import '../widgets/hair_theme.dart';
import 'hair_results_screen.dart';

/// Premium Quick Scan capture — Flutter owns UI only.
/// Camera / MediaPipe / auto-capture run in `window.HairCapture` (JS).
class HairQuickGuidedFlowScreen extends StatefulWidget {
  const HairQuickGuidedFlowScreen({super.key});

  @override
  State<HairQuickGuidedFlowScreen> createState() =>
      _HairQuickGuidedFlowScreenState();
}

class _HairQuickGuidedFlowScreenState extends State<HairQuickGuidedFlowScreen>
    with SingleTickerProviderStateMixin {
  final _client = HairAnalysisClient();

  String? _viewType;
  String? _containerId;
  HairCaptureState _state = HairCaptureState.idle();
  bool _started = false;
  bool _readyBriefing = true;
  bool _analyzing = false;
  String? _error;

  late final AnimationController _analyzeSpin;
  Timer? _messageTimer;
  int _messageIndex = 0;

  static const _analyzeMessages = [
    'Analyzing visible hair coverage…',
    'Detecting scalp regions…',
    'Evaluating image quality…',
    'Composing your insights…',
  ];

  @override
  void initState() {
    super.initState();
    _analyzeSpin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (kIsWeb) {
      final reg = HairCaptureBridge.registerView();
      _viewType = reg.viewType;
      _containerId = reg.containerId;
    } else {
      _error =
          'Guided Quick Scan camera runs in the browser. Use Gallery here, or open the web app.';
      _readyBriefing = false;
    }
  }

  Future<void> _onReady() async {
    setState(() => _readyBriefing = false);
    await _startJsCapture();
  }

  Future<void> _startJsCapture() async {
    final id = _containerId;
    if (id == null || _started || _analyzing) return;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    for (var i = 0; i < 50 && !HairCaptureBridge.isAvailable; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    final ok = await HairCaptureBridge.start(
      containerId: id,
      onUpdate: (state) {
        if (!mounted || _analyzing) return;
        setState(() {
          _state = state;
          _error = null;
        });
      },
      onCaptured: (bytes, pose) {
        if (!mounted || _analyzing) return;
        _onCaptured(bytes);
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _error = message);
      },
    );

    if (!mounted) return;
    setState(() {
      _started = ok;
      if (!ok && _error == null) {
        _error = 'Could not start camera.';
      }
    });
  }

  Future<void> _onCaptured(Uint8List bytes) async {
    setState(() {
      _analyzing = true;
      _messageIndex = 0;
      _error = null;
    });
    _analyzeSpin.repeat();
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _analyzeMessages.length;
      });
    });

    await HairCaptureBridge.stop();

    try {
      final result = await _client.analyzeSingle(
        bytes: bytes,
        fileName: 'quick_scan.jpg',
        includeImages: false,
      );
      if (!mounted) return;
      _messageTimer?.cancel();
      _analyzeSpin.stop();

      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (_, __, ___) => HairResultsScreen.single(
            result: result,
            previewBytes: bytes,
          ),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _messageTimer?.cancel();
      _analyzeSpin.stop();
      setState(() {
        _analyzing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      _started = false;
      await _startJsCapture();
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _analyzeSpin.dispose();
    HairCaptureBridge.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HairTheme.pageBg,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HairTheme.blush.withValues(alpha: 0.35),
                    HairTheme.blush.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(onClose: () => Navigator.pop(context)),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    child: _analyzing
                        ? _AnalyzingPane(
                            key: const ValueKey('analyzing'),
                            spin: _analyzeSpin,
                            message: _analyzeMessages[_messageIndex],
                          )
                        : _readyBriefing
                            ? _ReadyBriefing(
                                key: const ValueKey('briefing'),
                                onReady: _onReady,
                              )
                            : _CapturePane(
                                key: const ValueKey('capture'),
                                viewType: _viewType,
                                state: _state,
                                error: _error,
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: HairTheme.textHigh,
          ),
          Expanded(
            child: Text(
              'QUICK SCAN',
              textAlign: TextAlign.center,
              style: HairTheme.eyebrow(11),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Original “get ready” sheet — three soft step cues before camera starts.
class _ReadyBriefing extends StatelessWidget {
  final VoidCallback onReady;
  const _ReadyBriefing({super.key, required this.onReady});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        decoration: HairTheme.softCard(radius: 28),
        child: Column(
          children: [
            Text('Get ready to scan', style: HairTheme.headline(28)),
            const SizedBox(height: 10),
            Text(
              'Follow the animated face mask. Stay roughly inside it — you don’t need to fill every edge.',
              textAlign: TextAlign.center,
              style: HairTheme.body(14.5),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _StepCue(
                  label: 'Face forward',
                  painter: _CueFacePainter(tilted: false),
                ),
                _StepCue(
                  label: 'Tilt with mask',
                  painter: _CueFacePainter(tilted: true),
                ),
                _StepCue(
                  label: 'Photo taken',
                  painter: _CueCameraPainter(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '1. Align your face to the mask\n'
              '2. When the mask tilts, gently lower your head\n'
              '3. Hold still for the countdown',
              textAlign: TextAlign.center,
              style: HairTheme.body(13.5),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: onReady,
                style: FilledButton.styleFrom(
                  backgroundColor: HairTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "I'm ready",
                  style: GoogleFonts.lora(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCue extends StatelessWidget {
  final String label;
  final CustomPainter painter;
  const _StepCue({required this.label, required this.painter});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: HairTheme.blush.withValues(alpha: 0.28),
          ),
          child: Center(
            child: CustomPaint(size: const Size(40, 40), painter: painter),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 88,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 12,
              color: HairTheme.textMuted,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _CueFacePainter extends CustomPainter {
  final bool tilted;
  const _CueFacePainter({required this.tilted});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = HairTheme.accentDark.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    if (tilted) {
      canvas.scale(1, 0.82);
      canvas.translate(0, 4);
      canvas.rotate(-0.2);
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size.width * 0.7, height: size.height * 0.85),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-7, -2), width: 6, height: 3.5),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(7, -2), width: 6, height: 3.5),
      p,
    );
    canvas.restore();
    if (tilted) {
      final arrow = Paint()
        ..color = HairTheme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.1, 16, 22),
        -1.2,
        2.2,
        false,
        arrow,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CueFacePainter oldDelegate) =>
      oldDelegate.tilted != tilted;
}

class _CueCameraPainter extends CustomPainter {
  const _CueCameraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = HairTheme.accentDark.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 + 2),
        width: size.width * 0.72,
        height: size.height * 0.5,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(r, p);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 + 2),
      size.width * 0.14,
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CapturePane extends StatelessWidget {
  final String? viewType;
  final HairCaptureState state;
  final String? error;

  const _CapturePane({
    super.key,
    required this.viewType,
    required this.state,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Column(
              key: ValueKey('${state.step}-${state.title}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STEP ${state.step} OF 2',
                  style: HairTheme.eyebrow(10),
                ),
                const SizedBox(height: 6),
                Text(state.title, style: HairTheme.headline(26)),
                const SizedBox(height: 6),
                Text(
                  state.instruction,
                  style: HairTheme.body(15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: HairTheme.softCard(radius: 28),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (viewType != null)
                    HtmlElementView(viewType: viewType!)
                  else
                    const ColoredBox(color: Color(0xFF1A1212)),
                  if (state.countdown != null)
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          '${state.countdown}',
                          key: ValueKey(state.countdown),
                          style: GoogleFonts.lora(
                            fontSize: 88,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.92),
                            shadows: const [
                              Shadow(
                                blurRadius: 18,
                                color: Color(0x88000000),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _LiveStatus(state: state),
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 13.5,
                color: const Color(0xFFB04A4A),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Live coaching + thin progress — no oval / HUD overlays.
class _LiveStatus extends StatelessWidget {
  final HairCaptureState state;
  const _LiveStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    final lines = state.lines;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFCF9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HairTheme.accent.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            state.instruction,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: HairTheme.textHigh,
              height: 1.3,
            ),
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 13.5,
                    color: HairTheme.textMuted,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: state.progress.clamp(0.0, 1.0),
              minHeight: 3.5,
              backgroundColor: HairTheme.blush.withValues(alpha: 0.28),
              color: state.progress > 0
                  ? const Color(0xFF7CB39A)
                  : HairTheme.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzingPane extends StatelessWidget {
  final AnimationController spin;
  final String message;

  const _AnalyzingPane({
    super.key,
    required this.spin,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Column(
        children: [
          const Spacer(),
          Text('Analyzing Hair', style: HairTheme.headline(30)),
          const SizedBox(height: 12),
          Text(
            'This may take a little while. Keep this screen open.',
            textAlign: TextAlign.center,
            style: HairTheme.body(14.5),
          ),
          const SizedBox(height: 36),
          AnimatedBuilder(
            animation: spin,
            builder: (_, __) {
              return CustomPaint(
                size: const Size(148, 148),
                painter: _BloomLoaderPainter(spin.value),
              );
            },
          ),
          const SizedBox(height: 36),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            child: Text(
              message,
              key: ValueKey(message),
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: HairTheme.textHigh,
                height: 1.4,
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _BloomLoaderPainter extends CustomPainter {
  final double t;
  _BloomLoaderPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final radius = r * (0.55 + phase * 0.55);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = HairTheme.accent.withValues(alpha: 1 - phase),
      );
    }
    canvas.drawCircle(
      c,
      r * 0.28,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r * 0.28,
          [HairTheme.blush, HairTheme.accent],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _BloomLoaderPainter oldDelegate) =>
      oldDelegate.t != t;
}
