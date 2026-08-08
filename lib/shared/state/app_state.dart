import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../data/bible/bible_api_repository.dart';
import '../../data/bible/bible_asset_repository.dart';
import '../../data/bible/bible_repository.dart';
import '../../data/commentary/commentary_repository.dart';
import '../../data/daily_verse/daily_verse_service.dart';
import '../../data/favorites/favorites_repository.dart';
import '../../data/search/search_index_repository.dart';
import '../../data/search/smart_offline_search_repository.dart';
import '../../features/notes/repository/notes_repository.dart';
import '../../features/notifications/repository/notification_inbox_repository.dart';
import '../../features/notifications/repository/notification_preferences_repository.dart';
import '../../features/notifications/repository/scheduled_notification_repository.dart';
import '../../features/notifications/services/app_notification_service.dart';
import '../../features/notifications/services/notification_content_service.dart';
import '../../features/notifications/services/notification_coordinator.dart';
import '../../features/notifications/services/notification_navigation_service.dart';
import '../../features/notifications/services/notification_scheduler.dart';
import '../../features/reading_plan/reading_plan_service.dart';
import '../../features/devotional/model/devotional_model.dart';
import '../../features/daily_verse/model/promise_history_entry.dart';
import '../../features/sermon_notes/repository/sermon_draft_repository.dart';
import '../../features/sermon_notes/repository/sermon_note_repository.dart';
import '../../features/scripture_memory/repository/memory_verse_repository.dart';
import '../../features/tracts/repository/user_tract_repository.dart';
import '../../features/devotional/repository/devotional_journal_repository.dart';
import '../../features/devotional/service/devotional_service.dart';
import '../../core/utils/env.dart';
import '../../core/narration/services/narration_cache_service.dart';
import '../../core/narration/services/narration_service.dart';
import '../../core/narration/services/narration_controller.dart';
import '../../core/narration/services/narration_lifecycle_observer.dart';
import '../../core/narration/services/narration_preferences_service.dart';
import '../../core/narration/services/narration_sync_engine.dart';
import '../../domain/entities/bible_translation.dart';
import '../settings/home_text_size.dart';
import '../../features/home/activity/model/faith_activity_type.dart';
import '../../features/home/activity/repository/faith_activity_repository.dart';

/// Tracks the last chapter position so Home can show "Continue Reading".
/// [version] lets us safely discard stale Hive data when the schema changes.
class LastReadRef {
  const LastReadRef({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    this.version = _kCurrentVersion,
  });

  static const int _kCurrentVersion = 1;

  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final int version;

  /// True when the stored version matches the current schema.
  bool get isValid => version == _kCurrentVersion;
}

enum DevotionalResumeStage {
  reading,
  audio,
  reflection,
  prayer,
  journal,
}

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  final assetBibleRepo = BibleAssetRepository();
  late final BibleRepository bibleRepo = _buildBibleRepo();
  final commentaryRepo = CommentaryRepository();
  final favoritesRepo = FavoritesRepository();
  final notesRepo = NotesRepository();
  final sermonNoteRepo = SermonNoteRepository();
  final sermonDraftRepo = SermonDraftRepository();
  final memoryVerseRepo = MemoryVerseRepository();
  final userTractRepo = UserTractRepository();
  final devotionalJournalRepo = DevotionalJournalRepository();
  final devotionalService = const DevotionalService();

  /// Repository for the three new faith activities: Daily Verse, Promise,
  /// and Scripture Memory. Persisted in the settings Hive box.
  final faithActivityRepo = FaithActivityRepository();
  final notificationPreferencesRepository = NotificationPreferencesRepository();
  final scheduledNotificationRepository = ScheduledNotificationRepository();
  final notificationInboxRepository = NotificationInboxRepository();
  final notificationContentService = NotificationContentService();
  final appNotificationService = AppNotificationService();
  late final dailyVerseService = DailyVerseService(bibleRepo);
  late final notificationNavigationService =
      NotificationNavigationService(this);
  late final notificationScheduler = NotificationScheduler(
    notificationService: appNotificationService,
    contentService: notificationContentService,
    scheduleRepository: scheduledNotificationRepository,
    readingPlanRemainingCount: _readingPlanRemainingCountForDate,
    scriptureMemoryDueCount: _scriptureMemoryDueCountForDate,
    devotionalCompleted: isDevotionalCompletedForDate,
  );
  late final notificationCoordinator = NotificationCoordinator(
    preferencesRepository: notificationPreferencesRepository,
    scheduleRepository: scheduledNotificationRepository,
    inboxRepository: notificationInboxRepository,
    scheduler: notificationScheduler,
  );
  bool _notificationsInitialized = false;
  bool _notificationInboxListenerAttached = false;
  bool _notificationLifecycleObserverAttached = false;
  bool get notificationsAvailable => _notificationsInitialized;

  final searchIndexRepo = SearchIndexRepository();
  final smartSearchRepo = createSmartOfflineSearchRepository();

  late final narrationService = NarrationService();
  late final narrationCacheService = LocalNarrationCacheService();
  late final narrationPreferencesService = NarrationPreferencesService();
  late final narrationSyncEngine = NarrationSyncEngine();
  late final narrationController = NarrationController(
    narrationService,
    preferencesService: narrationPreferencesService,
    syncEngine: narrationSyncEngine,
    cacheService: narrationCacheService,
  );
  late final narrationLifecycleObserver =
      NarrationLifecycleObserver(narrationController);

  BibleTranslation translation = BibleTranslation.web;
  ThemeMode themeMode = ThemeMode.system;
  double fontScale = 1.0;
  HomeTextSize _homeTextSize = HomeTextSize.standard;
  Color primarySeed = Colors.indigo;
  LastReadRef? lastReadRef;
  DevotionalModel? _currentDevotional;
  DateTime? _currentDevotionalDate;
  DateTime? _currentDevotionalLastOpenedAt;
  DevotionalResumeStage _currentDevotionalStage = DevotionalResumeStage.reading;
  final Map<String, DateTime> _devotionalReadHistory = {};
  final Map<String, double> _devotionalProgressByDate = {};
  final Map<String, String> _readingPlanLastOpenedPassagesByDate = {};
  final Map<String, Set<String>> _readingPlanCompletedPassagesByDate = {};
  final Set<String> _readingPlanCompletionActivityDates = {};
  final List<PromiseHistoryEntry> _promiseHistory = [];

  Map<String, DateTime> get devotionalReadHistory =>
      Map<String, DateTime>.unmodifiable(_devotionalReadHistory);

  List<PromiseHistoryEntry> get promiseHistory =>
      List<PromiseHistoryEntry>.unmodifiable(_promiseHistory);

  DevotionalModel? get currentDevotional => _currentDevotional;

  DateTime? get currentDevotionalDate => _currentDevotionalDate;

  DateTime? get currentDevotionalLastOpenedAt => _currentDevotionalLastOpenedAt;

  DevotionalResumeStage get currentDevotionalStage => _currentDevotionalStage;

  HomeTextSize get homeTextSize => _homeTextSize;

  double get homeTextScale => _homeTextSize.scale;

  double devotionalProgressForDate(DateTime date) {
    final value = _devotionalProgressByDate[_dateKey(date)] ?? 0.0;
    return value.clamp(0.0, 1.0);
  }

  bool isDevotionalCompletedForDate(DateTime date) =>
      devotionalProgressForDate(date) >= 0.999;

  String? get readingPlanLastOpenedPassageToday =>
      readingPlanLastOpenedPassageForDate(DateTime.now());

  Set<String> get readingPlanCompletedPassagesToday =>
      readingPlanCompletedPassagesForDate(DateTime.now());

  List<DateTime> get readingPlanCompletionActivityDates =>
      _readingPlanCompletionActivityDates
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .toList(growable: false);

  String? readingPlanLastOpenedPassageForDate(DateTime date) =>
      _readingPlanLastOpenedPassagesByDate[_dateKey(date)];

  Set<String> readingPlanCompletedPassagesForDate(DateTime date) {
    final completed = _readingPlanCompletedPassagesByDate[_dateKey(date)];
    if (completed == null) {
      return const <String>{};
    }
    return Set<String>.unmodifiable(completed);
  }

  bool isReadingPlanPassageCompletedToday(String passage) =>
      isReadingPlanPassageCompletedForDate(DateTime.now(), passage);

  bool isReadingPlanPassageCompletedForDate(DateTime date, String passage) =>
      readingPlanCompletedPassagesForDate(date).contains(passage);

  bool isReadingPlanCompletedFor(Iterable<String> passages) =>
      isReadingPlanCompletedForDate(DateTime.now(), passages);

  bool isReadingPlanCompletedForDate(DateTime date, Iterable<String> passages) {
    final completedPassages = readingPlanCompletedPassagesForDate(date);
    final passageList = passages.toList(growable: false);
    if (passageList.isEmpty) return false;
    return passageList.every(completedPassages.contains);
  }

  /// Records a faith activity event for today.
  ///
  /// Only [FaithActivityType.dailyVerse], [FaithActivityType.promise], and
  /// [FaithActivityType.scriptureMemory] are persisted; all other types are
  /// derived from their existing repositories at calculation time.
  ///
  /// Returns without writing to Hive if the same type was already recorded
  /// today (deduplication is free via [FaithActivityRepository.record]).
  Future<void> recordFaithActivity(FaithActivityType type) async {
    final changed = faithActivityRepo.record(type, DateTime.now());
    if (!changed) return;

    final box = _settingsBox;
    if (box != null) {
      await box.put('faithActivityDates', faithActivityRepo.encode());
    }
    notifyListeners();
  }

  Future<void> recordPromiseShown({
    required String promiseId,
    required String theme,
    DateTime? shownOn,
  }) async {
    final day = PromiseHistoryEntry.localDay(shownOn ?? DateTime.now());
    final existingIndex = _promiseHistory.indexWhere(
      (entry) =>
          PromiseHistoryEntry.calendarDaysBetween(
            entry.shownOn,
            day,
          ).abs() ==
          0,
    );
    if (existingIndex >= 0 &&
        _promiseHistory[existingIndex].promiseId == promiseId &&
        _promiseHistory[existingIndex].theme == theme) {
      return;
    }

    if (existingIndex >= 0) {
      _promiseHistory.removeAt(existingIndex);
    }
    _promiseHistory.add(
      PromiseHistoryEntry(
        promiseId: promiseId,
        theme: theme,
        shownOn: day,
      ),
    );
    _promiseHistory.removeWhere((entry) {
      final age = PromiseHistoryEntry.calendarDaysBetween(day, entry.shownOn);
      return age > 90 || age < 0;
    });
    _promiseHistory.sort((a, b) => a.shownOn.compareTo(b.shownOn));
    await _saveSetting(
      'promiseHistory',
      PromiseHistoryEntry.encodeList(_promiseHistory),
    );
  }

  void setLastRead(LastReadRef ref) {
    lastReadRef = ref;
    notifyListeners();
    _saveSetting('lastReadVersion', LastReadRef._kCurrentVersion);
    _saveSetting('lastReadBookId', ref.bookId);
    _saveSetting('lastReadBookName', ref.bookName);
    _saveSetting('lastReadChapter', ref.chapter);
    _saveSetting('lastReadVerse', ref.verse);
  }

  void markDevotionalRead(
    String devotionalId, {
    DateTime? readAt,
    DateTime? activeDate,
  }) {
    final effectiveReadAt = readAt ?? DateTime.now();
    final currentChanged = _setCurrentDevotionalById(
      devotionalId,
      activeDate: activeDate ?? effectiveReadAt,
      lastOpenedAt: effectiveReadAt,
      notify: false,
    );
    final changed = _markDevotionalReadInternal(
      devotionalId,
      effectiveReadAt,
    );
    if (!changed) {
      if (currentChanged) {
        notifyListeners();
      }
      return;
    }

    notifyListeners();
  }

  void setDevotionalProgress(
    String devotionalId, {
    DateTime? activeDate,
    required double progress,
  }) {
    final effectiveDate = activeDate ?? DateTime.now();
    final normalizedProgress = progress.clamp(0.0, 1.0);
    final currentChanged = _setCurrentDevotionalById(
      devotionalId,
      activeDate: effectiveDate,
      stage: _stageForDevotionalProgress(normalizedProgress),
      notify: false,
    );
    final dateKey = _dateKey(effectiveDate);
    final previousProgress = _devotionalProgressByDate[dateKey] ?? 0.0;
    final shouldUpgrade = normalizedProgress >= 1.0 ||
        normalizedProgress > previousProgress + 0.0001;

    if (!shouldUpgrade) {
      if (currentChanged) {
        notifyListeners();
      }
      return;
    }

    _devotionalProgressByDate[dateKey] = normalizedProgress;
    _persistDevotionalProgress();
    _markDevotionalReadInternal(devotionalId, DateTime.now());
    notifyListeners();
    _refreshNotifications();
  }

  void markDevotionalCompleted(
    String devotionalId, {
    DateTime? activeDate,
  }) {
    setDevotionalProgress(
      devotionalId,
      activeDate: activeDate,
      progress: 1.0,
    );
  }

  bool _markDevotionalReadInternal(
    String devotionalId,
    DateTime effectiveReadAt,
  ) {
    final previousReadAt = _devotionalReadHistory[devotionalId];
    if (previousReadAt != null && !effectiveReadAt.isAfter(previousReadAt)) {
      return false;
    }

    _devotionalReadHistory[devotionalId] = effectiveReadAt;
    _saveSetting(
      'devotionalReadHistory',
      jsonEncode(
        _devotionalReadHistory.map(
          (key, value) => MapEntry(key, value.toIso8601String()),
        ),
      ),
    );
    return true;
  }

  void setCurrentDevotional(
    DevotionalModel devotional, {
    DateTime? activeDate,
    DateTime? lastOpenedAt,
    DevotionalResumeStage? stage,
  }) {
    final normalizedDate = activeDate == null ? null : _dateOnly(activeDate);
    final effectiveLastOpenedAt = lastOpenedAt ?? DateTime.now();
    final effectiveStage = stage ?? _currentDevotionalStage;
    if (_currentDevotional?.id == devotional.id &&
        _currentDevotionalDate == normalizedDate &&
        _currentDevotionalLastOpenedAt == effectiveLastOpenedAt &&
        _currentDevotionalStage == effectiveStage) {
      return;
    }

    _currentDevotional = devotional;
    _currentDevotionalDate = normalizedDate;
    _currentDevotionalLastOpenedAt = effectiveLastOpenedAt;
    _currentDevotionalStage = effectiveStage;
    _persistCurrentDevotional();
    notifyListeners();
  }

  void clearCurrentDevotional() {
    if (_currentDevotional == null &&
        _currentDevotionalDate == null &&
        _currentDevotionalLastOpenedAt == null &&
        _currentDevotionalStage == DevotionalResumeStage.reading) {
      return;
    }

    _currentDevotional = null;
    _currentDevotionalDate = null;
    _currentDevotionalLastOpenedAt = null;
    _currentDevotionalStage = DevotionalResumeStage.reading;
    _clearPersistedCurrentDevotional();
    notifyListeners();
  }

  bool _setCurrentDevotionalById(
    String devotionalId, {
    DateTime? activeDate,
    DateTime? lastOpenedAt,
    DevotionalResumeStage? stage,
    required bool notify,
  }) {
    final devotional = devotionalService.getById(devotionalId);
    if (devotional == null) return false;

    final normalizedDate = activeDate == null ? null : _dateOnly(activeDate);
    final effectiveLastOpenedAt =
        lastOpenedAt ?? _currentDevotionalLastOpenedAt ?? DateTime.now();
    final effectiveStage = stage ?? _currentDevotionalStage;
    if (_currentDevotional?.id == devotional.id &&
        _currentDevotionalDate == normalizedDate &&
        _currentDevotionalLastOpenedAt == effectiveLastOpenedAt &&
        _currentDevotionalStage == effectiveStage) {
      return false;
    }

    _currentDevotional = devotional;
    _currentDevotionalDate = normalizedDate;
    _currentDevotionalLastOpenedAt = effectiveLastOpenedAt;
    _currentDevotionalStage = effectiveStage;
    _persistCurrentDevotional();
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  void setCurrentDevotionalStage(DevotionalResumeStage stage) {
    if (_currentDevotionalStage == stage) return;
    _currentDevotionalStage = stage;
    _persistCurrentDevotional();
    notifyListeners();
  }

  Future<void> markReadingPlanPassageOpened(
    String passage, {
    DateTime? openedAt,
  }) async {
    final effectiveDate = openedAt ?? DateTime.now();
    final dateKey = _dateKey(effectiveDate);
    _readingPlanLastOpenedPassagesByDate[dateKey] = passage;
    await _persistReadingPlanProgress();
    notifyListeners();
    _refreshNotifications();
  }

  Future<void> markReadingPlanPassageCompleted(
    String passage, {
    DateTime? planDate,
    DateTime? completedAt,
    bool completed = true,
  }) async {
    final dateKey = _dateKey(planDate ?? DateTime.now());
    final completedPassages = _readingPlanCompletedPassagesByDate.putIfAbsent(
      dateKey,
      () => <String>{},
    );

    if (completed) {
      completedPassages.add(passage);
      _recordReadingPlanCompletionActivity(completedAt ?? DateTime.now());
    } else {
      completedPassages.remove(passage);
      if (completedPassages.isEmpty) {
        _readingPlanCompletedPassagesByDate.remove(dateKey);
      }
    }

    await _persistReadingPlanProgress();
    notifyListeners();
    _refreshNotifications();
  }

  Future<void> markReadingPlanCompleted({
    DateTime? planDate,
    DateTime? completedAt,
    Iterable<String>? passages,
  }) async {
    final dateKey = _dateKey(planDate ?? DateTime.now());

    if (passages != null) {
      final completedPassages = passages.toSet();
      if (completedPassages.isEmpty) {
        _readingPlanCompletedPassagesByDate.remove(dateKey);
      } else {
        _readingPlanCompletedPassagesByDate[dateKey] = completedPassages;
        _recordReadingPlanCompletionActivity(completedAt ?? DateTime.now());
      }
    }

    await _persistReadingPlanProgress();
    notifyListeners();
    _refreshNotifications();
  }

  static const _settingsBoxName = 'settings';
  Box<dynamic>? _settingsBox;
  Timer? _dailyDevotionalRolloverTimer;

  Future<void> init() async {
    await narrationService.initialize();
    await narrationPreferencesService.init();
    await narrationController.hydratePreferences();
    narrationLifecycleObserver.attach();
    await favoritesRepo.init();
    await notesRepo.init();
    await sermonNoteRepo.init();
    await sermonDraftRepo.init();
    await memoryVerseRepo.init();
    memoryVerseRepo.addListener(_handleMemoryVerseChange);
    await userTractRepo.init();
    await devotionalJournalRepo.init();
    await commentaryRepo.init();
    try {
      _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(_settingsBoxName);
      } catch (_) {
        // ignore
      }
      _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    }
    _loadSettings();
    _scheduleDailyDevotionalRollover();
    await initializeNotificationsForStartup();
  }

  @visibleForTesting
  Future<void> initializeNotificationsForStartup({
    Future<void> Function()? initializer,
    Future<void> Function()? refresher,
  }) async {
    if (!_notificationLifecycleObserverAttached) {
      WidgetsBinding.instance.addObserver(this);
      _notificationLifecycleObserverAttached = true;
    }
    try {
      if (initializer != null) {
        await initializer();
      } else {
        await notificationPreferencesRepository.init();
        await scheduledNotificationRepository.init();
        await notificationInboxRepository.init();
        if (!_notificationInboxListenerAttached) {
          notificationInboxRepository.addListener(
            _handleNotificationInboxChange,
          );
          _notificationInboxListenerAttached = true;
        }
        await notificationContentService.init();
        await appNotificationService.initialize(
          onPayload: (payload) async {
            await notificationCoordinator.recordNotificationTap(payload);
            await notificationNavigationService.handlePayload(payload);
          },
        );
      }
      _notificationsInitialized = true;
    } catch (error, stackTrace) {
      _notificationsInitialized = false;
      debugPrint('Notifications unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
      return;
    }

    try {
      await (refresher ?? notificationCoordinator.refresh)();
    } catch (error, stackTrace) {
      // The plugin and permission flow remain usable. A later lifecycle event
      // retries scheduling without treating a transient alarm error as fatal.
      debugPrint('Notification schedule refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _loadSettings() {
    final box = _settingsBox;
    if (box == null) return; // Should not happen after init

    // Translation
    final transIndex = box.get('translationIndex') as int?;
    if (transIndex != null &&
        transIndex >= 0 &&
        transIndex < BibleTranslation.values.length) {
      translation = BibleTranslation.values[transIndex];
    }

    // ThemeMode
    final themeIndex = box.get('themeModeIndex') as int?;
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < ThemeMode.values.length) {
      themeMode = ThemeMode.values[themeIndex];
    }

    // FontScale
    final fs = box.get('fontScale') as double?;
    if (fs != null) {
      fontScale = fs.clamp(0.85, 1.5);
    }

    final savedHomeTextSize = box.get('homeTextSize') as String?;
    _homeTextSize = HomeTextSize.values.firstWhere(
      (value) => value.name == savedHomeTextSize,
      orElse: () => HomeTextSize.standard,
    );

    // PrimarySeed
    final colorVal = box.get('primarySeedValue') as int?;
    if (colorVal != null) {
      primarySeed = Color(colorVal);
    }

    // Continue Reading — only restore if schema version matches
    final storedVersion = box.get('lastReadVersion') as int?;
    if (storedVersion == LastReadRef._kCurrentVersion) {
      final bookId = box.get('lastReadBookId') as String?;
      final bookName = box.get('lastReadBookName') as String?;
      final chapter = box.get('lastReadChapter') as int?;
      final verse = box.get('lastReadVerse') as int?;
      if (bookId != null &&
          bookName != null &&
          chapter != null &&
          verse != null) {
        lastReadRef = LastReadRef(
          bookId: bookId,
          bookName: bookName,
          chapter: chapter,
          verse: verse,
        );
      }
    }

    final devotionalReadHistoryRaw =
        box.get('devotionalReadHistory') as String?;
    if (devotionalReadHistoryRaw != null &&
        devotionalReadHistoryRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(devotionalReadHistoryRaw);
        if (decoded is Map) {
          _devotionalReadHistory
            ..clear()
            ..addEntries(
              decoded.entries
                  .where(
                      (entry) => entry.key is String && entry.value is String)
                  .map(
                    (entry) => MapEntry(
                      entry.key as String,
                      DateTime.parse(entry.value as String),
                    ),
                  ),
            );
        }
      } catch (_) {
        _devotionalReadHistory.clear();
      }
    }

    final devotionalProgressByDateRaw =
        box.get('devotionalProgressByDate') as String?;
    _devotionalProgressByDate.clear();
    if (devotionalProgressByDateRaw != null &&
        devotionalProgressByDateRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(devotionalProgressByDateRaw);
        if (decoded is Map) {
          _devotionalProgressByDate.addEntries(
            decoded.entries
                .where(
                  (entry) => entry.key is String && entry.value is num,
                )
                .map(
                  (entry) => MapEntry(
                    entry.key as String,
                    (entry.value as num).toDouble().clamp(0.0, 1.0),
                  ),
                ),
          );
        }
      } catch (_) {
        _devotionalProgressByDate.clear();
      }
    }

    if (_devotionalProgressByDate.isEmpty &&
        _devotionalReadHistory.isNotEmpty) {
      for (final entry in _devotionalReadHistory.entries) {
        final dateKey = _dateKey(entry.value);
        final existing = _devotionalProgressByDate[dateKey] ?? 0.0;
        if (existing < 1.0) {
          _devotionalProgressByDate[dateKey] = 1.0;
        }
      }
      _persistDevotionalProgress();
    }

    final readingPlanLastOpenedByDateRaw =
        box.get('readingPlanLastOpenedByDate') as String?;
    _readingPlanLastOpenedPassagesByDate.clear();
    if (readingPlanLastOpenedByDateRaw != null &&
        readingPlanLastOpenedByDateRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(readingPlanLastOpenedByDateRaw);
        if (decoded is Map) {
          _readingPlanLastOpenedPassagesByDate.addEntries(
            decoded.entries
                .where(
                  (entry) => entry.key is String && entry.value is String,
                )
                .map(
                  (entry) => MapEntry(
                    entry.key as String,
                    entry.value as String,
                  ),
                ),
          );
        }
      } catch (_) {
        _readingPlanLastOpenedPassagesByDate.clear();
      }
    }

    final readingPlanCompletedByDateRaw =
        box.get('readingPlanCompletedPassagesByDate') as String?;
    _readingPlanCompletedPassagesByDate.clear();
    if (readingPlanCompletedByDateRaw != null &&
        readingPlanCompletedByDateRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(readingPlanCompletedByDateRaw);
        if (decoded is Map) {
          _readingPlanCompletedPassagesByDate.addEntries(
            decoded.entries
                .where((entry) => entry.key is String && entry.value is List)
                .map(
                  (entry) => MapEntry(
                    entry.key as String,
                    (entry.value as List).whereType<String>().toSet(),
                  ),
                ),
          );
        }
      } catch (_) {
        _readingPlanCompletedPassagesByDate.clear();
      }
    }

    if (_readingPlanLastOpenedPassagesByDate.isEmpty &&
        _readingPlanCompletedPassagesByDate.isEmpty) {
      final legacyDateKey = box.get('readingPlanDateKey') as String?;
      final legacyLastOpenedPassage =
          box.get('readingPlanLastOpenedPassage') as String?;
      final legacyCompletedPassagesRaw =
          box.get('readingPlanCompletedPassages') as String?;

      if (legacyDateKey != null && legacyLastOpenedPassage != null) {
        _readingPlanLastOpenedPassagesByDate[legacyDateKey] =
            legacyLastOpenedPassage;
      }

      if (legacyDateKey != null &&
          legacyCompletedPassagesRaw != null &&
          legacyCompletedPassagesRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(legacyCompletedPassagesRaw);
          if (decoded is List) {
            _readingPlanCompletedPassagesByDate[legacyDateKey] =
                decoded.whereType<String>().toSet();
          }
        } catch (_) {
          _readingPlanCompletedPassagesByDate.remove(legacyDateKey);
        }
      }
    }

    final readingPlanActivityDatesRaw =
        box.get('readingPlanCompletionActivityDates') as String?;
    _readingPlanCompletionActivityDates.clear();
    if (readingPlanActivityDatesRaw != null &&
        readingPlanActivityDatesRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(readingPlanActivityDatesRaw);
        if (decoded is List) {
          _readingPlanCompletionActivityDates.addAll(
            decoded.whereType<String>().where(
                  (value) => DateTime.tryParse(value) != null,
                ),
          );
        }
      } catch (_) {
        _readingPlanCompletionActivityDates.clear();
      }
    } else if (_hasReadingPlanCompletionInCurrentWeek()) {
      // Legacy progress stored plan dates, not completion timestamps. Collapse
      // current-week records to today rather than inflating reading-day totals.
      _recordReadingPlanCompletionActivity(DateTime.now());
      unawaited(_persistReadingPlanProgress());
    }

    final today = PromiseHistoryEntry.localDay(DateTime.now());
    _promiseHistory
      ..clear()
      ..addAll(
        PromiseHistoryEntry.decodeList(
          box.get('promiseHistory') as String?,
        ).where((entry) {
          final age = PromiseHistoryEntry.calendarDaysBetween(
            today,
            entry.shownOn,
          );
          return age >= 0 && age <= 90;
        }),
      );
    _promiseHistory.sort((a, b) => a.shownOn.compareTo(b.shownOn));

    // Faith activity dates (Daily Verse, Promise, Scripture Memory)
    faithActivityRepo.decode(box.get('faithActivityDates') as String?);

    _initializeCurrentDevotional();

    // Notify listeners after loading all settings
    notifyListeners();
  }

  void _initializeCurrentDevotional() {
    final today = _dateOnly(DateTime.now());
    final box = _settingsBox;
    final savedId = box?.get('currentDevotionalId') as String?;
    final savedDevotional =
        savedId == null ? null : devotionalService.getById(savedId);
    final savedDate =
        _parseDateOnly(box?.get('currentDevotionalDate') as String?);

    if (savedDevotional != null && savedDate == today) {
      _currentDevotional = savedDevotional;
      _currentDevotionalDate = savedDate;
      _currentDevotionalLastOpenedAt =
          _parseDateTime(box?.get('currentDevotionalLastOpenedAt') as String?);
      _currentDevotionalStage = _parseDevotionalResumeStage(
        box?.get('currentDevotionalResumeStage') as String?,
      );
      return;
    }

    if (savedDevotional != null && savedDate != today) {
      _clearPersistedCurrentDevotional();
    }

    _currentDevotional = devotionalService.getTodaysDevotional(now: today);
    _currentDevotionalDate = today;
    _currentDevotionalLastOpenedAt = null;
    _currentDevotionalStage = DevotionalResumeStage.reading;
    _persistCurrentDevotional();
  }

  void _scheduleDailyDevotionalRollover() {
    _dailyDevotionalRolloverTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _dailyDevotionalRolloverTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      _handleDailyDevotionalRollover,
    );
  }

  void _handleDailyDevotionalRollover() {
    _scheduleDailyDevotionalRollover();
    final today = _dateOnly(DateTime.now());
    _currentDevotional = devotionalService.getTodaysDevotional(now: today);
    _currentDevotionalDate = today;
    _currentDevotionalLastOpenedAt = null;
    _currentDevotionalStage = DevotionalResumeStage.reading;
    _persistCurrentDevotional();
    notifyListeners();
    _refreshNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_notificationsInitialized) {
      if (state == AppLifecycleState.resumed) {
        unawaited(initializeNotificationsForStartup());
      }
      return;
    }
    if (state == AppLifecycleState.resumed) {
      notificationCoordinator.setForeground(true);
      unawaited(_refreshTimezoneAndNotifications());
    } else if (state == AppLifecycleState.paused) {
      notificationCoordinator.setForeground(false);
      _refreshNotifications();
    }
  }

  Future<void> _refreshTimezoneAndNotifications() async {
    await appNotificationService.refreshTimezone();
    await notificationCoordinator.refresh();
  }

  void _refreshNotifications() {
    if (!_notificationsInitialized) return;
    unawaited(notificationCoordinator.refresh());
  }

  int _readingPlanRemainingCountForDate(DateTime date) {
    final reading = ReadingPlanService().getReadingForDate(date);
    final completed = readingPlanCompletedPassagesForDate(date);
    return reading.passages
        .where((passage) => !completed.contains(passage))
        .length;
  }

  int _scriptureMemoryDueCountForDate(DateTime date) {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return memoryVerseRepo.due(now: endOfDay).length;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime? _parseDateOnly(String? value) {
    final parsed = _parseDateTime(value);
    if (parsed == null) return null;
    return _dateOnly(parsed);
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  DevotionalResumeStage _parseDevotionalResumeStage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return DevotionalResumeStage.reading;
    }
    return DevotionalResumeStage.values.firstWhere(
      (stage) => stage.name == value,
      orElse: () => DevotionalResumeStage.reading,
    );
  }

  DevotionalResumeStage _stageForDevotionalProgress(double progress) {
    if (progress >= 0.999) return DevotionalResumeStage.journal;
    if (progress >= 0.82) return DevotionalResumeStage.prayer;
    if (progress >= 0.58) return DevotionalResumeStage.reflection;
    return DevotionalResumeStage.reading;
  }

  void _persistCurrentDevotional() {
    final devotional = _currentDevotional;
    if (devotional == null) {
      _clearPersistedCurrentDevotional();
      return;
    }
    _saveSetting('currentDevotionalId', devotional.id);
    _saveSetting(
      'currentDevotionalDate',
      _currentDevotionalDate?.toIso8601String(),
    );
    _saveSetting(
      'currentDevotionalLastOpenedAt',
      _currentDevotionalLastOpenedAt?.toIso8601String(),
    );
    _saveSetting(
      'currentDevotionalResumeStage',
      _currentDevotionalStage.name,
    );
  }

  void _clearPersistedCurrentDevotional() {
    _deleteSetting('currentDevotionalId');
    _deleteSetting('currentDevotionalDate');
    _deleteSetting('currentDevotionalLastOpenedAt');
    _deleteSetting('currentDevotionalResumeStage');
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void _recordReadingPlanCompletionActivity(DateTime completedAt) {
    _readingPlanCompletionActivityDates.add(_dateKey(completedAt.toLocal()));
  }

  bool _hasReadingPlanCompletionInCurrentWeek() {
    final today = _dateOnly(DateTime.now());
    final weekStart = today.subtract(
      Duration(days: today.weekday % DateTime.daysPerWeek),
    );
    final nextWeekStart = weekStart.add(
      const Duration(days: DateTime.daysPerWeek),
    );

    return _readingPlanCompletedPassagesByDate.entries.any((entry) {
      if (entry.value.isEmpty) return false;
      final planDate = DateTime.tryParse(entry.key);
      if (planDate == null) return false;
      return !planDate.isBefore(weekStart) && planDate.isBefore(nextWeekStart);
    });
  }

  Future<void> _persistReadingPlanProgress() async {
    await _saveSetting(
      'readingPlanLastOpenedByDate',
      jsonEncode(_readingPlanLastOpenedPassagesByDate),
    );
    await _saveSetting(
      'readingPlanCompletedPassagesByDate',
      jsonEncode(
        _readingPlanCompletedPassagesByDate.map(
          (key, value) => MapEntry(key, value.toList()..sort()),
        ),
      ),
    );
    await _saveSetting(
      'readingPlanCompletionActivityDates',
      jsonEncode(_readingPlanCompletionActivityDates.toList()..sort()),
    );
  }

  void _persistDevotionalProgress() {
    _saveSetting(
      'devotionalProgressByDate',
      jsonEncode(_devotionalProgressByDate),
    );
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (value == null) {
      await _settingsBox?.delete(key);
      return;
    }
    await _settingsBox?.put(key, value);
  }

  Future<void> _deleteSetting(String key) async {
    await _settingsBox?.delete(key);
  }

  BibleRepository _buildBibleRepo() {
    final url = Env.bibleApiUrl;
    if (url == null) return assetBibleRepo;
    return BibleApiRepository(baseUrl: url);
  }

  void setTranslation(BibleTranslation t) {
    translation = t;
    _saveSetting('translationIndex', t.index);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _saveSetting('themeModeIndex', mode.index);
    notifyListeners();
  }

  void setPrimarySeed(Color c) {
    primarySeed = c;
    _saveSetting('primarySeedValue', c.toARGB32());
    notifyListeners();
  }

  void setFontScale(double scale) {
    fontScale = scale.clamp(0.85, 1.5);
    _saveSetting('fontScale', fontScale);
    notifyListeners();
  }

  void setHomeTextSize(HomeTextSize value) {
    if (_homeTextSize == value) return;
    _homeTextSize = value;
    _saveSetting('homeTextSize', value.name);
    notifyListeners();
  }

  void _handleMemoryVerseChange() {
    notifyListeners();
    _refreshNotifications();
  }

  void _handleNotificationInboxChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    _dailyDevotionalRolloverTimer?.cancel();
    if (_notificationLifecycleObserverAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _notificationLifecycleObserverAttached = false;
    }
    if (_notificationInboxListenerAttached) {
      notificationInboxRepository.removeListener(
        _handleNotificationInboxChange,
      );
      _notificationInboxListenerAttached = false;
    }
    notificationCoordinator.dispose();
    memoryVerseRepo.removeListener(_handleMemoryVerseChange);
    memoryVerseRepo.dispose();
    narrationLifecycleObserver.detach();
    narrationController.dispose();
    narrationSyncEngine.dispose();
    unawaited(narrationService.dispose());
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) throw StateError('AppScope not found');
    return scope.notifier!;
  }
}
