import '../../../data/bible/book_catalog.dart';
import '../../../domain/entities/book.dart';
import '../model/sermon_note.dart';

class ResolvedScriptureMatch {
  const ResolvedScriptureMatch({
    required this.scripture,
    required this.start,
    required this.end,
  });

  final LinkedScripture scripture;
  final int start;
  final int end;
}

class ScriptureParser {
  /// Regular expression to match standard Bible chapter references
  /// For example:
  /// - John 3
  /// - 1 John 3
  /// - 1 Corinthians 13
  /// - Song of Solomon 2
  static final RegExp versePattern = RegExp(
    r'\b((?:1\s|2\s|3\s)?[A-Za-z]+(?:\s[A-Za-z]+)?)\s(\d+)(?::(\d+)(?:-(\d+))?)?\b',
    caseSensitive: false,
  );

  static List<ResolvedScriptureMatch> findMatches(String text) {
    if (text.isEmpty) return const [];

    final results = <ResolvedScriptureMatch>[];

    for (final match in versePattern.allMatches(text)) {
      final bookPhrase = match.group(1)?.trim();
      final chapterStr = match.group(2);
      final verseStartStr = match.group(3);
      final verseEndStr = match.group(4);

      if (bookPhrase == null || chapterStr == null) {
        continue;
      }

      final chapter = int.tryParse(chapterStr);
      final startVerse =
          verseStartStr == null ? null : int.tryParse(verseStartStr);
      final endVerse = verseEndStr == null ? null : int.tryParse(verseEndStr);
      if (chapter == null) {
        continue;
      }

      final catalogBook = _findBookLazy(bookPhrase);
      if (catalogBook == null) {
        continue;
      }

      results.add(
        ResolvedScriptureMatch(
          scripture: LinkedScripture(
            rawText: match.group(0) ?? '',
            matchText: '${catalogBook.name} $chapter',
            bookId: catalogBook.id,
            chapter: chapter,
            startVerse: startVerse,
            endVerse: endVerse,
          ),
          start: match.start,
          end: match.end,
        ),
      );
    }

    return results;
  }

  /// Scan a string and extract all scriptures parsed with proper context
  static List<LinkedScripture> extractScriptures(String text) {
    return _deduplicate(
      findMatches(text).map((match) => match.scripture).toList(),
    );
  }

  static Book? _findBookLazy(String query) {
    String q = query.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    for (var book in BookCatalog.books) {
      String bName = book.name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      if (bName == q ||
          bName.startsWith(q) ||
          (bName.length > 3 && q.startsWith(bName.substring(0, 3)))) {
        return book;
      }
    }
    return null;
  }

  static List<LinkedScripture> _deduplicate(List<LinkedScripture> items) {
    final seen = <String>{};
    return items.where((element) {
      final key = '${element.bookId}-${element.chapter}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }
}
