import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/hair_single_result.dart';
import 'hair_theme.dart';

class HairLoadingOverlay extends StatelessWidget {
  final String message;

  const HairLoadingOverlay({
    super.key,
    this.message =
        'Analyzing hair & scalp…\nThis can take up to a couple of minutes.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HairTheme.textHigh.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
          decoration: HairTheme.softCard(radius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3.2,
                  color: HairTheme.accent,
                  backgroundColor: HairTheme.blush.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 15,
                  height: 1.45,
                  color: HairTheme.textHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HairDensityBars extends StatelessWidget {
  final HairDensity density;

  const HairDensityBars({super.key, required this.density});

  @override
  Widget build(BuildContext context) {
    // Semantic score colors aligned with skin results thresholds.
    final items = [
      ('High visible density', density.densePct, const Color(0xFF43A047)),
      ('Medium visible density', density.mediumPct, const Color(0xFFFB8C00)),
      ('Low visible density', density.thinPct, const Color(0xFFD32F2F)),
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _BarRow(
            label: items[i].$1,
            pct: items[i].$2,
            color: items[i].$3,
            delayMs: i * 100,
          ),
          const SizedBox(height: 12),
        ],
        if (density.confidence != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Confidence ${density.confidence!.toStringAsFixed(1)}%',
              style: GoogleFonts.lora(
                fontSize: 12,
                color: HairTheme.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double? pct;
  final Color color;
  final int delayMs;

  const _BarRow({
    required this.label,
    required this.pct,
    required this.color,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final value = ((pct ?? 0).clamp(0, 100)) / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lora(
            fontSize: 13,
            color: HairTheme.textHigh,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: Duration(milliseconds: 850 + delayMs),
                curve: Curves.easeOutQuad,
                builder: (context, val, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: val,
                    minHeight: 11,
                    backgroundColor: HairTheme.track,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              child: Text(
                pct == null ? '—' : '${pct!.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: HairTheme.label(12, color: HairTheme.textHigh),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HairKeyValueList extends StatelessWidget {
  final List<MapEntry<String, String>> entries;

  const HairKeyValueList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        'No details available',
        style: GoogleFonts.lora(color: HairTheme.textMuted, fontSize: 13),
      );
    }
    return Column(
      children: [
        for (final e in entries) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: HairTheme.pageBg.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    e.key,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      color: HairTheme.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    e.value,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: HairTheme.textHigh,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class HairSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? accent;

  const HairSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: HairTheme.softCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accent ?? HairTheme.textHigh,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class HairBanner extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const HairBanner({
    super.key,
    required this.text,
    required this.color,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lora(
                fontSize: 13,
                height: 1.35,
                color: HairTheme.textHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
