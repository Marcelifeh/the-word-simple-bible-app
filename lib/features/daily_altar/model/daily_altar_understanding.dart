import 'daily_altar_support_origin.dart';

/// Concise explanatory material accompanying the Scripture passage.
///
/// These fields interpret or illuminate Scripture but are never Scripture.
class DailyAltarUnderstanding {
  const DailyAltarUnderstanding({
    required this.context,
    required this.centralTruth,
    required this.lookAgain,
    required this.origin,
  });

  final String context;
  final String centralTruth;
  final String lookAgain;
  final DailyAltarSupportOrigin origin;
}
