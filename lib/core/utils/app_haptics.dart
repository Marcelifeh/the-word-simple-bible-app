import 'package:flutter/services.dart';

class AppHaptics {
  const AppHaptics._();

  static Future<void> noteSaved() => HapticFeedback.lightImpact();

  static Future<void> favoriteToggled() => HapticFeedback.selectionClick();

  static Future<void> shareTriggered() => HapticFeedback.lightImpact();
}
