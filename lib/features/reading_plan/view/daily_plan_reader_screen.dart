import 'package:flutter/material.dart';

import '../../../core/narration/models/narration_state.dart';
import '../../../core/utils/bible_text_sanitizer.dart';
import '../../../core/utils/env.dart';
import '../../../domain/entities/bible_translation.dart';
import '../../../domain/entities/verse.dart';
import '../../../shared/bible/bible_text.dart';
import '../../../shared/bible/bible_translation_dropdown.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/verse_insight_panel.dart';
import '../model/daily_plan_passage.dart';
import '../model/narratable_daily_plan.dart';

class DailyPlanReaderScreen extends StatefulWidget {
  const DailyPlanReaderScreen({
    super.key,
    required this.passages,
    required this.translation,
    this.onMarkComplete,
  });

  final List<DailyPlanPassage> passages;
  final BibleTranslation translation;
  final Future<void> Function()? onMarkComplete;

  @override
  State<DailyPlanReaderScreen> createState() => _DailyPlanReaderScreenState();
}

class _DailyPlanReaderScreenState extends State<DailyPlanReaderScreen> {
  late BibleTranslation _translation;
  late Future<List<DailyPlanChapterContent>> _chaptersFuture;
  bool _didInit = false;
  bool _markedComplete = false;

  @override
  void initState() {
    super.initState();
    _translation = widget.translation;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;

    _didInit = true;
    _chaptersFuture = _loadAllChapters(AppScope.of(context));
  }

  void _changeTranslation(BibleTranslation value) {
    if (value == _translation) return;
    if (value.isLicensed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${value.label} requires licensed data.')),
      );
      return;
    }

    final state = AppScope.of(context);
    state.setTranslation(value);

    setState(() {
      _translation = value;
      _chaptersFuture = _loadAllChapters(state);
    });
  }

  Future<List<DailyPlanChapterContent>> _loadAllChapters(AppState state) async {
    final chapters = <DailyPlanChapterContent>[];

    for (final passage in widget.passages) {
      final verses = await _loadChapterWithFallback(state, passage);
      if (verses.isNotEmpty) {
        chapters.add(
          DailyPlanChapterContent(
            passage: passage,
            verses: verses,
          ),
        );
      }
    }

    return chapters;
  }

  Future<List<Verse>> _loadChapterWithFallback(
    AppState state,
    DailyPlanPassage passage,
  ) async {
    try {
      final verses = await state.bibleRepo.loadChapter(
        translation: _translation,
        bookId: passage.bookId,
        chapter: passage.chapter,
      );
      if (verses.isNotEmpty) return verses;
    } catch (e) {
      debugPrint(
        'DailyPlanReaderScreen: primary repo failed for '
        '${passage.bookId} ${passage.chapter}: $e',
      );
    }

    return state.assetBibleRepo.loadChapter(
      translation: _translation,
      bookId: passage.bookId,
      chapter: passage.chapter,
    );
  }

  Future<void> _listenToAll(List<DailyPlanChapterContent> chapters) async {
    if (chapters.isEmpty) return;

    final controller = AppScope.of(context).narrationController;
    final content = NarratableDailyPlan(chapters: chapters);

    await controller.playContent(
      content,
      id: 'daily_plan_${DateTime.now().toIso8601String()}',
      sourceType: NarrationSourceType.bible,
      mode: NarrationMode.reading,
    );
  }

  Future<void> _markComplete() async {
    if (_markedComplete) return;

    setState(() {
      _markedComplete = true;
    });

    await widget.onMarkComplete?.call();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Today's reading marked complete.")),
    );

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Reading"),
        actions: [
          FutureBuilder<List<DailyPlanChapterContent>>(
            future: _chaptersFuture,
            builder: (context, snapshot) {
              final ready = snapshot.hasData && snapshot.data!.isNotEmpty;
              return IconButton(
                tooltip: 'Listen to all passages',
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: ready ? () => _listenToAll(snapshot.data!) : null,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _TranslationSelector(
            translation: _translation,
            onChanged: _changeTranslation,
          ),
          Expanded(
            child: FutureBuilder<List<DailyPlanChapterContent>>(
              future: _chaptersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load today\'s reading.\n${snapshot.error}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }

                final chapters =
                    snapshot.data ?? const <DailyPlanChapterContent>[];
                if (chapters.isEmpty) {
                  return const Center(
                    child: Text('No reading passages found for today.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                  itemCount: chapters.length + 1,
                  itemBuilder: (context, index) {
                    if (index == chapters.length) {
                      return _MarkCompleteSection(
                        markedComplete: _markedComplete,
                        onPressed:
                            _markedComplete ? null : () => _markComplete(),
                      );
                    }

                    return _DailyPlanChapterSection(
                      chapterNumber: index + 1,
                      totalChapters: chapters.length,
                      content: chapters[index],
                      translation: _translation,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslationSelector extends StatelessWidget {
  const _TranslationSelector({
    required this.translation,
    required this.onChanged,
  });

  final BibleTranslation translation;
  final ValueChanged<BibleTranslation> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foregroundColor = scheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.translate_rounded,
            size: 18,
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          Text(
            'Translation',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          BibleTranslationDropdown(
            translation: translation,
            foregroundColor: foregroundColor,
            textStyle: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: foregroundColor,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DailyPlanChapterSection extends StatelessWidget {
  const _DailyPlanChapterSection({
    required this.chapterNumber,
    required this.totalChapters,
    required this.content,
    required this.translation,
  });

  final int chapterNumber;
  final int totalChapters;
  final DailyPlanChapterContent content;
  final BibleTranslation translation;

  @override
  Widget build(BuildContext context) {
    final isLastChapter = chapterNumber == totalChapters;

    return Padding(
      padding: EdgeInsets.only(bottom: isLastChapter ? 24 : 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChapterHeader(
            label: 'Chapter $chapterNumber of $totalChapters',
            number: chapterNumber,
            title: content.passage.label,
          ),
          const SizedBox(height: 18),
          SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final verse in content.verses)
                  DailyPlanVerseTile(
                    verse: verse,
                    bookId: content.passage.bookId,
                    bookName: content.passage.bookName,
                    chapter: content.passage.chapter,
                    translation: translation,
                  ),
              ],
            ),
          ),
          if (!isLastChapter) ...[
            const SizedBox(height: 18),
            Divider(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.35),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({
    required this.label,
    required this.number,
    required this.title,
  });

  final String label;
  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.18),
            scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary.withValues(alpha: 0.16),
            child: Text(
              '$number',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DailyPlanVerseTile extends StatefulWidget {
  const DailyPlanVerseTile({
    super.key,
    required this.verse,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.translation,
  });

  final Verse verse;
  final String bookId;
  final String bookName;
  final int chapter;
  final BibleTranslation translation;

  @override
  State<DailyPlanVerseTile> createState() => _DailyPlanVerseTileState();
}

class _DailyPlanVerseTileState extends State<DailyPlanVerseTile> {
  bool _expanded = false;
  bool _loading = false;
  bool _loaded = false;
  String? _commentary;

  Future<void> _loadCommentary() async {
    if (_loaded || _loading) return;

    setState(() => _loading = true);

    try {
      final state = AppScope.of(context);
      final text = await state.commentaryRepo.getOrGenerateAndStore(
        translation: widget.translation,
        ref: widget.verse.ref,
        verseText: widget.verse.text,
        bookName: widget.bookName,
      );

      if (!mounted) return;
      setState(() {
        _commentary = text != null && text.trim().isNotEmpty
            ? BibleTextSanitizer.clean(text)
            : _missingInsightMessage;
        _loaded = true;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('DailyPlanVerseTile: failed to load commentary: $e\n$st');
      if (!mounted) return;
      setState(() {
        _commentary = _missingInsightMessage;
        _loaded = true;
        _loading = false;
      });
    }
  }

  String get _missingInsightMessage => Env.commentaryApiUrl == null
      ? 'Understanding: No verse insight is bundled offline for this verse.'
      : 'Understanding: No verse insight available right now. Check the commentary API connection.';

  @override
  void didUpdateWidget(covariant DailyPlanVerseTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.translation != widget.translation ||
        oldWidget.verse.ref.key != widget.verse.ref.key) {
      _expanded = false;
      _loading = false;
      _loaded = false;
      _commentary = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final readingStyles = BibleReadingTextStyles.of(
      context,
      state,
      isFallback: widget.verse.isFallback,
    );

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final next = !_expanded;
              setState(() => _expanded = next);
              if (next) _loadCommentary();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              padding: BibleReadingTextStyles.verseTilePadding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: BibleReadingTextStyles.expandIndicatorClearance,
                    ),
                    child: BibleVerseText(
                      verse: widget.verse,
                      styles: readingStyles,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        turns: _expanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: scheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: BibleReadingTextStyles.expandedInsightPadding,
                    child: _loading
                        ? const LinearProgressIndicator()
                        : VerseInsightPanel(
                            rawText: _commentary ?? _missingInsightMessage,
                            accentColor: scheme.primary,
                            baseTextStyle: readingStyles.commentaryTextStyle,
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _MarkCompleteSection extends StatelessWidget {
  const _MarkCompleteSection({
    required this.markedComplete,
    required this.onPressed,
  });

  final bool markedComplete;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Icon(
            markedComplete
                ? Icons.check_circle_rounded
                : Icons.flag_circle_rounded,
            size: 44,
            color: markedComplete ? Colors.greenAccent : scheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            markedComplete
                ? 'Today\'s reading is complete'
                : 'Finished today\'s reading?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            markedComplete
                ? 'Great job staying consistent in God\'s Word.'
                : 'Mark this day complete and keep your Bible reading rhythm strong.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(
                markedComplete
                    ? Icons.check_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(markedComplete ? 'Completed' : 'Mark Today Complete'),
            ),
          ),
        ],
      ),
    );
  }
}
