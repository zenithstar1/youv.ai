import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/hair_analysis_client.dart';
import '../models/hair_single_result.dart';
import '../utils/hair_image_picker.dart';
import '../widgets/hair_result_widgets.dart';
import '../widgets/hair_theme.dart';
import 'hair_camera_screen.dart';
import 'hair_results_screen.dart';

enum HairScanSlot {
  front('Front', 'Face visible for hairline', Icons.face_retouching_natural),
  left('Left side', 'Left profile / parting', Icons.rotate_90_degrees_ccw),
  right('Right side', 'Right profile / parting', Icons.rotate_90_degrees_cw),
  top('Top / crown', 'Crown or top of head', Icons.keyboard_arrow_up_rounded);

  const HairScanSlot(this.title, this.hint, this.icon);
  final String title;
  final String hint;
  final IconData icon;
}

class _SlotImage {
  final Uint8List bytes;
  final String fileName;
  final String? softTip;

  const _SlotImage({
    required this.bytes,
    required this.fileName,
    this.softTip,
  });
}

class HairFullScanScreen extends StatefulWidget {
  const HairFullScanScreen({super.key});

  @override
  State<HairFullScanScreen> createState() => _HairFullScanScreenState();
}

class _HairFullScanScreenState extends State<HairFullScanScreen> {
  final _client = HairAnalysisClient();
  final Map<HairScanSlot, _SlotImage> _slots = {};
  bool _loading = false;
  String? _error;
  String _loadingMsg =
      'Running Full Scan…\nThis can take a minute or more.';

  int get _filledCount => _slots.length;

  Future<void> _fillSlot(HairScanSlot slot, {required bool camera}) async {
    setState(() => _error = null);
    final navigator = Navigator.of(context);
    final picked = camera
        ? await navigator.push<HairPickedImage>(
            MaterialPageRoute(
              builder: (_) => HairCameraScreen(
                title: slot.title,
                preferredLens: slot == HairScanSlot.front
                    ? CameraLensDirection.front
                    : CameraLensDirection.back,
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
      _slots[slot] = _SlotImage(
        bytes: picked.bytes,
        fileName: '${slot.name}_${picked.fileName}',
        softTip: validation.tip,
      );
    });
  }

  void _clearSlot(HairScanSlot slot) {
    setState(() => _slots.remove(slot));
  }

  Future<void> _analyze() async {
    if (_filledCount < 2) {
      setState(() {
        _error = 'Add at least 2 photos for Full Scan (you can skip the rest).';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _loadingMsg =
          'Running multi-view analysis…\nThis can take 30–90+ seconds.';
    });

    try {
      final files = _slots.entries
          .map(
            (e) => (
              bytes: e.value.bytes,
              fileName: e.value.fileName,
            ),
          )
          .toList();

      final multi = await _client.analyzeMulti(files: files);

      final perSlot = <HairScanSlot, HairSingleResult>{};
      final ordered = _slots.entries.toList();
      for (var i = 0; i < ordered.length; i++) {
        final entry = ordered[i];
        if (!mounted) return;
        setState(() {
          _loadingMsg =
              'Analyzing photo ${i + 1}/${ordered.length}…\nPlease keep this screen open.';
        });
        try {
          final single = await _client.analyzeSingle(
            bytes: entry.value.bytes,
            fileName: entry.value.fileName,
            includeImages: false,
          );
          perSlot[entry.key] = single;
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() => _loading = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HairResultsScreen.multi(
            multi: multi,
            slotResults: perSlot,
            slotPreviews: {
              for (final e in _slots.entries) e.key: e.value.bytes,
            },
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
    final ready = _filledCount >= 2;

    return Scaffold(
      backgroundColor: HairTheme.pageBg,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HairTheme.blush.withValues(alpha: 0.3),
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
                          'Full Scan',
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
                        'Capture a few angles',
                        textAlign: TextAlign.center,
                        style: HairTheme.headline(22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill at least 2 slots. Skip any angle you cannot capture.',
                        textAlign: TextAlign.center,
                        style: HairTheme.body(13.5),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: HairTheme.softCard(radius: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _filledCount /
                                      HairScanSlot.values.length,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFEDE4E0),
                                  color: HairTheme.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$_filledCount / ${HairScanSlot.values.length}',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: HairTheme.accentDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_error != null)
                        HairBanner(
                          text: _error!,
                          color: Colors.redAccent,
                          icon: Icons.error_outline,
                        ),
                      for (final slot in HairScanSlot.values) ...[
                        _SlotCard(
                          slot: slot,
                          image: _slots[slot],
                          onCamera: () => _fillSlot(slot, camera: true),
                          onGallery: () => _fillSlot(slot, camera: false),
                          onClear: () => _clearSlot(slot),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: ready && !_loading
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFD4B5A0),
                                      Color(0xFFB8897A),
                                    ],
                                  )
                                : null,
                            color: ready && !_loading
                                ? null
                                : const Color(0xFFE8DDD9),
                          ),
                          child: ElevatedButton(
                            onPressed: _loading || !ready ? null : _analyze,
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
                              ready
                                  ? 'Analyze Full Scan'
                                  : 'Add ${_filledCount >= 2 ? 0 : 2 - _filledCount} more photo${_filledCount == 1 ? '' : 's'}',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
          if (_loading) HairLoadingOverlay(message: _loadingMsg),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final HairScanSlot slot;
  final _SlotImage? image;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onClear;

  const _SlotCard({
    required this.slot,
    required this.image,
    required this.onCamera,
    required this.onGallery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final filled = image != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HairTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: filled
              ? HairTheme.accent.withValues(alpha: 0.75)
              : const Color(0xFFE8DDD8),
          width: filled ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: filled ? 0.06 : 0.03),
            blurRadius: filled ? 14 : 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: filled
                      ? HairTheme.accent.withValues(alpha: 0.2)
                      : HairTheme.pageBgDeep,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  filled ? Icons.check_rounded : slot.icon,
                  color: HairTheme.accentDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.title,
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: HairTheme.textHigh,
                      ),
                    ),
                    Text(
                      slot.hint,
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        color: HairTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (filled)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 20),
                  color: HairTheme.textMuted,
                )
              else
                Text(
                  'Optional',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: HairTheme.textSoft,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (filled) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.memory(image!.bytes, fit: BoxFit.cover),
              ),
            ),
            if (image!.softTip != null) ...[
              const SizedBox(height: 8),
              Text(
                image!.softTip!,
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: HairTheme.warn,
                ),
              ),
            ],
          ] else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HairTheme.accentDark,
                      side: const BorderSide(color: HairTheme.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HairTheme.accentDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
