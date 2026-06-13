import '../../domain/entities/book.dart';
import 'book_catalog.dart';

class BookLookup {
  static Book? tryResolve(String input) {
    final n = _normalize(input);
    if (n.isEmpty) return null;

    final synonym = _synonyms[n];
    if (synonym != null) {
      return BookCatalog.books.firstWhere((b) => b.id == synonym);
    }

    // Exact by normalized name
    for (final b in BookCatalog.books) {
      if (_normalize(b.name) == n) return b;
    }

    // Prefix match ("rom" -> Romans)
    final matches = <Book>[];
    for (final b in BookCatalog.books) {
      final bn = _normalize(b.name);
      if (bn.startsWith(n)) matches.add(b);
    }

    if (matches.length == 1) return matches.single;
    return null;
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const Map<String, String> _synonyms = {
    // Psalms
    'psalm': 'psalms',
    'psalms': 'psalms',
    'ps': 'psalms',

    // John
    'jn': 'john',
    'jhn': 'john',

    // Romans
    'rom': 'romans',
    'rm': 'romans',

    // Common shorthand
    'rev': 'revelation',
    'song of solomon': 'song_of_songs',
    'song of songs': 'song_of_songs',
    'canticles': 'song_of_songs',
  };
}
