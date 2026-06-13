import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/env.dart';
import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse_ref.dart';

class CommentaryRepository {
  CommentaryRepository();

  static const _boxName = 'commentary';
  static const _seedAsset = 'assets/data/commentary/sample_commentary.json';
  static const _offlineStyle = 'insight_premium_v2';
  static const _apiStyle = 'insight_premium_v2';
  static const _cacheVersion = 'insight_premium_v2';

  // Kept only to avoid showing an older placeholder that may be cached from
  // previous versions. New versions no longer generate/store this text.
  static const _legacyPlaceholderText =
      'This verse shows what God is like and how He wants us to live. Think about one simple step you can take today to trust and obey Him.';

  Box<dynamic>? _box;
  Map<String, String>? _seed;

  // Cache of per-chapter offline commentary assets.
  // Key: '<translation>:<bookId>:<chapter>'
  final Map<String, Map<int, String>> _offlineChapterCache = {};

  Future<void> init() async {
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
    } catch (_) {
      // Recover from corrupted box instead of crashing on startup.
      try {
        await Hive.deleteBoxFromDisk(_boxName);
      } catch (_) {
        // ignore
      }
      _box = await Hive.openBox<dynamic>(_boxName);
    }

    try {
      final raw = await rootBundle.loadString(_seedAsset);
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      _seed = decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      // Seed commentary is optional; keep the app usable even if missing.
      _seed = const {};
    }
  }

  Future<String?> getExplanation(VerseRef ref) async {
    final box = _box;
    if (box == null) throw StateError('CommentaryRepository not initialized');

    final cached = box.get(ref.key);
    if (cached is String && cached.trim().isNotEmpty) return cached;

    final seeded = _seed?[ref.key];
    if (seeded != null) return seeded;

    return null;
  }

  Future<String?> getOrGenerateAndStore({
    required BibleTranslation translation,
    required VerseRef ref,
    required String verseText,
    required String bookName,
  }) async {
    // All translations intentionally share the KJV commentary corpus.
    final effective = _effectiveCommentaryTranslation(translation);
    final native =
        await getExplanationForTranslation(translation: effective, ref: ref);
    if (native != null) return native;

    // Defensive fallback for any older callers that bypassed the effective
    // translation mapping.
    if (effective != BibleTranslation.kjv) {
      final englishFallback = await getExplanationForTranslation(
          translation: BibleTranslation.kjv, ref: ref);
      if (englishFallback != null) return englishFallback;
    }

    // Step 3: Try to generate via API (will store under the effective language).
    final apiUrl = (Env.commentaryApiUrl ?? Env.bibleApiUrl);
    if (apiUrl == null) return null;

    final generated = await _generateFromApi(
      baseUrl: apiUrl,
      translation: effective,
      ref: ref,
    );
    if (generated == null || generated.trim().isEmpty) return null;

    await storeExplanationForTranslation(
      translation: effective,
      ref: ref,
      explanation: generated,
    );
    return generated;
  }

  /// Returns the translation used for commentary storage.
  /// All app translations intentionally reuse KJV commentary.
  BibleTranslation _effectiveCommentaryTranslation(BibleTranslation t) =>
      BibleTranslation.kjv;

  /// The shared KJV commentary corpus is authored in English.
  String _languageIdFor(BibleTranslation t) => 'english';

  Future<String?> getExplanationForTranslation({
    required BibleTranslation translation,
    required VerseRef ref,
  }) async {
    final effectiveTranslation = _effectiveCommentaryTranslation(translation);

    final box = _box;
    if (box == null) throw StateError('CommentaryRepository not initialized');

    final key = _boxKey(translation: effectiveTranslation, ref: ref);
    final legacyKey = '${effectiveTranslation.name}:${ref.key}';

    final apiConfigured = (Env.commentaryApiUrl ?? Env.bibleApiUrl) != null;

    final cached = box.get(key);
    if (cached is String && cached.trim().isNotEmpty) {
      final value = cached.trim();
      if (value == _legacyPlaceholderText) {
        // Ignore/remove the legacy placeholder.
        try {
          await box.delete(key);
        } catch (_) {
          // ignore
        }
      } else {
        return value;
      }
    }

    if (!apiConfigured) {
      final legacyPrefixed = box.get(legacyKey);
      if (legacyPrefixed is String && legacyPrefixed.trim().isNotEmpty) {
        return legacyPrefixed.trim();
      }

      // Back-compat for older cache format (no translation prefix).
      final legacy = box.get(ref.key);
      if (legacy is String && legacy.trim().isNotEmpty) return legacy.trim();

      final offline = await _getOfflineAssetExplanation(
        translation: effectiveTranslation,
        ref: ref,
      );
      if (offline != null) return offline;

      final seeded = _seed?[ref.key];
      if (seeded != null) return seeded;
    }

    // If the API is configured but unavailable, still allow bundled offline commentary.
    final offline = await _getOfflineAssetExplanation(
      translation: effectiveTranslation,
      ref: ref,
    );
    if (offline != null) return offline;

    return null;
  }

  Future<String?> _getOfflineAssetExplanation({
    required BibleTranslation translation,
    required VerseRef ref,
  }) async {
    final key = '${translation.name}:${ref.bookId}:${ref.chapter}';
    Map<int, String>? chapter;

    if (_offlineChapterCache.containsKey(key)) {
      chapter = _offlineChapterCache[key];
    } else {
      // Expected path:
      // assets/data/commentary/insight_premium_v2/<translation>/<bookId>/<chapter>.json
      final path =
          'assets/data/commentary/$_offlineStyle/${translation.name}/${ref.bookId}/${ref.chapter}.json';
      try {
        final raw = await rootBundle.loadString(path);
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final map = <int, String>{};
          for (final entry in decoded.entries) {
            final verseNum = int.tryParse(entry.key.toString());
            if (verseNum == null) continue;
            final rawValue = entry.value;
            final value = rawValue is Map || rawValue is List
                ? jsonEncode(rawValue)
                : rawValue?.toString().trim() ?? '';
            if (value.isEmpty) continue;
            map[verseNum] = value;
          }
          chapter = map;
        }
      } catch (_) {
        chapter = null;
      }

      // Cache (including null) to avoid repeated asset loads.
      if (chapter != null) {
        _offlineChapterCache[key] = chapter;
      } else {
        _offlineChapterCache[key] = <int, String>{};
      }
    }

    final verseText = chapter?[ref.verse];
    if (verseText == null || verseText.trim().isEmpty) return null;
    return verseText.trim();
  }

  Future<void> storeExplanationForTranslation({
    required BibleTranslation translation,
    required VerseRef ref,
    required String explanation,
  }) async {
    final box = _box;
    if (box == null) throw StateError('CommentaryRepository not initialized');
    await box.put(_boxKey(translation: translation, ref: ref), explanation);
  }

  Future<String?> _generateFromApi({
    required String baseUrl,
    required BibleTranslation translation,
    required VerseRef ref,
  }) async {
    try {
      final base = Uri.parse(baseUrl);
      final uri = base.path.endsWith('/commentary/ensure')
          ? base
          : base.replace(
              path:
                  '${base.path.endsWith('/') ? base.path.substring(0, base.path.length - 1) : base.path}/commentary/ensure',
            );
      final res = await http.post(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          // Works with our Postgres-backed API endpoint: POST /commentary/ensure
          'translation': translation.name,
          'bookId': ref.bookId,
          'chapter': ref.chapter,
          'verse': ref.verse,
          'style': _apiStyle,
          'language': _languageIdFor(translation),
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['insight'] is Map) {
          final encoded = jsonEncode(decoded['insight']);
          if (encoded.trim().isNotEmpty) return encoded;
        }
        if (decoded is Map && decoded['explanation'] is String) {
          final explanation = (decoded['explanation'] as String).trim();
          if (explanation.isNotEmpty) return explanation;
        }
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  String _boxKey({
    required BibleTranslation translation,
    required VerseRef ref,
  }) {
    return '$_cacheVersion:${translation.name}:${ref.key}';
  }
}
