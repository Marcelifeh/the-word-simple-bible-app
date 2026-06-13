import 'package:flutter/material.dart';

class DevotionalWaveform extends StatefulWidget {
  final bool isPlaying;

  const DevotionalWaveform({super.key, this.isPlaying = true});

  @override
  State<DevotionalWaveform> createState() => _DevotionalWaveformState();
}

class _DevotionalWaveformState extends State<DevotionalWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DevotionalWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final t = _animation.value; // 0.0 → 1.0 → 0.0

        return IgnorePointer(
          child: CustomPaint(
            painter: _OrbPainter(t),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t; // 0.0..1.0 breathing phase

  const _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR   = size.shortestSide * 0.45; // max radius

    // Three rings, each breathing at slightly different phase
    _drawRing(canvas, center, maxR * (0.4 + t * 0.35), 0.06 + t * 0.04);
    _drawRing(canvas, center, maxR * (0.65 + t * 0.20), 0.035 + t * 0.025);
    _drawRing(canvas, center, maxR * (0.85 + t * 0.10), 0.018 + t * 0.012);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
