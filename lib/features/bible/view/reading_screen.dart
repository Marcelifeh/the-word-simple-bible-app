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
          pauseAfter: const Duration(seconds: 1)),
      ...verses.map((v) => NarrationSegment(
          id: v.ref.verse.toString(),
          text: v.text,
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

class _ReadingScreenState extends State<ReadingScreen> {
  late int _currentChapter;
  late Book _currentBook;
  late ScrollController _scrollController;
  final Map<int, GlobalKey> _verseKeys = <int, GlobalKey>{};
  bool _didScroll = false;

  // Caching the future to prevent re-fetching on theme changes
  Future<List<Verse>>? _chapterFuture;
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

      _chapterFuture = _loadChapterWithFallback(state);
    }

    return Scaffold(
      body: FutureBuilder<List<Verse>>(
        future: _chapterFuture,
        builder: (context, snapshot) {
          try {
            if (snapshot.hasData) {
              _currentVerses = snapshot.data;
            }

            final verses = snapshot.data ?? _currentVerses ?? const <Verse>[];
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
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _chapterFuture =
                                    _loadChapterWithFallback(state);
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
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

              final offlineOnly = Env.bibleApiUrl == null;
              final message = offlineOnly
                  ? 'This chapter isn\'t bundled offline for ${state.translation.label}.\n\nAdd the chapter assets or run with an API.'
                  : 'No verses found for this chapter in ${state.translation.label}.\n\nIf you\'re using the API, check the server has this translation/book/chapter.';
              return _buildReaderScrollView(
                context,
                state,
                slivers: [
                  _buildStateSliver(
                    context,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(message, textAlign: TextAlign.center),
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
                ? '${verses.first.ref.canonicalId}-${verses.length}'
                : '${_currentBook.id}-$_currentChapter-${state.translation.id}';

            return _buildReaderScrollView(
              context,
              state,
              slivers: [
                if (isWaiting)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(minHeight: 2),
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
          DropdownButtonHideUnderline(
            child: DropdownButton<BibleTranslation>(
              value: state.translation,
              isDense: true,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 11, color: foregroundColor),
              icon: Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: foregroundColor,
              ),
              onChanged: (t) {
                if (t == null) return;
                if (t.isLicensed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${t.label} requires licensed data.')),
                  );
                  return;
                }
                state.setTranslation(t);
              },
              items: BibleTranslation.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        t.label,
                        style: TextStyle(color: foregroundColor),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
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

  Future<List<Verse>> _loadChapterWithFallback(AppState state) async {
    try {
      final verses = await state.bibleRepo.loadChapter(
          translation: state.translation,
          bookId: _currentBook.id,
          chapter: _currentChapter);
      if (verses.isNotEmpty) {
        state.setLastRead(LastReadRef(
          bookId: _currentBook.id,
          bookName: _currentBook.name,
          chapter: _currentChapter,
          verse:
              1, // Defaulting to verse 1, could be enhanced with ItemPositionsListener later
        ));
        _preloadNextChapter(state);
        return verses;
      }

      // Fallback if primary returned empty (e.g. API missing data)
      debugPrint('Primary repo returned empty, trying fallback asset repo...');
      return await state.assetBibleRepo.loadChapter(
          translation: state.translation,
          bookId: _currentBook.id,
          chapter: _currentChapter);
    } catch (e) {
      debugPrint('Primary repo failed ($e), trying fallback asset repo...');
      try {
        // Fallback if primary threw exception (e.g. network error)
        final fallbackVerses = await state.assetBibleRepo.loadChapter(
            translation: state.translation,
            bookId: _currentBook.id,
            chapter: _currentChapter);
        if (fallbackVerses.isNotEmpty) {
          state.setLastRead(LastReadRef(
            bookId: _currentBook.id,
            bookName: _currentBook.name,
            chapter: _currentChapter,
            verse: 1,
          ));
          _preloadNextChapter(state);
          return fallbackVerses;
        }
      } catch (e2) {
        debugPrint('Asset fallback failed: $e2');
      }

      rethrow; // Rethrow original error if we can't handle it
    }
  }

  void _preloadNextChapter(AppState state) {
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
            'assets/data/bibles/${state.translation.id}/$nBookId/$nextCh.json';
        if (!state.assetBibleRepo.isChapterCached(nextPath)) {
          unawaited(_preloadChapterWithFallback(
            state,
            bookId: nBookId,
            chapter: nextCh,
          ));
        }
      });
    }
  }

  Future<void> _preloadChapterWithFallback(
    AppState state, {
    required String bookId,
    required int chapter,
  }) async {
    try {
      final verses = await state.bibleRepo.loadChapter(
        translation: state.translation,
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
        translation: state.translation,
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
    required this.motionProfile,
    this.glowToken,
  });

  final Verse verse;
  final String bookName;
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
        translation: state.translation,
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
    final verseLabel = '${ref.verse}';
    final verseLabelStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.amber,
          fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) *
              state.fontScale,
          fontWeight: FontWeight.bold,
          height: 1.2,
        );
    final isFallback = widget.verse.isFallback;
    final verseTextStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) *
              state.fontScale,
          fontWeight: isFallback ? FontWeight.normal : FontWeight.w500,
          fontStyle: isFallback ? FontStyle.italic : FontStyle.normal,
          color: isFallback ? Colors.grey : null,
          height: 1.35,
        );
    final explanationTextStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize:
                  (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) *
                      state.fontScale,
            );

    // Spacing for the verse number inside Text.rich
    const double numberWidth = 38.0;
    const double gapWidth = 4.0;

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
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            baseline: TextBaseline.alphabetic,
                            alignment: PlaceholderAlignment.baseline,
                            child: SizedBox(
                              width: numberWidth + gapWidth,
                              child: Text(
                                verseLabel,
                                style: verseLabelStyle,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: verseText,
                            style: verseTextStyle,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.justify,
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (loading) const LinearProgressIndicator(),
                        if (!loading)
                          VerseInsightPanel(
                            rawText: (explanation != null &&
                                    explanation!.trim().isNotEmpty)
                                ? explanation!
                                : ((Env.commentaryApiUrl ?? Env.bibleApiUrl) ==
                                        null
                                    ? 'Understanding: No verse insight is bundled offline for this verse.'
                                    : 'Understanding: No verse insight available right now. Check the commentary API connection.'),
                            accentColor: Theme.of(context).colorScheme.primary,
                            baseTextStyle: explanationTextStyle,
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Save',
                              icon: Icon(state.favoritesRepo.isFavorite(
                                      translation: state.translation, ref: ref)
                                  ? Icons.star
                                  : Icons.star_border),
                              onPressed: () async {
                                final display =
                                    '${widget.bookName} ${ref.chapter}:${ref.verse}';
                                try {
                                  await state.favoritesRepo.toggle(
                                      translation: state.translation,
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
                                      .getVerseAudioUrl(state.translation, ref);
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
