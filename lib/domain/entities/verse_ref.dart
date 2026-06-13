class VerseRef {
  const VerseRef(
      {required this.bookId, required this.chapter, required this.verse});

  final String bookId;
  final int chapter;
  final int verse;

  String get key => '$bookId.$chapter.$verse';

  /// Stable hyphenated ID for cross-language commentary linking.
  /// e.g. "genesis-1-1", "john-3-16"
  String get canonicalId => '$bookId-$chapter-$verse';

  @override
  bool operator ==(Object other) {
    return other is VerseRef &&
        other.bookId == bookId &&
        other.chapter == chapter &&
        other.verse == verse;
  }

  @override
  int get hashCode => Object.hash(bookId, chapter, verse);
}
