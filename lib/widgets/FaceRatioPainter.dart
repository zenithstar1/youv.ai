import 'package:flutter/material.dart';
import 'package:skin_analysis_app/Models/FaceRatioLine.dart';

class PrettyRatioPainter extends CustomPainter {
  final FaceRatioData data;
  final RatioMode mode;
  PrettyRatioPainter(this.data, this.mode);

  // ===== Brightened Brand Palette =====
  static const _rose = Color(0xFFF58B92);
  static const _roseDeep = Color(0xFFE67880);
  static const _mauve = Color(0xFFCA6E77);
  static const _plum = Color(0xFFA4545E);
  static const _maroon = Color(0xFF7B3E45);
  static const _veil = Color(0x15000000);
  static const _pillBg = Color(0xE61C1C1C);

  // Base paints (we'll override strokeWidth dynamically per-screen)
  Paint get _edge => Paint()
    ..color = _plum.withOpacity(.98)
    ..strokeWidth = 2.3
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  Paint get _line => Paint()
    ..color = _roseDeep.withOpacity(.95)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  Paint get _dash => Paint()
    ..color = _mauve.withOpacity(.95)
    ..strokeWidth = 1.8
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  Paint get _softFill => Paint()
    ..color = _rose.withOpacity(.14)
    ..style = PaintingStyle.fill;

  Paint _bubblePaint(RRect r) => Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF999A0), Color(0xFFE26E77)],
    ).createShader(r.outerRect);

  // ---- text ----
  TextPainter _tp(
    String s, {
    double fs = 14,
    FontWeight fw = FontWeight.w800,
    Color c = Colors.white,
  }) {
    final t = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: fs,
          fontWeight: fw,
          color: c,
          letterSpacing: .3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    t.layout();
    return t;
  }

  void _pill(
    Canvas canvas,
    Size size, {
    required String your,
    String? golden,
    double scale = 1.0,
  }) {
    final title = _tp(
      your,
      fs: 17 * scale.clamp(1.0, 1.3),
      fw: FontWeight.w900,
    );
    final sub = golden != null && golden.trim().isNotEmpty
        ? _tp(
            golden,
            fs: 14 * scale.clamp(1.0, 1.3),
            fw: FontWeight.w600,
            c: Colors.white70,
          )
        : null;

    final w = sub == null
        ? (title.width + (38 * scale))
        : (title.width > sub.width ? title.width : sub.width) + (40 * scale);
    final h = sub == null
        ? (title.height + (16 * scale))
        : (title.height + sub.height + (24 * scale));

    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, 34 * scale),
        width: w,
        height: h,
      ),
      Radius.circular(24 * scale),
    );
    canvas.drawRRect(r, Paint()..color = _pillBg);

    final topLeft = Offset(
      size.width / 2 - title.width / 2,
      (34 * scale) - (h / 2) + (10 * scale),
    );
    title.paint(canvas, topLeft);

    if (sub != null) {
      final subTop =
          topLeft +
          Offset((title.width - sub.width) / 2, title.height + (5 * scale));
      sub.paint(canvas, subTop);
    }
  }

  // ---- dynamic stroke width helpers ----
  Paint _edgeP(double s) {
    final p = _edge;
    p.strokeWidth = 3.0 * s; // thicker edge
    return p;
  }

  Paint _lineP(double s) {
    final p = _line;
    p.strokeWidth = 2.6 * s; // thicker inner lines
    return p;
  }

  Paint _dashP(double s) {
    final p = _dash;
    p.strokeWidth = 2.2 * s; // thicker dashed rulers
    return p;
  }

  // dashed line helpers (scaled)
  void _dashedH(
    Canvas c,
    double x1,
    double x2,
    double y, {
    required Paint p,
    double dash = 8,
    double gap = 5,
    double scale = 1.0,
  }) {
    double x = x1;
    final d = dash * scale;
    final g = gap * scale;
    while (x < x2) {
      final x2c = (x + d).clamp(x1, x2);
      c.drawLine(Offset(x, y), Offset(x2c.toDouble(), y), p);
      x += d + g;
    }
  }

  void _dashedV(
    Canvas c,
    double x,
    double y1,
    double y2, {
    required Paint p,
    double dash = 8,
    double gap = 5,
    double scale = 1.0,
  }) {
    double y = y1;
    final d = dash * scale;
    final g = gap * scale;
    while (y < y2) {
      final y2c = (y + d).clamp(y1, y2);
      c.drawLine(Offset(x, y), Offset(x, y2c.toDouble()), p);
      y += d + g;
    }
  }

  // arrows (scaled, use dashed paint)
  void _arrowUp(Canvas c, Offset p, Paint dashPaint, double s) {
    c.drawLine(p, p + Offset(-6 * s, 9 * s), dashPaint);
    c.drawLine(p, p + Offset(6 * s, 9 * s), dashPaint);
  }

  void _arrowDown(Canvas c, Offset p, Paint dashPaint, double s) {
    c.drawLine(p, p + Offset(-6 * s, -9 * s), dashPaint);
    c.drawLine(p, p + Offset(6 * s, -9 * s), dashPaint);
  }

  void _arrowLeft(Canvas c, Offset p, Paint dashPaint, double s) {
    c.drawLine(p, p + Offset(9 * s, -6 * s), dashPaint);
    c.drawLine(p, p + Offset(9 * s, 6 * s), dashPaint);
  }

  void _arrowRight(Canvas c, Offset p, Paint dashPaint, double s) {
    c.drawLine(p, p + Offset(-9 * s, -6 * s), dashPaint);
    c.drawLine(p, p + Offset(-9 * s, 6 * s), dashPaint);
  }

  RRect _bubbleAt(Offset center, TextPainter txt, double s) =>
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: txt.width + (24 * s), // wider bubble
          height: txt.height + (12 * s), // taller bubble
        ),
        Radius.circular(14 * s),
      );

  @override
  void paint(Canvas canvas, Size size) {
    // translucent veil
    canvas.drawRect(Offset.zero & size, Paint()..color = _veil);

    // scale (full-image coordinates)
    final sx = size.width / (data.imageW == 0 ? size.width : data.imageW);
    final sy = size.height / (data.imageH == 0 ? size.height : data.imageH);

    // Visual scaling for mobile clarity (baseline ~360px shortest side)
    final s = (size.shortestSide / 360.0).clamp(
      1.1,
      1.8,
    ); // bump slightly even on small screens

    // Pre-sized paints
    final edge = _edgeP(s);
    final line = _lineP(s);
    final dash = _dashP(s);

    // ================= VERTICAL =================
    if (mode == RatioMode.vertical) {
      if (data.verticalLines.isEmpty) return;

      final xs = <double>[];
      double top = 1e9, bot = -1e9;
      for (int i = 0; i < data.verticalLines.length; i++) {
        final l = data.verticalLines[i];
        final x = l.x1 * sx, y1 = l.y1 * sy, y2 = l.y2 * sy;
        xs.add(x);
        top = y1 < top ? y1 : top;
        bot = y2 > bot ? y2 : bot;
        canvas.drawLine(
          Offset(x, y1),
          Offset(x, y2),
          (i == 0 || i == data.verticalLines.length - 1) ? edge : line,
        );
      }
      xs.sort();

      final vals = (data.verticalPerc.length >= 5)
          ? data.verticalPerc.take(5).toList()
          : const [20, 20, 20, 20, 20];
      _pill(
        canvas,
        size,
        your: "Your ${vals.map((e) => '${e.toStringAsFixed(0)}%').join(' : ')}",
        golden: "Golden ${data.idealVertical}",
        scale: s,
      );

      final baseY = (bot - 12 * s).clamp(0, size.height).toDouble();
      for (int i = 0; i < 5 && i + 1 < xs.length; i++) {
        final left = xs[i], right = xs[i + 1];
        _dashedH(canvas, left + 8 * s, right - 8 * s, baseY, p: dash, scale: s);
        _arrowLeft(canvas, Offset(left + 8 * s, baseY), dash, s);
        _arrowRight(canvas, Offset(right - 8 * s, baseY), dash, s);

        final txt = _tp("${vals[i].toStringAsFixed(0)}%", fs: 12 * s);
        final rr = _bubbleAt(
          Offset((left + right) / 2, baseY + 16 * s),
          txt,
          s,
        );
        canvas.drawRRect(rr, _bubblePaint(rr));
        txt.paint(
          canvas,
          Offset(
            rr.outerRect.center.dx - txt.width / 2,
            rr.outerRect.center.dy - txt.height / 2,
          ),
        );
      }
      return;
    }

    // ================= HORIZONTAL =================
    if (mode == RatioMode.horizontal) {
      if (data.horizontalLines.isEmpty) return;

      final ys = data.horizontalLines.map((l) => l.y1 * sy).toList()..sort();
      if (ys.length < 4) return;
      final topY = ys.first, mid1Y = ys[1], mid2Y = ys[2], botY = ys.last;

      double leftBound, rightBound;
      if (data.faceBox != null) {
        leftBound = data.faceBox!.rect.left * sx;
        rightBound = data.faceBox!.rect.right * sx;
      } else if (data.verticalLines.length >= 2) {
        final xs = data.verticalLines.map((l) => l.x1 * sx).toList()..sort();
        leftBound = xs.first;
        rightBound = xs.last;
      } else {
        leftBound = size.width * .18;
        rightBound = size.width * .82;
      }

      final vals = (data.horizontalPerc.length >= 3)
          ? data.horizontalPerc.take(3).toList()
          : const [33, 33, 33];
      _pill(
        canvas,
        size,
        your:
            "Your Ratio ${vals.map((e) => '${e.toStringAsFixed(0)}%').join(' : ')}",
        golden: "Golden ${data.idealHorizontal}",
        scale: s,
      );

      void h(double y, bool isEdge) {
        canvas.drawLine(
          Offset(leftBound, y),
          Offset(rightBound, y),
          isEdge ? edge : line,
        );
      }

      h(topY, true);
      h(mid1Y, false);
      h(mid2Y, false);
      h(botY, true);

      final guideX = rightBound - 12 * s;
      _dashedV(canvas, guideX, topY + 2 * s, botY - 2 * s, p: dash, scale: s);
      _arrowUp(canvas, Offset(guideX, topY + 2 * s), dash, s);
      _arrowDown(canvas, Offset(guideX, botY - 2 * s), dash, s);

      final bands = <(double, double, num)>[
        (topY, mid1Y, vals[0]),
        (mid1Y, mid2Y, vals[1]),
        (mid2Y, botY, vals[2]),
      ];
      for (final (a, b, pct) in bands) {
        final cy = (a + b) / 2;
        final txt = _tp("${pct.toStringAsFixed(0)}%", fs: 12 * s);
        final rr = _bubbleAt(Offset(guideX + 24 * s, cy), txt, s);
        canvas.drawRRect(rr, _bubblePaint(rr));
        txt.paint(
          canvas,
          Offset(
            rr.outerRect.center.dx - txt.width / 2,
            rr.outerRect.center.dy - txt.height / 2,
          ),
        );
      }
      return;
    }

    // ================= EYES =================
    // ================= EYES =================
    if (mode == RatioMode.eyes) {
      final l = data.leftEye, r = data.rightEye;
      if (l == null && r == null) return;

      final overall = l?.measured.isNotEmpty == true
          ? l!.measured
          : (r?.measured ?? "");
      _pill(
        canvas,
        size,
        your: "Your Ratio 1 : $overall",
        golden: "Golden ${l?.golden ?? r?.golden ?? ''}",
        scale: s,
      );

      void eye(EyeBox e) {
        final rect = Rect.fromLTRB(
          e.rect.left * sx,
          e.rect.top * sy,
          e.rect.right * sx,
          e.rect.bottom * sy,
        );

        // Eye rectangle (crisp, not rounded)
        canvas.drawRect(rect, _softFill);
        canvas.drawRect(rect, _lineP(s));

        // Measure eye height to adapt the side ruler so it never looks like an X
        final h = rect.height;

        // How far left the side ruler sits; push it farther left for tiny eyes
        final sideInset = 12 * s + (h < 28 * s ? (28 * s - h) * .35 : 0);
        final leftX = rect.left - sideInset;

        // Vertical ruler length: clamp to a pleasant window so it doesn’t
        // collide with the eye box corners on short heights
        final vLen = (h - 10 * s).clamp(
          18 * s,
          42 * s,
        ); // min..max visible length
        final vTop = rect.center.dy - vLen / 2;
        final vBot = rect.center.dy + vLen / 2;

        // Shrink dash & arrow heads for small eyes
        final k = h < 28 * s ? 0.65 : 1.0; // scale factor for tiny heights
        final dashLen = (8 * s * k);
        final dashGap = (5 * s * k);

        // Local smaller arrowheads so they don't create an "X" look
        void _arrowUpSmall(Offset p) {
          canvas.drawLine(p, p + Offset(-6 * s * k, 8 * s * k), _dashP(s));
          canvas.drawLine(p, p + Offset(6 * s * k, 8 * s * k), _dashP(s));
        }

        void _arrowDownSmall(Offset p) {
          canvas.drawLine(p, p + Offset(-6 * s * k, -8 * s * k), _dashP(s));
          canvas.drawLine(p, p + Offset(6 * s * k, -8 * s * k), _dashP(s));
        }

        void _arrowLeftSmall(Offset p) {
          canvas.drawLine(p, p + Offset(9 * s * k, -6 * s * k), _dashP(s));
          canvas.drawLine(p, p + Offset(9 * s * k, 6 * s * k), _dashP(s));
        }

        void _arrowRightSmall(Offset p) {
          canvas.drawLine(p, p + Offset(-9 * s * k, -6 * s * k), _dashP(s));
          canvas.drawLine(p, p + Offset(-9 * s * k, 6 * s * k), _dashP(s));
        }

        // --- Horizontal dashed width ruler (below eye) ---
        final belowY = rect.bottom + 10 * s;
        _dashedH(
          canvas,
          rect.left,
          rect.right,
          belowY,
          p: _dashP(s),
          dash: dashLen,
          gap: dashGap,
          scale: 1,
        );
        _arrowLeftSmall(Offset(rect.left, belowY));
        _arrowRightSmall(Offset(rect.right, belowY));

        // --- Vertical dashed height ruler (left of eye), adapted to eye height ---
        _dashedV(
          canvas,
          leftX,
          vTop,
          vBot,
          p: _dashP(s),
          dash: dashLen,
          gap: dashGap,
          scale: 1,
        );
        _arrowUpSmall(Offset(leftX, vTop));
        _arrowDownSmall(Offset(leftX, vBot));

        // --- “1” bubble on the side ruler ---
        final oneTxt = _tp("1", fs: 11 * s);
        final oneRR = _bubbleAt(
          Offset(leftX - 16 * s, rect.center.dy),
          oneTxt,
          s,
        );
        canvas.drawRRect(oneRR, _bubblePaint(oneRR));
        oneTxt.paint(
          canvas,
          Offset(
            oneRR.outerRect.center.dx - oneTxt.width / 2,
            oneRR.outerRect.center.dy - oneTxt.height / 2,
          ),
        );

        // --- measured ratio bubble below the eye ---
        final ratioTxt = _tp(e.measured, fs: 13 * s);
        final ratioRR = _bubbleAt(
          Offset(rect.center.dx, belowY + 20 * s),
          ratioTxt,
          s,
        );
        canvas.drawRRect(ratioRR, _bubblePaint(ratioRR));
        ratioTxt.paint(
          canvas,
          Offset(
            ratioRR.outerRect.center.dx - ratioTxt.width / 2,
            ratioRR.outerRect.center.dy - ratioTxt.height / 2,
          ),
        );
      }

      if (l != null) eye(l);
      if (r != null) eye(r);
      return;
    }

    // ================= FACE BOX =================
    if (mode == RatioMode.faceBox) {
      final fb = data.faceBox;
      if (fb == null) return;

      final rect = Rect.fromLTRB(
        fb.rect.left * sx,
        fb.rect.top * sy,
        fb.rect.right * sx,
        fb.rect.bottom * sy,
      );
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(14 * s));
      canvas.drawRRect(rr, _softFill);
      canvas.drawRRect(rr, edge);

      double wVal = 1.0, hVal = 0.0;
      if (fb.yours.contains(':')) {
        final p = fb.yours.split(':');
        if (p.length >= 2) {
          wVal = double.tryParse(p[0].trim()) ?? 1.0;
          hVal = double.tryParse(p[1].trim()) ?? 0.0;
        }
      }

      _pill(
        canvas,
        size,
        your: "Your Ratio ${fb.yours}",
        golden: "Golden ${fb.golden}",
        scale: s,
      );

      // vertical ruler inside right edge
      final vx = rect.right - 10 * s;
      _dashedV(
        canvas,
        vx,
        rect.top + 14 * s,
        rect.bottom - 14 * s,
        p: dash,
        scale: s,
      );
      _arrowUp(canvas, Offset(vx, rect.top + 14 * s), dash, s);
      _arrowDown(canvas, Offset(vx, rect.bottom - 14 * s), dash, s);

      final vTxt = _tp(
        hVal == 0 ? fb.yours : hVal.toStringAsFixed(3),
        fs: 13 * s,
      );
      final vRR = _bubbleAt(Offset(vx - 34 * s, rect.center.dy), vTxt, s);
      canvas.drawRRect(vRR, _bubblePaint(vRR));
      vTxt.paint(
        canvas,
        Offset(
          vRR.outerRect.center.dx - vTxt.width / 2,
          vRR.outerRect.center.dy - vTxt.height / 2,
        ),
      );

      // bottom ruler
      final by = rect.bottom - 10 * s;
      _dashedH(
        canvas,
        rect.left + 14 * s,
        rect.right - 14 * s,
        by,
        p: dash,
        scale: s,
      );
      _arrowLeft(canvas, Offset(rect.left + 14 * s, by), dash, s);
      _arrowRight(canvas, Offset(rect.right - 14 * s, by), dash, s);

      final hTxt = _tp(wVal.toStringAsFixed(0), fs: 13 * s);
      final hRR = _bubbleAt(Offset(rect.center.dx, by + 20 * s), hTxt, s);
      canvas.drawRRect(hRR, _bubblePaint(hRR));
      hTxt.paint(
        canvas,
        Offset(
          hRR.outerRect.center.dx - hTxt.width / 2,
          hRR.outerRect.center.dy - hTxt.height / 2,
        ),
      );
      return;
    }

    // ================= NOSE–LIP–CHIN =================
    if (mode == RatioMode.noseLipChin) {
      if (data.noseLipChinLines.isEmpty) return;

      final ys = data.noseLipChinLines.map((l) => l.y1 * sy).toList()..sort();
      final top = ys.first, mid = ys[1], bot = ys.last;

      double leftBound, rightBound;
      if (data.faceBox != null) {
        leftBound = data.faceBox!.rect.left * sx;
        rightBound = data.faceBox!.rect.right * sx;
      } else if (data.verticalLines.length >= 2) {
        final xs = data.verticalLines.map((l) => l.x1 * sx).toList()..sort();
        leftBound = xs.first;
        rightBound = xs.last;
      } else {
        leftBound = size.width * .18;
        rightBound = size.width * .82;
      }

      _pill(
        canvas,
        size,
        your: "Your ${data.noseLipChinRatio ?? ''}",
        golden: "Golden ${data.noseLipChinIdeal ?? ''}",
        scale: s,
      );

      final leftFill = Rect.fromLTRB(
        leftBound,
        top,
        leftBound + (rightBound - leftBound) * .55,
        mid,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(leftFill, Radius.circular(8 * s)),
        _softFill,
      );

      for (final y in ys) {
        canvas.drawLine(
          Offset(leftBound, y),
          Offset(rightBound, y),
          (y == top || y == bot) ? edge : line,
        );
      }

      final guideX = rightBound - 12 * s;
      _dashedV(canvas, guideX, top + 2 * s, bot - 2 * s, p: dash, scale: s);
      _arrowUp(canvas, Offset(guideX, top + 2 * s), dash, s);
      _arrowDown(canvas, Offset(guideX, bot - 2 * s), dash, s);

      final tag = _tp("1", fs: 11 * s);
      final tagRR = _bubbleAt(
        Offset(guideX + 18 * s, top + (mid - top) * .15),
        tag,
        s,
      );
      canvas.drawRRect(tagRR, _bubblePaint(tagRR));
      tag.paint(
        canvas,
        Offset(
          tagRR.outerRect.center.dx - tag.width / 2,
          tagRR.outerRect.center.dy - tag.height / 2,
        ),
      );

      String valueOnly = (data.noseLipChinRatio ?? '').replaceFirst(
        RegExp(r'^\s*1\s*:\s*'),
        '',
      );
      if (valueOnly.isEmpty) valueOnly = (data.noseLipChinRatio ?? '');
      final t = _tp(valueOnly, fs: 12 * s);
      final rr = _bubbleAt(Offset(guideX + 12 * s, (mid + bot) / 2), t, s);
      canvas.drawRRect(rr, _bubblePaint(rr));
      t.paint(
        canvas,
        Offset(
          rr.outerRect.center.dx - t.width / 2,
          rr.outerRect.center.dy - t.height / 2,
        ),
      );
      return;
    }

    // ================= LIPS =================
    if (mode == RatioMode.lips) {
      if (data.lipLines.isEmpty) return;

      final lips = [...data.lipLines]..sort((a, b) => a.y1.compareTo(b.y1));
      for (int i = 0; i < lips.length; i++) {
        final l = lips[i];
        final y = l.y1 * sy, x1 = l.x1 * sx, x2 = l.x2 * sx;
        final p = (i == 1) ? edge : line;
        canvas.drawLine(Offset(x1, y), Offset(x2, y), p);
      }

      if (lips.length >= 3) {
        final top = lips.first, mid = lips[1], bot = lips.last;
        final rightMost = [
          top.x2 * sx,
          mid.x2 * sx,
          bot.x2 * sx,
        ].reduce((a, b) => a < b ? a : b);
        final rulerX = rightMost - 8 * s;
        final yTop = top.y1 * sy + 6 * s, yBot = bot.y1 * sy - 6 * s;

        _dashedV(
          canvas,
          rulerX,
          yTop,
          yBot,
          p: dash,
          dash: 6,
          gap: 4,
          scale: s,
        );
        _arrowUp(canvas, Offset(rulerX, yTop), dash, s);
        _arrowDown(canvas, Offset(rulerX, yBot), dash, s);

        final one = _tp("1", fs: 12 * s);
        final oneRR = _bubbleAt(
          Offset((top.x1 * sx + top.x2 * sx) / 2, mid.y1 * sy - 12 * s),
          one,
          s,
        );
        canvas.drawRRect(oneRR, _bubblePaint(oneRR));
        one.paint(
          canvas,
          Offset(
            oneRR.outerRect.center.dx - one.width / 2,
            oneRR.outerRect.center.dy - one.height / 2,
          ),
        );

        final ratio = _tp(data.lipRatio ?? "", fs: 12 * s);
        final ratioRR = _bubbleAt(
          Offset(rulerX + 30 * s, (yTop + yBot) / 2),
          ratio,
          s,
        );
        canvas.drawRRect(ratioRR, _bubblePaint(ratioRR));
        ratio.paint(
          canvas,
          Offset(
            ratioRR.outerRect.center.dx - ratio.width / 2,
            ratioRR.outerRect.center.dy - ratio.height / 2,
          ),
        );
      }

      _pill(
        canvas,
        size,
        your: "Your ${data.lipRatio ?? ''}",
        golden: "Golden ${data.lipIdeal ?? ''}",
        scale: s,
      );
      return;
    }

    // ================= JAW =================
    if (mode == RatioMode.jaw) {
      final j = data.jaw;
      if (j == null) return;

      Offset sc(Offset o) => Offset(o.dx * sx, o.dy * sy);
      final a = sc(j.leftJaw),
          b = sc(j.rightJaw),
          c = sc(j.chin),
          d = sc(j.noseBottom);

      // elegant lower-face curve (soft)
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo((a.dx + b.dx) / 2, c.dy - 14 * s, b.dx, b.dy)
        ..quadraticBezierTo((a.dx + b.dx) / 2, c.dy - 22 * s, a.dx, a.dy);
      canvas.drawPath(path, _softFill);
      canvas.drawPath(path, _lineP(s));

      // landmark dots (slightly larger)
      void dot(Offset p) =>
          canvas.drawCircle(p, 3.2 * s, Paint()..color = _plum);
      dot(a);
      dot(b);
      dot(c);
      dot(d);

      // jaw width (↔) a bit above jaw line
      final yJaw = (a.dy + b.dy) / 2 - 10 * s;
      _dashedH(canvas, a.dx + 8 * s, b.dx - 8 * s, yJaw, p: dash, scale: s);
      _arrowLeft(canvas, Offset(a.dx + 8 * s, yJaw), dash, s);
      _arrowRight(canvas, Offset(b.dx - 8 * s, yJaw), dash, s);

      // nose-bottom → chin (↕)
      final xMid = (a.dx + b.dx) / 2, yTop = d.dy + 8 * s, yBot = c.dy - 8 * s;
      _dashedV(canvas, xMid, yTop, yBot, p: dash, scale: s);
      _arrowUp(canvas, Offset(xMid, yTop), dash, s);
      _arrowDown(canvas, Offset(xMid, yBot), dash, s);

      _pill(
        canvas,
        size,
        your: "Your ${j.ratio.toStringAsFixed(3)}",
        golden: "Golden ${j.ideal.toStringAsFixed(3)}",
        scale: s,
      );

      // width bubble "1"
      final wTxt = _tp("1", fs: 13 * s);
      final wRR = _bubbleAt(Offset((a.dx + b.dx) / 2, yJaw - 14 * s), wTxt, s);
      canvas.drawRRect(wRR, _bubblePaint(wRR));
      wTxt.paint(
        canvas,
        Offset(
          wRR.outerRect.center.dx - wTxt.width / 2,
          wRR.outerRect.center.dy - wTxt.height / 2,
        ),
      );

      // height bubble (ratio)
      final hTxt = _tp(j.ratio.toStringAsFixed(3), fs: 13 * s);
      final hRR = _bubbleAt(Offset(xMid + 38 * s, (yTop + yBot) / 2), hTxt, s);
      canvas.drawRRect(hRR, _bubblePaint(hRR));
      hTxt.paint(
        canvas,
        Offset(
          hRR.outerRect.center.dx - hTxt.width / 2,
          hRR.outerRect.center.dy - hTxt.height / 2,
        ),
      );
      return;
    }
  }

  @override
  bool shouldRepaint(covariant PrettyRatioPainter old) =>
      old.data != data || old.mode != mode;
}
