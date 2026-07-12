import 'package:flutter/material.dart';
import '../../../core/config/app_branding.dart';

import '../../../app/main_shell.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../data/bible/book_catalog.dart';
import '../../../core/utils/bible_text_sanitizer.dart';
import '../../../domain/entities/verse.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../daily_verse/view/daily_verse_screen.dart';
import '../../devotional/model/devotional_model.dart';
import '../../devotional/view/devotional_detail_screen.dart';
import '../../devotional/view/devotional_history_screen.dart';
import '../../devotional_audio/view/devotional_player_screen.dart';
import '../../notes/view/notes_screen.dart';
import '../../reading_plan/model/daily_plan_passage.dart';
import '../../reading_plan/reading_plan_service.dart';
import '../../reading_plan/view/daily_plan_reader_screen.dart';
import '../../reading_plan/view/reading_plan_screen.dart';
import '../../sermon_notes/view/sermon_notes_screen.dart';
import '../../daily_verse/model/promise_verse.dart';
import '../../daily_verse/services/promise_verse_service.dart';
import '../../daily_verse/view/promise_verse_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class WeeklyHomeStats {
  const WeeklyHomeStats({
    required this.readingDays,
    required this.chaptersRead,
    required this.devotionalsCompleted,
    required this.sermonsRecorded,
    required this.savedItems,
  });

  final int readingDays;
  final int chaptersRead;
  final int devotionalsCompleted;
  final int sermonsRecorded;
  final int savedItems;

  double get progress => (readingDays / 7).clamp(0.0, 1.0).toDouble();
}

class DailyEncouragement {
  const DailyEncouragement({
    required this.message,
    required this.reference,
    required this.body,
  });

  final String message;
  final String reference;
  final String body;
}

const _encouragements = [
  DailyEncouragement(
    message: 'Grace meets you here. Begin again in the Word.',
    reference: 'Psalm 51:12',
    body:
        'God restores the joy of salvation and renews the heart that returns to Him.',
  ),
  DailyEncouragement(
    message: 'Take heart. The Lord restores your steps.',
    reference: 'Joel 2:25',
    body:
        'Nothing surrendered to God is wasted. He is able to restore what was lost.',
  ),
  DailyEncouragement(
    message: 'You are not behind God\'s mercy.',
    reference: 'Lamentations 3:22-23',
    body:
        'His mercies are new every morning. Today is another invitation to walk with Him.',
  ),
  DailyEncouragement(
    message: 'Begin today\'s walk in the Word.',
    reference: 'Psalm 119:105',
    body:
        'The Word of God gives light for the next step, even before the whole path is visible.',
  ),
  DailyEncouragement(
    message: 'Let the Word dwell richly in you.',
    reference: 'Colossians 3:16',
    body:
        'Scripture forms the heart over time. Every faithful return to the Word matters.',
  ),
];

class _HomeScreenState extends State<HomeScreen> {
  Verse? _dailyVerse;
  bool _verseLoading = true;
  PromiseVerse? _promiseVerse;
  WeeklyHomeStats _weeklyStats = const WeeklyHomeStats(
    readingDays: 0,
    chaptersRead: 0,
    devotionalsCompleted: 0,
    sermonsRecorded: 0,
    savedItems: 0,
  );
  late final PageController _dashboardController;
  int _dashboardPage = 0;

  bool _initDone = false;

  @override
  void initState() {
    super.initState();
    _dashboardController = PageController(viewportFraction: 0.94);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadWeeklyStats();
    if (!_initDone) {
      _initDone = true;
      _loadDailyVerse();
    }
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyVerse() async {
    if (!mounted) return;
    final state = AppScope.of(context);
    try {
      final v = await state.dailyVerseService
          .getDailyVerse(translation: state.translation);
      await _loadPromiseVerse();
      if (mounted) {
        setState(() {
          _dailyVerse = v;
          _verseLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _verseLoading = false);
    }
  }

  Future<void> _loadPromiseVerse() async {
    final state = AppScope.of(context);

    final service = PromiseVerseService(
      bibleRepository: state.bibleRepo,
    );

    try {
      final promise = await service.getTodayPromise(
        translation: state.translation,
      );
      if (mounted) {
        setState(() {
          _promiseVerse = promise;
        });
      }
    } catch (_) {}
  }

  DateTime get _todayOnly {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _openDailyVerse() {
    AppRouter.push(
      context,
      DailyVerseScreen(initialVerse: _dailyVerse),
      transition: AppTransitionType.devotional,
    );
  }

  Future<void> _loadWeeklyStats() async {
    if (!mounted) return;
    final stats = _weeklyStatsFor(AppScope.of(context), ReadingPlanService());
    if (!mounted) return;
    setState(() => _weeklyStats = stats);
  }

  Future<void> _openReadingPlanOverview([DateTime? initialDate]) async {
    await AppRouter.push(
      context,
      ReadingPlanScreen(initialDate: initialDate),
      transition: AppTransitionType.slideRight,
    );
    if (!mounted) return;
    await _loadWeeklyStats();
  }

  Future<void> _openTodayCombinedReading(DailyReading reading) async {
    final passages = _dailyPlanPassages(reading);
    if (passages.isEmpty) return;

    final state = AppScope.of(context);
    if (reading.passages.isNotEmpty) {
      await state.markReadingPlanPassageOpened(reading.passages.first);
    }
    if (!mounted) return;

    await AppRouter.push(
      context,
      DailyPlanReaderScreen(
        passages: passages,
        translation: state.translation,
        onMarkComplete: () async {
          await state.markReadingPlanCompleted(passages: reading.passages);
          await _loadWeeklyStats();
        },
      ),
      transition: AppTransitionType.slideRight,
    );
    if (!mounted) return;
    await _loadWeeklyStats();
  }

  List<DailyPlanPassage> _dailyPlanPassages(DailyReading reading) {
    final parsed = <DailyPlanPassage>[];
    for (final passage in reading.passages) {
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

  void _openDevotional(
    DevotionalModel devotional, {
    required DateTime activeDate,
  }) {
    AppRouter.push(
      context,
      DevotionalDetailScreen(
        devotional: devotional,
        activeDate: activeDate,
      ),
      rootNavigator: true,
      transition: AppTransitionType.devotional,
    );
  }

  Future<void> _openDevotionalHistory() async {
    await AppRouter.push(
      context,
      const DevotionalHistoryScreen(),
      rootNavigator: true,
      transition: AppTransitionType.devotional,
    );
    if (!mounted) return;
    await _loadWeeklyStats();
  }

  void _openAudioDevotional(DevotionalModel devotional) {
    AppRouter.push(
      context,
      DevotionalPlayerScreen(devotional: devotional),
      rootNavigator: true,
      transition: AppTransitionType.devotional,
    );
  }

  Future<void> _openSermonNotes() async {
    await AppRouter.push(
      context,
      const SermonNotesScreen(),
      rootNavigator: true,
      transition: AppTransitionType.scale,
    );
    if (!mounted) return;
    await _loadWeeklyStats();
  }

  Future<void> _openSavedNotes() async {
    await AppRouter.push(
      context,
      const NotesScreen(),
      rootNavigator: true,
      transition: AppTransitionType.scale,
    );
    if (!mounted) return;
    await _loadWeeklyStats();
  }

  String _greetingTitle() {
    final hour = TimeOfDay.now().hour;
    if (hour < 5) return 'Good Night';
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String _greetingSubtitle() {
    final hour = TimeOfDay.now().hour;
    if (hour < 5) return 'Meditate on His Word';
    if (hour < 12) return AppBranding.tagline;
    if (hour < 17) return 'Walk in His Wisdom';
    if (hour < 21) return "Rest in God's Presence";
    return 'Meditate on His Word';
  }

  DailyEncouragement get _todayEncouragement {
    final dayIndex = _todayOnly.difference(DateTime(2026, 1, 1)).inDays;
    final index =
        ((dayIndex % _encouragements.length) + _encouragements.length) %
            _encouragements.length;
    return _encouragements[index];
  }

  void _showEncouragementSheet(DailyEncouragement item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF7AB6),
                  size: 34,
                ),
                const SizedBox(height: 16),
                Text(
                  item.message,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.reference,
                  style: const TextStyle(
                    color: Color(0xFFFF7AB6),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.body,
                  style: TextStyle(
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  WeeklyHomeStats _weeklyStatsFor(
    AppState state,
    ReadingPlanService readingPlanService,
  ) {
    return WeeklyHomeStats(
      readingDays: _completedDaysThisWeek(state, readingPlanService),
      chaptersRead: _completedChaptersThisWeek(state, readingPlanService),
      devotionalsCompleted: _devotionalsThisWeek(state),
      sermonsRecorded: _sermonsRecordedThisWeek(state),
      savedItems: _savedItemsThisWeek(state),
    );
  }

  int _completedDaysThisWeek(
    AppState state,
    ReadingPlanService readingPlanService,
  ) {
    final today = _todayOnly;
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    var count = 0;

    for (var offset = 0; offset < 7; offset += 1) {
      final date = weekStart.add(Duration(days: offset));
      if (date.isAfter(today)) break;
      final reading = readingPlanService.getReadingForDate(date);
      if (state.isReadingPlanCompletedForDate(date, reading.passages)) {
        count += 1;
      }
    }

    return count;
  }

  int _completedChaptersThisWeek(
    AppState state,
    ReadingPlanService readingPlanService,
  ) {
    final today = _todayOnly;
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    var count = 0;

    for (var offset = 0; offset < 7; offset += 1) {
      final date = weekStart.add(Duration(days: offset));
      if (date.isAfter(today)) break;
      final reading = readingPlanService.getReadingForDate(date);
      if (state.isReadingPlanCompletedForDate(date, reading.passages)) {
        for (final passage in reading.passages) {
          count += _chapterCountForPassage(passage);
        }
      }
    }

    return count;
  }

  int _chapterCountForPassage(String passage) {
    final chapterPart = passage.trim().split(RegExp(r'\s+')).last;
    final range = chapterPart.split('-');
    final start = int.tryParse(range.first);
    if (start == null) return 1;
    if (range.length < 2) return 1;

    final end = int.tryParse(range.last);
    if (end == null || end < start) return 1;
    return end - start + 1;
  }

  bool _isThisWeek(DateTime date) {
    final today = _todayOnly;
    final normalized = DateTime(date.year, date.month, date.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return !normalized.isBefore(weekStart) && !normalized.isAfter(today);
  }

  int _devotionalsThisWeek(AppState state) {
    return state.devotionalReadHistory.values.where(_isThisWeek).length;
  }

  int _sermonsRecordedThisWeek(AppState state) {
    try {
      return state.sermonNoteRepo
          .list()
          .where((note) =>
              note.recordedAt != null && _isThisWeek(note.recordedAt!))
          .length;
    } catch (_) {
      return 0;
    }
  }

  int _savedItemsThisWeek(AppState state) {
    try {
      return state.notesRepo
          .getAll()
          .where((note) => _isThisWeek(note.createdAt))
          .length;
    } catch (_) {
      return 0;
    }
  }

  _ReadingPlanIndicator? _readingPlanIndicator(
    AppState state,
    ReadingPlanService readingPlanService,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayReading = readingPlanService.getReadingForDate(today);
    final todayCompleted =
        state.isReadingPlanCompletedForDate(today, todayReading.passages);

    var cursor = DateTime(today.year, 1, 1);
    while (cursor.isBefore(today)) {
      final reading = readingPlanService.getReadingForDate(cursor);
      if (!state.isReadingPlanCompletedForDate(cursor, reading.passages)) {
        return _ReadingPlanIndicator(
          label: 'Missed',
          color: Color(0xFFFB7185),
          missedDate: cursor,
          missedDayNumber: readingPlanService.dayIndexForDate(cursor) + 1,
          missedFirstPassage:
              reading.passages.isEmpty ? null : reading.passages.first,
        );
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    if (!todayCompleted) {
      return const _ReadingPlanIndicator(
        label: 'Unread',
        color: Color(0xFFF59E0B),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final readingPlanService = ReadingPlanService();
    final devotionalService = state.devotionalService;
    final todayDevotional = devotionalService.getTodaysDevotional();
    final todayReading = readingPlanService.getReadingForDate(_todayOnly);
    final todayReadingDay = readingPlanService.dayIndexForDate(_todayOnly) + 1;
    final devotionalHistory = devotionalService.getHistoryDevotionals(
      readHistory: state.devotionalReadHistory,
    );
    final readingPlanIndicator =
        _readingPlanIndicator(state, readingPlanService);
    final lastReadDevotional =
        devotionalHistory.isEmpty ? null : devotionalHistory.first;
    final lastReadAt = lastReadDevotional == null
        ? null
        : state.devotionalReadHistory[lastReadDevotional.id];
    final continueDevotional = lastReadDevotional ?? todayDevotional;
    final continueDate = lastReadAt ?? _todayOnly;
    final continueProgress = lastReadAt == null
        ? 0.0
        : state.devotionalProgressForDate(continueDate);
    final showContinueDevotional = lastReadDevotional != null &&
        lastReadAt != null &&
        lastReadDevotional.id != todayDevotional.id &&
        continueProgress > 0 &&
        continueProgress < 0.999;
    final todayEncouragement = _todayEncouragement;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: [
            _HomeReveal(
              index: 0,
              child: _HomeHeader(
                title: _greetingTitle(),
                subtitle: _greetingSubtitle(),
                onSettingsTap: () => AppRouter.pushNamed(
                  context,
                  AppRouter.settingsRoute,
                  rootNavigator: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _HomeReveal(
              index: 1,
              child: _promiseVerse != null
                  ? _PromisePill(
                      promise: _promiseVerse!,
                      onTap: () {
                        AppRouter.push(
                          context,
                          PromiseVerseScreen(
                            promise: _promiseVerse!,
                          ),
                        );
                      },
                    )
                  : const SizedBox(),
            ),
            const SizedBox(height: 10),
            _HomeReveal(
              index: 2,
              child: _DailyEncouragementCard(
                item: todayEncouragement,
                onTap: () => _showEncouragementSheet(todayEncouragement),
              ),
            ),
            const SizedBox(height: 16),
            _HomeReveal(
              index: 3,
              child: _SpiritualDashboardPager(
                controller: _dashboardController,
                currentPage: _dashboardPage,
                dailyVerse: _dailyVerse,
                loading: _verseLoading,
                planStatus: readingPlanIndicator,
                reading: todayReading,
                readingDay: todayReadingDay,
                devotional: continueDevotional,
                devotionalProgress: continueProgress,
                onOpenReading: () => _openTodayCombinedReading(todayReading),
                onOpenVerse: _openDailyVerse,
                onOpenDevotional: () => _openDevotional(
                  continueDevotional,
                  activeDate: continueDate,
                ),
                onPageChanged: (page) => setState(() => _dashboardPage = page),
              ),
            ),
            const SizedBox(height: 22),
            _HomeReveal(
              index: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Continue Your Journey'),
                  const SizedBox(height: 10),
                  _QuickActionsGrid(
                    onReadBible: () => MainShell.switchTo(kTabBible),
                    onSearch: () => MainShell.switchTo(kTabSearch),
                    onTodayPlan: () => _openReadingPlanOverview(),
                    onNotes: () => MainShell.switchTo(kTabJournal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _HomeReveal(
              index: 5,
              child: _WeeklyInsightsCard(
                stats: _weeklyStats,
                onOpenChapters: () => _openReadingPlanOverview(),
                onOpenDevotionals: _openDevotionalHistory,
                onOpenSermons: _openSermonNotes,
                onOpenSaved: _openSavedNotes,
              ),
            ),
            if (showContinueDevotional) ...[
              const SizedBox(height: 22),
              _HomeReveal(
                index: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Continue Where You Left Off',
                      onSeeAll: _openDevotionalHistory,
                      seeAllLabel: 'History',
                    ),
                    const SizedBox(height: 10),
                    _ContinueDevotionalCard(
                      title: AppBranding.logosDevotional,
                      devotionalTitle: continueDevotional.title,
                      subtitle: 'Continue Reflection',
                      meta: 'Unfinished',
                      progress: continueProgress,
                      onTap: () => _openDevotional(
                        continueDevotional,
                        activeDate: continueDate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            _HomeReveal(
              index: showContinueDevotional ? 7 : 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Grow in Faith'),
                  const SizedBox(height: 10),
                  _DevotionalHistoryCard(
                    readCount: devotionalHistory.length,
                    onTap: _openDevotionalHistory,
                  ),
                  const SizedBox(height: 12),
                  _GospelTractsCard(
                    onTap: () => MainShell.switchTo(kTabTracts),
                  ),
                  const SizedBox(height: 12),
                  _SermonIntelligenceCard(
                    onTap: _openSermonNotes,
                  ),
                  const SizedBox(height: 12),
                  _AudioDevotionalCard(
                    onTap: () => _openAudioDevotional(continueDevotional),
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

class _HomeReveal extends StatefulWidget {
  const _HomeReveal({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_HomeReveal> createState() => _HomeRevealState();
}

class _HomeRevealState extends State<_HomeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.035),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.index * 40), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.title,
    required this.subtitle,
    required this.onSettingsTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final logoBackground = isLight
        ? scheme.primary.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.08);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: logoBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
          ),
          child: Image.asset(AppBranding.logoAsset),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          onPressed: onSettingsTap,
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

class _PromisePill extends StatelessWidget {
  final PromiseVerse promise;
  final VoidCallback onTap;

  const _PromisePill({
    required this.promise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withValues(alpha: 0.26),
              const Color(0xFF111827).withValues(alpha: 0.72),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.34),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Color(0xFFB794F6),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "Today's Promise • ${promise.reference}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PromiseTag(tag: promise.tag),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded,
                size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _PromiseTag extends StatelessWidget {
  final String tag;

  const _PromiseTag({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.32),
        ),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFFFF7AB6),
        ),
      ),
    );
  }
}

class _DailyEncouragementCard extends StatelessWidget {
  const _DailyEncouragementCard({
    required this.item,
    required this.onTap,
  });

  final DailyEncouragement item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEC4899).withValues(alpha: 0.18),
              const Color(0xFF111827).withValues(alpha: 0.72),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFEC4899).withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF7AB6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item.message} ${item.reference}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyInsightsCard extends StatelessWidget {
  const _WeeklyInsightsCard({
    required this.stats,
    required this.onOpenChapters,
    required this.onOpenDevotionals,
    required this.onOpenSermons,
    required this.onOpenSaved,
  });

  final WeeklyHomeStats stats;
  final VoidCallback onOpenChapters;
  final VoidCallback onOpenDevotionals;
  final VoidCallback onOpenSermons;
  final VoidCallback onOpenSaved;

  String _countLabel(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF06B6D4);
    final dayProgress = stats.progress;
    final progressLabel = '${(dayProgress * 100).round()}%';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x33116475),
            Color(0x22111427),
            Color(0x331E1B4B),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: CircularProgressIndicator(
                        value: dayProgress,
                        strokeWidth: 5,
                        color: accent,
                        backgroundColor: Colors.white.withValues(alpha: 0.10),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      progressLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Week',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats.readingDays >= 7
                          ? 'Week completed'
                          : '${stats.readingDays} of 7 reading days',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.64),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WeekMetricChip(
                icon: Icons.menu_book_rounded,
                label: _countLabel(stats.chaptersRead, 'Chapter', 'Chapters'),
                onTap: onOpenChapters,
              ),
              _WeekMetricChip(
                icon: Icons.history_edu_rounded,
                label: _countLabel(
                  stats.devotionalsCompleted,
                  'Devotional',
                  'Devotionals',
                ),
                onTap: onOpenDevotionals,
              ),
              _WeekMetricChip(
                icon: Icons.mic_rounded,
                label: _countLabel(stats.sermonsRecorded, 'Sermon', 'Sermons'),
                onTap: onOpenSermons,
              ),
              _WeekMetricChip(
                icon: Icons.bookmark_rounded,
                label: '${stats.savedItems} Saved',
                onTap: onOpenSaved,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekMetricChip extends StatelessWidget {
  const _WeekMetricChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.07),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: Colors.white.withValues(alpha: 0.70),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpiritualDashboardPager extends StatelessWidget {
  const _SpiritualDashboardPager({
    required this.controller,
    required this.currentPage,
    required this.dailyVerse,
    required this.loading,
    required this.planStatus,
    required this.reading,
    required this.readingDay,
    required this.devotional,
    required this.devotionalProgress,
    required this.onOpenReading,
    required this.onOpenVerse,
    required this.onOpenDevotional,
    required this.onPageChanged,
  });

  final PageController controller;
  final int currentPage;
  final Verse? dailyVerse;
  final bool loading;
  final _ReadingPlanIndicator? planStatus;
  final DailyReading reading;
  final int readingDay;
  final DevotionalModel devotional;
  final double devotionalProgress;
  final VoidCallback onOpenReading;
  final VoidCallback onOpenVerse;
  final VoidCallback onOpenDevotional;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 238,
          child: PageView(
            controller: controller,
            padEnds: false,
            onPageChanged: onPageChanged,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _DailyVerseDashboardCard(
                  verse: dailyVerse,
                  loading: loading,
                  onOpenVerse: onOpenVerse,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _ReadingPlanDashboardCard(
                  reading: reading,
                  readingDay: readingDay,
                  planStatus: planStatus,
                  onOpenReading: onOpenReading,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _DevotionalDashboardCard(
                  devotional: devotional,
                  progress: devotionalProgress,
                  onTap: onOpenDevotional,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(3, (index) {
            final selected = index == currentPage;
            final accent = switch (index) {
              0 => const Color(0xFF8B5CF6),
              1 => const Color(0xFFF59E0B),
              _ => const Color(0xFF6366F1),
            };

            return Semantics(
              button: true,
              selected: selected,
              label: 'Show dashboard card ${index + 1}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!selected && controller.hasClients) {
                    controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 6,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: selected ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: selected
                          ? accent
                          : Colors.white.withValues(alpha: 0.24),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DailyVerseDashboardCard extends StatelessWidget {
  const _DailyVerseDashboardCard({
    required this.verse,
    required this.loading,
    required this.onOpenVerse,
  });

  final Verse? verse;
  final bool loading;
  final VoidCallback onOpenVerse;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF8B5CF6);
    final theme = Theme.of(context);
    final reference = _compactVerseReference(verse);
    final verseText = verse == null
        ? 'The Lord is my shepherd, I shall not want.'
        : BibleTextSanitizer.clean(verse!.text);

    return _DashboardCardShell(
      accent: accent,
      gradient: const [
        Color(0x332D1B69),
        Color(0x22111427),
        Color(0x331E1B4B),
      ],
      child: loading
          ? LinearProgressIndicator(
              color: accent,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              minHeight: 4,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardEyebrow(
                  icon: Icons.menu_book_rounded,
                  label: 'DAILY VERSE',
                  accent: accent,
                ),
                const SizedBox(height: 14),
                Text(
                  reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$verseText"',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _DashboardLink(
                  label: 'Read Full Verse',
                  color: accent,
                  onTap: onOpenVerse,
                ),
              ],
            ),
    );
  }
}

class _ReadingPlanDashboardCard extends StatelessWidget {
  const _ReadingPlanDashboardCard({
    required this.reading,
    required this.readingDay,
    required this.planStatus,
    required this.onOpenReading,
  });

  final DailyReading reading;
  final int readingDay;
  final _ReadingPlanIndicator? planStatus;
  final VoidCallback onOpenReading;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF59E0B);
    final theme = Theme.of(context);
    final passages = reading.passages.take(2).toList(growable: false);

    return _DashboardCardShell(
      accent: accent,
      gradient: const [
        Color(0x332D1B00),
        Color(0x22111427),
        Color(0x331E1B4B),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardEyebrow(
            icon: Icons.check_circle_rounded,
            label: 'BIBLE IN ONE YEAR',
            accent: accent,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Day $readingDay',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (planStatus?.missedDayNumber != null) ...[
                const SizedBox(width: 10),
                _StatusPill(
                  text: 'Missed D${planStatus!.missedDayNumber}',
                  color: const Color(0xFFFF6B8A),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Today's Reading",
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.65),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          for (final passage in passages)
            Text(
              passage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          const Spacer(),
          _DashboardLink(
            label: 'Read All Passages',
            color: accent,
            onTap: onOpenReading,
          ),
        ],
      ),
    );
  }
}

class _DevotionalDashboardCard extends StatelessWidget {
  const _DevotionalDashboardCard({
    required this.devotional,
    required this.progress,
    required this.onTap,
  });

  final DevotionalModel devotional;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6366F1);
    final theme = Theme.of(context);
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();
    final isContinuing = normalizedProgress > 0 && normalizedProgress < 0.999;
    final progressPercent = (normalizedProgress * 100).round();

    return _DashboardCardShell(
      accent: accent,
      gradient: const [
        Color(0x332D1B69),
        Color(0x22111427),
        Color(0x331E3A8A),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardEyebrow(
            icon: Icons.history_edu_rounded,
            label: 'LOGOS DEVOTIONAL',
            accent: accent,
          ),
          const SizedBox(height: 16),
          Text(
            devotional.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const Spacer(),
          _DashboardLink(
            label: 'Continue Reflection',
            color: accent,
            onTap: onTap,
          ),
          const SizedBox(height: 10),
          if (isContinuing) ...[
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.56),
                ),
                const SizedBox(width: 5),
                Text(
                  '$progressPercent% complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: normalizedProgress,
              color: accent,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              minHeight: 5,
            ),
          ] else
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.56),
                ),
                const SizedBox(width: 5),
                Text(
                  '7 minutes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DashboardCardShell extends StatelessWidget {
  const _DashboardCardShell({
    required this.accent,
    required this.gradient,
    required this.child,
  });

  final Color accent;
  final List<Color> gradient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.26),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DashboardEyebrow extends StatelessWidget {
  const _DashboardEyebrow({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: accent.withValues(alpha: 0.18),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
        ),
      ],
    );
  }
}

class _DashboardLink extends StatelessWidget {
  const _DashboardLink({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, size: 15, color: color),
          ],
        ),
      ),
    );
  }
}

String _compactVerseReference(Verse? verse) {
  if (verse == null) return 'Psalm 23:1';

  final book = BookCatalog.books.firstWhere(
    (candidate) => candidate.id.toLowerCase() == verse.ref.bookId.toLowerCase(),
    orElse: () => BookCatalog.books.first,
  );
  final bookName =
      book.id == verse.ref.bookId ? book.name : _fallbackBookName(verse);
  return '$bookName ${verse.ref.chapter}:${verse.ref.verse}';
}

String _fallbackBookName(Verse verse) {
  final book = verse.book.trim();
  if (book.isEmpty) return verse.ref.bookId.replaceAll('_', ' ');
  return book
      .toLowerCase()
      .split(RegExp(r'[\s_]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onReadBible,
    required this.onSearch,
    required this.onTodayPlan,
    required this.onNotes,
  });

  final VoidCallback onReadBible;
  final VoidCallback onSearch;
  final VoidCallback onTodayPlan;
  final VoidCallback onNotes;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.82,
      children: [
        FeatureCard(
          title: 'Bible',
          subtitle: 'Continue Reading',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: onReadBible,
        ),
        FeatureCard(
          title: 'Search',
          subtitle: 'Find Scripture',
          icon: Icons.search_rounded,
          color: const Color(0xFF3B82F6),
          onTap: onSearch,
        ),
        FeatureCard(
          title: 'Plan',
          subtitle: 'Full schedule',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFFF59E0B),
          onTap: onTodayPlan,
        ),
        FeatureCard(
          title: AppBranding.logosNotes,
          subtitle: 'Record Sermons',
          icon: Icons.edit_note_rounded,
          color: const Color(0xFF14B8A6),
          onTap: onNotes,
        ),
      ],
    );
  }
}

class _ContinueDevotionalCard extends StatelessWidget {
  const _ContinueDevotionalCard({
    required this.title,
    required this.devotionalTitle,
    required this.subtitle,
    required this.meta,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final String devotionalTitle;
  final String subtitle;
  final String meta;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = const Color(0xFF8B5CF6);
    final progressValue = progress.clamp(0.0, 1.0);
    final progressLabel = progressValue <= 0
        ? 'Ready'
        : '${(progressValue * 100).round()}% complete';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x332D1B69),
              Color(0x22111427),
              Color(0x331E1B4B),
            ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            const _IconBadge(
              icon: Icons.history_edu_rounded,
              color: Color(0xFF8B5CF6),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Text(
                        progressLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    devotionalTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFC4B5FD),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.60),
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: accent.withValues(alpha: 0.72),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _ReadingPlanIndicator {
  const _ReadingPlanIndicator({
    required this.label,
    required this.color,
    this.missedDate,
    this.missedDayNumber,
    this.missedFirstPassage,
  });

  final String label;
  final Color color;
  final DateTime? missedDate;
  final int? missedDayNumber;
  final String? missedFirstPassage;
}

class _DevotionalHistoryCard extends StatelessWidget {
  const _DevotionalHistoryCard({
    required this.readCount,
    required this.onTap,
  });

  final int readCount;
  final VoidCallback onTap;

  String get _meta {
    if (readCount <= 0) return 'Past reflections appear here';
    if (readCount == 1) return '1 reflection saved';
    return '$readCount reflections saved';
  }

  @override
  Widget build(BuildContext context) {
    return _GlassExploreCard(
      title: 'Devotional History',
      subtitle: 'LOGOS reflections',
      meta: _meta,
      icon: Icons.history_rounded,
      accent: const Color(0xFF6366F1),
      gradient: const [
        Color(0x332D1B69),
        Color(0x22111427),
      ],
      onTap: onTap,
    );
  }
}

class _GospelTractsCard extends StatelessWidget {
  const _GospelTractsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassExploreCard(
      title: 'Gospel Tracts',
      subtitle: 'Share the Gospel',
      meta: 'Create and send beautiful tracts',
      icon: Icons.ios_share_rounded,
      accent: const Color(0xFF8B5CF6),
      gradient: const [
        Color(0x332D1B69),
        Color(0x22111427),
      ],
      onTap: onTap,
    );
  }
}

class _SermonIntelligenceCard extends StatelessWidget {
  const _SermonIntelligenceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassExploreCard(
      title: 'Sermon Intelligence',
      subtitle: 'Record • Transcribe • AI',
      meta: 'Capture notes and sermon insight',
      icon: Icons.auto_awesome_rounded,
      accent: const Color(0xFF06B6D4),
      gradient: const [
        Color(0x33116475),
        Color(0x220B1120),
      ],
      onTap: onTap,
    );
  }
}

class _AudioDevotionalCard extends StatelessWidget {
  const _AudioDevotionalCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassExploreCard(
      title: 'Audio Devotional',
      subtitle: 'Listen & Reflect',
      meta: 'Guided Scripture, prayer, and journaling',
      icon: Icons.headphones_rounded,
      accent: const Color(0xFFEC4899),
      gradient: const [
        Color(0x334C1238),
        Color(0x22111427),
      ],
      onTap: onTap,
    );
  }
}

class _GlassExploreCard extends StatelessWidget {
  const _GlassExploreCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.icon,
    required this.accent,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String meta;
  final IconData icon;
  final Color accent;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(
            color: accent.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.14),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.95),
                    accent.withValues(alpha: 0.35),
                  ],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: accent.withValues(alpha: 0.72),
            ),
          ],
        ),
      ),
    );
  }
}
