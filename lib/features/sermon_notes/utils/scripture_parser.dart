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
  static final List<_BookAlias> _bookAliases = _buildBookAliases();
  static final String _bookPattern =
      _bookAliases.map((alias) => _aliasPattern(alias.value)).join('|');

  static final RegExp _numericPattern = RegExp(
    r'\b(' +
        _bookPattern +
        r')\s+(?:(?:chapter|chap\.?|ch\.?)\s*)?(\d{1,3})(?:\s*(?::|\.|,)?\s*(?:(?:verse|verses|v\.?)\s*)?(\d{1,3})(?:\s*(?:-|through|to)\s*(\d{1,3}))?)?\b',
    caseSensitive: false,
  );

  static final RegExp _spokenExplicitPattern = RegExp(
    r'\b(' +
        _bookPattern +
        r')\s+(?:(?:chapter|chap\.?|ch\.?)\s+)?(' +
        _numberWordPattern +
        r')(?:\s+(?:verse|verses|v\.?)\s+(' +
        _numberWordPattern +
        r')(?:\s+(?:-|through|to)\s+(' +
        _numberWordPattern +
        r'))?)?\b',
    caseSensitive: false,
  );

  static final RegExp _spokenCompactPattern = RegExp(
    r'\b(' +
        _bookPattern +
        r')\s+(' +
        _singleDigitWordPattern +
        r')\s+(' +
        _numberWordPattern +
        r')\b',
    caseSensitive: false,
  );

  /// Scan a string and return resolved scripture matches with text offsets.
  static List<ResolvedScriptureMatch> findMatches(String text) {
    if (text.trim().isEmpty) return const [];

    final results = <ResolvedScriptureMatch>[];
    _collectNumericMatches(text, results);
    _collectSpokenExplicitMatches(text, results);
    _collectSpokenCompactMatches(text, results);

    results.sort((a, b) => a.start.compareTo(b.start));
    return _deduplicateMatches(results);
  }

  /// Scan a string and extract all scriptures parsed with proper context.
  static List<LinkedScripture> extractScriptures(String text) {
    return findMatches(text).map((match) => match.scripture).toList();
  }

  /// Returns the match containing [offset], using Dart's standard half-open
  /// range convention: start is inclusive and end is exclusive.
  static ResolvedScriptureMatch? matchAtOffset(
    Iterable<ResolvedScriptureMatch> matches,
    int offset,
  ) {
    for (final match in matches) {
      if (offset >= match.start && offset < match.end) return match;
    }
    return null;
  }

  static void _collectNumericMatches(
    String text,
    List<ResolvedScriptureMatch> results,
  ) {
    for (final match in _numericPattern.allMatches(text)) {
      final chapter = int.tryParse(match.group(2) ?? '');
      final startVerse = int.tryParse(match.group(3) ?? '');
      final endVerse = int.tryParse(match.group(4) ?? '');
      _addMatch(
        results,
        rawText: match.group(0) ?? '',
        bookPhrase: match.group(1),
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
        start: match.start,
        end: match.end,
      );
    }
  }

  static void _collectSpokenExplicitMatches(
    String text,
    List<ResolvedScriptureMatch> results,
  ) {
    for (final match in _spokenExplicitPattern.allMatches(text)) {
      _addMatch(
        results,
        rawText: match.group(0) ?? '',
        bookPhrase: match.group(1),
        chapter: _parseSpokenNumber(match.group(2)),
        startVerse: _parseSpokenNumber(match.group(3)),
        endVerse: _parseSpokenNumber(match.group(4)),
        start: match.start,
        end: match.end,
      );
    }
  }

  static void _collectSpokenCompactMatches(
    String text,
    List<ResolvedScriptureMatch> results,
  ) {
    for (final match in _spokenCompactPattern.allMatches(text)) {
      _addMatch(
        results,
        rawText: match.group(0) ?? '',
        bookPhrase: match.group(1),
        chapter: _parseSpokenNumber(match.group(2)),
        startVerse: _parseSpokenNumber(match.group(3)),
        endVerse: null,
        start: match.start,
        end: match.end,
      );
    }
  }

  static void _addMatch(
    List<ResolvedScriptureMatch> results, {
    required String rawText,
    required String? bookPhrase,
    required int? chapter,
    required int? startVerse,
    required int? endVerse,
    required int start,
    required int end,
  }) {
    if (bookPhrase == null || chapter == null || chapter <= 0) return;

    final catalogBook = _findBook(bookPhrase);
    if (catalogBook == null || chapter > catalogBook.chapterCount) return;
    if (startVerse != null && startVerse <= 0) return;
    if (endVerse != null && endVerse <= 0) return;

    results.add(
      ResolvedScriptureMatch(
        scripture: LinkedScripture(
          rawText: rawText,
          matchText: '${catalogBook.name} $chapter',
          bookId: catalogBook.id,
          chapter: chapter,
          startVerse: startVerse,
          endVerse: endVerse,
        ),
        start: start,
        end: end,
      ),
    );
  }

  static Book? _findBook(String query) {
    final normalized = _normalizeAlias(query);
    for (final alias in _bookAliases) {
      if (_normalizeAlias(alias.value) == normalized) {
        return alias.book;
      }
    }
    return _findBookLazy(query);
  }

  static Book? _findBookLazy(String query) {
    final normalized = _normalizeAlias(query);
    final words =
        normalized.split(' ').where((word) => word.isNotEmpty).toList();

    for (var index = 0; index < words.length; index++) {
      final suffix = words.sublist(index).join(' ');
      for (final alias in _bookAliases) {
        if (_normalizeAlias(alias.value) == suffix) {
          return alias.book;
        }
      }
    }

    final compact = normalized.replaceAll(' ', '');
    for (final book in BookCatalog.books) {
      final bookName = _normalizeAlias(book.name).replaceAll(' ', '');
      if (bookName == compact ||
          bookName.startsWith(compact) ||
          (bookName.length > 3 &&
              compact.startsWith(bookName.substring(0, 3)))) {
        return book;
      }
    }
    return null;
  }

  static int? _parseSpokenNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final tokens = value
        .toLowerCase()
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty && token != 'and')
        .toList();

    var total = 0;
    var current = 0;
    for (final token in tokens) {
      if (token == 'hundred') {
        current = current == 0 ? 100 : current * 100;
        total += current;
        current = 0;
        continue;
      }
      final number = _numberWords[token];
      if (number == null) return null;
      current += number;
    }

    final parsed = total + current;
    return parsed == 0 ? null : parsed;
  }

  static List<ResolvedScriptureMatch> _deduplicateMatches(
    List<ResolvedScriptureMatch> items,
  ) {
    final seen = <String>{};
    final output = <ResolvedScriptureMatch>[];

    for (final item in items) {
      final scripture = item.scripture;
      final key = [
        scripture.bookId,
        scripture.chapter,
        scripture.startVerse ?? 0,
        scripture.endVerse ?? 0,
      ].join('-');
      if (seen.add(key)) output.add(item);
    }
    return output;
  }

  static List<_BookAlias> _buildBookAliases() {
    final aliases = <_BookAlias>[];
    final seen = <String>{};

    void add(Book book, String value) {
      final normalized = _normalizeAlias(value);
      if (normalized.isEmpty || !seen.add('${book.id}:$normalized')) return;
      aliases.add(_BookAlias(value, book));
    }

    for (final book in BookCatalog.books) {
      add(book, book.name);

      final numericPrefix = RegExp(r'^([1-3])\s+(.+)$').firstMatch(book.name);
      if (numericPrefix != null) {
        final number = numericPrefix.group(1)!;
        final base = numericPrefix.group(2)!;
        final words = _ordinalAliases[number] ?? const <String>[];
        for (final word in words) {
          add(book, '$word $base');
        }
        add(book, '$number$base');
      }
    }

    for (final entry in _extraAliases.entries) {
      final book = BookCatalog.byId(entry.key);
      for (final alias in entry.value) {
        add(book, alias);
      }
    }

    aliases.sort((a, b) => b.value.length.compareTo(a.value.length));
    return aliases;
  }

  static String _aliasPattern(String value) {
    final escaped = RegExp.escape(value).replaceAll(r'\ ', r'\s+');
    return escaped.endsWith(r'\\.') ? escaped : '$escaped\\.?';
  }

  static String _normalizeAlias(String value) {
    return value
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const Map<String, List<String>> _ordinalAliases = {
    '1': ['1st', 'first', 'one', 'i'],
    '2': ['2nd', 'second', 'two', 'ii'],
    '3': ['3rd', 'third', 'three', 'iii'],
  };

  static const Map<String, List<String>> _extraAliases = {
    'genesis': ['Gen', 'Ge'],
    'exodus': ['Exod', 'Ex', 'Exo'],
    'leviticus': ['Lev'],
    'numbers': ['Num', 'Nm'],
    'deuteronomy': ['Deut', 'Dt'],
    'joshua': ['Josh'],
    'judges': ['Judg'],
    '1_samuel': ['1 Sam', '1 Sam.', 'First Sam'],
    '2_samuel': ['2 Sam', '2 Sam.', 'Second Sam'],
    '1_kings': ['1 Kgs', 'First Kgs'],
    '2_kings': ['2 Kgs', 'Second Kgs'],
    '1_chronicles': ['1 Chron', 'First Chron'],
    '2_chronicles': ['2 Chron', 'Second Chron'],
    'psalms': ['Psalm', 'Ps', 'Psa'],
    'proverbs': ['Prov', 'Pr'],
    'ecclesiastes': ['Eccl'],
    'song_of_songs': ['Song of Solomon', 'Song', 'SOS'],
    'isaiah': ['Isa'],
    'jeremiah': ['Jer'],
    'lamentations': ['Lam'],
    'ezekiel': ['Ezek'],
    'daniel': ['Dan'],
    'obadiah': ['Obad'],
    'habakkuk': ['Hab'],
    'zechariah': ['Zech'],
    'malachi': ['Mal'],
    'matthew': ['Matt', 'Mt'],
    'mark': ['Mk'],
    'luke': ['Lk'],
    'john': ['Jn'],
    'romans': ['Rom'],
    '1_corinthians': ['1 Cor', '1 Cor.', 'First Cor'],
    '2_corinthians': ['2 Cor', '2 Cor.', 'Second Cor'],
    'galatians': ['Gal'],
    'ephesians': ['Eph'],
    'philippians': ['Phil'],
    'colossians': ['Col'],
    '1_thessalonians': ['1 Thess', 'First Thess'],
    '2_thessalonians': ['2 Thess', 'Second Thess'],
    '1_timothy': ['1 Tim', 'First Tim'],
    '2_timothy': ['2 Tim', 'Second Tim'],
    'philemon': ['Philem'],
    'hebrews': ['Heb'],
    'james': ['Jas'],
    '1_peter': ['1 Pet', 'First Pet'],
    '2_peter': ['2 Pet', 'Second Pet'],
    '1_john': ['First Jn', '1 Jn'],
    '2_john': ['Second Jn', '2 Jn'],
    '3_john': ['Third Jn', '3 Jn'],
    'revelation': ['Rev'],
  };

  static const String _singleDigitWordPattern =
      r'(?:one|two|three|four|five|six|seven|eight|nine)';

  static const String _numberWordPattern =
      r'(?:one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred)(?:[-\s]+(?:and\s+)?(?:one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred))*';

  static const Map<String, int> _numberWords = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };
}

class _BookAlias {
  const _BookAlias(this.value, this.book);

  final String value;
  final Book book;
}
