import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive.dart';

/// Shown on the History screen when the user has no analysis sessions yet.
///
/// Provides a CTA button so the user can start their first scan immediately.
class EmptyActivityWidget extends StatelessWidget {
  final VoidCallback? onStartScan;

  const EmptyActivityWidget({super.key, this.onStartScan});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.w(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration container
            Container(
              width: r.w(120),
              height: r.w(120),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFCE7E7), Color(0xFFE4B3B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD79096).withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.history_outlined,
                size: r.sp(52),
                color: const Color(0xFFD79096),
              ),
            ),

            SizedBox(height: r.h(28)),

            Text(
              'No Scans Yet',
              style: GoogleFonts.lora(
                fontSize: r.sp(22),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B1F1F),
              ),
            ),

            SizedBox(height: r.h(10)),

            Text(
              'Your skin analysis history will appear\nhere after your first scan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: r.sp(13.5),
                color: const Color(0xFF8A7A72),
                height: 1.6,
              ),
            ),

            SizedBox(height: r.h(32)),

            if (onStartScan != null)
              GestureDetector(
                onTap: onStartScan,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: r.w(32),
                    vertical: r.h(14),
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD79096), Color(0xFFBC826E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(r.w(30)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBC826E).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: r.sp(18),
                      ),
                      SizedBox(width: r.w(8)),
                      Text(
                        'Start Your First Scan',
                        style: GoogleFonts.lora(
                          fontSize: r.sp(15),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
