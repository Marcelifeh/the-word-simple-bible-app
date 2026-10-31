class DailyAltarContentNotFoundException implements Exception {
  const DailyAltarContentNotFoundException(this.contentId);

  final String contentId;

  @override
  String toString() {
    return 'DailyAltarContentNotFoundException: $contentId';
  }
}
