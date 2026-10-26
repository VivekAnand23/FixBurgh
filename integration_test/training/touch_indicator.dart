import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Draws a soft circle where each tap lands, so a screen recording shows
/// what the viewer would touch. Used only by the training walkthrough.
class TouchIndicator extends StatefulWidget {
  const TouchIndicator({required this.child, super.key});

  final Widget child;

  @override
  State<TouchIndicator> createState() => _TouchIndicatorState();
}

class _TouchIndicatorState extends State<TouchIndicator>
    with SingleTickerProviderStateMixin {
  final _taps = <({Offset at, DateTime when})>[];
  late final Ticker _ticker = createTicker(_tick);

  void _tick(Duration _) {
    final now = DateTime.now();
    _taps.removeWhere((t) => now.difference(t.when) > _life);
    setState(() {});
    if (_taps.isEmpty) _ticker.stop();
  }

  static const _life = Duration(milliseconds: 900);

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      _taps.add((at: e.position, when: DateTime.now()));
      if (!_ticker.isActive) _ticker.start();
    },
    child: Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _TapPainter(List.of(_taps))),
          ),
        ),
      ],
    ),
  );
}

class _TapPainter extends CustomPainter {
  _TapPainter(this.taps);

  final List<({Offset at, DateTime when})> taps;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    for (final t in taps) {
      final p = (now.difference(t.when).inMilliseconds / 900).clamp(0.0, 1.0);
      final fade = 1 - p;
      canvas
        ..drawCircle(
          t.at,
          22 + 18 * p,
          Paint()
            ..color = const Color(0xFF1B4F86).withValues(alpha: 0.28 * fade),
        )
        ..drawCircle(
          t.at,
          22 + 18 * p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white.withValues(alpha: 0.9 * fade),
        );
    }
  }

  @override
  bool shouldRepaint(_TapPainter old) => true;
}
