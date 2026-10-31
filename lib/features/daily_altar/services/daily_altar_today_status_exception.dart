class DailyAltarTodayStatusException implements Exception {
  const DailyAltarTodayStatusException(
    this.message, [
    this.cause,
  ]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'DailyAltarTodayStatusException: $message';
    }

    return 'DailyAltarTodayStatusException: $message ($cause)';
  }
}
