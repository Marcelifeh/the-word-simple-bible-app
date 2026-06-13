import '../bible/book_lookup.dart';
import '../../domain/entities/verse_ref.dart';
import 'search_query.dart';

class SearchQueryParser {
  const SearchQueryParser();

  SearchQuery parse(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return const KeywordQuery('');

    // Examples:
    // - "Romans 8"
    // - "Psalm 23:1"
    // - "John 3:16"
    final normalized = _collapseWhitespace(raw);

    final verseMatch =
        RegExp(r'^(.+?)\s+(\d+)\s*:\s*(\d+)$').firstMatch(normalized);
    if (verseMatch != null) {
      final bookPart = verseMatch.group(1)!.trim();
      final chapter = int.tryParse(verseMatch.group(2)!);
      final verse = int.tryParse(verseMatch.group(3)!);
      if (chapter != null && verse != null) {
        final book = BookLookup.tryResolve(bookPart);
        if (book != null) {
          return VerseQuery(
              ref: VerseRef(bookId: book.id, chapter: chapter, verse: verse),
              bookName: book.name);
        }
      }
    }

    final chapterMatch = RegExp(r'^(.+?)\s+(\d+)$').firstMatch(normalized);
    if (chapterMatch != null) {
      final bookPart = chapterMatch.group(1)!.trim();
      final chapter = int.tryParse(chapterMatch.group(2)!);
      if (chapter != null) {
        final book = BookLookup.tryResolve(bookPart);
        if (book != null) {
          return ChapterQuery(
              bookId: book.id, chapter: chapter, bookName: book.name);
        }
      }
    }

    // Book-only queries like "Romans" (optional): interpret as keyword to keep it simple.
    // You can later change this to open chapter picker.
    if (BookLookup.tryResolve(normalized) != null) {
      return KeywordQuery(normalized);
    }

    return KeywordQuery(raw);
  }

  String _collapseWhitespace(String s) => s.replaceAll(RegExp(r'\s+'), ' ');
}
