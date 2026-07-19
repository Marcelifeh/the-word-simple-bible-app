import '../../data/bible/book_catalog.dart';
import '../../domain/entities/book.dart';

class ScriptureReferenceRange {
  const ScriptureReferenceRange({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
  });

  final String bookId;
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;

  bool get isSingleVerse => startVerse == endVerse;

  String get label {
    final verses = isSingleVerse ? '$startVerse' : '$startVerse-$endVerse';
    return '$bookName $chapter:$verses';
  }
}

class ScriptureReferenceParser {
  const ScriptureReferenceParser();

  ScriptureReferenceRange? tryParse(String input) {
    final normalized = input
        .trim()
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'\s+'), ' ');
    final match = RegExp(
      r'^(.+?)\s+(\d+):(\d+)(?:\s*-\s*(\d+))?$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (match == null) return null;

    final requestedBook = _normalizeBook(match.group(1)!);
    Book? book;
    for (final candidate in BookCatalog.books) {
      final name = _normalizeBook(candidate.name);
      final id = _normalizeBook(candidate.id.replaceAll('_', ' '));
      if (requestedBook == name ||
          requestedBook == id ||
          (requestedBook == 'psalm' && name == 'psalms') ||
          (requestedBook == 'song of solomon' && name == 'song of songs')) {
        book = candidate;
        break;
      }
    }
    if (book == null) return null;

    final chapter = int.tryParse(match.group(2)!);
    final start = int.tryParse(match.group(3)!);
    final end = int.tryParse(match.group(4) ?? match.group(3)!);
    if (chapter == null ||
        start == null ||
        end == null ||
        chapter < 1 ||
        start < 1 ||
        end < 1) {
      return null;
    }
    return ScriptureReferenceRange(
      bookId: book.id,
      bookName: book.name,
      chapter: chapter,
      startVerse: start <= end ? start : end,
      endVerse: start <= end ? end : start,
    );
  }

  static String _normalizeBook(String value) {
    return value
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
