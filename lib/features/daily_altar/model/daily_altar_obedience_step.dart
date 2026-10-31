import 'daily_altar_support_origin.dart';

/// A concrete, proportionate application of the day's Scripture.
///
/// This is presented as a suggested act of obedience/application rather than
/// as a new command from God.
class DailyAltarObedienceStep {
  const DailyAltarObedienceStep({
    required this.text,
    required this.origin,
  });

  final String text;
  final DailyAltarSupportOrigin origin;
}
