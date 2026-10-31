class DailyAltarTransitionException implements Exception {
  const DailyAltarTransitionException(this.message);

  final String message;

  @override
  String toString() => 'DailyAltarTransitionException: $message';
}
