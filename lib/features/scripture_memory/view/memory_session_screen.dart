import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/reading_text_scale.dart';
import '../model/interactive_recall_result.dart';
import '../model/memory_review_event.dart';
import '../model/memory_schedule.dart';
import '../model/memory_session_draft.dart';
import '../model/memory_verse.dart';
import '../repository/memory_verse_repository.dart';
import '../services/memory_exercise_generator.dart';
import '../services/interactive_memory_exercise.dart';
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
  static const _interactiveGenerator = InteractiveMemoryExerciseGenerator();

  final _typedController = TextEditingController();
  final Map<int, TextEditingController> _blankControllers = {};
  final Map<int, FocusNode> _blankFocusNodes = {};
  final Map<int, MemoryBlankState> _blankStates = {};
  MemoryVerseRepository? _repository;
  MemorySessionDraft? _draft;
  TypedRecallController? _typedRecall;
  MemoryComparisonResult? _comparison;
  ProgressiveFadeStep? _fadeStep;
  List<InteractiveMemoryToken>? _interactiveTokens;
  Timer? _draftSaveDebounce;
  DateTime _exerciseStartedAt = DateTime.now();
  int _index = 0;
  int _hintCount = 0;
  int _checkAttemptCount = 0;
  int _correctOnFirstCheck = 0;
  int _correctAfterRetry = 0;
  bool _initialized = false;
  bool _preparedCurrent = false;
  bool _revealed = false;
  bool _interactiveComplete = false;
  bool _fullVerseRevealed = false;
  bool _saving = false;
  String? _interactiveFeedback;

  bool get _complete => _initialized && _index >= widget.verses.length;
  MemoryVerse get _current => widget.verses[_index];
  bool get _isInteractiveMode =>
      _mode == MemoryExerciseMode.missingWords ||
      _mode == MemoryExerciseMode.firstLetter;

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
    _draftSaveDebounce?.cancel();
    unawaited(_persistCurrent());
    _disposeInteractiveFields();
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

  void _ensureInteractiveState() {
    if (!_isInteractiveMode || _interactiveTokens != null) return;
    final tokens = _interactiveGenerator.build(
      verse: _current,
      mode: _mode,
    );
    final existing = _draft?.results[_current.id];
    _interactiveTokens = tokens;
    _checkAttemptCount = existing?.checkAttemptCount ?? 0;
    _correctOnFirstCheck = existing?.correctOnFirstCheck ?? 0;
    _correctAfterRetry = existing?.correctAfterRetry ?? 0;
    _fullVerseRevealed = existing?.fullVerseRevealed ?? false;
    _hintCount = existing?.hintCount ?? _hintCount;
    for (final token in tokens) {
      final index = _blankIndex(token);
      if (index == null) continue;
      final controller = TextEditingController(
        text: existing?.enteredAnswers[index] ?? '',
      );
      final focusNode = FocusNode();
      focusNode.addListener(() {
        if (!focusNode.hasFocus) _scheduleDraftSave();
      });
      _blankControllers[index] = controller;
      _blankFocusNodes[index] = focusNode;
      if (existing?.revealedBlankIndexes.contains(index) == true) {
        _blankStates[index] = MemoryBlankState.revealed;
      } else if (_checkAttemptCount > 0 && controller.text.trim().isNotEmpty) {
        _blankStates[index] = isMemoryWordCorrect(
          controller.text,
          _blankAnswer(token),
        )
            ? MemoryBlankState.correct
            : MemoryBlankState.needsReview;
      } else {
        _blankStates[index] = MemoryBlankState.unanswered;
      }
    }
    final blankCount = _blankControllers.length;
    _interactiveComplete = blankCount > 0 && _correctAfterRetry == blankCount;
  }

  Future<void> _checkInteractiveAnswers() async {
    _ensureInteractiveState();
    if (_blankControllers.isEmpty) return;
    _checkAttemptCount++;
    var correct = 0;
    int? firstNeedsReview;
    for (final token in _interactiveTokens!) {
      final index = _blankIndex(token);
      if (index == null) continue;
      final isCorrect = isMemoryWordCorrect(
        _blankControllers[index]!.text,
        _blankAnswer(token),
      );
      if (isCorrect) {
        correct++;
        if (_blankStates[index] != MemoryBlankState.revealed) {
          _blankStates[index] = MemoryBlankState.correct;
        }
      } else {
        _blankStates[index] = MemoryBlankState.needsReview;
        firstNeedsReview ??= index;
      }
    }
    if (_checkAttemptCount == 1) _correctOnFirstCheck = correct;
    _correctAfterRetry = correct;
    _interactiveComplete = correct == _blankControllers.length;
    _interactiveFeedback = _interactiveComplete
        ? 'Excellent recall. You completed every missing word.'
        : correct >= (_blankControllers.length * 0.7).ceil()
            ? 'Almost there. You remembered most of the verse.'
            : 'Wonderful start. Review the highlighted words once more.';
    setState(() {});
    if (firstNeedsReview != null) {
      _blankFocusNodes[firstNeedsReview]?.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
    await _persistCurrent(
      internalAccuracy: correct / _blankControllers.length.clamp(1, 1 << 20),
    );
  }

  Future<void> _revealInteractiveHint() async {
    _ensureInteractiveState();
    int? revealIndex;
    for (final index in _blankControllers.keys.toList()..sort()) {
      if (_blankControllers[index]!.text.trim().isEmpty ||
          _blankStates[index] == MemoryBlankState.needsReview) {
        revealIndex = index;
        break;
      }
    }
    final index = revealIndex;
    if (index == null) return;
    final token = _interactiveTokens!.firstWhere(
      (token) => _blankIndex(token) == index,
    );
    setState(() {
      _blankControllers[index]!.text = _blankAnswer(token);
      _blankStates[index] = MemoryBlankState.revealed;
      _hintCount++;
      _interactiveFeedback = 'One word is revealed. Keep recalling the rest.';
    });
    await _persistCurrent();
  }

  Future<void> _revealInteractiveVerse() async {
    _ensureInteractiveState();
    for (final token in _interactiveTokens!) {
      final index = _blankIndex(token);
      if (index == null) continue;
      _blankControllers[index]!.text = _blankAnswer(token);
      _blankStates[index] = MemoryBlankState.revealed;
    }
    setState(() {
      _hintCount++;
      _fullVerseRevealed = true;
      _revealed = true;
      _interactiveFeedback =
          'Read the full verse slowly. This remains a learning exposure until you choose how to continue.';
    });
    await _persistCurrent();
  }

  void _tryInteractiveAgain() {
    setState(() {
      for (final entry in _blankControllers.entries) {
        entry.value.clear();
        _blankStates[entry.key] = MemoryBlankState.unanswered;
      }
      _revealed = false;
      _interactiveComplete = false;
      _checkAttemptCount = 0;
      _correctOnFirstCheck = 0;
      _correctAfterRetry = 0;
      _interactiveFeedback = 'Try the verse once more, one word at a time.';
    });
    _blankFocusNodes[0]?.requestFocus();
    _scheduleDraftSave();
  }

  void _rateAfterFullReveal() {
    setState(() {
      _interactiveComplete = true;
      _interactiveFeedback =
          'Choose the confidence that honestly reflects this review.';
    });
    unawaited(_persistCurrent());
  }

  void _focusNextBlank(int currentIndex) {
    final indexes = _blankFocusNodes.keys.toList()..sort();
    final position = indexes.indexOf(currentIndex);
    if (position >= 0 && position + 1 < indexes.length) {
      _blankFocusNodes[indexes[position + 1]]?.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void _onInteractiveAnswerChanged(int index) {
    setState(() {
      _blankStates[index] = MemoryBlankState.unanswered;
      _interactiveFeedback = null;
      _interactiveComplete = false;
    });
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    _draftSaveDebounce?.cancel();
    _draftSaveDebounce = Timer(
      const Duration(milliseconds: 500),
      () => unawaited(_persistCurrent()),
    );
  }

  Future<void> _record(MemoryReviewRating rating) async {
    if (_saving || _draft == null) return;
    final exercise = _exercise;
    if (exercise.mode == MemoryExerciseMode.read) return;

    setState(() => _saving = true);
    final duration = DateTime.now().difference(_exerciseStartedAt);
    final interactiveResult =
        _isInteractiveMode ? _currentInteractiveResult(duration) : null;
    final result = MemoryDraftResult(
      memoryVerseId: _current.id,
      mode: exercise.mode,
      rating: rating,
      internalAccuracy:
          _typedRecall?.combinedAccuracy ?? interactiveResult?.accuracy,
      hintCount: _hintCount,
      duration: duration,
      enteredAnswers: _enteredAnswers,
      revealedBlankIndexes: _revealedBlankIndexes,
      checkAttemptCount: _checkAttemptCount,
      correctOnFirstCheck: _correctOnFirstCheck,
      correctAfterRetry: _correctAfterRetry,
      fullVerseRevealed: _fullVerseRevealed,
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
        enteredAnswers: _enteredAnswers,
        revealedBlankIndexes: _revealedBlankIndexes,
        checkAttemptCount: _checkAttemptCount,
        correctOnFirstCheck: _correctOnFirstCheck,
        correctAfterRetry: _correctAfterRetry,
        fullVerseRevealed: _fullVerseRevealed,
      );
    _draft = _draft!.copyWith(
      currentIndex: results.values.where((result) => result.committed).length,
      results: results,
    );
    await _repository!.saveSessionDraft(_draft!);
  }

  void _resetExerciseState() {
    _draftSaveDebounce?.cancel();
    _disposeInteractiveFields();
    _comparison = null;
    _fadeStep = null;
    _typedRecall = null;
    _interactiveTokens = null;
    _typedController.clear();
    _hintCount = 0;
    _checkAttemptCount = 0;
    _correctOnFirstCheck = 0;
    _correctAfterRetry = 0;
    _interactiveComplete = false;
    _fullVerseRevealed = false;
    _interactiveFeedback = null;
    _exerciseStartedAt = DateTime.now();
  }

  Map<int, String> get _enteredAnswers => {
        for (final entry in _blankControllers.entries)
          entry.key: entry.value.text,
      };

  Set<int> get _revealedBlankIndexes => _blankStates.entries
      .where((entry) => entry.value == MemoryBlankState.revealed)
      .map((entry) => entry.key)
      .toSet();

  InteractiveRecallResult _currentInteractiveResult(Duration duration) {
    return InteractiveRecallResult(
      totalBlanks: _blankControllers.length,
      correctOnFirstCheck: _correctOnFirstCheck,
      correctAfterRetry: _correctAfterRetry,
      hintCount: _hintCount,
      fullVerseRevealed: _fullVerseRevealed,
      duration: duration,
    );
  }

  void _disposeInteractiveFields() {
    for (final controller in _blankControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _blankFocusNodes.values) {
      focusNode.dispose();
    }
    _blankControllers.clear();
    _blankFocusNodes.clear();
    _blankStates.clear();
  }

  bool get _showRevealDecision {
    if (!_fullVerseRevealed || _interactiveComplete || _blankStates.isEmpty) {
      return false;
    }
    return _blankStates.values.every(
      (state) => state == MemoryBlankState.revealed,
    );
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
    if (_isInteractiveMode) _ensureInteractiveState();
    final progress = (_index + (_revealed ? 0.75 : 0.25)) /
        widget.verses.length.clamp(1, 999);

    return PopScope(
      onPopInvokedWithResult: (_, __) => unawaited(_persistCurrent()),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              LinearProgressIndicator(value: progress.clamp(0, 1).toDouble()),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    MediaQuery.viewInsetsOf(context).bottom + 24,
                  ),
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
                    if (_isInteractiveMode)
                      _InteractiveExerciseCard(
                        tokens: _interactiveTokens!,
                        controllers: _blankControllers,
                        focusNodes: _blankFocusNodes,
                        states: _blankStates,
                        onChanged: _onInteractiveAnswerChanged,
                        onSubmitted: _focusNextBlank,
                      )
                    else if (exercise.mode == MemoryExerciseMode.typeIt)
                      _TypedRecallArea(
                        controller: _typedController,
                        phraseNumber:
                            (_typedRecall?.currentPhraseIndex ?? 0) + 1,
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
                    if (_revealed && !_isInteractiveMode) ...[
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
                    else if (_isInteractiveMode && _interactiveComplete)
                      _RatingChoices(
                        suggested: _suggestedRating,
                        saving: _saving,
                        onSelected: _record,
                      )
                    else if (_isInteractiveMode && _showRevealDecision)
                      _RevealDecisionControls(
                        onTryAgain: _tryInteractiveAgain,
                        onRate: _rateAfterFullReveal,
                      )
                    else if (_isInteractiveMode)
                      _InteractiveControls(
                        canCheck: _blankControllers.values.any(
                          (controller) => controller.text.trim().isNotEmpty,
                        ),
                        feedback: _interactiveFeedback,
                        onCheck: _checkInteractiveAnswers,
                        onHint: _revealInteractiveHint,
                        onReveal: _revealInteractiveVerse,
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
      ),
    );
  }

  MemoryReviewRating get _suggestedRating {
    if (_isInteractiveMode) {
      return _currentInteractiveResult(
        DateTime.now().difference(_exerciseStartedAt),
      ).suggestedRating;
    }
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

int? _blankIndex(InteractiveMemoryToken token) {
  return switch (token) {
    EditableMemoryBlank(:final index) => index,
    FirstLetterBlank(:final index) => index,
    VisibleMemoryText() => null,
  };
}

String _blankAnswer(InteractiveMemoryToken token) {
  return switch (token) {
    EditableMemoryBlank(:final answer) => answer,
    FirstLetterBlank(:final remainingAnswer) => remainingAnswer,
    VisibleMemoryText() => '',
  };
}

class _InteractiveExerciseCard extends StatelessWidget {
  const _InteractiveExerciseCard({
    required this.tokens,
    required this.controllers,
    required this.focusNodes,
    required this.states,
    required this.onChanged,
    required this.onSubmitted,
  });

  final List<InteractiveMemoryToken> tokens;
  final Map<int, TextEditingController> controllers;
  final Map<int, FocusNode> focusNodes;
  final Map<int, MemoryBlankState> states;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final verseStyle = theme.textTheme.titleLarge?.copyWith(
      height: 1.45,
      fontWeight: FontWeight.w700,
    );

    return Semantics(
      label: 'Interactive verse recall',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ReadingTextScale(
          child: Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 12,
            children: [
              for (final token in tokens)
                switch (token) {
                  VisibleMemoryText(:final text) => Text(
                      text,
                      style: verseStyle,
                    ),
                  EditableMemoryBlank(
                    :final index,
                    :final answer,
                    :final trailingText,
                  ) =>
                    _InteractiveBlankField(
                      key: ValueKey('missing-word-$index'),
                      index: index,
                      expectedAnswer: answer,
                      trailingText: trailingText,
                      controller: controllers[index]!,
                      focusNode: focusNodes[index]!,
                      state: states[index] ?? MemoryBlankState.unanswered,
                      verseStyle: verseStyle,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                    ),
                  FirstLetterBlank(
                    :final index,
                    :final firstLetter,
                    :final remainingAnswer,
                    :final trailingText,
                  ) =>
                    _InteractiveBlankField(
                      key: ValueKey('first-letter-$index'),
                      index: index,
                      firstLetter: firstLetter,
                      expectedAnswer: remainingAnswer,
                      trailingText: trailingText,
                      controller: controllers[index]!,
                      focusNode: focusNodes[index]!,
                      state: states[index] ?? MemoryBlankState.unanswered,
                      verseStyle: verseStyle,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                    ),
                },
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveBlankField extends StatelessWidget {
  const _InteractiveBlankField({
    super.key,
    required this.index,
    this.firstLetter = '',
    required this.expectedAnswer,
    required this.trailingText,
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.verseStyle,
    required this.onChanged,
    required this.onSubmitted,
  });

  final int index;
  final String firstLetter;
  final String expectedAnswer;
  final String trailingText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final MemoryBlankState state;
  final TextStyle? verseStyle;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fieldWidth =
        ((expectedAnswer.runes.length * 13.0) + 32).clamp(72.0, 180.0);
    final borderColor = switch (state) {
      MemoryBlankState.correct => scheme.tertiary,
      MemoryBlankState.needsReview => scheme.secondary,
      MemoryBlankState.revealed => scheme.primary,
      MemoryBlankState.unanswered => scheme.outline,
    };
    final statusIcon = switch (state) {
      MemoryBlankState.correct => Icons.check_circle_rounded,
      MemoryBlankState.needsReview => Icons.edit_rounded,
      MemoryBlankState.revealed => Icons.lightbulb_rounded,
      MemoryBlankState.unanswered => null,
    };

    return Semantics(
      textField: true,
      label: firstLetter.isEmpty
          ? 'Missing word ${index + 1}'
          : 'Complete word ${index + 1}, beginning with $firstLetter',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (firstLetter.isNotEmpty) Text(firstLetter, style: verseStyle),
          SizedBox(
            width: fieldWidth,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => onChanged(index),
              onSubmitted: (_) => onSubmitted(index),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: scheme.primary, width: 2),
                ),
                suffixIcon: statusIcon == null
                    ? null
                    : Icon(statusIcon, size: 17, color: borderColor),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 26,
                  minHeight: 26,
                ),
              ),
            ),
          ),
          if (trailingText.isNotEmpty) Text(trailingText, style: verseStyle),
        ],
      ),
    );
  }
}

class _InteractiveControls extends StatelessWidget {
  const _InteractiveControls({
    required this.canCheck,
    required this.feedback,
    required this.onCheck,
    required this.onHint,
    required this.onReveal,
  });

  final bool canCheck;
  final String? feedback;
  final Future<void> Function() onCheck;
  final Future<void> Function() onHint;
  final Future<void> Function() onReveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (feedback != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              feedback!,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
          ),
          const SizedBox(height: 14),
        ],
        FilledButton.icon(
          onPressed: canCheck ? onCheck : null,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Check Answers'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onHint,
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: const Text('Hint'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton.icon(
                onPressed: onReveal,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Reveal Verse'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RevealDecisionControls extends StatelessWidget {
  const _RevealDecisionControls({
    required this.onTryAgain,
    required this.onRate,
  });

  final VoidCallback onTryAgain;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            'The full verse is visible for learning. Try active recall again, '
            'or continue to an honest review rating.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onTryAgain,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Try Again'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRate,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('I\'m Ready to Rate This Review'),
        ),
      ],
    );
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
