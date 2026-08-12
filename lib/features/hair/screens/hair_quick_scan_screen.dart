import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/hair_analysis_client.dart';
import '../utils/hair_image_picker.dart';
import '../widgets/hair_oval_guide.dart';
import '../widgets/hair_pose_coach.dart';
import '../widgets/hair_result_widgets.dart';
import '../widgets/hair_theme.dart';
import 'hair_camera_screen.dart';
import 'hair_results_screen.dart';

class HairQuickScanScreen extends StatefulWidget {
  const HairQuickScanScreen({super.key});

  @override
  State<HairQuickScanScreen> createState() => _HairQuickScanScreenState();
}

class _HairQuickScanScreenState extends State<HairQuickScanScreen> {
  final _client = HairAnalysisClient();
  Uint8List? _bytes;
  String _fileName = 'capture.jpg';
  String? _softTip;
  String? _error;
  bool _loading = false;

  Future<void> _pick(bool camera) async {
    setState(() {
      _error = null;
      _softTip = null;
    });
    final navigator = Navigator.of(context);
    final picked = camera
        ? await navigator.push<HairPickedImage>(
            MaterialPageRoute(
              builder: (_) => const HairCameraScreen(
                title: 'Hair photo',
                pose: HairCapturePose.top,
              ),
            ),
          )
        : await HairImagePickerHelper.fromGallery();
    if (picked == null || !mounted) return;

    final validation = HairImagePickerHelper.validate(picked.bytes);
    if (validation.isEmpty) {
      setState(() => _error = validation.tip);
      return;
    }

    setState(() {
      _bytes = picked.bytes;
      _fileName = picked.fileName;
      _softTip = validation.tip;
    });
  }

  Future<void> _analyze() async {
    final bytes = _bytes;
    if (bytes == null) {
      setState(() => _error = 'Add a photo first — tap Gallery or Camera.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _client.analyzeSingle(
        bytes: bytes,
        fileName: _fileName,
        viewType: 'Front View',
      );
      if (!mounted) return;
      setState(() => _loading = false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HairResultsScreen.single(
            result: result,
            previewBytes: bytes,
            expectedSlotLabel: null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _bytes != null;

    return Scaffold(
      backgroundColor: HairTheme.pageBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: HairTheme.textHigh,
                      ),
                      Expanded(
                        child: Text(
                          'Quick Scan',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lora(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: HairTheme.textHigh,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      children: [
                        Text(
                          'Add one clear head or scalp photo',
                          textAlign: TextAlign.center,
                          style: HairTheme.headline(20),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nothing appears until you choose Camera or Gallery — then Analyze unlocks.',
                          textAlign: TextAlign.center,
                          style: HairTheme.body(13),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            width: double.infinity,
                            decoration: HairTheme.softCard(radius: 24),
                            clipBehavior: Clip.antiAlias,
                            child: hasPhoto
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(
                                        _bytes!,
                                        fit: BoxFit.cover,
                                      ),
                                      const HairOvalGuide(
                                        hint: 'Looks good? Continue below',
                                        hintBottomFraction: 0.08,
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: _PillButton(
                                          icon: Icons.refresh_rounded,
                                          label: 'Change',
                                          onTap: () => _pick(false),
                                        ),
                                      ),
                                    ],
                                  )
                                : const _EmptyPhotoState(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _loading ? null : () => _pick(false),
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                    size: 20,
                                  ),
                                  label: Text(
                                    'Upload from gallery',
                                    style: GoogleFonts.lora(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: HairTheme.accent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _loading ? null : () => _pick(true),
                                  icon: const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 20,
                                  ),
                                  label: Text(
                                    'Use camera',
                                    style: GoogleFonts.lora(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: HairTheme.accentDark,
                                    side: const BorderSide(
                                      color: HairTheme.accent,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(
                              child: _TipChip(
                                icon: Icons.wb_sunny_outlined,
                                label: 'Even light',
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _TipChip(
                                icon: Icons.water_drop_outlined,
                                label: 'Dry hair',
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _TipChip(
                                icon: Icons.crop_free,
                                label: 'Fill the oval',
                              ),
                            ),
                          ],
                        ),
                        if (_softTip != null) ...[
                          const SizedBox(height: 12),
                          HairBanner(
                            text: _softTip!,
                            color: HairTheme.warn,
                            icon: Icons.wb_sunny_outlined,
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          HairBanner(
                            text: _error!,
                            color: HairTheme.error,
                            icon: Icons.error_outline,
                          ),
                        ],
                        const SizedBox(height: 14),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: hasPhoto && !_loading ? 1 : 0.5,
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: hasPhoto && !_loading
                                    ? const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: HairTheme.ctaGradient,
                                      )
                                    : null,
                                color: hasPhoto && !_loading
                                    ? null
                                    : HairTheme.disabledFill,
                                boxShadow: hasPhoto && !_loading
                                    ? [
                                        BoxShadow(
                                          color: HairTheme.accent
                                              .withValues(alpha: 0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    _loading || !hasPhoto ? null : _analyze,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: HairTheme.textSoft,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: Text(
                                  hasPhoto
                                      ? 'Analyze photo'
                                      : 'Add a photo to analyze',
                                  style: HairTheme.cta(15),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const HairLoadingOverlay(
              message:
                  'Reading density & scalp signals…\nThis can take 30–90+ seconds.',
            ),
        ],
      ),
    );
  }
}

class _EmptyPhotoState extends StatelessWidget {
  const _EmptyPhotoState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFCF9), Color(0xFFF6E4E6)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _DashedOvalPainter()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HairTheme.iconTile,
                    boxShadow: [
                      BoxShadow(
                        color: HairTheme.accent.withValues(alpha: 0.25),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.content_cut_rounded,
                    color: HairTheme.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No photo yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: HairTheme.textHigh,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fit your head in the oval after you add a photo.',
                  textAlign: TextAlign.center,
                  style: HairTheme.body(12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedOvalPainter extends CustomPainter {
  const _DashedOvalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.48),
      width: size.width * 0.62,
      height: size.height * 0.58,
    );
    final paint = Paint()
      ..color = HairTheme.accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const dash = 8.0;
    const gap = 6.0;
    final path = Path()..addOval(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TipChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TipChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HairTheme.blush.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HairTheme.accentDark),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lora(
                fontSize: 11,
                color: HairTheme.textHigh,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: HairTheme.accentDark),
              const SizedBox(width: 4),
              Text(
                label,
                style: HairTheme.label(12, color: HairTheme.accentDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
