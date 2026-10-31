/// Stable metadata describing the My Daily Altar module.
///
/// Keeping feature identity separate from UI makes it reusable later by
/// navigation, entitlements, analytics-free diagnostics, and tests.
abstract final class DailyAltarFeature {
  static const String id = 'my_daily_altar';
  static const String title = 'My Daily Altar';

  static const String subtitle =
      'Meet God in His Word. Carry His truth into your day.';
}
