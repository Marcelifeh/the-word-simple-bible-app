import 'package:flutter/material.dart';

class AnimatedStaggerItem extends StatelessWidget {
  const AnimatedStaggerItem({
    super.key,
    required this.child,
    required this.index,
  });

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delay = index * 70;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 450 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 24, end: 0),
      builder: (context, value, childWidget) {
        final opacity = (1 - (value / 24)).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: opacity,
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}
