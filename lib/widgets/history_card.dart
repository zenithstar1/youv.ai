import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity_model.dart';
import '../utils/responsive.dart';

/// Card widget displaying a single analysis session summary.
///
/// Shows analysis type, date, acne score, hydration score, and an
/// optional thumbnail.  Tapping the card can navigate to a detail
/// screen once the backend detail endpoint is available.
class HistoryCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback? onTap;

  const HistoryCard({
    super.key,
    required this.activity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: r.h(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.w(18)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD79096).withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(r.w(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ──────────────────────────────────────────────────
              _Thumbnail(activity: activity, r: r),

              SizedBox(width: r.w(14)),

              // ── Content ────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Analysis type + status chip
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            activity.analysisType,
                            style: GoogleFonts.lora(
                              fontSize: r.sp(13.5),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3B1F1F),
                              height: 1.3,
                            ),
                          ),
                        ),
                        SizedBox(width: r.w(6)),
                        _StatusChip(status: activity.status, r: r),
                      ],
                    ),

                    SizedBox(height: r.h(6)),

                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: r.sp(12),
                          color: const Color(0xFF8A7A72),
                        ),
                        SizedBox(width: r.w(4)),
                        Text(
                          activity.formattedDate,
                          style: GoogleFonts.poppins(
                            fontSize: r.sp(11.5),
                            color: const Color(0xFF8A7A72),
                          ),
                        ),
                      ],
                    ),

                    // Overall skin health index
                    if (activity.skinHealthIndex != null) ...[
                      SizedBox(height: r.h(8)),
                      _HealthIndexBar(score: activity.skinHealthIndex!, r: r),
                    ],

                    SizedBox(height: r.h(10)),

                    // Score pills row
                    Row(
                      children: [
                        _ScorePill(
                          label: 'Acne',
                          score: activity.acneScore,
                          color: const Color(0xFFE57373),
                          r: r,
                        ),
                        SizedBox(width: r.w(8)),
                        _ScorePill(
                          label: 'Hydration',
                          score: activity.hydrationScore,
                          color: const Color(0xFF64B5F6),
                          r: r,
                        ),
                        if (activity.pigmentationScore != null) ...[
                          SizedBox(width: r.w(8)),
                          _ScorePill(
                            label: 'Pigment',
                            score: activity.pigmentationScore!,
                            color: const Color(0xFFBA68C8),
                            r: r,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final ActivityModel activity;
  final Responsive r;
  const _Thumbnail({required this.activity, required this.r});

  @override
  Widget build(BuildContext context) {
    final size = r.w(68);
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(r.w(12)),
      gradient: const LinearGradient(
        colors: [Color(0xFFFCE7E7), Color(0xFFE4B3B8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );

    Widget inner;

    if (activity.thumbnailUrl != null && activity.thumbnailUrl!.isNotEmpty) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(r.w(12)),
        child: Image.network(
          activity.thumbnailUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              color: const Color(0xFFFCE7E7),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD79096),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _FallbackIcon(size: size, r: r),
        ),
      );
    } else if (activity.thumbnailAsset != null &&
        activity.thumbnailAsset!.isNotEmpty) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(r.w(12)),
        child: Image.asset(
          activity.thumbnailAsset!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackIcon(size: size, r: r),
        ),
      );
    } else {
      inner = _FallbackIcon(size: size, r: r);
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      child: inner,
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final double size;
  final Responsive r;
  const _FallbackIcon({required this.size, required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.w(12)),
        gradient: const LinearGradient(
          colors: [Color(0xFFFCE7E7), Color(0xFFE4B3B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.face_retouching_natural_outlined,
        size: r.sp(30),
        color: const Color(0xFFD79096),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Responsive r;
  const _StatusChip({required this.status, required this.r});

  @override
  Widget build(BuildContext context) {
    final color = status == 'completed'
        ? const Color(0xFF4CAF50)
        : status == 'pending'
            ? const Color(0xFFFF9800)
            : const Color(0xFFF44336);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.w(8),
        vertical: r.h(3),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(r.w(20)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: GoogleFonts.poppins(
          fontSize: r.sp(10),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _HealthIndexBar extends StatelessWidget {
  final double score;
  final Responsive r;
  const _HealthIndexBar({required this.score, required this.r});

  Color get _color {
    if (score >= 75) return const Color(0xFF4CAF50);
    if (score >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(7)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(r.w(10)),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skin Health Index',
                style: GoogleFonts.poppins(
                  fontSize: r.sp(9),
                  color: const Color(0xFF8A7A72),
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)}/100',
                style: GoogleFonts.poppins(
                  fontSize: r.sp(13),
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(width: r.w(12)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(r.w(4)),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                minHeight: r.h(6),
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final Responsive r;
  const _ScorePill({
    required this.label,
    required this.score,
    required this.color,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.w(8),
        vertical: r.h(4),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(r.w(8)),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${score.toStringAsFixed(0)}%',
            style: GoogleFonts.poppins(
              fontSize: r.sp(11.5),
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: r.sp(9.5),
              color: const Color(0xFF8A7A72),
            ),
          ),
        ],
      ),
    );
  }
}
