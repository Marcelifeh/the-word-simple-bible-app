import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/config/app_branding.dart';

import '../../../app/main_shell.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../data/bible/book_catalog.dart';
import '../../../core/utils/bible_text_sanitizer.dart';
import '../../../domain/entities/verse.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/home_text_scale.dart';
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
import '../../scripture_memory/model/memory_home_summary.dart';
import '../../scripture_memory/view/scripture_memory_screen.dart';
import '../../daily_verse/model/promise_verse.dart';
import '../../daily_verse/services/promise_verse_service.dart';
import '../../daily_verse/view/promise_verse_screen.dart';
import '../model/daily_encouragement.dart';
import '../services/daily_encouragement_service.dart';
import '../services/weekly_date_utils.dart';
import '../services/weekly_sermon_progress.dart';
import '../widgets/journey_action_tile.dart';
import '../activity/model/daily_faith_activity.dart';
import '../activity/model/faith_activity_type.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class WeeklyHomeStats {
  const WeeklyHomeStats({
    required this.weekStart,
    required this.nextWeekStart,
    required this.calendarDay,
    required this.readingDays,
    required this.chaptersRead,
    required this.devotionalDays,
    required this.sermonsCreated,
    required this.savedVerses,
    required this.weeklyRhythm,
    required this.todayDailyVerse,
    required this.todayPromise,
    required this.todayScriptureMemory,
  });

  /// The Sunday that opens this week (00:00 local time).
  final DateTime weekStart;

  /// The Sunday that opens the *next* week (00:00 local time).
  /// Use for half-open filtering: weekStart <= date < nextWeekStart.
  final DateTime nextWeekStart;

  /// Ordinal position in the current week: Sunday = 1 … Saturday = 7.
  final int calendarDay;

  /// Number of distinct local dates this week with completed Bible reading.
  final int readingDays;

  final int chaptersRead;
  final int devotionalDays;
  final int sermonsCreated;
  final int savedVerses;

  /// Pre-computed weekly rhythm ring value (0.0–1.0).
  /// Each calendar day contributes at most 1/7 of this total.
  final double weeklyRhythm;

  /// Whether Today's Verse screen was opened today.
  final bool todayDailyVerse;

  /// Whether Today's Promise screen was opened today.
  final bool todayPromise;

  /// Whether a Scripture Memory review was completed today.
  final bool todayScriptureMemory;

  /// The inclusive last day of the week (Saturday 00:00), for display only.
  DateTime get weekEndDate =>
      nextWeekStart.subtract(const Duration(days: 1));

  /// Fraction of days with Bible reading completed this week.
  /// Kept separate so a dedicated reading-consistency screen can use it.
  double get readingConsistency =>
      (readingDays / 7.0).clamp(0.0, 1.0);
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Verse? _dailyVerse;
  bool _verseLoading = true;
  PromiseVerse? _promiseVerse;
  // Initialised with the actual current week boundaries so the ring shows
  // the correct calendar position even before _loadWeeklyStats() completes.
  WeeklyHomeStats _weeklyStats = WeeklyHomeStats(
    weekStart: startOfSundayWeek(DateTime.now()),
    nextWeekStart: endOfSundayWeek(DateTime.now()),
    calendarDay: calendarDayOfSundayWeek(DateTime.now()),
    readingDays: 0,
    chaptersRead: 0,
    devotionalDays: 0,
    sermonsCreated: 0,
    savedVerses: 0,
    weeklyRhythm: 0.0,
    todayDailyVerse: false,
    todayPromise: false,
    todayScriptureMemory: false,
  );
  late final PageController _dashboardController;
  int _dashboardPage = 0;

  bool _initDone = false;
  DateTime? _loadedDailyContentDate;
  Timer? _dateRefreshTimer;
  static const _encouragementService = DailyEncouragementService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardController = PageController(viewportFraction: 0.94);
    _scheduleDateRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadWeeklyStats();
    final today = _todayOnly;
    if (!_initDone || _loadedDailyContentDate != today) {
      _initDone = true;
      _loadedDailyContentDate = today;
      _loadDailyVerse();
    }
  }

  @override
  void dispose() {
    _dateRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _dashboardController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _refreshForCurrentDate();
    _scheduleDateRefresh();
  }

  void _scheduleDateRefresh() {
    _dateRefreshTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
    _dateRefreshTimer = Timer(tomorrow.difference(now), () {
      if (!mounted) return;
      _refreshForCurrentDate();
      _scheduleDateRefresh();
    });
  }

  void _refreshForCurrentDate() {
    final today = _todayOnly;
    if (_loadedDailyContentDate != today) {
      _loadedDailyContentDate = today;
      unawaited(_loadDailyVerse());
    }
    unawaited(_loadWeeklyStats());
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
        history: state.promiseHistory,
      );
      await state.recordPromiseShown(
        promiseId: promise.id,
        theme: promise.tag,
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
    unawaited(
      AppScope.of(context).recordFaithActivity(FaithActivityType.dailyVerse),
    );
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

  Future<void> _openDevotional(
    DevotionalModel devotional, {
    required DateTime activeDate,
  }) async {
    AppScope.of(context).setCurrentDevotional(
      devotional,
      activeDate: activeDate,
      stage: DevotionalResumeStage.reading,
    );
    await AppRouter.push(
      context,
      DevotionalDetailScreen(
        devotional: devotional,
        activeDate: activeDate,
      ),
      rootNavigator: true,
      transition: AppTransitionType.devotional,
    );
    if (!mounted) return;
    await _loadWeeklyStats();
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

  Future<void> _openAudioDevotional(DevotionalModel devotional) async {
    final state = AppScope.of(context);
    state.setCurrentDevotional(
      devotional,
      activeDate: state.currentDevotional?.id == devotional.id
          ? state.currentDevotionalDate
          : _todayOnly,
      stage: DevotionalResumeStage.audio,
    );
    await AppRouter.push(
      context,
      DevotionalPlayerScreen(devotional: devotional),
      rootNavigator: true,
      transition: AppTransitionType.devotional,
    );
    if (!mounted) return;
    await _loadWeeklyStats();
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

  Future<void> _openScriptureMemory() async {
    await AppRouter.push(
      context,
      const ScriptureMemoryScreen(),
      rootNavigator: true,
      transition: AppTransitionType.slideUp,
    );
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

  DailyEncouragement _todayEncouragementFor(
    AppState state,
    ReadingPlanService readingPlanService,
  ) {
    final today = _todayOnly;
    final todayReading = readingPlanService.getReadingForDate(today);
    final devotionalProgress = state.devotionalProgressForDate(today);
    final hasReadToday = devotionalProgress > 0 ||
        state.readingPlanLastOpenedPassageForDate(today) != null ||
        state.readingPlanCompletedPassagesForDate(today).isNotEmpty;

    return _encouragementService.select(
      DailyEncouragementContext(
        now: DateTime.now(),
        hasReadToday: hasReadToday,
        readingPlanCompleted: state.isReadingPlanCompletedForDate(
          today,
          todayReading.passages,
        ),
        devotionalCompleted: state.isDevotionalCompletedForDate(today),
        missedTwoDays: _missedTwoRecentDays(state, readingPlanService),
        streakDays: _spiritualStreakDays(state, readingPlanService),
      ),
    );
  }

  bool _hasSpiritualActivityForDate(
    AppState state,
    ReadingPlanService readingPlanService,
    DateTime date,
  ) {
    final reading = readingPlanService.getReadingForDate(date);
    return state.devotionalProgressForDate(date) > 0 ||
        state.readingPlanLastOpenedPassageForDate(date) != null ||
        state.isReadingPlanCompletedForDate(date, reading.passages);
  }

  bool _completedSpiritualPracticeForDate(
    AppState state,
    ReadingPlanService readingPlanService,
    DateTime date,
  ) {
    final reading = readingPlanService.getReadingForDate(date);
    return state.isDevotionalCompletedForDate(date) ||
        state.isReadingPlanCompletedForDate(date, reading.passages);
  }

  bool _missedTwoRecentDays(
    AppState state,
    ReadingPlanService readingPlanService,
  ) {
    final yesterday = _todayOnly.subtract(const Duration(days: 1));
    final dayBefore = _todayOnly.subtract(const Duration(days: 2));
    if (_hasSpiritualActivityForDate(state, readingPlanService, yesterday) ||
        _hasSpiritualActivityForDate(state, readingPlanService, dayBefore)) {
      return false;
    }

    for (var offset = 3; offset <= 14; offset += 1) {
      final date = _todayOnly.subtract(Duration(days: offset));
      if (_hasSpiritualActivityForDate(state, readingPlanService, date)) {
        return true;
      }
    }
    return false;
  }

  int _spiritualStreakDays(
    AppState state,
    ReadingPlanService readingPlanService,
  ) {
    var cursor = _todayOnly;
    if (!_completedSpiritualPracticeForDate(
      state,
      readingPlanService,
      cursor,
    )) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (streak < 365 &&
        _completedSpiritualPracticeForDate(
          state,
          readingPlanService,
          cursor,
        )) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void _showEncouragementSheet(DailyEncouragement item) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _encouragementToneColor(item.tone, theme.brightness);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _encouragementToneIcon(item.tone),
                  color: accent,
                  size: 34,
                ),
                const SizedBox(height: 16),
                Text(
                  item.message,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.reference,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.body,
                  style: TextStyle(
                    height: 1.55,
                    color: scheme.onSurfaceVariant,
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
    final now = DateTime.now();
    final today = normalizeLocalDate(now);
    final weekStart = startOfSundayWeek(now);
    final nextWeekStart = endOfSundayWeek(now);
    final repo = state.faithActivityRepo;

    // Build one DailyFaithActivity for every day of the week.
    // Future days get all-false values so they contribute 0 to the ring.
    final weekDays = List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      return DailyFaithActivity(
        date: date,
        bibleReading: _hasBibleReadingOn(state, date),
        devotional: _hasDevotionalOn(state, date),
        dailyVerse: repo.hasActivityOn(FaithActivityType.dailyVerse, date),
        promise: repo.hasActivityOn(FaithActivityType.promise, date),
        scriptureMemory:
            repo.hasActivityOn(FaithActivityType.scriptureMemory, date),
        sermon: _hasSermonOn(state, date),
        saved: _hasSavedVerseOn(state, date),
      );
    });

    return WeeklyHomeStats(
      weekStart: weekStart,
      nextWeekStart: nextWeekStart,
      calendarDay: calendarDayOfSundayWeek(now),
      readingDays: _completedDaysThisWeek(state),
      chaptersRead: _completedChaptersThisWeek(state, readingPlanService),
      devotionalDays: _devotionalDaysThisWeek(state),
      sermonsCreated: _sermonsThisWeek(state),
      savedVerses: _savedItemsThisWeek(state),
      weeklyRhythm: calculateWeeklyRhythm(weekDays),
      todayDailyVerse: repo.hasActivityOn(FaithActivityType.dailyVerse, today),
      todayPromise: repo.hasActivityOn(FaithActivityType.promise, today),
      todayScriptureMemory:
          repo.hasActivityOn(FaithActivityType.scriptureMemory, today),
    );
  }

  // ── Per-day boolean helpers (used by DailyFaithActivity construction) ───

  bool _hasBibleReadingOn(AppState state, DateTime date) {
    final key = _localDateKey(date);
    return state.readingPlanCompletionActivityDates.any(
      (d) => _localDateKey(d) == key,
    );
  }

  bool _hasDevotionalOn(AppState state, DateTime date) {
    final key = _localDateKey(date);
    return state.devotionalReadHistory.values.any(
      (d) => _localDateKey(d) == key,
    );
  }

  bool _hasSermonOn(AppState state, DateTime date) {
    final key = _localDateKey(date);
    try {
      return state.sermonNoteRepo
          .list()
          .any((n) => _localDateKey(n.date) == key);
    } catch (_) {
      return false;
    }
  }

  bool _hasSavedVerseOn(AppState state, DateTime date) {
    final key = _localDateKey(date);
    try {
      return state.notesRepo
          .getAll()
          .any((n) => _localDateKey(n.createdAt) == key);
    } catch (_) {
      return false;
    }
  }

  String _localDateKey(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  // ── Aggregate weekly count helpers (for chip display) ───────────────────

  int _completedDaysThisWeek(AppState state) {
    final completedAtDates = <DateTime>[
      ...state.readingPlanCompletionActivityDates,
    ];
    return calculateBibleReadingDays(
      completedAtDates: completedAtDates,
      now: DateTime.now(),
    );
  }

  int _completedChaptersThisWeek(
    AppState state,
    ReadingPlanService readingPlanService,
  ) {
    final today = _todayOnly;
    final weekStart = startOfSundayWeek(today);
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
    return isWithinSundayWeek(date, DateTime.now());
  }

  int _devotionalDaysThisWeek(AppState state) {
    return countWeeklyDevotionalDays(
      completedDevotionalDates: state.devotionalReadHistory.values,
      now: DateTime.now(),
    );
  }

  int _sermonsThisWeek(AppState state) {
    try {
      return sermonsCapturedThisWeek(state.sermonNoteRepo.list());
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
    final todayDevotionalProgress = state.devotionalProgressForDate(_todayOnly);
    final devotionalHistory = devotionalService.getHistoryDevotionals(
      readHistory: state.devotionalReadHistory,
    );
    final readingPlanIndicator =
        _readingPlanIndicator(state, readingPlanService);
    final resumeDevotional = state.currentDevotional;
    final resumeDate = state.currentDevotionalDate ?? _todayOnly;
    final resumeProgress = state.devotionalProgressForDate(resumeDate);
    final showContinueDevotional = resumeDevotional != null &&
        resumeDevotional.id != todayDevotional.id &&
        resumeProgress > 0 &&
        resumeProgress < 0.999;
    final todayEncouragement = _todayEncouragementFor(
      state,
      readingPlanService,
    );
    return Scaffold(
      body: HomeTextScale(
        scale: state.homeTextScale,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: [
              _HomeReveal(
                index: 0,
                child: _HomeHeader(
                  title: _greetingTitle(),
                  subtitle: _greetingSubtitle(),
                  unreadNotifications:
                      state.notificationInboxRepository.unreadCount,
                  onNotificationsTap: () => AppRouter.pushNamed(
                    context,
                    AppRouter.notificationInboxRoute,
                    rootNavigator: true,
                  ),
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
                          unawaited(
                            AppScope.of(context).recordFaithActivity(
                              FaithActivityType.promise,
                            ),
                          );
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
                  devotional: todayDevotional,
                  devotionalProgress: todayDevotionalProgress,
                  isContinuingDevotional: todayDevotionalProgress > 0 &&
                      todayDevotionalProgress < 0.999,
                  onOpenReading: () => _openTodayCombinedReading(todayReading),
                  onOpenVerse: _openDailyVerse,
                  onOpenDevotional: () => _openDevotional(
                    todayDevotional,
                    activeDate: _todayOnly,
                  ),
                  onPageChanged: (page) =>
                      setState(() => _dashboardPage = page),
                ),
              ),
              const SizedBox(height: 22),
              _HomeReveal(
                index: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Continue Your Journey'),
                    const SizedBox(height: 14),
                    _JourneyRail(
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
                  onOpenDailyVerse: _openDailyVerse,
                  onOpenPromise: () {
                    if (_promiseVerse != null) {
                      unawaited(
                        AppScope.of(context).recordFaithActivity(
                          FaithActivityType.promise,
                        ),
                      );
                      AppRouter.push(
                        context,
                        PromiseVerseScreen(promise: _promiseVerse!),
                      );
                    }
                  },
                  onOpenScriptureMemory: () => AppRouter.push(
                    context,
                    const ScriptureMemoryScreen(),
                  ),
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
                        devotionalTitle: resumeDevotional.title,
                        subtitle: 'Continue Reflection',
                        meta: 'Unfinished',
                        progress: resumeProgress,
                        onTap: () => _openDevotional(
                          resumeDevotional,
                          activeDate: resumeDate,
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
                    _ScriptureMemoryCard(
                      summary: state.memoryVerseRepo.homeSummary,
                      onTap: _openScriptureMemory,
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
                      onTap: () => _openAudioDevotional(todayDevotional),
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
    required this.unreadNotifications,
    required this.onNotificationsTap,
    required this.onSettingsTap,
  });

  final String title;
  final String subtitle;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;
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
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onNotificationsTap,
              icon: const Icon(Icons.notifications_none),
              tooltip: 'Notifications',
            ),
            if (unreadNotifications > 0)
              Positioned(
                right: 4,
                top: 3,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: scheme.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onError,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF171426) : Colors.white;
    final iconColor =
        isLight ? const Color(0xFF8B5CF6) : const Color(0xFFB794F6);

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
            colors: isLight
                ? [
                    const Color(0xFFEDE5FF),
                    const Color(0xFFFFFFFF),
                  ]
                : [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.26),
                    const Color(0xFF111827).withValues(alpha: 0.72),
                  ],
          ),
          border: Border.all(
            color: const Color(0xFF8B5CF6)
                .withValues(alpha: isLight ? 0.30 : 0.34),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "Today's Promise • ${promise.reference}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PromiseTag(tag: promise.tag),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 18, color: textColor),
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
    return _FixedHomeTextScale(
      child: Container(
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
      ),
    );
  }
}

IconData _encouragementToneIcon(DailyEncouragementTone tone) {
  switch (tone) {
    case DailyEncouragementTone.grace:
      return Icons.favorite_rounded;
    case DailyEncouragementTone.peace:
      return Icons.spa_rounded;
    case DailyEncouragementTone.hope:
      return Icons.auto_awesome_rounded;
    case DailyEncouragementTone.protection:
      return Icons.shield_rounded;
    case DailyEncouragementTone.faith:
      return Icons.local_fire_department_rounded;
    case DailyEncouragementTone.prayer:
      return Icons.self_improvement_rounded;
    case DailyEncouragementTone.wisdom:
      return Icons.menu_book_rounded;
    case DailyEncouragementTone.newBeginning:
      return Icons.wb_twilight_rounded;
    case DailyEncouragementTone.celebration:
      return Icons.celebration_rounded;
    case DailyEncouragementTone.comfort:
      return Icons.volunteer_activism_rounded;
  }
}

Color _encouragementToneColor(
  DailyEncouragementTone tone,
  Brightness brightness,
) {
  final isLight = brightness == Brightness.light;
  switch (tone) {
    case DailyEncouragementTone.grace:
      return isLight ? const Color(0xFFDB2777) : const Color(0xFFFF7AB6);
    case DailyEncouragementTone.peace:
      return isLight ? const Color(0xFF0F766E) : const Color(0xFF5EEAD4);
    case DailyEncouragementTone.hope:
      return isLight ? const Color(0xFF7C3AED) : const Color(0xFFC4B5FD);
    case DailyEncouragementTone.protection:
      return isLight ? const Color(0xFF2563EB) : const Color(0xFF93C5FD);
    case DailyEncouragementTone.faith:
      return isLight ? const Color(0xFFC2410C) : const Color(0xFFFDBA74);
    case DailyEncouragementTone.prayer:
      return isLight ? const Color(0xFF6D28D9) : const Color(0xFFD8B4FE);
    case DailyEncouragementTone.wisdom:
      return isLight ? const Color(0xFF0369A1) : const Color(0xFF7DD3FC);
    case DailyEncouragementTone.newBeginning:
      return isLight ? const Color(0xFF047857) : const Color(0xFF6EE7B7);
    case DailyEncouragementTone.celebration:
      return isLight ? const Color(0xFFB45309) : const Color(0xFFFCD34D);
    case DailyEncouragementTone.comfort:
      return isLight ? const Color(0xFF9333EA) : const Color(0xFFE9D5FF);
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
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final accent = _encouragementToneColor(item.tone, theme.brightness);
    final textColor = isLight ? const Color(0xFF171426) : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: isLight
                ? [
                    accent.withValues(alpha: 0.20),
                    Color.alphaBlend(
                      accent.withValues(alpha: 0.05),
                      theme.colorScheme.surface,
                    ),
                  ]
                : [
                    accent.withValues(alpha: 0.18),
                    const Color(0xFF111827).withValues(alpha: 0.72),
                  ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: isLight ? 0.30 : 0.34),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _encouragementToneIcon(item.tone),
              color: accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item.message} ${item.reference}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: textColor,
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
    required this.onOpenDailyVerse,
    required this.onOpenPromise,
    required this.onOpenScriptureMemory,
  });

  final WeeklyHomeStats stats;
  final VoidCallback onOpenChapters;
  final VoidCallback onOpenDevotionals;
  final VoidCallback onOpenSermons;
  final VoidCallback onOpenSaved;
  final VoidCallback onOpenDailyVerse;
  final VoidCallback onOpenPromise;
  final VoidCallback onOpenScriptureMemory;

  String _countLabel(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }

  /// Formats a DateTime as e.g. "Aug 2".
  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    const accent = Color(0xFF06B6D4);
    final activityProgress = stats.weeklyRhythm;
    final calendarDay = stats.calendarDay;
    final titleColor = isLight ? const Color(0xFF172033) : Colors.white;
    final bodyColor = isLight
        ? const Color(0xFF526070)
        : Colors.white.withValues(alpha: 0.64);
    final dividerColor = accent.withValues(alpha: isLight ? 0.20 : 0.15);

    // Date-range label: "Aug 2–8"
    final dateRange =
        '${_shortDate(stats.weekStart)}–${stats.weekEndDate.day}';

    // Percentage label inside the ring
    final progressLabel = '${(activityProgress * 100).round()}%';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? const [
                  Color(0xFFE8FAFF),
                  Color(0xFFF8FBFF),
                  Color(0xFFEAF2FF),
                ]
              : const [
                  Color(0x33116475),
                  Color(0x22111427),
                  Color(0x331E1B4B),
                ],
        ),
        border:
            Border.all(color: accent.withValues(alpha: isLight ? 0.34 : 0.24)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isLight ? 0.14 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: title · date range ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _FixedHomeTextScale(
                child: Text(
                  dateRange,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: bodyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Calendar position — context only, not a progress metric
          Text(
            'Day $calendarDay of 7',
            style: theme.textTheme.bodySmall?.copyWith(
              color: bodyColor,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),
          // ── Activity ring + Weekly Activity label ───────────────────────
          Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: activityProgress,
                        strokeWidth: 5,
                        color: accent,
                        backgroundColor: isLight
                            ? const Color(0xFFCCEEF7)
                            : Colors.white.withValues(alpha: 0.10),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    _FixedHomeTextScale(
                      child: Text(
                        progressLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly Rhythm',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // ── Bible Reading – highlighted row ────────────────────────────
          const SizedBox(height: 12),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, size: 15, color: accent),
              const SizedBox(width: 6),
              _FixedHomeTextScale(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bible Reading',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: bodyColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${stats.readingDays} of 7 days',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: dividerColor),

          // ── Metric chips ────────────────────────────────────────────────
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WeekMetricChip(
                icon: Icons.menu_book_rounded,
                label: _countLabel(stats.chaptersRead, 'Chapter', 'Chapters'),
                accent: accent,
                onTap: onOpenChapters,
              ),
              _WeekMetricChip(
                icon: Icons.history_edu_rounded,
                label: _countLabel(
                  stats.devotionalDays,
                  'Devotional Day',
                  'Devotional Days',
                ),
                accent: accent,
                onTap: onOpenDevotionals,
              ),
              _WeekMetricChip(
                icon: Icons.mic_rounded,
                label:
                    _countLabel(stats.sermonsCreated, 'Sermon', 'Sermons'),
                accent: accent,
                onTap: onOpenSermons,
              ),
              _WeekMetricChip(
                icon: Icons.bookmark_rounded,
                label: '${stats.savedVerses} Saved',
                accent: accent,
                onTap: onOpenSaved,
              ),
            ],
          ),

          // ── Daily Habits ────────────────────────────────────────────────
          const SizedBox(height: 10),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 10),
          _FixedHomeTextScale(
            child: Text(
              'Daily Habits',
              style: theme.textTheme.labelSmall?.copyWith(
                color: bodyColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _HabitIndicator(
                icon: Icons.wb_sunny_rounded,
                label: 'Daily Verse',
                completed: stats.todayDailyVerse,
                accent: accent,
                onTap: onOpenDailyVerse,
              ),
              const SizedBox(width: 8),
              _HabitIndicator(
                icon: Icons.local_florist_rounded,
                label: 'Promise',
                completed: stats.todayPromise,
                accent: accent,
                onTap: onOpenPromise,
              ),
              const SizedBox(width: 8),
              _HabitIndicator(
                icon: Icons.psychology_rounded,
                label: 'Memory',
                completed: stats.todayScriptureMemory,
                accent: accent,
                onTap: onOpenScriptureMemory,
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
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textColor = isLight ? const Color(0xFF172033) : Colors.white;
    final iconColor = isLight ? accent : Colors.white.withValues(alpha: 0.70);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isLight
              ? Colors.white.withValues(alpha: 0.74)
              : Colors.white.withValues(alpha: 0.07),
          border: Border.all(
            color: isLight
                ? accent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: iconColor,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: textColor,
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

/// A compact tappable indicator showing whether a daily habit was completed.
///
/// Displays a filled check-circle when [completed], an open circle otherwise.
/// Tapping always navigates to the feature so the user can complete it.
class _HabitIndicator extends StatelessWidget {
  const _HabitIndicator({
    required this.icon,
    required this.label,
    required this.completed,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool completed;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final completedBg = accent.withValues(alpha: isLight ? 0.14 : 0.20);
    final pendingBg = isLight
        ? Colors.white.withValues(alpha: 0.50)
        : Colors.white.withValues(alpha: 0.05);
    final labelColor = completed
        ? (isLight ? const Color(0xFF0E7490) : accent)
        : (isLight
            ? const Color(0xFF526070)
            : Colors.white.withValues(alpha: 0.50));
    final iconColor = completed
        ? (isLight ? accent : accent)
        : (isLight
            ? const Color(0xFFB0C4D0)
            : Colors.white.withValues(alpha: 0.30));

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: completed ? completedBg : pendingBg,
            border: Border.all(
              color: completed
                  ? accent.withValues(alpha: 0.30)
                  : (isLight
                      ? const Color(0xFFD0E8EE)
                      : Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(completed),
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 4),
              _FixedHomeTextScale(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
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
    required this.isContinuingDevotional,
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
  final bool isContinuingDevotional;
  final VoidCallback onOpenReading;
  final VoidCallback onOpenVerse;
  final VoidCallback onOpenDevotional;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      children: [
        SizedBox(
          height: 220,
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
                  isContinuing: isContinuingDevotional,
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
                          : isLight
                              ? const Color(0xFF5B5570).withValues(alpha: 0.24)
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
    final isLight = theme.brightness == Brightness.light;
    final titleColor = isLight ? const Color(0xFF1E1830) : Colors.white;
    final bodyColor = isLight
        ? const Color(0xFF4B415F)
        : Colors.white.withValues(alpha: 0.88);
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
              backgroundColor: isLight
                  ? accent.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.08),
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
                const SizedBox(height: 10),
                Text(
                  reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      '"$verseText"',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: bodyColor,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
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
    final isLight = theme.brightness == Brightness.light;
    final titleColor = isLight ? const Color(0xFF2D2312) : Colors.white;
    final bodyColor = isLight
        ? const Color(0xFF6B5A3B)
        : Colors.white.withValues(alpha: 0.65);
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
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Day $readingDay',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: titleColor,
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
          const SizedBox(height: 8),
          Text(
            "Today's Reading",
            style: theme.textTheme.labelLarge?.copyWith(
              color: bodyColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                passages.join('\n'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
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
    required this.isContinuing,
    required this.onTap,
  });

  final DevotionalModel devotional;
  final double progress;
  final bool isContinuing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6366F1);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final titleColor = isLight ? const Color(0xFF1E1830) : Colors.white;
    final metaColor = isLight
        ? const Color(0xFF5B5570)
        : Colors.white.withValues(alpha: 0.62);
    final iconColor = isLight
        ? const Color(0xFF6366F1)
        : Colors.white.withValues(alpha: 0.56);
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();
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
            label: isContinuing ? 'CONTINUE REFLECTION' : 'TODAY\'S DEVOTIONAL',
            accent: accent,
          ),
          const SizedBox(height: 16),
          Text(
            devotional.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const Spacer(),
          _DashboardLink(
            label: isContinuing ? 'Continue Reflection' : 'Start Devotional',
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
                  color: iconColor,
                ),
                const SizedBox(width: 5),
                Text(
                  '$progressPercent% complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: metaColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: normalizedProgress,
              color: accent,
              backgroundColor: isLight
                  ? accent.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              minHeight: 5,
            ),
          ] else
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: iconColor,
                ),
                const SizedBox(width: 5),
                Text(
                  '7 minutes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: metaColor,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final shellGradient = isLight
        ? [
            Color.lerp(Colors.white, accent, 0.16)!,
            Color.lerp(const Color(0xFFF8F5FF), accent, 0.07)!,
            Colors.white.withValues(alpha: 0.98),
          ]
        : gradient;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: shellGradient,
        ),
        border: Border.all(
          color: accent.withValues(alpha: isLight ? 0.34 : 0.26),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isLight ? 0.16 : 0.12),
            blurRadius: isLight ? 22 : 26,
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

class _JourneyRail extends StatelessWidget {
  const _JourneyRail({
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
    return Column(
      children: [
        JourneyActionTile(
          title: 'Bible',
          subtitle: 'Continue reading Scripture',
          icon: Icons.menu_book_rounded,
          accent: const Color(0xFF8B5CF6),
          badge: 'Resume',
          onTap: onReadBible,
        ),
        const SizedBox(height: 12),
        JourneyActionTile(
          title: 'Search Scripture',
          subtitle: 'Find a verse, word, or passage',
          icon: Icons.search_rounded,
          accent: const Color(0xFF3B82F6),
          onTap: onSearch,
        ),
        const SizedBox(height: 12),
        JourneyActionTile(
          title: 'Reading Plan',
          subtitle: 'Open today or view the full schedule',
          icon: Icons.check_circle_rounded,
          accent: const Color(0xFFF59E0B),
          badge: 'Today',
          onTap: onTodayPlan,
        ),
        const SizedBox(height: 12),
        JourneyActionTile(
          title: AppBranding.logosNotes,
          subtitle: 'Notes, recording, transcription, and AI',
          icon: Icons.edit_note_rounded,
          accent: const Color(0xFF14B8A6),
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
    final isLight = theme.brightness == Brightness.light;
    final titleColor = isLight ? const Color(0xFF1E1830) : Colors.white;
    final bodyColor = isLight
        ? const Color(0xFF5B5570)
        : Colors.white.withValues(alpha: 0.70);
    final metaColor = isLight
        ? const Color(0xFF746D86)
        : Colors.white.withValues(alpha: 0.60);
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? const [
                    Color(0xFFF0E9FF),
                    Color(0xFFFFFFFF),
                    Color(0xFFF8F5FF),
                  ]
                : const [
                    Color(0x332D1B69),
                    Color(0x22111427),
                    Color(0x331E1B4B),
                  ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: isLight ? 0.34 : 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isLight ? 0.14 : 0.12),
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
                            color: titleColor,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                      _FixedHomeTextScale(
                        child: Text(
                          progressLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
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
                      color: bodyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    devotionalTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isLight ? accent : const Color(0xFFC4B5FD),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: metaColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: isLight
                        ? accent.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.08),
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

class _FixedHomeTextScale extends StatelessWidget {
  const _FixedHomeTextScale({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
      ),
      child: child,
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

class _ScriptureMemoryCard extends StatelessWidget {
  const _ScriptureMemoryCard({
    required this.summary,
    required this.onTap,
  });

  final MemoryHomeSummary summary;
  final VoidCallback onTap;

  String get _meta {
    if (summary.activeCount == 0) return 'Begin with a verse from your reading';
    if (summary.dueCount == 0) return 'You are caught up for today';
    return '${summary.dueCount} '
        '${summary.dueCount == 1 ? 'verse' : 'verses'} ready to review';
  }

  @override
  Widget build(BuildContext context) {
    return _GlassExploreCard(
      title: 'Hide God\'s Word',
      subtitle: 'Memorize and review Scripture',
      meta: _meta,
      icon: Icons.psychology_alt_rounded,
      accent: const Color(0xFF10B981),
      gradient: const [
        Color(0x33206448),
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
    final isLight = theme.brightness == Brightness.light;

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
            colors: isLight
                ? [
                    Color.lerp(Colors.white, accent, 0.14)!,
                    Colors.white.withValues(alpha: 0.96),
                  ]
                : gradient,
          ),
          border: Border.all(
            color: accent.withValues(alpha: isLight ? 0.34 : 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isLight ? 0.12 : 0.14),
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
