import 'package:flutter/material.dart';

import '../../../shared/state/app_state.dart';
import '../model/memory_review_event.dart';
import '../model/memory_verse.dart';
import '../services/memory_scheduler.dart';

class MemoryVerseHistoryScreen extends StatelessWidget {
  const MemoryVerseHistoryScreen({
    super.key,
    required this.verse,
  });

  final MemoryVerse verse;

  @override
  Widget build(BuildContext context) {
    final events = AppScope.of(context).memoryVerseRepo.historyFor(verse.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Review History')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            verse.reference,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(verse.translation.name.toUpperCase()),
          const SizedBox(height: 22),
          if (events.isEmpty)
            const _EmptyHistory()
          else
            for (final event in events) ...[
              _HistoryEntry(event: event),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.event});

  final MemoryReviewEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _friendlyDate(event.completedAtUtc.toLocal()),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_modeLabel(event.mode)} · ${_ratingLabel(event.rating)}',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 5),
          Text(
            _intervalChange(event),
            style: theme.textTheme.bodyMedium,
          ),
          if (event.hintCount > 0 || event.internalAccuracy != null) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (event.hintCount > 0)
                  '${event.hintCount} ${event.hintCount == 1 ? 'hint' : 'hints'}',
                if (event.internalAccuracy != null)
                  '${(event.internalAccuracy! * 100).round()}% typed recall',
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _intervalChange(MemoryReviewEvent event) {
    final before = _intervalAt(event.previousStage);
    final after = _intervalAt(event.nextStage);
    if (after > before) {
      return 'Advanced from ${_days(before)} to ${_days(after)}';
    }
    if (after < before) {
      return 'Needs strengthening · next review ${_days(after)}';
    }
    return 'Remained at ${_days(after)}';
  }

  int _intervalAt(int stage) {
    final normalized =
        stage.clamp(0, MemoryScheduler.intervalsInDays.length - 1);
    return MemoryScheduler.intervalsInDays[normalized];
  }

  String _days(int days) {
    if (days == 0) return 'today';
    return '$days ${days == 1 ? 'day' : 'days'}';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Text(
          'Your practice history will appear after the first active recall.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

String _modeLabel(MemoryExerciseMode mode) {
  return switch (mode) {
    MemoryExerciseMode.read => 'Read',
    MemoryExerciseMode.firstLetter => 'First Letter',
    MemoryExerciseMode.missingWords => 'Missing Words',
    MemoryExerciseMode.progressiveFade => 'Progressive Fade',
    MemoryExerciseMode.typeIt => 'Type It',
  };
}

String _ratingLabel(MemoryReviewRating rating) {
  return switch (rating) {
    MemoryReviewRating.needsPractice => 'Practice again',
    MemoryReviewRating.almostThere => 'Needs strengthening',
    MemoryReviewRating.remembered => 'Remembered',
    MemoryReviewRating.easyToday => 'Easy today',
  };
}

String _friendlyDate(DateTime date) {
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
