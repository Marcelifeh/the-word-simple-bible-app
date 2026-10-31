import 'daily_altar_support_origin.dart';

/// Prompts used when the believer returns to the Daily Altar in the evening.
class DailyAltarEveningReflection {
  const DailyAltarEveningReflection({
    required this.rememberedWordPrompt,
    required this.obediencePrompt,
    required this.relevancePrompt,
    required this.heartResponsePrompt,
    required this.carryForwardPrompt,
    required this.origin,
  });

  final String rememberedWordPrompt;
  final String obediencePrompt;
  final String relevancePrompt;
  final String heartResponsePrompt;
  final String carryForwardPrompt;
  final DailyAltarSupportOrigin origin;
}
