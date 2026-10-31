import 'daily_altar_support_origin.dart';

/// A suggested Scripture-shaped prayer.
///
/// The wording is a prayer aid, not Scripture and not a claim that God is
/// speaking directly to the user.
class DailyAltarPrayerPrompt {
  const DailyAltarPrayerPrompt({
    required this.text,
    required this.origin,
  });

  final String text;
  final DailyAltarSupportOrigin origin;
}
