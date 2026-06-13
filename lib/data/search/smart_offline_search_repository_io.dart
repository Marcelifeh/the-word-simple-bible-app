import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../core/utils/bible_text_sanitizer.dart';
import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/verse_ref.dart';
import '../bible/bible_asset_repository.dart';
import 'smart_offline_search_repository_api.dart';

class SqliteFtsSmartOfflineSearchRepository
    implements SmartOfflineSearchRepository {
  static const int _schemaVersion = 1;

  final _inFlight = <BibleTranslation, Future<void>>{};
  final _dbByTranslation = <BibleTranslation, Database>{};

  @override
  Future<void> ensureBuilt({
    required BibleTranslation translation,
    required BibleAssetRepository bibleRepo,
  }) {
    return _inFlight.putIfAbsent(
      translation,
      () async {
        final db = await _openDb(translation);
        _dbByTranslation[translation] = db;

        final built = _isBuilt(db);
        if (built) return;

        _createSchema(db);
        _clearIndex(db);

        await _buildIndex(
            db: db, translation: translation, bibleRepo: bibleRepo);
        _markBuilt(db);
      },
    );
  }

  @override
  Future<List<Verse>> search({
    required BibleTranslation translation,
    required String query,
    int limit = 50,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final db = _dbByTranslation[translation] ?? await _openDb(translation);
    _dbByTranslation[translation] = db;

    final match = _buildMatchQuery(q);
    if (match == null) return const [];

    final stmt = db.prepare(
      'SELECT refKey, bookId, book, chapter, verse, text '
      'FROM verses_fts '
      'WHERE verses_fts MATCH ? '
      'ORDER BY bm25(verses_fts) '
      'LIMIT ?;',
    );

    try {
      final rows = stmt.select([match, limit.clamp(1, 200)]);
      final out = <Verse>[];
      for (final r in rows) {
        final bookId = (r['bookId'] as String?) ?? '';
        final book = (r['book'] as String?) ?? '';
        final chapter = int.tryParse('${r['chapter']}') ?? 0;
        final verse = int.tryParse('${r['verse']}') ?? 0;
        final text = (r['text'] as String?) ?? '';

        if (bookId.isEmpty || chapter <= 0 || verse <= 0) continue;

        out.add(
          Verse(
            ref: VerseRef(bookId: bookId, chapter: chapter, verse: verse),
            book: book,
            text: text,
          ),
        );
      }
      return List<Verse>.unmodifiable(out);
    } finally {
      stmt.dispose();
    }
  }

  bool _isBuilt(Database db) {
    try {
      final rows = db.select(
        'SELECT value FROM meta WHERE key = ? LIMIT 1;',
        ['schema_version'],
      );
      if (rows.isEmpty) return false;
      final v = int.tryParse('${rows.first['value']}');
      return v == _schemaVersion;
    } catch (_) {
      return false;
    }
  }

  void _markBuilt(Database db) {
    db.execute(
      'INSERT OR REPLACE INTO meta(key, value) VALUES (?, ?);',
      ['schema_version', _schemaVersion.toString()],
    );
  }

  void _createSchema(Database db) {
    db.execute('PRAGMA journal_mode=WAL;');
    db.execute('PRAGMA synchronous=NORMAL;');

    db.execute(
      'CREATE TABLE IF NOT EXISTS meta('
      '  key TEXT PRIMARY KEY,'
      '  value TEXT NOT NULL'
      ');',
    );

    // FTS5 table for verse text. We store metadata columns as UNINDEXED and only
    // index the verse text. Prefix indexes speed up token* queries.
    db.execute(
      'CREATE VIRTUAL TABLE IF NOT EXISTS verses_fts USING fts5('
      '  refKey UNINDEXED,'
      '  bookId UNINDEXED,'
      '  book UNINDEXED,'
      '  chapter UNINDEXED,'
      '  verse UNINDEXED,'
      '  text,'
      '  tokenize = "porter",'
      '  prefix = "2 3 4"'
      ');',
    );
  }

  void _clearIndex(Database db) {
    db.execute('DELETE FROM verses_fts;');
    db.execute('DELETE FROM meta WHERE key = ?;', ['schema_version']);
  }

  Future<void> _buildIndex({
    required Database db,
    required BibleTranslation translation,
    required BibleAssetRepository bibleRepo,
  }) async {
    // Prefer chapter-per-file assets; fall back to legacy all-verses asset.
    final chapterAssets = await bibleRepo.listChapterAssetPaths(translation);

    final insert = db.prepare(
      'INSERT INTO verses_fts(refKey, bookId, book, chapter, verse, text) '
      'VALUES (?, ?, ?, ?, ?, ?);',
    );

    try {
      db.execute('BEGIN;');

      if (chapterAssets.isNotEmpty) {
        final assets = chapterAssets.toList()..sort();
        for (final path in assets) {
          final verses = await bibleRepo.loadChapterByAssetPath(path);
          for (final v in verses) {
            final cleaned = BibleTextSanitizer.clean(v.text);
            if (cleaned.isEmpty) continue;
            insert.execute([
              v.ref.key,
              v.ref.bookId,
              v.book,
              v.ref.chapter,
              v.ref.verse,
              cleaned,
            ]);
          }
          // Yield between chapters to keep the UI responsive on large datasets.
          await Future<void>.delayed(Duration.zero);
        }
      } else {
        final all = await bibleRepo.loadAllVerses(translation);
        for (final v in all) {
          final cleaned = BibleTextSanitizer.clean(v.text);
          if (cleaned.isEmpty) continue;
          insert.execute([
            v.ref.key,
            v.ref.bookId,
            v.book,
            v.ref.chapter,
            v.ref.verse,
            cleaned,
          ]);
        }
      }

      db.execute('COMMIT;');
    } catch (_) {
      try {
        db.execute('ROLLBACK;');
      } catch (_) {}
      rethrow;
    } finally {
      insert.dispose();
    }
  }

  static String? _buildMatchQuery(String raw) {
    final tokens = _tokenize(raw);
    if (tokens.isEmpty) return null;

    final groups = <String>[];
    for (final t in tokens.take(6)) {
      final variants = _expandToken(t).map((v) => '${_escape(v)}*').toSet();
      if (variants.isEmpty) continue;
      if (variants.length == 1) {
        groups.add(variants.first);
      } else {
        groups.add('(${variants.join(' OR ')})');
      }
    }

    if (groups.isEmpty) return null;
    // AND groups together to keep results relevant.
    return groups.join(' ');
  }

  static Iterable<String> _tokenize(String input) sync* {
    final lower = input.toLowerCase();
    for (final m in RegExp(r'[a-z0-9]+').allMatches(lower)) {
      final t = m.group(0)!;
      if (t.length < 2) continue;
      yield t;
    }
  }

  /// Tiny heuristic stemming for queries.
  ///
  /// SQLite porter stemming helps primarily for English, but we also expand
  /// query variants to improve matches across translations.
  static Iterable<String> _expandToken(String token) sync* {
    final t = token;
    yield t;

    // Common English-ish reductions.
    if (t.endsWith('ing') && t.length > 5) yield t.substring(0, t.length - 3);
    if (t.endsWith('ed') && t.length > 4) yield t.substring(0, t.length - 2);
    if (t.endsWith('es') && t.length > 4) yield t.substring(0, t.length - 2);
    if (t.endsWith('s') && t.length > 3) yield t.substring(0, t.length - 1);
  }

  static String _escape(String token) {
    // Escape double quotes for FTS query safety.
    return token.replaceAll('"', '""');
  }

  Future<Database> _openDb(BibleTranslation translation) async {
    if (!Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.isMacOS &&
        !Platform.isWindows &&
        !Platform.isLinux) {
      // Conservative: if a platform is unknown, avoid attempting sqlite.
      throw UnsupportedError('SQLite FTS is not supported on this platform');
    }

    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);

    final path =
        '${dir.path}${Platform.pathSeparator}search_fts_${translation.name}_v$_schemaVersion.sqlite';
    return sqlite3.open(path);
  }
}

SmartOfflineSearchRepository createSmartOfflineSearchRepository() =>
    SqliteFtsSmartOfflineSearchRepository();
