import 'package:hive/hive.dart';

import '../../data/bible/bible_asset_repository.dart';
import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse_ref.dart';

class SearchIndexRepository {
  static const int _version = 1;
  static const String _versionKey = '__version';

  final _inFlight = <BibleTranslation, Future<void>>{};

  Future<bool> isBuilt(BibleTranslation t) async {
    final box = await _openBox(t);
    return box.get(_versionKey) == _version;
  }

  Future<void> ensureBuilt(
      {required BibleTranslation translation,
      required BibleAssetRepository bibleRepo}) {
    return _inFlight.putIfAbsent(
      translation,
      () async {
        final box = await _openBox(translation);
        final built = box.get(_versionKey) == _version;
        if (built) return;

        await box.clear();
        await _buildIndex(
            box: box, translation: translation, bibleRepo: bibleRepo);
        await box.put(_versionKey, _version);
      },
    );
  }

  Future<List<VerseRef>> lookup(
      {required BibleTranslation translation,
      required String query,
      int limit = 50}) async {
    final tokens = _tokenizeQuery(query);
    if (tokens.isEmpty) return const [];

    final box = await _openBox(translation);

    Set<String>? intersection;
    for (final t in tokens) {
      final raw = box.get(t);
      final list = (raw is List) ? raw.whereType<String>().toSet() : <String>{};

      if (intersection == null) {
        intersection = list;
      } else {
        intersection = intersection.intersection(list);
      }

      if (intersection.isEmpty) break;
    }

    final keys =
        (intersection ?? <String>{}).take(limit).toList(growable: false);
    return keys
        .map(_parseVerseKey)
        .whereType<VerseRef>()
        .toList(growable: false);
  }

  Future<Box<dynamic>> _openBox(BibleTranslation t) {
    final name = 'search_index_${t.name}_v$_version';
    return Hive.openBox<dynamic>(name);
  }

  Future<void> _buildIndex({
    required Box<dynamic> box,
    required BibleTranslation translation,
    required BibleAssetRepository bibleRepo,
  }) async {
    final chapterAssets = await bibleRepo.listChapterAssetPaths(translation);
    if (chapterAssets.isEmpty) return;

    // token -> set(verseKey)
    final map = <String, Set<String>>{};

    final assets = chapterAssets.toList()..sort();
    for (final path in assets) {
      final verses = await bibleRepo.loadChapterByAssetPath(path);
      for (final v in verses) {
        final verseKey = v.ref.key;
        for (final token in _tokenizeText(v.text)) {
          final set = map.putIfAbsent(token, () => <String>{});
          set.add(verseKey);
        }
      }
    }

    // Persist in a compact-ish way (List<String> per token).
    // For a full Bible this can still be large, but avoids scanning assets at query time.
    for (final entry in map.entries) {
      await box.put(entry.key, entry.value.toList(growable: false));
    }
  }

  static VerseRef? _parseVerseKey(String key) {
    // key format: bookId.chapter.verse
    final parts = key.split('.');
    if (parts.length != 3) return null;
    final chapter = int.tryParse(parts[1]);
    final verse = int.tryParse(parts[2]);
    if (chapter == null || verse == null) return null;
    return VerseRef(bookId: parts[0], chapter: chapter, verse: verse);
  }

  static List<String> _tokenizeQuery(String query) {
    final tokens = _tokenizeText(query);
    // For queries with many words, keep only the first few meaningful tokens.
    return tokens.take(5).toList(growable: false);
  }

  static Iterable<String> _tokenizeText(String input) sync* {
    final lower = input.toLowerCase();
    final matches = RegExp(r'[a-z0-9]+').allMatches(lower);

    for (final m in matches) {
      final token = m.group(0)!;
      if (token.length < 2) continue;
      if (_stopWords.contains(token)) continue;
      yield token;
    }
  }

  static const Set<String> _stopWords = {
    'the',
    'and',
    'of',
    'to',
    'a',
    'in',
    'that',
    'is',
    'for',
    'with',
    'on',
    'as',
    'be',
    'are',
    'was',
    'were',
    'it',
    'this',
    'but',
    'not',
    'his',
    'her',
    'their',
    'your',
    'you',
    'i',
    'we',
    'they',
    'he',
    'she',
    'them',
    'who',
    'what',
    'when',
    'where',
    'why',
    'how',
    'from',
    'by',
    'at',
    'or',
    'an',
    'into',
    'out',
    'up',
    'down',
    'so',
    'no',
    'yes',
  };
}
