import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fixburgh/features/report/domain/report.dart';
import 'package:flutter/material.dart';

/// Map marker shapes, one per category, so color is never the only cue
/// (BRD FR-MAP-02, section 11.5).
enum MarkerShape {
  circle,
  triangle,
  drop,
  square,
  diamond,
  hexagon,
  roundedSquare,
  star,
}

extension ReportCategoryStyle on ReportCategory {
  /// Marker colors from BRD section 11.5. Each passes 3:1 against white
  /// (non-text contrast) behind the white icon.
  Color get color => switch (this) {
    ReportCategory.pothole => const Color(0xFFB4530E),
    ReportCategory.landslide => const Color(0xFF8B5A2B),
    ReportCategory.flooding => const Color(0xFF2B6CB0),
    ReportCategory.streetlight => const Color(0xFFB7791F),
    ReportCategory.dumping => const Color(0xFF6B46C1),
    ReportCategory.fallenTree => const Color(0xFF2F855A),
    ReportCategory.sidewalk => const Color(0xFF1B4F86),
    ReportCategory.other => const Color(0xFF4A5568),
  };

  MarkerShape get shape => switch (this) {
    ReportCategory.pothole => MarkerShape.circle,
    ReportCategory.landslide => MarkerShape.triangle,
    ReportCategory.flooding => MarkerShape.drop,
    ReportCategory.streetlight => MarkerShape.square,
    ReportCategory.dumping => MarkerShape.diamond,
    ReportCategory.fallenTree => MarkerShape.hexagon,
    ReportCategory.sidewalk => MarkerShape.roundedSquare,
    ReportCategory.other => MarkerShape.star,
  };
}

/// Draws a category marker: colored shape, white outline, white icon, and
/// a red "!" badge for urgent reports. Used for map pins and the legend.
class CategoryMarkerPainter extends CustomPainter {
  const CategoryMarkerPainter(this.category, {this.urgent = false});

  final ReportCategory category;
  final bool urgent;

  static const urgentColor = Color(0xFFC53030);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    // Leave room for the outline and the urgent badge.
    final body = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: s * 0.78,
      height: s * 0.78,
    );
    final path = shapePath(category.shape, body);
    canvas
      ..drawShadow(path, Colors.black, s * 0.04, false)
      ..drawPath(path, Paint()..color = category.color)
      ..drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.06
          ..strokeJoin = StrokeJoin.round,
      );

    final icon = category.icon;
    final iconCenter = category.shape == MarkerShape.triangle
        ? body.center.translate(0, body.height * 0.12)
        : category.shape == MarkerShape.drop
        ? body.center.translate(0, body.height * 0.08)
        : body.center;
    final text = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: s * (category.shape == MarkerShape.triangle ? 0.3 : 0.4),
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(
      canvas,
      iconCenter - Offset(text.width / 2, text.height / 2),
    );

    if (urgent) {
      final c = Offset(size.width - s * 0.17, s * 0.17);
      canvas
        ..drawCircle(c, s * 0.16, Paint()..color = Colors.white)
        ..drawCircle(c, s * 0.12, Paint()..color = urgentColor);
      final bang = TextPainter(
        text: TextSpan(
          text: '!',
          style: TextStyle(
            fontSize: s * 0.18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      bang.paint(canvas, c - Offset(bang.width / 2, bang.height / 2));
    }
  }

  @override
  bool shouldRepaint(CategoryMarkerPainter old) =>
      old.category != category || old.urgent != urgent;

  /// The outline of [shape] filling [r].
  static Path shapePath(MarkerShape shape, Rect r) {
    final c = r.center;
    final h = r.width / 2;
    Path polygon(int sides, {double start = -math.pi / 2, double? inner}) {
      final p = Path();
      final n = inner == null ? sides : sides * 2;
      for (var i = 0; i < n; i++) {
        final radius = inner != null && i.isOdd ? inner : h;
        final a = start + i * 2 * math.pi / n;
        final pt = c + Offset(math.cos(a), math.sin(a)) * radius;
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p..close();
    }

    return switch (shape) {
      MarkerShape.circle => Path()..addOval(r),
      MarkerShape.triangle =>
        Path()
          ..moveTo(c.dx, r.top)
          ..lineTo(r.right, r.bottom - h * 0.1)
          ..lineTo(r.left, r.bottom - h * 0.1)
          ..close(),
      MarkerShape.drop =>
        Path()
          ..moveTo(c.dx, r.top)
          ..cubicTo(
            c.dx + h * 0.35,
            r.top + h * 0.45,
            r.right,
            c.dy,
            r.right,
            c.dy + h * 0.3,
          )
          ..arcToPoint(
            Offset(r.left, c.dy + h * 0.3),
            radius: Radius.circular(h),
          )
          ..cubicTo(
            r.left,
            c.dy,
            c.dx - h * 0.35,
            r.top + h * 0.45,
            c.dx,
            r.top,
          )
          ..close(),
      MarkerShape.square => Path()..addRect(r.deflate(h * 0.12)),
      MarkerShape.diamond => polygon(4),
      MarkerShape.hexagon => polygon(6, start: 0),
      MarkerShape.roundedSquare =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            r.deflate(h * 0.08),
            Radius.circular(h / 2.2),
          ),
        ),
      MarkerShape.star => polygon(5, inner: h * 0.5),
    };
  }
}

/// Renders a marker to PNG bytes at [pixelRatio] for a map pin.
Future<ui.Image> renderMarker(
  ReportCategory category, {
  required bool urgent,
  required double logicalSize,
  required double pixelRatio,
}) async {
  final px = (logicalSize * pixelRatio).ceilToDouble();
  final recorder = ui.PictureRecorder();
  CategoryMarkerPainter(
    category,
    urgent: urgent,
  ).paint(Canvas(recorder), Size.square(px));
  return recorder.endRecording().toImage(px.toInt(), px.toInt());
}
