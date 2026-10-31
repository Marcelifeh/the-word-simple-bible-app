class DailyAltarContentValidationException implements Exception {
  const DailyAltarContentValidationException(this.errors);

  final List<String> errors;

  @override
  String toString() {
    return 'DailyAltarContentValidationException: ${errors.join('; ')}';
  }
}
