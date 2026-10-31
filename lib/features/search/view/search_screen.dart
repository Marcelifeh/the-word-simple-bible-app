import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../app/main_shell.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../core/utils/bible_text_sanitizer.dart';
import '../../../data/bible/book_catalog.dart';
import '../../../data/search/search_query.dart';
import '../../../data/search/search_relevance.dart';
import '../../../data/search/search_query_parser.dart';
import '../../../domain/entities/verse.dart';
import '../../../domain/entities/bible_translation.dart';
import '../../../domain/entities/verse_ref.dart';
import '../../../core/utils/env.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/reading_text_scale.dart';
import '../../bible/view/reading_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  List<Verse> results = const [];
  String? info;
  bool loading = false;
  int _searchGeneration = 0;

  @override
  void dispose() {
    _searchGeneration++;
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => MainShell.switchTo(0),
        ),
        title: const Text('🔍 Search Bible'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'faith, Psalm 23, John 3:16',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _runSearch(state),
                ),
              ),
              onSubmitted: (_) => _runSearch(state),
            ),
            const SizedBox(height: 12),
            if (loading) const LinearProgressIndicator(),
            if (info != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child:
                    Text(info!, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final v = results[index];
                  final label = '${v.book} ${v.ref.chapter}:${v.ref.verse}';
                  final cleanedText = BibleTextSanitizer.clean(v.text);
                  final referenceSize = (14 * state.fontScale).clamp(14, 18);
                  return ListTile(
                    title: Text(
                      label,
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: referenceSize.toDouble(),
                      ),
                    ),
                    subtitle: ReadingTextScale(
                      child: Text(
                        cleanedText,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    isThreeLine: true,
                    onTap: () async {
                      try {
                        final book = BookCatalog.books.firstWhere(
                          (b) =>
                              b.id.toLowerCase() == v.ref.bookId.toLowerCase(),
                        );
                        AppRouter.push(
                          context,
                          ReadingScreen(
                            book: book,
                            chapter: v.ref.chapter,
                            initialVerse: v.ref.verse,
                          ),
                          transition: AppTransitionType.slideRight,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not open verse: $e')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runSearch(AppState state) async {
    final raw = controller.text.trim();
    if (raw.isEmpty) return;

    final generation = ++_searchGeneration;
    setState(() {
      loading = true;
      info = null;
      results = const [];
    });

    try {
    final parsed = const SearchQueryParser().parse(raw);

    List<Verse> next = const [];
    String? nextInfo;

    if (parsed is VerseQuery) {
      final chapterVerses = await state.bibleRepo.loadChapter(
        translation: state.translation,
        bookId: parsed.ref.bookId,
        chapter: parsed.ref.chapter,
      );
      final match = chapterVerses
          .where((v) => v.ref.verse == parsed.ref.verse)
          .toList(growable: false);
      next = match;
      nextInfo = '${parsed.bookName} ${parsed.ref.chapter}:${parsed.ref.verse}';
    } else if (parsed is ChapterQuery) {
      next = await state.bibleRepo.loadChapter(
        translation: state.translation,
        bookId: parsed.bookId,
        chapter: parsed.chapter,
      );
      nextInfo = '${parsed.bookName} ${parsed.chapter}';
    } else if (parsed is KeywordQuery) {
      final q = parsed.keyword.trim();
      if (Env.bibleApiUrl != null) {
        next = await state.bibleRepo
            .searchKeyword(translation: state.translation, query: q, limit: 50);
      } else {
        if (!kIsWeb) {
          await state.smartSearchRepo.ensureBuilt(
              translation: state.translation, bibleRepo: state.assetBibleRepo);
          next = await state.smartSearchRepo
              .search(translation: state.translation, query: q, limit: 50);
        } else {
          // Web: prefer API search when available. If not configured, fall back to the
          // lightweight token index (best-effort for bundled assets).
          await state.searchIndexRepo.ensureBuilt(
              translation: state.translation, bibleRepo: state.assetBibleRepo);
          final refs = await state.searchIndexRepo
              .lookup(translation: state.translation, query: q, limit: 50);
          next = await _loadVersesForRefs(state: state, refs: refs);
        }
      }
      // Filter and rank local matches before cross-translation discovery.
      // This avoids displaying verses that share only generic words.
      final scored = <String, (Verse, double)>{};
      for (final verse in next) {
        final score = SearchRelevance.score(q, verse.text);
        if (score > 0) scored[verse.ref.key] = (verse, score);
      }
      // Search the other bundled English translation for remembered wording.
      // Display only verses from the user's selected translation.
      if (state.translation == BibleTranslation.kjv ||
          state.translation == BibleTranslation.web) {
        final other = state.translation == BibleTranslation.kjv
            ? BibleTranslation.web : BibleTranslation.kjv;
        try {
          List<VerseRef> otherRefs;
          if (kIsWeb) {
            await state.searchIndexRepo.ensureBuilt(
                translation: other, bibleRepo: state.assetBibleRepo);
            otherRefs = await state.searchIndexRepo.lookup(
                translation: other, query: q, limit: 30);
          } else {
            await state.smartSearchRepo.ensureBuilt(
                translation: other, bibleRepo: state.assetBibleRepo);
            final matches = await state.smartSearchRepo.search(
                translation: other, query: q, limit: 30);
            otherRefs = matches.map((v) => v.ref).toList();
          }
          // Require strong wording overlap in the other translation too.
          final otherVerses = await _loadVersesForTranslation(
              state: state, translation: other, refs: otherRefs);
          final matchedRefs = <VerseRef>[];
          for (final verse in otherVerses) {
            final score = SearchRelevance.score(q, verse.text);
            if (score <= 0) continue;
            final existing = scored[verse.ref.key];
            if (existing != null) {
              if (score > existing.$2) scored[verse.ref.key] = (existing.$1, score);
            } else {
              matchedRefs.add(verse.ref);
            }
          }
          final additional = await _loadVersesForRefs(state: state, refs: matchedRefs);
          for (final verse in additional) {
            final otherVerse = otherVerses.where((v) => v.ref.key == verse.ref.key).firstOrNull;
            if (otherVerse == null) continue;
            scored[verse.ref.key] = (verse, SearchRelevance.score(q, otherVerse.text));
          }
        } catch (error) {
          debugPrint('Cross-translation search unavailable: $error');
        }
      }
      final ranked = scored.values.toList()
        ..sort((a, b) => b.$2.compareTo(a.$2));
      // When a strong phrase match exists, don't dilute it with weak hits.
      final top = ranked.isEmpty ? 0.0 : ranked.first.$2;
      next = ranked.where((entry) => top < 150 || entry.$2 >= top * 0.7)
          .take(50).map((entry) => entry.$1).toList(growable: false);
      nextInfo = next.isEmpty
          ? 'No close matches found for "$q".'
          : 'Keyword: "$q" (best matches first)';
    }

    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      results = next;
      info = nextInfo;
    });
    } catch (error, stackTrace) {
      debugPrint('Bible search failed: $error\n$stackTrace');
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        results = const [];
        info = 'Search could not be completed. Please try again.';
      });
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => loading = false);
      }
    }
  }

  Future<List<Verse>> _loadVersesForTranslation({
    required AppState state,
    required BibleTranslation translation,
    required List<VerseRef> refs,
  }) async {
    final verses = <Verse>[];
    final cache = <String, List<Verse>>{};
    for (final ref in refs) {
      final chapterKey = '${ref.bookId}.${ref.chapter}';
      var chapter = cache[chapterKey];
      if (chapter == null) {
        chapter = await state.assetBibleRepo.loadChapter(
          translation: translation,
          bookId: ref.bookId,
          chapter: ref.chapter,
        );
        cache[chapterKey] = chapter;
      }
      for (final verse in chapter) {
        if (verse.ref.verse == ref.verse) {
          verses.add(verse);
          break;
        }
      }
    }
    return verses;
  }

  Future<List<Verse>> _loadVersesForRefs(
      {required AppState state, required List<VerseRef> refs}) async {
    if (refs.isEmpty) return const [];

    final byChapter = <String, List<VerseRef>>{};
    for (final r in refs) {
      final key = '${r.bookId}.${r.chapter}';
      (byChapter[key] ??= <VerseRef>[]).add(r);
    }

    final foundByKey = <String, Verse>{};

    for (final group in byChapter.values) {
      final first = group.first;
      final chapterVerses = await state.bibleRepo.loadChapter(
        translation: state.translation,
        bookId: first.bookId,
        chapter: first.chapter,
      );

      final wantedVerses = group.map((r) => r.verse).toSet();
      for (final v in chapterVerses) {
        if (wantedVerses.contains(v.ref.verse)) {
          foundByKey[v.ref.key] = v;
        }
      }
    }

    final ordered = <Verse>[];
    for (final r in refs) {
      final v = foundByKey[r.key];
      if (v != null) ordered.add(v);
    }
    return List<Verse>.unmodifiable(ordered);
  }
}
