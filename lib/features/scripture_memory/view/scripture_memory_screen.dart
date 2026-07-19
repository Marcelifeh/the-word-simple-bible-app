import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../shared/state/app_state.dart';
import '../model/memory_home_summary.dart';
import '../model/memory_progress_summary.dart';
import '../model/memory_review_event.dart';
import '../model/memory_schedule.dart';
import '../model/memory_session_draft.dart';
import '../model/memory_verse.dart';
import '../repository/memory_verse_repository.dart';
import '../widgets/add_to_memory_sheet.dart';
import 'memory_session_screen.dart';
import 'memory_collections_screen.dart';
import 'memory_verse_history_screen.dart';

class ScriptureMemoryScreen extends StatelessWidget {
  const ScriptureMemoryScreen({super.key});

  Future<void> _startReview(
    BuildContext context,
    List<MemoryVerse> due,
    int dailyGoal,
    MemoryVerseRepository repository,
  ) async {
    if (due.isEmpty) return;
    final sessionVerses = due.take(dailyGoal).toList();
    final draft = await repository.startSession(
      sessionVerses.map((verse) => verse.id).toList(growable: false),
      replaceExisting: true,
    );
    if (!context.mounted) return;
    await AppRouter.push(
      context,
      MemorySessionScreen(verses: sessionVerses, draft: draft),
      transition: AppTransitionType.slideUp,
    );
  }

  Future<void> _continueReview(
    BuildContext context,
    MemoryVerseRepository repository,
    MemorySessionDraft draft,
  ) async {
    final verses = repository.resumableSessionVerses(draft);
    if (verses.isEmpty) {
      await repository.clearSessionDraft();
      return;
    }
    if (!context.mounted) return;
    await AppRouter.push(
      context,
      MemorySessionScreen(verses: verses, draft: draft),
      transition: AppTransitionType.slideUp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final repository = state.memoryVerseRepo;
    final summary = repository.homeSummary;
    final due = repository.due();
    final verses = repository.list();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hide God\'s Word'),
          actions: [
            IconButton(
              tooltip: 'Memory collections',
              onPressed: () => AppRouter.push(
                context,
                MemoryCollectionsScreen(),
                transition: AppTransitionType.slideRight,
              ),
              icon: const Icon(Icons.collections_bookmark_rounded),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'My Verses'),
              Tab(text: 'Progress'),
            ],
          ),
        ),
        body: Column(
          children: [
            _MemoryDashboardHeader(
              summary: summary,
              dailyGoal: repository.dailyGoal,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TodayMemoryView(
                    due: due,
                    dailyGoal: repository.dailyGoal,
                    sessionDraft: repository.sessionDraft,
                    onStart: () => _startReview(
                      context,
                      due,
                      repository.dailyGoal,
                      repository,
                    ),
                    onContinue: repository.sessionDraft == null
                        ? null
                        : () => _continueReview(
                              context,
                              repository,
                              repository.sessionDraft!,
                            ),
                    onStartOver: repository.sessionDraft == null
                        ? null
                        : () async {
                            final verses = repository.resumableSessionVerses(
                              repository.sessionDraft!,
                            );
                            await _startReview(
                              context,
                              verses,
                              repository.dailyGoal,
                              repository,
                            );
                          },
                    onDiscard: repository.sessionDraft == null
                        ? null
                        : repository.clearSessionDraft,
                  ),
                  _MemoryVerseLibrary(verses: verses),
                  _MemoryProgressView(
                    verses: verses,
                    summary: repository.progressSummary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryDashboardHeader extends StatelessWidget {
  const _MemoryDashboardHeader({
    required this.summary,
    required this.dailyGoal,
  });

  final MemoryHomeSummary summary;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = summary.reviewedToday / math.max(1, dailyGoal);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Psalm 119:11',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  value: '${summary.dueCount}',
                  label: 'Due',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  value: '${summary.streakDays}',
                  label: 'Day streak',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  value: '${summary.establishedCount}',
                  label: 'Established',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1).toDouble(),
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${summary.reviewedToday}/$dailyGoal today',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _TodayMemoryView extends StatelessWidget {
  const _TodayMemoryView({
    required this.due,
    required this.dailyGoal,
    required this.sessionDraft,
    required this.onStart,
    required this.onContinue,
    required this.onStartOver,
    required this.onDiscard,
  });

  final List<MemoryVerse> due;
  final int dailyGoal;
  final MemorySessionDraft? sessionDraft;
  final VoidCallback onStart;
  final VoidCallback? onContinue;
  final VoidCallback? onStartOver;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (due.isEmpty && sessionDraft == null) {
      return _EmptyMemoryState(
        icon: Icons.check_circle_rounded,
        title: 'You are caught up',
        message: 'Add a verse from Bible reading, Daily Verse, or a promise.',
      );
    }

    final sessionCount = math.min(dailyGoal, due.length).toInt();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (sessionDraft != null) ...[
          _SessionRecoveryCard(
            draft: sessionDraft!,
            onContinue: onContinue!,
            onStartOver: onStartOver!,
            onDiscard: onDiscard!,
          ),
          const SizedBox(height: 22),
        ],
        Text(
          'Today\'s Review',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$sessionCount ${sessionCount == 1 ? 'verse' : 'verses'} ready '
          'for this session.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: due.isEmpty ? null : onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Begin Review'),
        ),
        const SizedBox(height: 22),
        for (final verse in due.take(sessionCount)) ...[
          _MemoryDueTile(verse: verse),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MemoryDueTile extends StatelessWidget {
  const _MemoryDueTile({required this.verse});

  final MemoryVerse verse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verse.reference,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${verse.translation.name.toUpperCase()} · '
                  '${_statusLabel(verse.schedule.status)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryVerseLibrary extends StatelessWidget {
  const _MemoryVerseLibrary({required this.verses});

  final List<MemoryVerse> verses;

  Future<void> _edit(BuildContext context, MemoryVerse verse) async {
    await showAddToMemorySheet(
      context,
      draft: MemoryVerseDraft(
        bookId: verse.bookId,
        bookName: verse.bookName,
        chapter: verse.chapter,
        startVerse: verse.startVerse,
        endVerse: verse.endVerse,
        translation: verse.translation,
        text: verse.textSnapshot,
        source: verse.source,
        categories: verse.categories,
        difficulty: verse.difficulty,
      ),
    );
  }

  Future<void> _delete(BuildContext context, MemoryVerse verse) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove permanently?'),
        content: Text(
          'This will remove ${verse.reference} and its review history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AppScope.of(context).memoryVerseRepo.deletePermanently(verse.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (verses.isEmpty) {
      return const _EmptyMemoryState(
        icon: Icons.psychology_alt_rounded,
        title: 'Your memory list is empty',
        message: 'Use Memorize on a verse to begin.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: verses.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final verse = verses[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(verse.reference),
          subtitle: Text(
            '${verse.translation.name.toUpperCase()} · '
            '${verse.categories.isEmpty ? 'Uncategorized' : verse.categories.join(', ')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => AppRouter.push(
            context,
            MemoryVerseHistoryScreen(verse: verse),
            transition: AppTransitionType.slideRight,
          ),
          trailing: PopupMenuButton<String>(
            tooltip: 'Memory verse options',
            onSelected: (action) async {
              if (action == 'edit') {
                await _edit(context, verse);
              } else if (action == 'archive') {
                await AppScope.of(context).memoryVerseRepo.archive(verse.id);
              } else if (action == 'delete') {
                await _delete(context, verse);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'archive', child: Text('Archive')),
              PopupMenuItem(value: 'delete', child: Text('Remove permanently')),
            ],
          ),
        );
      },
    );
  }
}

class _MemoryProgressView extends StatelessWidget {
  const _MemoryProgressView({
    required this.verses,
    required this.summary,
  });

  final List<MemoryVerse> verses;
  final MemoryProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = <String, int>{};
    for (final verse in verses) {
      for (final category in verse.categories) {
        counts.update(category, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final categories = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${summary.establishedCount} verses established',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'A verse becomes established at the 30-day interval. A later lapse '
          'marks it as needing strengthening without erasing that milestone.',
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ProgressMetric(
              value: '${summary.learningCount}',
              label: 'Currently growing',
            ),
            _ProgressMetric(
              value: '${summary.strengtheningCount}',
              label: 'Need strengthening',
            ),
            _ProgressMetric(
              value: '${summary.reviewsThisMonth}',
              label: 'Reviews this month',
            ),
            _ProgressMetric(
              value: '${summary.practiceDaysThisMonth}',
              label: 'Practice days',
            ),
            _ProgressMetric(
              value: '${summary.streakDays}',
              label: 'Current streak',
            ),
            _ProgressMetric(
              value: '${summary.collectionsStartedCount}',
              label: 'Collections started',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Memory categories',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (categories.isEmpty)
          const Text('Add categories to see your memory library grouped here.')
        else
          for (final entry in categories)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.label_outline_rounded),
              title: Text(entry.key),
              trailing: Text(
                '${entry.value} ${entry.value == 1 ? 'verse' : 'verses'}',
              ),
            ),
        if (summary.recentActivity.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Recent activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final event in summary.recentActivity)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded),
              title: Text(_reviewModeLabel(event.mode)),
              subtitle: Text(event.completedLocalDate),
              trailing: Text(_reviewRatingLabel(event.rating)),
            ),
        ],
      ],
    );
  }
}

class _SessionRecoveryCard extends StatelessWidget {
  const _SessionRecoveryCard({
    required this.draft,
    required this.onContinue,
    required this.onStartOver,
    required this.onDiscard,
  });

  final MemorySessionDraft draft;
  final VoidCallback onContinue;
  final VoidCallback onStartOver;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue your review',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${draft.completedCount} of ${draft.verseIds.length} verses completed',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onContinue,
                child: const Text('Continue'),
              ),
              OutlinedButton(
                onPressed: onStartOver,
                child: const Text('Start Over'),
              ),
              TextButton(
                onPressed: onDiscard,
                child: const Text('Discard'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyMemoryState extends StatelessWidget {
  const _EmptyMemoryState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(MemoryStatus status) {
  return switch (status) {
    MemoryStatus.newVerse => 'New',
    MemoryStatus.learning => 'Learning',
    MemoryStatus.reviewing => 'Reviewing',
    MemoryStatus.established => 'Established',
    MemoryStatus.archived => 'Archived',
  };
}

String _reviewModeLabel(MemoryExerciseMode mode) {
  return switch (mode) {
    MemoryExerciseMode.read => 'Read',
    MemoryExerciseMode.firstLetter => 'First Letter',
    MemoryExerciseMode.missingWords => 'Missing Words',
    MemoryExerciseMode.progressiveFade => 'Progressive Fade',
    MemoryExerciseMode.typeIt => 'Type It',
  };
}

String _reviewRatingLabel(MemoryReviewRating rating) {
  return switch (rating) {
    MemoryReviewRating.needsPractice => 'Practice again',
    MemoryReviewRating.almostThere => 'Needs strengthening',
    MemoryReviewRating.remembered => 'Remembered',
    MemoryReviewRating.easyToday => 'Easy today',
  };
}
