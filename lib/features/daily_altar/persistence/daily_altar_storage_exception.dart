class DailyAltarStorageException implements Exception {
  const DailyAltarStorageException(
    this.message, [
    this.cause,
  ]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'DailyAltarStorageException: $message';
    }

    return 'DailyAltarStorageException: $message ($cause)';
  }
}
