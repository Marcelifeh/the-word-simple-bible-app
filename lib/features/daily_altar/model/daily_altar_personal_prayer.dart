/// A prayer personally written or edited by the user.
///
/// This is distinct from the app-provided DailyAltarPrayerPrompt.
class DailyAltarPersonalPrayer {
  const DailyAltarPersonalPrayer({
    required this.text,
  });

  final String text;

  bool get isEmpty => text.trim().isEmpty;
}
