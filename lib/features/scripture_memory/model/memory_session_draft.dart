import 'memory_review_event.dart';

class MemoryDraftResult {
  const MemoryDraftResult({
    required this.memoryVerseId,
    required this.mode,
    this.rating,
    this.internalAccuracy,
    this.hintCount = 0,
    this.duration = Duration.zero,
    this.committed = false,
    this.enteredAnswers = const <int, String>{},
    this.revealedBlankIndexes = const <int>{},
    this.checkAttemptCount = 0,
    this.correctOnFirstCheck = 0,
    this.correctAfterRetry = 0,
    this.fullVerseRevealed = false,
  });

  final String memoryVerseId;
  final MemoryExerciseMode mode;
  final MemoryReviewRating? rating;
  final double? internalAccuracy;
  final int hintCount;
  final Duration duration;
  final bool committed;
  final Map<int, String> enteredAnswers;
  final Set<int> revealedBlankIndexes;
  final int checkAttemptCount;
  final int correctOnFirstCheck;
  final int correctAfterRetry;
  final bool fullVerseRevealed;

  MemoryDraftResult copyWith({
    MemoryReviewRating? rating,
    double? internalAccuracy,
    int? hintCount,
    Duration? duration,
    bool? committed,
    Map<int, String>? enteredAnswers,
    Set<int>? revealedBlankIndexes,
    int? checkAttemptCount,
    int? correctOnFirstCheck,
    int? correctAfterRetry,
    bool? fullVerseRevealed,
  }) {
    return MemoryDraftResult(
      memoryVerseId: memoryVerseId,
      mode: mode,
      rating: rating ?? this.rating,
      internalAccuracy: internalAccuracy ?? this.internalAccuracy,
      hintCount: hintCount ?? this.hintCount,
      duration: duration ?? this.duration,
      committed: committed ?? this.committed,
      enteredAnswers: enteredAnswers ?? this.enteredAnswers,
      revealedBlankIndexes: revealedBlankIndexes ?? this.revealedBlankIndexes,
      checkAttemptCount: checkAttemptCount ?? this.checkAttemptCount,
      correctOnFirstCheck: correctOnFirstCheck ?? this.correctOnFirstCheck,
      correctAfterRetry: correctAfterRetry ?? this.correctAfterRetry,
      fullVerseRevealed: fullVerseRevealed ?? this.fullVerseRevealed,
    );
  }

  Map<String, dynamic> toJson() => {
        'memoryVerseId': memoryVerseId,
        'mode': mode.name,
        'rating': rating?.name,
        'internalAccuracy': internalAccuracy,
        'hintCount': hintCount,
        'durationMs': duration.inMilliseconds,
        'committed': committed,
        'enteredAnswers': enteredAnswers.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        'revealedBlankIndexes': revealedBlankIndexes.toList(growable: false),
        'checkAttemptCount': checkAttemptCount,
        'correctOnFirstCheck': correctOnFirstCheck,
        'correctAfterRetry': correctAfterRetry,
        'fullVerseRevealed': fullVerseRevealed,
      };

  factory MemoryDraftResult.fromJson(Map<String, dynamic> json) {
    return MemoryDraftResult(
      memoryVerseId: json['memoryVerseId'].toString(),
      mode: MemoryExerciseMode.values.firstWhere(
        (mode) => mode.name == json['mode'],
        orElse: () => MemoryExerciseMode.missingWords,
      ),
      rating: json['rating'] == null
          ? null
          : MemoryReviewRating.values.firstWhere(
              (rating) => rating.name == json['rating'],
              orElse: () => MemoryReviewRating.remembered,
            ),
      internalAccuracy: (json['internalAccuracy'] as num?)?.toDouble(),
      hintCount: (json['hintCount'] as num?)?.toInt() ?? 0,
      duration: Duration(
        milliseconds: (json['durationMs'] as num?)?.toInt() ?? 0,
      ),
      committed: json['committed'] == true,
      enteredAnswers: (json['enteredAnswers'] as Map? ?? const {}).map(
        (key, value) => MapEntry(
          int.parse(key.toString()),
          value.toString(),
        ),
      ),
      revealedBlankIndexes:
          (json['revealedBlankIndexes'] as List? ?? const <dynamic>[])
              .map((value) => (value as num).toInt())
              .toSet(),
      checkAttemptCount: (json['checkAttemptCount'] as num?)?.toInt() ?? 0,
      correctOnFirstCheck: (json['correctOnFirstCheck'] as num?)?.toInt() ?? 0,
      correctAfterRetry: (json['correctAfterRetry'] as num?)?.toInt() ?? 0,
      fullVerseRevealed: json['fullVerseRevealed'] == true,
    );
  }
}

class MemorySessionDraft {
  const MemorySessionDraft({
    required this.id,
    required this.verseIds,
    required this.currentIndex,
    required this.results,
    required this.startedAtUtc,
    required this.updatedAtUtc,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final String id;
  final List<String> verseIds;
  final int currentIndex;
  final Map<String, MemoryDraftResult> results;
  final DateTime startedAtUtc;
  final DateTime updatedAtUtc;
  final int schemaVersion;

  int get completedCount =>
      results.values.where((result) => result.committed).length;

  MemorySessionDraft copyWith({
    int? currentIndex,
    Map<String, MemoryDraftResult>? results,
    DateTime? updatedAtUtc,
  }) {
    return MemorySessionDraft(
      id: id,
      verseIds: verseIds,
      currentIndex: currentIndex ?? this.currentIndex,
      results: results ?? this.results,
      startedAtUtc: startedAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      schemaVersion: schemaVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'verseIds': verseIds,
        'currentIndex': currentIndex,
        'results': results.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'startedAtUtc': startedAtUtc.toIso8601String(),
        'updatedAtUtc': updatedAtUtc.toIso8601String(),
      };

  factory MemorySessionDraft.fromJson(Map<String, dynamic> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported memory session schema version: $schemaVersion',
      );
    }
    final rawResults = json['results'];
    if (rawResults is! Map) {
      throw const FormatException('Missing memory session results');
    }
    return MemorySessionDraft(
      id: json['id'].toString(),
      verseIds: (json['verseIds'] as List? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(growable: false),
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      results: rawResults.map(
        (key, value) => MapEntry(
          key.toString(),
          MemoryDraftResult.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      ),
      startedAtUtc: DateTime.parse(json['startedAtUtc'].toString()).toUtc(),
      updatedAtUtc: DateTime.parse(json['updatedAtUtc'].toString()).toUtc(),
      schemaVersion: schemaVersion,
    );
  }
}
