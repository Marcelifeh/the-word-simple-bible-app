import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../app/main_shell.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../core/utils/bible_text_sanitizer.dart';
import '../../../data/bible/book_catalog.dart';
import '../../../data/search/search_query.dart';
import '../../../data/search/search_query_parser.dart';
import '../../../domain/entities/verse.dart';
import '../../../domain/entities/verse_ref.dart';
import '../../../core/utils/env.dart';
import '../../../shared/state/app_state.dart';
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

  @override
  void dispose() {
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
                  return ListTile(
                    title: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      cleanedText,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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

    setState(() {
      loading = true;
      info = null;
      results = const [];
    });

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
      nextInfo = 'Keyword: "$q"';
    }

    if (!mounted) return;
    setState(() {
      results = next;
      info = nextInfo;
      loading = false;
    });
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
