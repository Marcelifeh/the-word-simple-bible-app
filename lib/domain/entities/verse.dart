import 'verse_ref.dart';

class Verse {
  const Verse({
    required this.ref,
    required this.book,
    required this.text,
    this.isFallback = false,
  });

  final VerseRef ref;
  final String book;
  final String text;
  final bool isFallback;

  static Verse fromJson(Map<String, dynamic> json) {
    final bookId =
        ((json['bookId'] ?? json['book_id'] ?? '') as String).toLowerCase();
    return Verse(
      ref: VerseRef(
        bookId: bookId,
        chapter: (json['chapter'] as num).toInt(),
        verse: (json['verse'] as num).toInt(),
      ),
      book: (json['book'] as String? ?? bookId),
      text: (json['text'] as String? ?? ''),
    );
  }
}
