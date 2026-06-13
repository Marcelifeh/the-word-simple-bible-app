import 'package:flutter/material.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../domain/entities/book.dart';
import 'reading_screen.dart';
import '../../../shared/state/app_state.dart';
import '../../../domain/entities/verse.dart';

class VerseScreen extends StatefulWidget {
  const VerseScreen({super.key, required this.book, required this.chapter});

  final Book book;
  final int chapter;

  @override
  State<VerseScreen> createState() => _VerseScreenState();
}

class _VerseScreenState extends State<VerseScreen> {
  late Future<List<Verse>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _load();
  }

  Future<List<Verse>> _load() async {
    final state = AppScope.of(context);
    try {
      final verses = await state.bibleRepo.loadChapter(
        translation: state.translation,
        bookId: widget.book.id,
        chapter: widget.chapter,
      );
      if (verses.isNotEmpty) return verses;
    } catch (_) {}
    // Fallback to bundled assets when the API is unavailable
    return state.assetBibleRepo.loadChapter(
      translation: state.translation,
      bookId: widget.book.id,
      chapter: widget.chapter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('${widget.book.name} ${widget.chapter} – Verses')),
      body: FutureBuilder<List<Verse>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.orange),
                  const SizedBox(height: 12),
                  const Text('Failed to load verses.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _future = _load()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final verses = snapshot.data ?? const <Verse>[];
          final verseCount = verses.length;
          if (verseCount == 0) {
            return const Center(
                child: Text('No verses found for this chapter.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: verseCount,
            itemBuilder: (context, index) {
              final verse = index + 1;
              return Card(
                child: InkWell(
                  onTap: () => AppRouter.push(
                    context,
                    ReadingScreen(
                      book: widget.book,
                      chapter: widget.chapter,
                      initialVerse: verse,
                    ),
                    transition: AppTransitionType.slideRight,
                  ),
                  child: Center(child: Text('$verse')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
