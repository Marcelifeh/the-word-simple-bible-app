import 'package:flutter/material.dart';

/// Helper to apply an opacity value to a [Color] without using the
/// deprecated `withOpacity` API. The [opacity] should be between 0.0 and 1.0.
Color applyOpacity(Color base, double opacity) {
  final clamped = opacity.clamp(0.0, 1.0);
  final alpha = (clamped * 255).round();
  return base.withAlpha(alpha);
}
