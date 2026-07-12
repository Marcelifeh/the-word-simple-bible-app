import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../data/audio/audio_player_controller.dart';
import '../../data/audio/remote_audio_bible_service.dart';
import '../../data/bible/bible_api_repository.dart';
import '../../data/bible/bible_asset_repository.dart';
import '../../data/bible/bible_repository.dart';
import '../../data/commentary/commentary_repository.dart';
import '../../data/daily_verse/daily_verse_service.dart';
import '../../data/favorites/favorites_repository.dart';
import '../../data/search/search_index_repository.dart';
import '../../data/search/smart_offline_search_repository.dart';
import '../../features/notes/repository/notes_repository.dart';
import '../../features/devotional/model/devotional_model.dart';
import '../../features/sermon_notes/repository/sermon_draft_repository.dart';
import '../../features/sermon_notes/repository/sermon_note_repository.dart';
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

class AppState extends ChangeNotifier {
  final assetBibleRepo = BibleAssetRepository();
  late final BibleRepository bibleRepo = _buildBibleRepo();
  final commentaryRepo = CommentaryRepository();
  final favoritesRepo = FavoritesRepository();
  final notesRepo = NotesRepository();
  final sermonNoteRepo = SermonNoteRepository();
  final sermonDraftRepo = SermonDraftRepository();
  final userTractRepo = UserTractRepository();
  final devotionalJournalRepo = DevotionalJournalRepository();
  final devotionalService = const DevotionalService();
  late final dailyVerseService = DailyVerseService(bibleRepo);

  final searchIndexRepo = SearchIndexRepository();
  final smartSearchRepo = createSmartOfflineSearchRepository();

  final audioService = RemoteAudioBibleService();
  final audioPlayer = AudioPlayerController();

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

  Map<String, DateTime> get devotionalReadHistory =>
      Map<String, DateTime>.unmodifiable(_devotionalReadHistory);

  DevotionalModel? get currentDevotional => _currentDevotional;

  DateTime? get currentDevotionalDate => _currentDevotionalDate;

  DateTime? get currentDevotionalLastOpenedAt => _currentDevotionalLastOpenedAt;

  DevotionalResumeStage get currentDevotionalStage => _currentDevotionalStage;

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
  }

  Future<void> markReadingPlanPassageCompleted(
    String passage, {
    DateTime? completedAt,
    bool completed = true,
  }) async {
    final effectiveDate = completedAt ?? DateTime.now();
    final dateKey = _dateKey(effectiveDate);
    final completedPassages = _readingPlanCompletedPassagesByDate.putIfAbsent(
      dateKey,
      () => <String>{},
    );

    if (completed) {
      completedPassages.add(passage);
    } else {
      completedPassages.remove(passage);
      if (completedPassages.isEmpty) {
        _readingPlanCompletedPassagesByDate.remove(dateKey);
      }
    }

    await _persistReadingPlanProgress();
    notifyListeners();
  }

  Future<void> markReadingPlanCompleted({
    DateTime? completedAt,
    Iterable<String>? passages,
  }) async {
    final effectiveDate = completedAt ?? DateTime.now();
    final dateKey = _dateKey(effectiveDate);

    if (passages != null) {
      final completedPassages = passages.toSet();
      if (completedPassages.isEmpty) {
        _readingPlanCompletedPassagesByDate.remove(dateKey);
      } else {
        _readingPlanCompletedPassagesByDate[dateKey] = completedPassages;
      }
    }

    await _persistReadingPlanProgress();
    notifyListeners();
  }

  static const _settingsBoxName = 'settings';
  Box<dynamic>? _settingsBox;

  Future<void> init() async {
    await narrationService.initialize();
    await narrationPreferencesService.init();
    await narrationController.hydratePreferences();
    narrationLifecycleObserver.attach();
    await favoritesRepo.init();
    await notesRepo.init();
    await sermonNoteRepo.init();
    await sermonDraftRepo.init();
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

    if (savedDevotional != null) {
      _currentDevotional = savedDevotional;
      _currentDevotionalDate =
          _parseDateOnly(box?.get('currentDevotionalDate') as String?) ?? today;
      _currentDevotionalLastOpenedAt =
          _parseDateTime(box?.get('currentDevotionalLastOpenedAt') as String?);
      _currentDevotionalStage = _parseDevotionalResumeStage(
        box?.get('currentDevotionalResumeStage') as String?,
      );
      return;
    }

    _currentDevotional = devotionalService.getTodaysDevotional(now: today);
    _currentDevotionalDate = today;
    _currentDevotionalLastOpenedAt = null;
    _currentDevotionalStage = DevotionalResumeStage.reading;
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

  @override
  void dispose() {
    narrationLifecycleObserver.detach();
    narrationController.dispose();
    narrationSyncEngine.dispose();
    unawaited(narrationService.dispose());
    audioPlayer.dispose();
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
