class DailyAltarResponseValidationException implements Exception {
  const DailyAltarResponseValidationException(this.errors);

  final List<String> errors;

  @override
  String toString() {
    return 'DailyAltarResponseValidationException: ${errors.join('; ')}';
  }
}
