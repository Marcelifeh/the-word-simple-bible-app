import 'package:flutter/material.dart';

class HomeTextScale extends StatelessWidget {
  const HomeTextScale({
    super.key,
    required this.scale,
    required this.child,
  });

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale.clamp(0.90, 1.12)),
      ),
      child: child,
    );
  }
}
