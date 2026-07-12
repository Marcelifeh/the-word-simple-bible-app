import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/color_utils.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../core/utils/bible_text_sanitizer.dart';
import '../../../core/utils/env.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/verse_insight_panel.dart';
import '../../../data/bible/book_catalog.dart';
import '../../../domain/entities/verse.dart';
import '../../../domain/entities/bible_translation.dart';
import '../../bible/view/reading_screen.dart';
import '../../reading_plan/model/daily_plan_passage.dart';
import '../../reading_plan/reading_plan_service.dart';
import '../../reading_plan/view/daily_plan_reader_screen.dart';
import '../../reading_plan/view/reading_plan_screen.dart';
import '../../notes/model/verse_note.dart';
import '../../sermon_notes/model/sermon_note.dart';
import '../../sermon_notes/view/sermon_editor_screen.dart';

class DailyVerseScreen extends StatefulWidget {
  final Verse? initialVerse;
  const DailyVerseScreen({super.key, this.initialVerse});

  @override
  State<DailyVerseScreen> createState() => _DailyVerseScreenState();
}

class _DailyVerseScreenState extends State<DailyVerseScreen> {
  Verse? _verse;
  bool _loading = false;
  bool _commentaryExpanded = false;
  Timer? _midnightTimer;
  Future<String?>? _commentaryFuture;

  bool _initDone = false;

  @override
  void initState() {
    super.initState();
    _verse = widget.initialVerse;
    _scheduleNextRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initDone) {
      _initDone = true;
      // Only trigger a fresh load if we don't have an initial verse.
      if (_verse == null) {
        _loadVerse();
      } else {
        // We have the verse, but we still want to trigger the commentary generation.
        _loadCommentary();
      }
    }
  }

  void _loadCommentary() {
    final state = AppScope.of(context);
    if (_verse != null) {
      setState(() {
        _commentaryFuture = state.commentaryRepo.getOrGenerateAndStore(
          translation: state.translation,
          ref: _verse!.ref,
          verseText: _verse!.text,
          bookName: _verse!.book,
        );
      });
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVerse() async {
    setState(() {
      _loading = true;
      _commentaryFuture = null;
    });
    try {
      final state = AppScope.of(context);
      final v = await state.dailyVerseService
          .getDailyVerse(translation: state.translation);

      Verse? finalVerse = v;
      if (finalVerse == null) {
        try {
          final all =
              await state.assetBibleRepo.loadAllVerses(state.translation);
          if (all.isNotEmpty) {
            final now = DateTime.now();
            final idx = (now.year + now.month + now.day) % all.length;
            finalVerse = all[idx];
          } else {
            final fallbacks = [BibleTranslation.kjv, BibleTranslation.web];
            for (final t in fallbacks) {
              final a = await state.assetBibleRepo.loadAllVerses(t);
              if (a.isNotEmpty) {
                final now = DateTime.now();
                final idx = (now.year + now.month + now.day) % a.length;
                finalVerse = a[idx];
                break;
              }
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _verse = finalVerse;
        _loading = false;
        if (_verse != null) {
          _commentaryFuture = state.commentaryRepo.getOrGenerateAndStore(
            translation: state.translation,
            ref: _verse!.ref,
            verseText: _verse!.text,
            bookName: _verse!.book,
          );
        }
      });
    } catch (e, st) {
      debugPrint('Failed loading daily verse: $e\n$st');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _scheduleNextRefresh() {
    final now = DateTime.now();
    final next =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final dur = next.difference(now);
    _midnightTimer?.cancel();
    _midnightTimer = Timer(dur + const Duration(seconds: 1), () {
      _loadVerse();
      _scheduleNextRefresh();
    });
  }

  void _addVerseToSermonNotes() {
    final verse = _verse;
    if (verse == null) return;

    final cleanedVerse = BibleTextSanitizer.clean(verse.text);
    final note = SermonNote(
      title:
          'Reflection on ${verse.book} ${verse.ref.chapter}:${verse.ref.verse}',
      content:
          '${verse.book} ${verse.ref.chapter}:${verse.ref.verse}\n"$cleanedVerse"\n\n',
    );

    AppRouter.push(
      context,
      SermonEditorScreen(note: note),
      transition: AppTransitionType.devotional,
    );
  }

  void _saveVerseToJournal() {
    final verse = _verse;
    if (verse == null) return;

    final state = AppScope.of(context);
    final verseId = verse.ref.canonicalId;
    final existingNote = state.notesRepo.get(verseId);

    if (existingNote != null && existingNote.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This verse is already in your Journal notes.'),
        ),
      );
      return;
    }

    final cleanedVerse = BibleTextSanitizer.clean(verse.text);
    final note = VerseNote(
      verseId: verseId,
      text:
          'Daily Verse reflection\n${verse.book} ${verse.ref.chapter}:${verse.ref.verse}\n"$cleanedVerse"\n\nWhat is God showing me today?\n',
      color: existingNote?.color ??
          Theme.of(context).colorScheme.primary.toARGB32(),
      createdAt: DateTime.now(),
    );

    state.notesRepo.save(note);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily Verse saved to your Journal notes.'),
      ),
    );
  }

  void _openSavedJournalNote() {
    final verse = _verse;
    if (verse == null) return;

    final book = BookCatalog.books.firstWhere(
      (candidate) =>
          candidate.id.toLowerCase() == verse.ref.bookId.toLowerCase(),
      orElse: () => BookCatalog.books.first,
    );

    AppRouter.push(
      context,
      ReadingScreen(
        book: book,
        chapter: verse.ref.chapter,
        initialVerse: verse.ref.verse,
        openNoteEditorOnLoad: true,
      ),
      transition: AppTransitionType.slideRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final readingPlan = ReadingPlanService().getTodayReading();
    final currentVerseId = _verse?.ref.canonicalId;
    final existingJournalNote =
        currentVerseId == null ? null : state.notesRepo.get(currentVerseId);
    final alreadySavedToJournal = existingJournalNote != null &&
        existingJournalNote.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Verse ✨'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_loading && _verse != null) ...[
            IconButton(
              tooltip: 'Listen',
              icon: const Icon(Icons.volume_up),
              onPressed: () async {
                try {
                  final url = await state.audioService
                      .getVerseAudioUrl(state.translation, _verse!.ref);
                  if (url == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Audio not configured yet. Set AUDIO_API_URL.')),
                    );
                    return;
                  }
                  await state.audioPlayer.playUrl(url);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Audio playback failed.')),
                  );
                }
              },
            ),
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share),
              onPressed: () async {
                final text =
                    '${_verse!.book} ${_verse!.ref.chapter}:${_verse!.ref.verse} — ${BibleTextSanitizer.clean(_verse!.text)}';
                await Share.share(text);
              },
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadVerse,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const LinearProgressIndicator()
              : _verse == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                            'No daily verse available yet (missing data).'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadVerse,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness ==
                                    Brightness.light
                                ? applyOpacity(
                                    Theme.of(context).colorScheme.primary, 0.08)
                                : applyOpacity(Colors.black, 0.35),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: applyOpacity(
                                    Theme.of(context).colorScheme.primary,
                                    0.25),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_verse!.book} ${_verse!.ref.chapter}:${_verse!.ref.verse}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: ((Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.fontSize ??
                                              24) *
                                          state.fontScale) +
                                      2,
                                  shadows: [
                                    Shadow(
                                      color: applyOpacity(Colors.black, 0.18),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '"${BibleTextSanitizer.clean(_verse!.text)}"',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.black
                                      : Theme.of(context).colorScheme.onSurface,
                                  height: 1.55,
                                  fontSize: ((Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.fontSize ??
                                              22) *
                                          state.fontScale) +
                                      2,
                                  shadows: [
                                    Shadow(
                                      color: applyOpacity(Colors.black, 0.13),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _DailyVerseInsightSection(
                          expanded: _commentaryExpanded,
                          fontScale: state.fontScale,
                          commentaryFuture: _commentaryFuture,
                          onToggle: () {
                            setState(() {
                              _commentaryExpanded = !_commentaryExpanded;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: alreadySavedToJournal
                                  ? _openSavedJournalNote
                                  : _saveVerseToJournal,
                              icon: Icon(
                                alreadySavedToJournal
                                    ? Icons.menu_book_rounded
                                    : Icons.bookmark_add_rounded,
                              ),
                              label: Text(
                                alreadySavedToJournal
                                    ? 'Open Saved Note'
                                    : 'Save to Journal',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _addVerseToSermonNotes,
                              icon: const Icon(Icons.edit_note_rounded),
                              label: const Text('Add to Sermon Notes'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _DailyReadingPlanSection(plan: readingPlan),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _DailyVerseInsightSection extends StatelessWidget {
  const _DailyVerseInsightSection({
    required this.expanded,
    required this.fontScale,
    required this.commentaryFuture,
    required this.onToggle,
  });

  final bool expanded;
  final double fontScale;
  final Future<String?>? commentaryFuture;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verse Insight',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expanded
                              ? 'Tap to collapse the commentary.'
                              : 'Tap to expand the commentary before the reading plan.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: FutureBuilder<String?>(
                        future: commentaryFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const LinearProgressIndicator();
                          }

                          final value = snapshot.data;
                          final apiConfigured = Env.commentaryApiUrl != null;
                          final text = (value != null &&
                                  value.trim().isNotEmpty)
                              ? value
                              : (apiConfigured
                                  ? 'Understanding: No verse insight available right now. Check the commentary API connection.'
                                  : 'Understanding: No verse insight is bundled offline for this verse.');

                          return VerseInsightPanel(
                            rawText: text,
                            accentColor: scheme.primary,
                            baseTextStyle: theme.textTheme.bodyLarge?.copyWith(
                              fontSize:
                                  (theme.textTheme.bodyLarge?.fontSize ?? 16) *
                                      fontScale,
                            ),
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyReadingPlanSection extends StatelessWidget {
  const _DailyReadingPlanSection({required this.plan});

  final DailyReading plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = AppScope.of(context);
    final primaryPassage =
        plan.passages.isNotEmpty ? plan.passages.first : null;
    final dailyPlanPassages = _dailyPlanPassages();
    final extraPassages = plan.passages.length > 1
        ? plan.passages.skip(1).toList()
        : const <String>[];
    final lastOpenedPassage = state.readingPlanLastOpenedPassageToday;
    final completedPassagesCount =
        plan.passages.where(state.isReadingPlanPassageCompletedToday).length;
    final completedToday = state.isReadingPlanCompletedFor(plan.passages);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.10),
            scheme.tertiary.withValues(alpha: 0.05),
            scheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.14),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bible In One Year',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Today\'s reading rhythm',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Move through today\'s passages in order and keep the habit lightweight.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          if (completedToday)
            _ReadingPlanStatusBanner(
              icon: Icons.check_circle_rounded,
              label: 'Completed today',
              text:
                  '$completedPassagesCount of ${plan.passages.length} passages finished. Revisit any passage whenever you want.',
              tint: scheme.tertiary,
            )
          else if (completedPassagesCount > 0)
            _ReadingPlanStatusBanner(
              icon: Icons.stacked_line_chart_rounded,
              label: 'Progress today',
              text: lastOpenedPassage != null
                  ? '$completedPassagesCount of ${plan.passages.length} passages finished. Last opened: $lastOpenedPassage'
                  : '$completedPassagesCount of ${plan.passages.length} passages finished.',
              tint: scheme.primary,
            )
          else if (lastOpenedPassage != null)
            _ReadingPlanStatusBanner(
              icon: Icons.history_edu_rounded,
              label: 'Last opened',
              text: lastOpenedPassage,
              tint: scheme.primary,
            ),
          if (completedToday || lastOpenedPassage != null)
            const SizedBox(height: 14),
          const SizedBox(height: 16),
          if (primaryPassage != null)
            _ReadingPlanPassageCard(
              title: primaryPassage,
              subtitle: 'Start here',
              icon: Icons.wb_sunny_outlined,
              emphasized: true,
              completed:
                  state.isReadingPlanPassageCompletedToday(primaryPassage),
              onTap: () => _openPassage(context, primaryPassage),
              onCompleteToggle: () => _togglePassageCompletion(
                context,
                primaryPassage,
              ),
            ),
          if (extraPassages.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...extraPassages.map(
              (passage) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReadingPlanPassageCard(
                  title: passage,
                  subtitle: 'Continue reading',
                  icon: Icons.auto_stories_outlined,
                  completed: state.isReadingPlanPassageCompletedToday(passage),
                  onTap: () => _openPassage(context, passage),
                  onCompleteToggle: () => _togglePassageCompletion(
                    context,
                    passage,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: dailyPlanPassages.isEmpty
                      ? null
                      : () => _openTodayReading(context, dailyPlanPassages),
                  icon: Icon(
                    completedToday
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    'Read All Today\'s Passages',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: completedToday
                    ? null
                    : () async {
                        await state.markReadingPlanCompleted(
                          passages: plan.passages,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Marked all today\'s passages as complete.'),
                          ),
                        );
                      },
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => AppRouter.push(
                context,
                ReadingPlanScreen(initialDate: DateTime.now()),
                transition: AppTransitionType.slideRight,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Open Full Plan'),
            ),
          ),
        ],
      ),
    );
  }

  List<DailyPlanPassage> _dailyPlanPassages() {
    final parsed = <DailyPlanPassage>[];
    for (final passage in plan.passages) {
      parsed.addAll(_parsePlanPassage(passage));
    }
    return parsed;
  }

  List<DailyPlanPassage> _parsePlanPassage(String passage) {
    final match = RegExp(r'^(.*?)\s+(\d+)(?:\s*[-–]\s*(\d+))?$')
        .firstMatch(passage.trim());
    if (match == null) return const <DailyPlanPassage>[];

    final bookName = match.group(1)?.trim() ?? '';
    final startChapter = int.tryParse(match.group(2) ?? '') ?? 1;
    final endChapter = int.tryParse(match.group(3) ?? '') ?? startChapter;
    final matches = BookCatalog.books
        .where(
          (candidate) => candidate.name.toLowerCase() == bookName.toLowerCase(),
        )
        .toList(growable: false);
    if (matches.isEmpty) return const <DailyPlanPassage>[];

    final book = matches.first;
    final firstChapter = startChapter <= endChapter ? startChapter : endChapter;
    final lastChapter = startChapter <= endChapter ? endChapter : startChapter;
    final boundedFirstChapter =
        firstChapter.clamp(1, book.chapterCount).toInt();
    final boundedLastChapter = lastChapter.clamp(1, book.chapterCount).toInt();

    return [
      for (var chapter = boundedFirstChapter;
          chapter <= boundedLastChapter;
          chapter++)
        DailyPlanPassage(
          bookId: book.id,
          bookName: book.name,
          chapter: chapter,
        ),
    ];
  }

  Future<void> _openTodayReading(
    BuildContext context,
    List<DailyPlanPassage> passages,
  ) async {
    if (passages.isEmpty) return;
    final state = AppScope.of(context);
    if (plan.passages.isNotEmpty) {
      await state.markReadingPlanPassageOpened(plan.passages.first);
    }
    if (!context.mounted) return;

    AppRouter.push(
      context,
      DailyPlanReaderScreen(
        passages: passages,
        translation: state.translation,
        onMarkComplete: () async {
          await state.markReadingPlanCompleted(passages: plan.passages);
        },
      ),
      transition: AppTransitionType.slideRight,
    );
  }

  Future<void> _openPassage(BuildContext context, String passage) async {
    final state = AppScope.of(context);
    final match = RegExp(r'^(.*?) (\d+)(?:-(\d+))?$').firstMatch(passage);
    if (match == null) return;

    await state.markReadingPlanPassageOpened(passage);
    if (!context.mounted) return;

    final bookName = match.group(1)?.trim() ?? '';
    final chapter = int.tryParse(match.group(2) ?? '1') ?? 1;
    final book = BookCatalog.books.firstWhere(
      (candidate) => candidate.name.toLowerCase() == bookName.toLowerCase(),
      orElse: () => BookCatalog.books.first,
    );

    AppRouter.push(
      context,
      ReadingScreen(book: book, chapter: chapter),
    );
  }

  Future<void> _togglePassageCompletion(
    BuildContext context,
    String passage,
  ) async {
    final state = AppScope.of(context);
    final completed = state.isReadingPlanPassageCompletedToday(passage);
    await state.markReadingPlanPassageCompleted(
      passage,
      completed: !completed,
    );
  }
}

class _ReadingPlanStatusBanner extends StatelessWidget {
  const _ReadingPlanStatusBanner({
    required this.icon,
    required this.label,
    required this.text,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
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

class _ReadingPlanPassageCard extends StatelessWidget {
  const _ReadingPlanPassageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.completed,
    required this.onCompleteToggle,
    this.emphasized = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool completed;
  final VoidCallback onCompleteToggle;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: emphasized
          ? scheme.primary.withValues(alpha: 0.10)
          : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary
                      .withValues(alpha: emphasized ? 0.18 : 0.12),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCompleteToggle,
                tooltip: completed ? 'Mark as not done' : 'Mark as done',
                icon: Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: completed ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
