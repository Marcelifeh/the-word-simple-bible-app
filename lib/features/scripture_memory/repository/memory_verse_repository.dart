import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/memory_home_summary.dart';
import '../model/memory_progress_summary.dart';
import '../model/memory_review_event.dart';
import '../model/memory_schedule.dart';
import '../model/memory_session_draft.dart';
import '../model/memory_verse.dart';
import '../services/memory_progress_calculator.dart';
import '../services/memory_scheduler.dart';

class MemoryVerseRepository extends ChangeNotifier {
  MemoryVerseRepository({
    MemoryScheduler scheduler = const MemoryScheduler(),
    Uuid uuid = const Uuid(),
  })  : _scheduler = scheduler,
        _uuid = uuid;

  static const _versesBoxName = 'memory_verses';
  static const _reviewsBoxName = 'memory_review_history';
  static const _preferencesBoxName = 'memory_preferences';
  static const _sessionBoxName = 'memory_session_draft';
  static const _sessionKey = 'active';

  final MemoryScheduler _scheduler;
  final Uuid _uuid;
  final MemoryProgressCalculator _progressCalculator =
      const MemoryProgressCalculator();
  final Map<String, MemoryVerse> _versesById = {};
  final List<MemoryReviewEvent> _reviewEvents = [];

  Box<dynamic>? _versesBox;
  Box<dynamic>? _reviewsBox;
  Box<dynamic>? _preferencesBox;
  Box<dynamic>? _sessionBox;
  MemoryHomeSummary _homeSummary = const MemoryHomeSummary();
  MemoryProgressSummary _progressSummary = const MemoryProgressSummary();
  MemorySessionDraft? _sessionDraft;
  String? _summaryLocalDate;

  MemoryHomeSummary get homeSummary {
    final today = MemoryScheduler.formatLocalDate(DateTime.now());
    if (_summaryLocalDate != today) _refreshSummary();
    return _homeSummary;
  }

  MemoryProgressSummary get progressSummary {
    final today = MemoryScheduler.formatLocalDate(DateTime.now());
    if (_summaryLocalDate != today) _refreshSummary();
    return _progressSummary;
  }

  MemorySessionDraft? get sessionDraft => _sessionDraft;

  int get dailyGoal {
    final value = _preferencesBox?.get('dailyGoal');
    return value is int ? value.clamp(3, 10).toInt() : 5;
  }

  Future<void> init() async {
    _versesBox = await _openRecovering(_versesBoxName);
    _reviewsBox = await _openRecovering(_reviewsBoxName);
    _preferencesBox = await _openRecovering(_preferencesBoxName);
    _sessionBox = await _openRecovering(_sessionBoxName);
    _loadVerses();
    _loadReviewEvents();
    await _loadSessionDraft();
    _refreshSummary();
  }

  List<MemoryVerse> list({bool includeArchived = false}) {
    final items = _versesById.values
        .where((verse) => includeArchived || !verse.isArchived)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAtUtc.compareTo(a.updatedAtUtc));
    return List<MemoryVerse>.unmodifiable(items);
  }

  List<MemoryVerse> due({DateTime? now}) {
    final items = _versesById.values
        .where((verse) => _scheduler.isDue(verse.schedule, now: now))
        .toList(growable: false)
      ..sort((a, b) {
        final statusOrder = _statusSortOrder(a.schedule.status) -
            _statusSortOrder(b.schedule.status);
        if (statusOrder != 0) return statusOrder;
        final dueOrder =
            a.schedule.dueLocalDate.compareTo(b.schedule.dueLocalDate);
        if (dueOrder != 0) return dueOrder;
        return a.createdAtUtc.compareTo(b.createdAtUtc);
      });
    return List<MemoryVerse>.unmodifiable(items);
  }

  MemoryVerse? findById(String id) => _versesById[id];

  List<MemoryReviewEvent> historyFor(
    String memoryVerseId, {
    int? limit,
  }) {
    final events = _reviewEvents
        .where((event) => event.memoryVerseId == memoryVerseId)
        .toList(growable: false)
      ..sort((a, b) => b.completedAtUtc.compareTo(a.completedAtUtc));
    final result = limit == null ? events : events.take(limit).toList();
    return List<MemoryReviewEvent>.unmodifiable(result);
  }

  Set<MemoryExerciseMode> recentlyUsedModes(
    String memoryVerseId, {
    int limit = 2,
  }) {
    return historyFor(memoryVerseId, limit: limit)
        .map((event) => event.mode)
        .toSet();
  }

  MemoryVerse? findByDedupeKey(String dedupeKey) {
    for (final verse in _versesById.values) {
      if (verse.dedupeKey == dedupeKey) return verse;
    }
    return null;
  }

  Future<MemoryVerse> saveDraft(MemoryVerseDraft draft) async {
    final nowUtc = DateTime.now().toUtc();
    final existing = findByDedupeKey(draft.dedupeKey);
    final normalizedCategories = _normalizeCategories(draft.categories);
    final normalizedCollectionIds = _normalizeCategories(draft.collectionIds);

    if (existing != null) {
      final restoredSchedule = existing.isArchived
          ? existing.schedule.copyWith(
              status: existing.schedule.stage >= 5
                  ? MemoryStatus.established
                  : existing.schedule.stage > 0
                      ? MemoryStatus.reviewing
                      : MemoryStatus.newVerse,
              dueLocalDate: MemoryScheduler.formatLocalDate(DateTime.now()),
            )
          : existing.schedule;
      final updated = existing.copyWith(
        categories: normalizedCategories,
        collectionIds: _normalizeCategories(
          <String>[
            ...existing.collectionIds,
            ...normalizedCollectionIds,
          ],
        ),
        difficulty: draft.difficulty,
        schedule: restoredSchedule,
        updatedAtUtc: nowUtc,
        clearArchivedAt: true,
      );
      await _persistVerse(updated);
      return updated;
    }

    final verse = MemoryVerse(
      id: _uuid.v4(),
      dedupeKey: draft.dedupeKey,
      bookId: draft.bookId.trim().toLowerCase(),
      bookName: draft.bookName.trim(),
      chapter: draft.chapter,
      startVerse: draft.startVerse <= draft.endVerse
          ? draft.startVerse
          : draft.endVerse,
      endVerse: draft.startVerse <= draft.endVerse
          ? draft.endVerse
          : draft.startVerse,
      translation: draft.translation,
      textSnapshot: draft.text.trim(),
      source: draft.source,
      categories: normalizedCategories,
      collectionIds: normalizedCollectionIds,
      difficulty: draft.difficulty,
      schedule: _scheduler.newSchedule(),
      createdAtUtc: nowUtc,
      updatedAtUtc: nowUtc,
    );
    await _persistVerse(verse);
    return verse;
  }

  Future<List<MemoryVerse>> saveCollectionDrafts(
    List<MemoryVerseDraft> drafts,
  ) async {
    final saved = <MemoryVerse>[];
    final today = MemoryScheduler.localDay(DateTime.now());
    for (var index = 0; index < drafts.length; index++) {
      final existing = findByDedupeKey(drafts[index].dedupeKey);
      var verse = await saveDraft(drafts[index]);
      if (existing == null && verse.schedule.stage == 0) {
        final dayOffset = index ~/ dailyGoal;
        if (dayOffset > 0) {
          verse = verse.copyWith(
            schedule: verse.schedule.copyWith(
              dueLocalDate: MemoryScheduler.formatLocalDate(
                today.add(Duration(days: dayOffset)),
              ),
            ),
            updatedAtUtc: DateTime.now().toUtc(),
          );
          await _persistVerse(verse, notify: false);
        }
      }
      saved.add(verse);
    }
    _refreshAndNotify();
    return List<MemoryVerse>.unmodifiable(saved);
  }

  Future<void> updateDetails({
    required String id,
    required List<String> categories,
    required MemoryDifficulty difficulty,
  }) async {
    final current = _versesById[id];
    if (current == null) return;
    await _persistVerse(
      current.copyWith(
        categories: _normalizeCategories(categories),
        difficulty: difficulty,
        updatedAtUtc: DateTime.now().toUtc(),
      ),
    );
  }

  Future<MemoryVerse?> recordReview({
    required String memoryVerseId,
    required MemoryExerciseMode mode,
    required MemoryReviewRating rating,
    DateTime? now,
    String? eventId,
    double? internalAccuracy,
    int hintCount = 0,
    Duration duration = Duration.zero,
  }) async {
    if (mode == MemoryExerciseMode.read) return findById(memoryVerseId);
    final current = _versesById[memoryVerseId];
    if (current == null || current.isArchived) return null;
    if (eventId != null && _reviewEvents.any((event) => event.id == eventId)) {
      return current;
    }

    final completedAt = now ?? DateTime.now();
    final nextSchedule = _scheduler.recordActiveRecall(
      current: current.schedule,
      rating: rating,
      now: completedAt,
    );
    final updated = current.copyWith(
      schedule: nextSchedule,
      updatedAtUtc: completedAt.toUtc(),
    );
    await _persistVerse(updated, notify: false);

    final event = MemoryReviewEvent(
      id: eventId ?? _uuid.v4(),
      memoryVerseId: current.id,
      mode: mode,
      rating: rating,
      completedLocalDate: MemoryScheduler.formatLocalDate(completedAt),
      completedAtUtc: completedAt.toUtc(),
      previousStage: current.schedule.stage,
      nextStage: nextSchedule.stage,
      internalAccuracy: internalAccuracy,
      hintCount: hintCount,
      duration: duration,
      wasLapse: rating == MemoryReviewRating.needsPractice,
    );
    _reviewEvents.add(event);
    await _reviewsBox?.put(event.id, jsonEncode(event.toJson()));
    _refreshAndNotify();
    return updated;
  }

  Future<MemorySessionDraft> startSession(
    List<String> verseIds, {
    bool replaceExisting = false,
  }) async {
    if (_sessionDraft != null && !replaceExisting) return _sessionDraft!;
    final now = DateTime.now().toUtc();
    final draft = MemorySessionDraft(
      id: _uuid.v4(),
      verseIds: List<String>.unmodifiable(verseIds),
      currentIndex: 0,
      results: const <String, MemoryDraftResult>{},
      startedAtUtc: now,
      updatedAtUtc: now,
    );
    await saveSessionDraft(draft);
    return draft;
  }

  Future<void> saveSessionDraft(MemorySessionDraft draft) async {
    _sessionDraft = draft.copyWith(updatedAtUtc: DateTime.now().toUtc());
    await _sessionBox?.put(
      _sessionKey,
      jsonEncode(_sessionDraft!.toJson()),
    );
    notifyListeners();
  }

  Future<void> clearSessionDraft() async {
    _sessionDraft = null;
    await _sessionBox?.delete(_sessionKey);
    notifyListeners();
  }

  List<MemoryVerse> resumableSessionVerses(MemorySessionDraft draft) {
    return draft.verseIds
        .map(findById)
        .whereType<MemoryVerse>()
        .where((verse) => !verse.isArchived)
        .where((verse) => draft.results[verse.id]?.committed != true)
        .toList(growable: false);
  }

  Future<void> archive(String id) async {
    final current = _versesById[id];
    if (current == null || current.isArchived) return;
    final nowUtc = DateTime.now().toUtc();
    await _persistVerse(
      current.copyWith(
        schedule: current.schedule.copyWith(status: MemoryStatus.archived),
        archivedAtUtc: nowUtc,
        updatedAtUtc: nowUtc,
      ),
    );
  }

  Future<void> deletePermanently(String id) async {
    _versesById.remove(id);
    await _versesBox?.delete(id);

    final eventIds = _reviewEvents
        .where((event) => event.memoryVerseId == id)
        .map((event) => event.id)
        .toList(growable: false);
    _reviewEvents.removeWhere((event) => event.memoryVerseId == id);
    if (eventIds.isNotEmpty) {
      await _reviewsBox?.deleteAll(eventIds);
    }
    _refreshAndNotify();
  }

  Future<void> setDailyGoal(int value) async {
    final normalized = value.clamp(3, 10).toInt();
    await _preferencesBox?.put('dailyGoal', normalized);
    notifyListeners();
  }

  Future<void> _persistVerse(
    MemoryVerse verse, {
    bool notify = true,
  }) async {
    _versesById[verse.id] = verse;
    await _versesBox?.put(verse.id, jsonEncode(verse.toJson()));
    if (notify) _refreshAndNotify();
  }

  Future<Box<dynamic>> _openRecovering(String name) async {
    try {
      return await Hive.openBox<dynamic>(name);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {
        // Continue and let the second open surface an actionable error.
      }
      return Hive.openBox<dynamic>(name);
    }
  }

  void _loadVerses() {
    _versesById.clear();
    final box = _versesBox;
    if (box == null) return;
    for (final raw in box.values) {
      if (raw is! String) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final verse = MemoryVerse.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        _versesById[verse.id] = verse;
      } catch (_) {
        // Skip only the malformed record; preserve the rest of the library.
      }
    }
  }

  void _loadReviewEvents() {
    _reviewEvents.clear();
    final box = _reviewsBox;
    if (box == null) return;
    for (final raw in box.values) {
      if (raw is! String) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        _reviewEvents.add(
          MemoryReviewEvent.fromJson(Map<String, dynamic>.from(decoded)),
        );
      } catch (_) {
        // Ignore a malformed history event without losing schedule state.
      }
    }
  }

  Future<void> _loadSessionDraft() async {
    _sessionDraft = null;
    final raw = _sessionBox?.get(_sessionKey);
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('Invalid draft');
      _sessionDraft = MemorySessionDraft.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      await _sessionBox?.delete(_sessionKey);
    }
  }

  void _refreshAndNotify() {
    _refreshSummary();
    notifyListeners();
  }

  void _refreshSummary() {
    final active = _versesById.values
        .where((verse) => !verse.isArchived)
        .toList(growable: false);
    final today = MemoryScheduler.formatLocalDate(DateTime.now());
    _summaryLocalDate = today;
    _progressSummary = _progressCalculator.calculate(
      verses: active,
      events: _reviewEvents,
    );
    _homeSummary = MemoryHomeSummary(
      dueCount:
          active.where((verse) => _scheduler.isDue(verse.schedule)).length,
      activeCount: active.length,
      establishedCount:
          active.where((verse) => verse.schedule.hasReachedEstablished).length,
      streakDays: _progressSummary.streakDays,
      reviewedToday: _reviewEvents
          .where((event) => event.completedLocalDate == today)
          .map((event) => event.memoryVerseId)
          .toSet()
          .length,
    );
  }

  static int _statusSortOrder(MemoryStatus status) {
    return switch (status) {
      MemoryStatus.newVerse => 0,
      MemoryStatus.learning => 1,
      MemoryStatus.reviewing => 2,
      MemoryStatus.established => 3,
      MemoryStatus.archived => 4,
    };
  }

  static List<String> _normalizeCategories(Iterable<String> values) {
    final normalized = <String>[];
    final seen = <String>{};
    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty || !seen.add(value.toLowerCase())) continue;
      normalized.add(value);
    }
    return List<String>.unmodifiable(normalized);
  }
}
