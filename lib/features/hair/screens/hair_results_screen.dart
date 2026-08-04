import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/hair_multi_result.dart';
import '../models/hair_single_result.dart';
import '../utils/hair_image_picker.dart';
import '../widgets/hair_result_widgets.dart';
import '../widgets/hair_theme.dart';
import 'hair_full_scan_screen.dart';

class HairResultsScreen extends StatelessWidget {
  final HairSingleResult? single;
  final HairMultiResult? multi;
  final Uint8List? previewBytes;
  final String? expectedSlotLabel;
  final Map<HairScanSlot, HairSingleResult>? slotResults;
  final Map<HairScanSlot, Uint8List>? slotPreviews;

  const HairResultsScreen._({
    this.single,
    this.multi,
    this.previewBytes,
    this.expectedSlotLabel,
    this.slotResults,
    this.slotPreviews,
  });

  factory HairResultsScreen.single({
    required HairSingleResult result,
    Uint8List? previewBytes,
    String? expectedSlotLabel,
  }) {
    return HairResultsScreen._(
      single: result,
      previewBytes: previewBytes,
      expectedSlotLabel: expectedSlotLabel,
    );
  }

  factory HairResultsScreen.multi({
    required HairMultiResult multi,
    Map<HairScanSlot, HairSingleResult>? slotResults,
    Map<HairScanSlot, Uint8List>? slotPreviews,
  }) {
    return HairResultsScreen._(
      multi: multi,
      slotResults: slotResults,
      slotPreviews: slotPreviews,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMulti = multi != null;
    return Scaffold(
      backgroundColor: HairTheme.pageBg,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
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
                          isMulti ? 'Full Scan Results' : 'Your hair insights',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lora(
                            fontSize: 17,
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
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
                    children: [
                      Text(
                        'Informational insights only — not a medical diagnosis.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          color: HairTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (single != null) ..._buildSingle(context, single!),
                      if (multi != null) ..._buildMulti(context, multi!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSingle(BuildContext context, HairSingleResult r) {
    final mismatch = expectedSlotLabel != null &&
        !HairImagePickerHelper.viewMatchesSlot(
          expectedSlotLabel!,
          r.viewType,
        );

    return [
      if (mismatch)
        HairBanner(
          text:
              'Wrong angle — API saw “${r.viewType}” but this slot was labeled “$expectedSlotLabel”. Retake or move the photo to the matching slot.',
          color: HairTheme.warn,
          icon: Icons.swap_horiz,
        ),
      if (r.lowQuality)
        HairBanner(
          text:
              'Quality score ${r.qualityScore!.toStringAsFixed(1)} is below 60. Results are shown, but a sharper/brighter retake may improve accuracy.',
          color: HairTheme.warn,
          icon: Icons.high_quality_outlined,
        ),
      if (previewBytes != null)
        HairSectionCard(
          title: 'Your photo',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(previewBytes!, fit: BoxFit.cover),
          ),
        ),
      HairSectionCard(
        title: 'Overview',
        child: HairKeyValueList(
          entries: [
            if (r.viewType.isNotEmpty) MapEntry('Detected view', r.viewType),
            if (r.qualityScore != null)
              MapEntry(
                'Quality score',
                r.qualityScore!.toStringAsFixed(1),
              ),
            if (r.densityAssessment != null &&
                r.densityAssessment!.trim().isNotEmpty)
              MapEntry('Assessment', r.densityAssessment!),
          ],
        ),
      ),
      if (r.density != null)
        HairSectionCard(
          title: 'Density',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.densityAssessment != null) ...[
                Text(
                  r.densityAssessment!,
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: HairTheme.textHigh,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              HairDensityBars(density: r.density!),
              if (r.crownDensity != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Crown density',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: HairTheme.textHigh,
                  ),
                ),
                const SizedBox(height: 8),
                HairDensityBars(density: r.crownDensity!),
              ],
            ],
          ),
        ),
      if (r.features != null && r.features!.entries.isNotEmpty)
        HairSectionCard(
          title: 'Features',
          child: HairKeyValueList(entries: r.features!.entries),
        ),
      if (r.scalpCondition != null && r.scalpCondition!.entries.isNotEmpty)
        HairSectionCard(
          title: 'Scalp condition',
          child: HairKeyValueList(entries: r.scalpCondition!.entries),
        ),
      if (r.hairline != null && r.hairline!.detected)
        HairSectionCard(
          title: 'Hairline',
          child: HairKeyValueList(
            entries: [
              for (final e in r.hairline!.metrics.entries)
                MapEntry(e.key, e.value.toString()),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildMulti(BuildContext context, HairMultiResult m) {
    final widgets = <Widget>[
      HairSectionCard(
        title: 'Combined summary',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.densityAssessment != null) ...[
              Text(
                m.densityAssessment!,
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HairTheme.textHigh,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (m.density != null) HairDensityBars(density: m.density!),
            if (m.features != null && m.features!.entries.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Features',
                style: GoogleFonts.lora(
                  fontWeight: FontWeight.w700,
                  color: HairTheme.textHigh,
                ),
              ),
              const SizedBox(height: 8),
              HairKeyValueList(entries: m.features!.entries),
            ],
            if (m.scalpCondition != null &&
                m.scalpCondition!.entries.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Scalp condition',
                style: GoogleFonts.lora(
                  fontWeight: FontWeight.w700,
                  color: HairTheme.textHigh,
                ),
              ),
              const SizedBox(height: 8),
              HairKeyValueList(entries: m.scalpCondition!.entries),
            ],
            if (m.density == null &&
                m.densityAssessment == null &&
                (m.features == null || m.features!.entries.isEmpty))
              Text(
                'Multi-view report received. Expand photos below for details.',
                style: GoogleFonts.lora(
                  fontSize: 13,
                  color: HairTheme.textMuted,
                ),
              ),
          ],
        ),
      ),
      Text(
        'Per-photo details',
        style: GoogleFonts.lora(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: HairTheme.textHigh,
        ),
      ),
      const SizedBox(height: 10),
    ];

    final slots = slotResults;
    if (slots != null && slots.isNotEmpty) {
      for (final entry in slots.entries) {
        final slot = entry.key;
        final r = entry.value;
        final preview = slotPreviews?[slot];
        final mismatch = !HairImagePickerHelper.viewMatchesSlot(
          slot.title,
          r.viewType,
        );

        widgets.add(
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: HairTheme.card,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(
                  slot.title,
                  style: GoogleFonts.lora(
                    fontWeight: FontWeight.w700,
                    color: HairTheme.textHigh,
                  ),
                ),
                subtitle: Text(
                  [
                    if (r.viewType.isNotEmpty) 'API: ${r.viewType}',
                    if (r.qualityScore != null)
                      'Q ${r.qualityScore!.toStringAsFixed(0)}',
                  ].join(' · '),
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: HairTheme.textMuted,
                  ),
                ),
                children: [
                  if (mismatch)
                    HairBanner(
                      text:
                          'Wrong angle — retake or move to the correct slot. API view: ${r.viewType}',
                      color: HairTheme.warn,
                    ),
                  if (r.lowQuality)
                    HairBanner(
                      text:
                          'Quality below 60 — results shown; a retake may help.',
                      color: HairTheme.warn,
                    ),
                  if (preview != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(preview, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (r.density != null) HairDensityBars(density: r.density!),
                  if (r.densityAssessment != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      r.densityAssessment!,
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        color: HairTheme.textHigh,
                      ),
                    ),
                  ],
                  if (r.hairline != null && r.hairline!.detected) ...[
                    const SizedBox(height: 10),
                    HairKeyValueList(
                      entries: [
                        for (final e in r.hairline!.metrics.entries)
                          MapEntry(e.key, e.value.toString()),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }
    } else if (m.perImage.isNotEmpty) {
      for (final item in m.perImage) {
        widgets.add(
          HairSectionCard(
            title: item.viewType ?? item.imageName ?? 'Photo',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.densityAssessment != null)
                  Text(item.densityAssessment!),
                if (item.density != null) ...[
                  const SizedBox(height: 8),
                  HairDensityBars(density: item.density!),
                ],
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
