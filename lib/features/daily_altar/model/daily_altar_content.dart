import 'daily_altar_evening_reflection.dart';
import 'daily_altar_obedience_step.dart';
import 'daily_altar_prayer_prompt.dart';
import 'daily_altar_reflection_prompts.dart';
import 'daily_altar_scripture.dart';
import 'daily_altar_understanding.dart';

/// Complete spiritual-content contract for one My Daily Altar encounter.
///
/// This object contains content supplied by the app. User-authored responses
/// belong to a separate response/session model in a later phase.
class DailyAltarContent {
  const DailyAltarContent({
    required this.id,
    required this.scripture,
    required this.understanding,
    required this.reflection,
    required this.prayer,
    required this.obedience,
    required this.carryWord,
    required this.eveningReflection,
  });

  final String id;

  /// Primary Scripture passage for Receive the Word.
  final DailyAltarScripture scripture;

  /// Explanation used by Understand the Word.
  final DailyAltarUnderstanding understanding;

  /// Questions used by Abide.
  final DailyAltarReflectionPrompts reflection;

  /// Suggested prayer used by Pray the Word.
  final DailyAltarPrayerPrompt prayer;

  /// Suggested application used by Walk in the Word.
  final DailyAltarObedienceStep obedience;

  /// Scripture verse or excerpt intentionally carried through the day.
  ///
  /// It remains typed as Scripture rather than explanatory content.
  final DailyAltarScripture carryWord;

  /// Prompts used during Return to the Altar.
  final DailyAltarEveningReflection eveningReflection;
}
