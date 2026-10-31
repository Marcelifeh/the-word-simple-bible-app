import 'daily_altar_support_origin.dart';

/// The three core reflection prompts used during the Abide stage.
///
/// They deliberately keep Scripture at the center:
/// 1. What does the passage reveal about God?
/// 2. What does it expose or correct in me?
/// 3. What response does the passage call for?
class DailyAltarReflectionPrompts {
  const DailyAltarReflectionPrompts({
    required this.aboutGod,
    required this.aboutMe,
    required this.response,
    required this.origin,
  });

  final String aboutGod;
  final String aboutMe;
  final String response;
  final DailyAltarSupportOrigin origin;
}
