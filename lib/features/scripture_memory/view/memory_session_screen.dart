import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/reading_text_scale.dart';
import '../model/memory_review_event.dart';
import '../model/memory_schedule.dart';
import '../model/memory_session_draft.dart';
import '../model/memory_verse.dart';
import '../repository/memory_verse_repository.dart';
import '../services/memory_exercise_generator.dart';
import '../services/memory_text_comparator.dart';
import '../services/progressive_fade_generator.dart';
import '../services/typed_recall_controller.dart';

class MemorySessionScreen extends StatefulWidget {
  const MemorySessionScreen({
    super.key,
    required this.verses,
    this.draft,
  });

  final List<MemoryVerse> verses;
  final MemorySessionDraft? draft;

  @override
  State<MemorySessionScreen> createState() => _MemorySessionScreenState();
}

class _MemorySessionScreenState extends State<MemorySessionScreen>
    with WidgetsBindingObserver {
  static const _generator = MemoryExerciseGenerator();
  static const _fadeGenerator = ProgressiveFadeGenerator();

  final _typedController = TextEditingController();
  MemoryVerseRepository? _repository;
  MemorySessionDraft? _draft;
  TypedRecallController? _typedRecall;
  MemoryComparisonResult? _comparison;
  ProgressiveFadeStep? _fadeStep;
  DateTime _exerciseStartedAt = DateTime.now();
  int _index = 0;
  int _hintCount = 0;
  bool _initialized = false;
  bool _preparedCurrent = false;
  bool _revealed = false;
  bool _saving = false;

  bool get _complete => _initialized && _index >= widget.verses.length;
  MemoryVerse get _current => widget.verses[_index];

  bool get _needsReadPass {
    final status = _current.schedule.status;
    return !_preparedCurrent &&
        (status == MemoryStatus.newVerse || status == MemoryStatus.learning);
  }

  MemoryExerciseMode get _mode {
    if (_needsReadPass) return MemoryExerciseMode.read;
    final restoredMode = _draft?.results[_current.id]?.mode;
    if (restoredMode != null && restoredMode != MemoryExerciseMode.read) {
      return restoredMode;
    }
    return _generator.chooseMode(
      verse: _current,
      recentlyUsedModes:
          _repository?.recentlyUsedModes(_current.id) ?? const {},
    );
  }

  MemoryExercise get _exercise {
    final mode = _mode;
    if (mode == MemoryExerciseMode.progressiveFade) {
      final step = _fadeStep ??=
          _fadeGenerator.generate(_current.textSnapshot, level: _fadeLevel);
      return MemoryExercise(
        mode: mode,
        prompt: step.visibleText,
        answer: _current.textSnapshot,
      );
    }
    if (mode == MemoryExerciseMode.typeIt) {
      _typedRecall ??= TypedRecallController(
        expectedText: _current.textSnapshot,
        phraseWordLimit: _current.difficulty == MemoryDifficulty.easy ? 12 : 20,
      );
    }
    return _generator.build(verse: _current, mode: mode);
  }

  int get _fadeLevel {
    final base = switch (_current.difficulty) {
      MemoryDifficulty.easy => 1,
      MemoryDifficulty.normal => 2,
      MemoryDifficulty.hard => 3,
    };
    return (base + _current.schedule.stage ~/ 4).clamp(1, 4);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _draft = widget.draft;
    _index = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _repository = AppScope.of(context).memoryVerseRepo;
    unawaited(_initializeDraft());
  }

  Future<void> _initializeDraft() async {
    final repository = _repository!;
    _draft ??= await repository.startSession(
      widget.verses.map((verse) => verse.id).toList(growable: false),
    );
    if (widget.verses.isNotEmpty) {
      _hintCount = _draft!.results[widget.verses.first.id]?.hintCount ?? 0;
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistCurrent());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_persistCurrent());
    _typedController.dispose();
    super.dispose();
  }

  void _beginActiveRecall() {
    setState(() {
      _preparedCurrent = true;
      _revealed = false;
      _resetExerciseState();
    });
  }

  Future<void> _revealWord() async {
    final step = _fadeStep;
    if (step == null || step.hiddenWordIndexes.isEmpty) return;
    setState(() {
      _fadeStep = _fadeGenerator.revealWord(_current.textSnapshot, step);
      _hintCount++;
    });
    await _persistCurrent();
  }

  Future<void> _submitTypedRecall() async {
    final controller = _typedRecall!;
    if (controller.isComplete || _typedController.text.trim().isEmpty) return;
    final result = controller.submit(_typedController.text);
    _typedController.clear();
    setState(() {
      _comparison = result;
      _revealed = controller.isComplete;
    });
    await _persistCurrent(internalAccuracy: controller.combinedAccuracy);
  }

  Future<void> _record(MemoryReviewRating rating) async {
    if (_saving || _draft == null) return;
    final exercise = _exercise;
    if (exercise.mode == MemoryExerciseMode.read) return;

    setState(() => _saving = true);
    final duration = DateTime.now().difference(_exerciseStartedAt);
    final result = MemoryDraftResult(
      memoryVerseId: _current.id,
      mode: exercise.mode,
      rating: rating,
      internalAccuracy: _typedRecall?.combinedAccuracy,
      hintCount: _hintCount,
      duration: duration,
    );
    final eventId = '${_draft!.id}:${_current.id}';
    await _repository!.recordReview(
      memoryVerseId: _current.id,
      mode: exercise.mode,
      rating: rating,
      eventId: eventId,
      internalAccuracy: result.internalAccuracy,
      hintCount: result.hintCount,
      duration: result.duration,
    );

    final results = Map<String, MemoryDraftResult>.from(_draft!.results)
      ..[_current.id] = result.copyWith(committed: true);
    _index++;
    _draft = _draft!.copyWith(
      currentIndex: results.values.where((result) => result.committed).length,
      results: results,
    );
    if (_index >= widget.verses.length) {
      await _repository!.clearSessionDraft();
    } else {
      await _repository!.saveSessionDraft(_draft!);
    }
    if (!mounted) return;
    setState(() {
      _preparedCurrent = false;
      _revealed = false;
      _saving = false;
      _resetExerciseState();
    });
  }

  Future<void> _persistCurrent({double? internalAccuracy}) async {
    if (_draft == null ||
        _repository == null ||
        _complete ||
        widget.verses.isEmpty) {
      return;
    }
    final existing = _draft!.results[_current.id];
    if (existing?.committed == true) return;
    final results = Map<String, MemoryDraftResult>.from(_draft!.results)
      ..[_current.id] = MemoryDraftResult(
        memoryVerseId: _current.id,
        mode: _mode,
        internalAccuracy: internalAccuracy ?? existing?.internalAccuracy,
        hintCount: _hintCount,
        duration: DateTime.now().difference(_exerciseStartedAt),
      );
    _draft = _draft!.copyWith(
      currentIndex: results.values.where((result) => result.committed).length,
      results: results,
    );
    await _repository!.saveSessionDraft(_draft!);
  }

  void _resetExerciseState() {
    _comparison = null;
    _fadeStep = null;
    _typedRecall = null;
    _typedController.clear();
    _hintCount = 0;
    _exerciseStartedAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _draft == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_complete) {
      return _MemorySessionComplete(reviewedCount: widget.verses.length);
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final exercise = _exercise;
    final progress = (_index + (_revealed ? 0.75 : 0.25)) /
        widget.verses.length.clamp(1, 999);

    return PopScope(
      onPopInvokedWithResult: (_, __) => unawaited(_persistCurrent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Today\'s Review'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('${_index + 1}/${widget.verses.length}'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(value: progress.clamp(0, 1).toDouble()),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                children: [
                  Text(
                    _modeLabel(exercise.mode),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_current.reference} · '
                    '${_current.translation.name.toUpperCase()}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (exercise.mode == MemoryExerciseMode.typeIt)
                    _TypedRecallArea(
                      controller: _typedController,
                      phraseNumber: (_typedRecall?.currentPhraseIndex ?? 0) + 1,
                      phraseCount: _typedRecall?.phrases.length ?? 1,
                      comparison: _comparison,
                    )
                  else
                    _PromptCard(text: exercise.prompt),
                  if (exercise.mode == MemoryExerciseMode.progressiveFade &&
                      !_revealed) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _fadeStep!.hiddenWordIndexes.isEmpty
                            ? null
                            : _revealWord,
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                        label: const Text('Reveal one word'),
                      ),
                    ),
                  ],
                  if (_revealed) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Full verse',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ReadingTextScale(
                      child: Text(
                        exercise.answer,
                        style:
                            theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  if (exercise.mode == MemoryExerciseMode.read)
                    FilledButton.icon(
                      onPressed: _beginActiveRecall,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Practice This Verse'),
                    )
                  else if (exercise.mode == MemoryExerciseMode.typeIt &&
                      !_revealed)
                    FilledButton.icon(
                      onPressed: _submitTypedRecall,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        _typedRecall == null ||
                                _typedRecall!.currentPhraseIndex + 1 >=
                                    _typedRecall!.phrases.length
                            ? 'Check Recall'
                            : 'Check Phrase',
                      ),
                    )
                  else if (!_revealed)
                    FilledButton.icon(
                      onPressed: () => setState(() => _revealed = true),
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('Reveal Verse'),
                    )
                  else
                    _RatingChoices(
                      suggested: _suggestedRating,
                      saving: _saving,
                      onSelected: _record,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  MemoryReviewRating get _suggestedRating {
    final accuracy = _typedRecall?.combinedAccuracy;
    if (accuracy == null) return MemoryReviewRating.remembered;
    if (accuracy >= 0.90) return MemoryReviewRating.remembered;
    if (accuracy >= 0.72) return MemoryReviewRating.almostThere;
    return MemoryReviewRating.needsPractice;
  }

  static String _modeLabel(MemoryExerciseMode mode) {
    return switch (mode) {
      MemoryExerciseMode.read => 'READ SLOWLY',
      MemoryExerciseMode.firstLetter => 'FIRST LETTER',
      MemoryExerciseMode.missingWords => 'MISSING WORDS',
      MemoryExerciseMode.progressiveFade => 'PROGRESSIVE FADE',
      MemoryExerciseMode.typeIt => 'TYPE IT',
    };
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: text.replaceAll(RegExp(r'_+'), 'blank'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ReadingTextScale(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypedRecallArea extends StatelessWidget {
  const _TypedRecallArea({
    required this.controller,
    required this.phraseNumber,
    required this.phraseCount,
    required this.comparison,
  });

  final TextEditingController controller;
  final int phraseNumber;
  final int phraseCount;
  final MemoryComparisonResult? comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          phraseCount > 1
              ? 'Phrase $phraseNumber of $phraseCount'
              : 'Type the verse',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Recall the words here...',
            border: OutlineInputBorder(),
          ),
        ),
        if (comparison != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              '${comparison!.feedbackTitle}\n${comparison!.feedbackMessage}',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
      ],
    );
  }
}

class _RatingChoices extends StatelessWidget {
  const _RatingChoices({
    required this.suggested,
    required this.saving,
    required this.onSelected,
  });

  final MemoryReviewRating suggested;
  final bool saving;
  final Future<void> Function(MemoryReviewRating) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How did this recall feel?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text('Suggested: ${_ratingLabel(suggested)}'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final rating in MemoryReviewRating.values)
              OutlinedButton(
                onPressed: saving ? null : () => onSelected(rating),
                child: Text(_ratingLabel(rating)),
              ),
          ],
        ),
      ],
    );
  }
}

String _ratingLabel(MemoryReviewRating rating) {
  return switch (rating) {
    MemoryReviewRating.needsPractice => 'Practice again',
    MemoryReviewRating.almostThere => 'Needs strengthening',
    MemoryReviewRating.remembered => 'Remembered',
    MemoryReviewRating.easyToday => 'Easy today',
  };
}

class _MemorySessionComplete extends StatelessWidget {
  const _MemorySessionComplete({required this.reviewedCount});

  final int reviewedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, size: 54, color: scheme.primary),
              const SizedBox(height: 18),
              Text(
                'Wonderful',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You practiced $reviewedCount '
                '${reviewedCount == 1 ? 'verse' : 'verses'} and hid '
                'God\'s Word in your heart today.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Psalm 119:11',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
