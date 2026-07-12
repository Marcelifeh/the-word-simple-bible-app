import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/bible_text_sanitizer.dart';
import '../../../core/utils/env.dart';
import '../../../domain/entities/bible_translation.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/verse.dart';
import '../../../data/bible/book_catalog.dart';
import '../../../shared/bible/bible_text.dart';
import '../../../shared/bible/bible_translation_dropdown.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/verse_insight_panel.dart';
import '../../notes/model/verse_note.dart';
import '../../../core/narration/contracts/narratable_content.dart';
import '../../../core/narration/models/narration_segment.dart';
import '../../../core/narration/models/narration_state.dart';
import '../../../core/narration/services/narration_controller.dart';

class NarratableChapter implements NarratableContent {
  final Book book;
  final int chapter;
  final List<Verse> verses;

  NarratableChapter(this.book, this.chapter, this.verses);

  @override
  List<NarrationSegment> get narrationSegments {
    return [
      NarrationSegment(
          id: 'intro',
          text: '${book.name} chapter $chapter',
          reference: '${book.name} $chapter',
          pauseAfter: const Duration(seconds: 1)),
      ...verses.map((v) => NarrationSegment(
          id: v.ref.verse.toString(),
          text: BibleTextSanitizer.clean(v.text),
          reference: '${book.name} $chapter:${v.ref.verse}',
          pauseAfter: const Duration(milliseconds: 500)))
    ];
  }
}

class ReadingScreen extends StatefulWidget {
  const ReadingScreen(
      {super.key,
      required this.book,
      required this.chapter,
      this.initialVerse,
      this.openNoteEditorOnLoad = false});

  final Book book;
  final int chapter;
  final int? initialVerse;
  final bool openNoteEditorOnLoad;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

enum _ReaderMotionMode {
  standard,
  immersive,
}

class _ReaderMotionProfile {
  const _ReaderMotionProfile({
    required this.appBarHeight,
    required this.appBarBackgroundAlpha,
    required this.appBarForegroundAlpha,
    required this.glowFillAlpha,
    required this.glowBorderAlpha,
    required this.glowDuration,
  });

  final double appBarHeight;
  final double appBarBackgroundAlpha;
  final double appBarForegroundAlpha;
  final double glowFillAlpha;
  final double glowBorderAlpha;
  final Duration glowDuration;

  static _ReaderMotionProfile forMode(_ReaderMotionMode mode) {
    switch (mode) {
      case _ReaderMotionMode.immersive:
        return const _ReaderMotionProfile(
          appBarHeight: 72,
          appBarBackgroundAlpha: 0.28,
          appBarForegroundAlpha: 0.88,
          glowFillAlpha: 0.15,
          glowBorderAlpha: 0.28,
          glowDuration: Duration(milliseconds: 1400),
        );
      case _ReaderMotionMode.standard:
        return const _ReaderMotionProfile(
          appBarHeight: 84,
          appBarBackgroundAlpha: 0.82,
          appBarForegroundAlpha: 1,
          glowFillAlpha: 0.12,
          glowBorderAlpha: 0.22,
          glowDuration: Duration(milliseconds: 1200),
        );
    }
  }
}

class _ChapterLoadResult {
  const _ChapterLoadResult({
    required this.verses,
    required this.requestedTranslation,
    required this.effectiveTranslation,
  });

  final List<Verse> verses;
  final BibleTranslation requestedTranslation;
  final BibleTranslation effectiveTranslation;

  bool get usedFallback => requestedTranslation != effectiveTranslation;
}

class _ReadingScreenState extends State<ReadingScreen> {
  late int _currentChapter;
  late Book _currentBook;
  late ScrollController _scrollController;
  final Map<int, GlobalKey> _verseKeys = <int, GlobalKey>{};
  bool _didScroll = false;

  // Caching the future to prevent re-fetching on theme changes
  Future<_ChapterLoadResult>? _chapterFuture;
  _ChapterLoadResult? _currentLoadResult;
  int? _lastChapter;
  BibleTranslation? _lastTranslation;
  String? _lastBookId;
  NarrationController? _narrationController;

  // Narration – sequential loop approach (no stream listener)
  int? _narrationIndex;
  List<Verse>? _currentVerses;
  bool _autoNarrateNextChapter = false; // flag to auto-start after chapter load
  int? _focusedVerseNumber;
  int _focusHighlightToken = 0;
  bool _hasRequestedInitialNoteEditor = false;
  bool _showFallbackBanner = true;

  _ReaderMotionMode get _motionMode => _isNarratingCurrentChapter()
      ? _ReaderMotionMode.immersive
      : _ReaderMotionMode.standard;

  _ReaderMotionProfile get _motionProfile =>
      _ReaderMotionProfile.forMode(_motionMode);

  bool _isNarratingCurrentChapter() {
    if (!mounted) return false;
    final controller = AppScope.of(context).narrationController;
    final session = controller.currentSession;
    return session != null &&
        session.status != NarrationStatus.idle &&
        session.status != NarrationStatus.error &&
        session.id == '${_currentBook.id}_$_currentChapter';
  }

  void _onNarrationChanged() {
    if (!mounted) return;
    final controller = _narrationController;
    if (controller == null) return;
    setState(() {
      if (_isNarratingCurrentChapter()) {
        final syncState = controller.syncState.value;
        final verseNum = int.tryParse(syncState.segmentId ?? '');
        if (verseNum != null && verseNum != _narrationIndex) {
          _narrationIndex = verseNum;
          if (syncState.autoScroll) {
            _attemptScrollToVerse(
              verseNum,
              highlightOnSuccess: controller.preferences.highlightVerses,
            );
          } else if (controller.preferences.highlightVerses) {
            _focusedVerseNumber = verseNum;
            _focusHighlightToken++;
          }
        }
      } else {
        _narrationIndex = null;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context).narrationController;
    if (!identical(_narrationController, controller)) {
      _narrationController?.syncState.removeListener(_onNarrationChanged);
      _narrationController = controller;
      _narrationController?.syncState.addListener(_onNarrationChanged);
    }
  }

  @override
  void didUpdateWidget(covariant ReadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset scroll flag if chapter or initialVerse changes
    if (oldWidget.chapter != widget.chapter ||
        oldWidget.book.id != widget.book.id ||
        oldWidget.initialVerse != widget.initialVerse) {
      _currentChapter = widget.chapter;
      _currentBook = widget.book;
      _didScroll = false;
      _chapterFuture = null;
      _autoNarrateNextChapter = false; // Reset on manual navigation
      _focusedVerseNumber = null;
      _currentLoadResult = null;
      _showFallbackBanner = true;
      _resetReaderAnchors();
      _jumpToTopSoon();
      // Stop narration if active when changing chapter
      if (_narrationIndex != null) {
        debugPrint(
            'ReadingScreen: Chapter changed, stopping current narration');
        _stopNarration();
      }
    }

    if (oldWidget.openNoteEditorOnLoad != widget.openNoteEditorOnLoad ||
        oldWidget.initialVerse != widget.initialVerse) {
      _hasRequestedInitialNoteEditor = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapter;
    _currentBook = widget.book;
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _narrationController?.syncState.removeListener(_onNarrationChanged);
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyForVerse(int verseNumber) {
    return _verseKeys.putIfAbsent(
      verseNumber,
      () => GlobalKey(debugLabel: 'verse_$verseNumber'),
    );
  }

  void _resetReaderAnchors() {
    _verseKeys.clear();
  }

  void _jumpToTopSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Future<void> _attemptScrollToVerse(int verseNum,
      {int attempts = 8,
      int? itemCount,
      bool highlightOnSuccess = false}) async {
    if (verseNum <= 0) return;
    if (itemCount != null && itemCount <= 0) return;
    final targetVerse =
        itemCount != null ? verseNum.clamp(1, itemCount) : verseNum;
    for (var i = 0; i < attempts; i++) {
      final renderObject =
          _verseKeys[targetVerse]?.currentContext?.findRenderObject();
      if (renderObject != null) {
        try {
          final viewport = RenderAbstractViewport.of(renderObject);
          if (!_scrollController.hasClients) {
            await Future.delayed(const Duration(milliseconds: 120));
            continue;
          }

          debugPrint(
              'ReadingScreen: attempt ${i + 1} scrolling to verse $targetVerse');
          final reveal = viewport.getOffsetToReveal(renderObject, 0.1).offset;
          final targetOffset = reveal.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          );
          await _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
          if (!mounted) return;
          _didScroll = true;
          if (highlightOnSuccess) {
            setState(() {
              _focusedVerseNumber = targetVerse;
              _focusHighlightToken++;
            });
          }
          return;
        } catch (e) {
          debugPrint('ReadingScreen: scroll attempt failed (try ${i + 1}): $e');
        }
      }
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    // Check if we need to reload the chapter
    if (_chapterFuture == null ||
        _lastTranslation != state.translation ||
        _lastBookId != _currentBook.id ||
        _lastChapter != _currentChapter) {
      _lastTranslation = state.translation;
      _lastBookId = _currentBook.id;
      _lastChapter = _currentChapter;
      _showFallbackBanner = true;

      _chapterFuture = _loadChapterWithFallback(state);
    }

    return Scaffold(
      body: FutureBuilder<_ChapterLoadResult>(
        future: _chapterFuture,
        builder: (context, snapshot) {
          try {
            if (snapshot.hasData) {
              _currentLoadResult = snapshot.data;
              _currentVerses = snapshot.data!.verses;
            }

            final loadResult = snapshot.data ?? _currentLoadResult;
            final verses =
                loadResult?.verses ?? _currentVerses ?? const <Verse>[];
            final effectiveTranslation =
                loadResult?.effectiveTranslation ?? state.translation;
            final hasVerses = verses.isNotEmpty;
            final isWaiting =
                snapshot.connectionState == ConnectionState.waiting;

            if (snapshot.hasError) {
              final errorMsg = snapshot.error.toString();
              debugPrint('ReadingScreen: FutureBuilder error: $errorMsg');
              return _buildReaderScrollView(
                context,
                state,
                slivers: [
                  _buildStateSliver(
                    context,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.orange),
                          const SizedBox(height: 16),
                          Text(
                            'Unable to load verses.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Details: $errorMsg',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          _ReaderRecoveryActions(
                            onSwitchToEnglish: () =>
                                _switchToEnglishFallback(state),
                            onChooseTranslation: () =>
                                _showTranslationChooser(context, state),
                            onRetry: () => _retryChapterLoad(state),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            if (!hasVerses) {
              if (isWaiting) {
                return _buildReaderScrollView(
                  context,
                  state,
                  slivers: const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                );
              }

              return _buildReaderScrollView(
                context,
                state,
                slivers: [
                  _buildStateSliver(
                    context,
                    child: _MissingChapterRecovery(
                      translation: state.translation,
                      bookName: _currentBook.name,
                      chapter: _currentChapter,
                      onSwitchToEnglish: () => _switchToEnglishFallback(state),
                      onChooseTranslation: () =>
                          _showTranslationChooser(context, state),
                      onRetry: () => _retryChapterLoad(state),
                    ),
                  ),
                ],
              );
            }

            // Auto-start narration if we transitioned from previous chapter automatically
            if (!isWaiting && _autoNarrateNextChapter) {
              _autoNarrateNextChapter = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _narrationIndex == null) {
                  _startNarration();
                }
              });
            }

            // ... (rest of the builder)

            // Try to scroll to the initial verse using index-based scrolling
            if (!isWaiting && !_didScroll && widget.initialVerse != null) {
              final int v = widget.initialVerse!;
              if (v > 0 && v <= verses.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;
                  // small delay to ensure list rendered
                  await Future.delayed(const Duration(milliseconds: 120));
                  try {
                    await _attemptScrollToVerse(
                      v,
                      itemCount: verses.length,
                      highlightOnSuccess: true,
                    );
                    if (widget.openNoteEditorOnLoad &&
                        !_hasRequestedInitialNoteEditor) {
                      final targetVerse = verses.cast<Verse?>().firstWhere(
                            (candidate) => candidate?.ref.verse == v,
                            orElse: () => null,
                          );
                      if (targetVerse != null) {
                        _hasRequestedInitialNoteEditor = true;
                        await Future.delayed(const Duration(milliseconds: 120));
                        if (!mounted || !context.mounted) return;
                        _showVerseNoteDialog(
                          context,
                          verse: targetVerse,
                          onSavedOrDeleted: () => setState(() {}),
                        );
                      }
                    }
                  } catch (e, st) {
                    debugPrint('ReadingScreen: scroll attempt failed: $e\n$st');
                  }
                });
              }
            }

            final chapterViewKey = verses.isNotEmpty
                ? '${verses.first.ref.canonicalId}-${verses.length}-${effectiveTranslation.id}'
                : '${_currentBook.id}-$_currentChapter-${effectiveTranslation.id}';

            return _buildReaderScrollView(
              context,
              state,
              slivers: [
                if (isWaiting)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (loadResult != null &&
                    loadResult.usedFallback &&
                    _showFallbackBanner)
                  SliverToBoxAdapter(
                    child: _TranslationFallbackBanner(
                      requestedTranslation: loadResult.requestedTranslation,
                      effectiveTranslation: loadResult.effectiveTranslation,
                      onDismiss: () {
                        setState(() => _showFallbackBanner = false);
                      },
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  sliver: SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Column(
                        key: ValueKey(chapterViewKey),
                        children: [
                          for (final verse in verses)
                            _VerseTile(
                              key: _keyForVerse(verse.ref.verse),
                              verse: verse,
                              bookName: widget.book.name,
                              translation: effectiveTranslation,
                              motionProfile: _motionProfile,
                              glowToken: _focusedVerseNumber == verse.ref.verse
                                  ? _focusHighlightToken
                                  : null,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          } catch (e, st) {
            debugPrint('ReadingScreen builder exception: $e\n$st');
            return _buildReaderScrollView(
              context,
              state,
              slivers: [
                _buildStateSliver(
                  context,
                  child: Text('Error rendering chapter: $e'),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildReaderScrollView(
    BuildContext context,
    AppState state, {
    required List<Widget> slivers,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildReaderAppBar(context, state),
        ...slivers,
      ],
    );
  }

  Widget _buildStateSliver(BuildContext context, {required Widget child}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: child),
    );
  }

  SliverAppBar _buildReaderAppBar(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final profile = _motionProfile;
    final foregroundColor = theme.colorScheme.onSurface
        .withValues(alpha: profile.appBarForegroundAlpha);

    return SliverAppBar(
      floating: true,
      snap: true,
      toolbarHeight: profile.appBarHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: theme.colorScheme.surface
          .withValues(alpha: profile.appBarBackgroundAlpha),
      foregroundColor: foregroundColor,
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_currentBook.name} $_currentChapter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: foregroundColor,
            ),
          ),
          BibleTranslationDropdown(
            translation: state.translation,
            foregroundColor: foregroundColor,
            textStyle: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: foregroundColor,
            ),
            onChanged: (t) {
              if (t.isLicensed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${t.label} requires licensed data.')),
                );
                return;
              }
              state.setTranslation(t);
            },
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _currentChapter > 1 || _isNotFirstBook()
              ? _goToPreviousChapter
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed:
              _currentChapter < _currentBook.chapterCount || _isNotLastBook()
                  ? _goToNextChapter
                  : null,
        ),
        IconButton(
          icon: Icon(_isNarratingCurrentChapter()
              ? Icons.stop_circle
              : Icons.play_circle_fill),
          onPressed: _toggleNarration,
          tooltip: _isNarratingCurrentChapter()
              ? 'Stop Narration'
              : 'Narrate Chapter',
        ),
      ],
    );
  }

  void _retryChapterLoad(AppState state) {
    setState(() {
      _chapterFuture = _loadChapterWithFallback(state);
      _currentLoadResult = null;
      _showFallbackBanner = true;
    });
  }

  void _switchToEnglishFallback(AppState state) {
    state.setTranslation(BibleTranslation.web);
    setState(() {
      _chapterFuture = null;
      _currentLoadResult = null;
      _showFallbackBanner = true;
    });
  }

  Future<void> _showTranslationChooser(
    BuildContext context,
    AppState state,
  ) async {
    final selected = await showModalBottomSheet<BibleTranslation>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Text(
                  'Choose Translation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              for (final translation in BibleTranslation.values)
                ListTile(
                  enabled: !translation.isLicensed,
                  title: Text(translation.label),
                  subtitle: translation.isLicensed
                      ? const Text('Licensed data required')
                      : null,
                  trailing: translation == state.translation
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: translation.isLicensed
                      ? null
                      : () => Navigator.of(context).pop(translation),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    state.setTranslation(selected);
    setState(() {
      _chapterFuture = null;
      _currentLoadResult = null;
      _showFallbackBanner = true;
    });
  }

  Future<_ChapterLoadResult> _loadChapterWithFallback(AppState state) async {
    final requestedTranslation = state.translation;
    final translationOrder = _chapterTranslationOrder(requestedTranslation);

    for (final candidate in translationOrder) {
      final verses = await _loadChapterForTranslation(state, candidate);
      if (_hasReadableVerses(verses)) {
        state.setLastRead(LastReadRef(
          bookId: _currentBook.id,
          bookName: _currentBook.name,
          chapter: _currentChapter,
          verse: 1,
        ));
        _preloadNextChapter(state, translation: candidate);
        return _ChapterLoadResult(
          verses: verses,
          requestedTranslation: requestedTranslation,
          effectiveTranslation: candidate,
        );
      }

      if (candidate == requestedTranslation) {
        debugPrint(
          'ReadingScreen: ${requestedTranslation.label} missing '
          '${_currentBook.name} $_currentChapter; trying English fallback.',
        );
      }
    }

    return _ChapterLoadResult(
      verses: const <Verse>[],
      requestedTranslation: requestedTranslation,
      effectiveTranslation: requestedTranslation,
    );
  }

  List<BibleTranslation> _chapterTranslationOrder(
    BibleTranslation requestedTranslation,
  ) {
    return [
      requestedTranslation,
      if (requestedTranslation != BibleTranslation.web) BibleTranslation.web,
      if (requestedTranslation != BibleTranslation.kjv) BibleTranslation.kjv,
    ];
  }

  Future<List<Verse>> _loadChapterForTranslation(
    AppState state,
    BibleTranslation translation,
  ) async {
    try {
      final verses = await state.bibleRepo.loadChapter(
        translation: translation,
        bookId: _currentBook.id,
        chapter: _currentChapter,
      );
      if (_hasReadableVerses(verses)) return verses;
    } catch (e) {
      debugPrint(
        'ReadingScreen: primary repo failed for ${translation.label} '
        '${_currentBook.name} $_currentChapter: $e',
      );
    }

    if (identical(state.bibleRepo, state.assetBibleRepo)) {
      return const <Verse>[];
    }

    try {
      final verses = await state.assetBibleRepo.loadChapter(
        translation: translation,
        bookId: _currentBook.id,
        chapter: _currentChapter,
      );
      if (_hasReadableVerses(verses)) return verses;
    } catch (e) {
      debugPrint(
        'ReadingScreen: asset repo failed for ${translation.label} '
        '${_currentBook.name} $_currentChapter: $e',
      );
    }

    return const <Verse>[];
  }

  bool _hasReadableVerses(List<Verse> verses) {
    return verses.any((verse) {
      final text = BibleTextSanitizer.clean(verse.text).trim();
      return text.isNotEmpty && !verse.isFallback;
    });
  }

  void _preloadNextChapter(
    AppState state, {
    required BibleTranslation translation,
  }) {
    if (_hasNextChapter()) {
      Future.microtask(() {
        int nextCh = _currentChapter + 1;
        String nBookId = _currentBook.id;
        if (nextCh > _currentBook.chapterCount) {
          final idx = BookCatalog.books.indexOf(_currentBook);
          if (idx >= 0 && idx < BookCatalog.books.length - 1) {
            nBookId = BookCatalog.books[idx + 1].id;
            nextCh = 1;
          }
        }
        // Guard: skip if the assetRepo already has it cached
        final nextPath =
            'assets/data/bibles/${translation.id}/$nBookId/$nextCh.json';
        if (!state.assetBibleRepo.isChapterCached(nextPath)) {
          unawaited(_preloadChapterWithFallback(
            state,
            translation: translation,
            bookId: nBookId,
            chapter: nextCh,
          ));
        }
      });
    }
  }

  Future<void> _preloadChapterWithFallback(
    AppState state, {
    required BibleTranslation translation,
    required String bookId,
    required int chapter,
  }) async {
    try {
      final verses = await state.bibleRepo.loadChapter(
        translation: translation,
        bookId: bookId,
        chapter: chapter,
      );
      if (verses.isNotEmpty) {
        return;
      }
    } catch (e) {
      debugPrint('ReadingScreen: API preload failed for $bookId $chapter: $e');
    }

    try {
      await state.assetBibleRepo.loadChapter(
        translation: translation,
        bookId: bookId,
        chapter: chapter,
      );
    } catch (e) {
      debugPrint(
          'ReadingScreen: asset preload failed for $bookId $chapter: $e');
    }
  }

  bool _isNotFirstBook() {
    final index = BookCatalog.books.indexOf(_currentBook);
    return index > 0;
  }

  bool _isNotLastBook() {
    final index = BookCatalog.books.indexOf(_currentBook);
    return index < BookCatalog.books.length - 1;
  }

  bool _hasNextChapter() {
    if (_currentChapter < _currentBook.chapterCount) return true;
    return _isNotLastBook();
  }

  void _goToPreviousChapter() {
    setState(() {
      if (_currentChapter > 1) {
        _currentChapter--;
      } else {
        final index = BookCatalog.books.indexOf(_currentBook);
        if (index > 0) {
          _currentBook = BookCatalog.books[index - 1];
          _currentChapter = _currentBook.chapterCount;
        }
      }
      _didScroll = false;
      _chapterFuture = null;
      _currentLoadResult = null;
      _showFallbackBanner = true;
      _focusedVerseNumber = null;
      _resetReaderAnchors();
      _jumpToTopSoon();
    });
  }

  void _goToNextChapter() {
    setState(() {
      if (_currentChapter < _currentBook.chapterCount) {
        _currentChapter++;
      } else {
        final index = BookCatalog.books.indexOf(_currentBook);
        if (index < BookCatalog.books.length - 1) {
          _currentBook = BookCatalog.books[index + 1];
          _currentChapter = 1;
        }
      }
      _didScroll = false;
      _chapterFuture = null;
      _currentLoadResult = null;
      _showFallbackBanner = true;
      _focusedVerseNumber = null;
      _resetReaderAnchors();
      _jumpToTopSoon();
    });
  }

  void _toggleNarration() {
    final controller = AppScope.of(context).narrationController;
    if (_isNarratingCurrentChapter()) {
      controller.stop();
    } else {
      _startNarration();
    }
  }

  void _stopNarration() {
    final controller = AppScope.of(context).narrationController;
    controller.stop();
  }

  void _startNarration() {
    final verses = _currentVerses;
    if (verses == null || verses.isEmpty) return;

    final controller = AppScope.of(context).narrationController;
    final content = NarratableChapter(_currentBook, _currentChapter, verses);
    controller.playContent(
      content,
      id: '${_currentBook.id}_$_currentChapter',
      sourceType: NarrationSourceType.bible,
      mode: controller.preferences.mode,
    );
  }
}

const List<Color> _noteColors = [
  Color(0xFFFDE047),
  Color(0xFF86EFAC),
  Color(0xFF93C5FD),
  Color(0xFFF9A8D4),
];

class _TranslationFallbackBanner extends StatelessWidget {
  const _TranslationFallbackBanner({
    required this.requestedTranslation,
    required this.effectiveTranslation,
    required this.onDismiss,
  });

  final BibleTranslation requestedTranslation;
  final BibleTranslation effectiveTranslation;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: colors.tertiaryContainer.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.tertiary.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: colors.onTertiaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${requestedTranslation.label} is unavailable for this '
                'chapter. Showing ${effectiveTranslation.label} instead.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: Icon(
                Icons.close_rounded,
                color: colors.onTertiaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingChapterRecovery extends StatelessWidget {
  const _MissingChapterRecovery({
    required this.translation,
    required this.bookName,
    required this.chapter,
    required this.onSwitchToEnglish,
    required this.onChooseTranslation,
    required this.onRetry,
  });

  final BibleTranslation translation;
  final String bookName;
  final int chapter;
  final VoidCallback onSwitchToEnglish;
  final VoidCallback onChooseTranslation;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 46,
            color: colors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '${translation.label} is not available for $bookName $chapter yet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose another translation or switch to English to keep reading.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          _ReaderRecoveryActions(
            onSwitchToEnglish: onSwitchToEnglish,
            onChooseTranslation: onChooseTranslation,
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

class _ReaderRecoveryActions extends StatelessWidget {
  const _ReaderRecoveryActions({
    required this.onSwitchToEnglish,
    required this.onChooseTranslation,
    required this.onRetry,
  });

  final VoidCallback onSwitchToEnglish;
  final VoidCallback onChooseTranslation;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: onSwitchToEnglish,
          icon: const Icon(Icons.translate_rounded),
          label: const Text('Switch to English'),
        ),
        OutlinedButton.icon(
          onPressed: onChooseTranslation,
          icon: const Icon(Icons.language_rounded),
          label: const Text('Choose Translation'),
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

void _showVerseNoteDialog(
  BuildContext context, {
  required Verse verse,
  required VoidCallback onSavedOrDeleted,
}) {
  final state = AppScope.of(context);
  final existingNote = state.notesRepo.get(verse.ref.canonicalId);
  final controller = TextEditingController(text: existingNote?.text ?? '');
  int selectedColor = existingNote?.color ?? _noteColors.first.toARGB32();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Note / Highlight'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Type your note here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Highlight Color',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _noteColors.map((color) {
                    final colorValue = color.toARGB32();
                    final isSelected = selectedColor == colorValue;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedColor = colorValue),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 16,
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.black54,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              if (existingNote != null)
                TextButton(
                  onPressed: () {
                    state.notesRepo.delete(verse.ref.canonicalId);
                    onSavedOrDeleted();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final note = VerseNote(
                    verseId: verse.ref.canonicalId,
                    text: controller.text.trim(),
                    color: selectedColor,
                    createdAt: DateTime.now(),
                  );
                  state.notesRepo.save(note);
                  onSavedOrDeleted();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _VerseTile extends StatefulWidget {
  const _VerseTile({
    super.key,
    required this.verse,
    required this.bookName,
    required this.translation,
    required this.motionProfile,
    this.glowToken,
  });

  final Verse verse;
  final String bookName;
  final BibleTranslation translation;
  final _ReaderMotionProfile motionProfile;
  final int? glowToken;

  @override
  State<_VerseTile> createState() => _VerseTileState();
}

class _VerseTileState extends State<_VerseTile> {
  String? explanation;
  bool loadedExplanation = false;
  bool loading = false;
  bool expanded = false;
  bool _focused = false;
  int? _lastGlowToken;

  @override
  void initState() {
    super.initState();
    _maybeTriggerFocusGlow(widget.glowToken);
  }

  @override
  void didUpdateWidget(covariant _VerseTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.glowToken != oldWidget.glowToken) {
      _maybeTriggerFocusGlow(widget.glowToken);
    }
  }

  void _maybeTriggerFocusGlow(int? token) {
    if (token == null || token == _lastGlowToken) return;
    _lastGlowToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _triggerFocusGlow();
      }
    });
  }

  Future<void> _triggerFocusGlow() async {
    if (!mounted) return;
    setState(() => _focused = true);
    await Future.delayed(widget.motionProfile.glowDuration);
    if (mounted) {
      setState(() => _focused = false);
    }
  }

  Future<void> _handleExpansionChange(bool nextExpanded) async {
    if (mounted) {
      setState(() => expanded = nextExpanded);
    }
    if (!nextExpanded || loadedExplanation) return;

    final state = AppScope.of(context);
    setState(() => loading = true);
    try {
      final text = await state.commentaryRepo.getOrGenerateAndStore(
        translation: widget.translation,
        ref: widget.verse.ref,
        verseText: widget.verse.text,
        bookName: widget.bookName,
      );
      if (!mounted) return;
      setState(() {
        explanation = text != null ? BibleTextSanitizer.clean(text) : null;
        loadedExplanation = true;
        loading = false;
      });
    } catch (e, st) {
      debugPrint('Failed to load explanation: $e\n$st');
      if (!mounted) return;
      setState(() {
        explanation = null;
        loadedExplanation = true;
        loading = false;
      });
    }
  }

  void _showNoteDialog(BuildContext context, Verse verse) {
    _showVerseNoteDialog(
      context,
      verse: verse,
      onSavedOrDeleted: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ref = widget.verse.ref;
    final verseText = BibleTextSanitizer.clean(widget.verse.text);
    final readingStyles = BibleReadingTextStyles.of(
      context,
      state,
      isFallback: widget.verse.isFallback,
    );

    final note = state.notesRepo.get(ref.canonicalId);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _triggerFocusGlow();
              _handleExpansionChange(!expanded);
            },
            onLongPress: () => _showNoteDialog(context, widget.verse),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              padding: BibleReadingTextStyles.verseTilePadding,
              decoration: BoxDecoration(
                color: _focused
                    ? const Color(0xFF6C63FF)
                        .withValues(alpha: widget.motionProfile.glowFillAlpha)
                    : note != null
                        ? Color(note.color).withValues(alpha: 0.25)
                        : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focused
                      ? const Color(0xFF6C63FF).withValues(
                          alpha: widget.motionProfile.glowBorderAlpha)
                      : Colors.transparent,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    // Leave space so the overlay arrow doesn't cover the text.
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
                        turns: expanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5),
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
            child: expanded
                ? Padding(
                    padding: BibleReadingTextStyles.expandedInsightPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (loading) const LinearProgressIndicator(),
                        if (!loading)
                          VerseInsightPanel(
                            rawText: (explanation != null &&
                                    explanation!.trim().isNotEmpty)
                                ? explanation!
                                : (Env.commentaryApiUrl == null
                                    ? 'Understanding: No verse insight is bundled offline for this verse.'
                                    : 'Understanding: No verse insight available right now. Check the commentary API connection.'),
                            accentColor: Theme.of(context).colorScheme.primary,
                            baseTextStyle: readingStyles.commentaryTextStyle,
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Save',
                              icon: Icon(state.favoritesRepo.isFavorite(
                                      translation: widget.translation, ref: ref)
                                  ? Icons.star
                                  : Icons.star_border),
                              onPressed: () async {
                                final display =
                                    '${widget.bookName} ${ref.chapter}:${ref.verse}';
                                try {
                                  await state.favoritesRepo.toggle(
                                      translation: widget.translation,
                                      ref: ref,
                                      display: display);
                                  await AppHaptics.favoriteToggled();
                                } catch (e, st) {
                                  debugPrint(
                                      'Failed toggling favorite: $e\n$st');
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Failed to update favorite.')));
                                  return;
                                }
                                if (!context.mounted) return;
                                unawaited(AppHaptics.noteSaved());
                                setState(() {});
                              },
                            ),
                            IconButton(
                              tooltip: 'Audio',
                              icon: const Icon(Icons.volume_up),
                              onPressed: () async {
                                try {
                                  final url = await state.audioService
                                      .getVerseAudioUrl(
                                          widget.translation, ref);
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
                                } catch (e, st) {
                                  debugPrint('Audio playback failed: $e\n$st');
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Audio playback failed.')));
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Share',
                              icon: const Icon(Icons.share),
                              onPressed: () async {
                                try {
                                  final text =
                                      '${widget.bookName} ${ref.chapter}:${ref.verse} — $verseText';
                                  await Share.share(text);
                                  await AppHaptics.shareTriggered();
                                } catch (e, st) {
                                  debugPrint('Share failed: $e\n$st');
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Failed to share verse.')));
                                }
                              },
                            ),
                          ],
                        ),
                      ],
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
