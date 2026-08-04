import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/hair_analysis_client.dart';
import '../utils/hair_image_picker.dart';
import '../widgets/hair_oval_guide.dart';
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
              builder: (_) => const HairCameraScreen(title: 'Hair photo'),
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
        includeImages: false,
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
          Positioned(
            top: -100,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HairTheme.blush.withValues(alpha: 0.28),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                    children: [
                      Text(
                        'Add one clear head or scalp photo',
                        textAlign: TextAlign.center,
                        style: HairTheme.headline(22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nothing appears until you choose Camera or Gallery — then Analyze unlocks.',
                        textAlign: TextAlign.center,
                        style: HairTheme.body(13.5),
                      ),
                      const SizedBox(height: 18),
                      AspectRatio(
                        aspectRatio: 0.82,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          decoration: HairTheme.softCard(radius: 26),
                          clipBehavior: Clip.antiAlias,
                          child: hasPhoto
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(_bytes!, fit: BoxFit.cover),
                                    HairOvalGuide(
                                      hint: 'Looks good? Continue below',
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
                              : _EmptyPhotoState(
                                  onGallery: () => _pick(false),
                                  onCamera: () => _pick(true),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: const [
                          _TipChip(icon: Icons.wb_sunny_outlined, label: 'Even light'),
                          _TipChip(icon: Icons.water_drop_outlined, label: 'Dry hair'),
                          _TipChip(icon: Icons.crop_free, label: 'Fill the oval'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_softTip != null)
                        HairBanner(
                          text: _softTip!,
                          color: HairTheme.warn,
                          icon: Icons.wb_sunny_outlined,
                        ),
                      if (_error != null)
                        HairBanner(
                          text: _error!,
                          color: Colors.redAccent,
                          icon: Icons.error_outline,
                        ),
                      if (hasPhoto) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : () => _pick(true),
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Retake'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: HairTheme.accentDark,
                                  side: const BorderSide(
                                    color: HairTheme.accent,
                                  ),
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : () => _pick(false),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Gallery'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: HairTheme.accentDark,
                                  side: const BorderSide(
                                    color: HairTheme.accent,
                                  ),
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: hasPhoto && !_loading
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFE4B3B8),
                                      Color(0xFFD79096),
                                    ],
                                  )
                                : null,
                            color: hasPhoto && !_loading
                                ? null
                                : const Color(0xFFE8DDD9),
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
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              hasPhoto ? 'Analyze photo' : 'Add a photo to analyze',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
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
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _EmptyPhotoState({
    required this.onGallery,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8F6), Color(0xFFF3DCE0)],
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _DashedOvalPainter(),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.85),
                      boxShadow: [
                        BoxShadow(
                          color: HairTheme.accent.withValues(alpha: 0.25),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.content_cut_rounded,
                      color: HairTheme.accentDark,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No photo yet',
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: HairTheme.textHigh,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fit your head in the oval after you add a photo.',
                    textAlign: TextAlign.center,
                    style: HairTheme.body(13),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        'Upload from gallery',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HairTheme.accentDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: onCamera,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(
                        'Use camera',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HairTheme.accentDark,
                        side: const BorderSide(color: HairTheme.accentDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.58,
      height: size.height * 0.48,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HairTheme.blush.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: HairTheme.accentDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.lora(
              fontSize: 12,
              color: HairTheme.textHigh,
              fontWeight: FontWeight.w600,
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
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HairTheme.accentDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
