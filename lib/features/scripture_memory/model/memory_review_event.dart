enum MemoryReviewRating {
  needsPractice,
  almostThere,
  remembered,
  easyToday,
}

enum MemoryExerciseMode {
  read,
  firstLetter,
  missingWords,
  progressiveFade,
  typeIt,
}

class MemoryReviewEvent {
  const MemoryReviewEvent({
    required this.id,
    required this.memoryVerseId,
    required this.mode,
    required this.rating,
    required this.completedLocalDate,
    required this.completedAtUtc,
    required this.previousStage,
    required this.nextStage,
    this.internalAccuracy,
    this.hintCount = 0,
    this.duration = Duration.zero,
    this.wasLapse = false,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 2;

  final String id;
  final String memoryVerseId;
  final MemoryExerciseMode mode;
  final MemoryReviewRating rating;
  final String completedLocalDate;
  final DateTime completedAtUtc;
  final int previousStage;
  final int nextStage;
  final double? internalAccuracy;
  final int hintCount;
  final Duration duration;
  final bool wasLapse;
  final int schemaVersion;

  int get stageBefore => previousStage;
  int get stageAfter => nextStage;

  Map<String, dynamic> toJson() => {
        'id': id,
        'memoryVerseId': memoryVerseId,
        'mode': mode.name,
        'rating': rating.name,
        'completedLocalDate': completedLocalDate,
        'completedAtUtc': completedAtUtc.toIso8601String(),
        'previousStage': previousStage,
        'nextStage': nextStage,
        'internalAccuracy': internalAccuracy,
        'hintCount': hintCount,
        'durationMs': duration.inMilliseconds,
        'wasLapse': wasLapse,
        'schemaVersion': schemaVersion,
      };

  factory MemoryReviewEvent.fromJson(Map<String, dynamic> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (schemaVersion < 1 || schemaVersion > currentSchemaVersion) {
      throw FormatException(
        'Unsupported memory review schema version: $schemaVersion',
      );
    }
    return MemoryReviewEvent(
      id: json['id'].toString(),
      memoryVerseId: json['memoryVerseId'].toString(),
      mode: MemoryExerciseMode.values.firstWhere(
        (value) => value.name == json['mode'],
        orElse: () => MemoryExerciseMode.missingWords,
      ),
      rating: MemoryReviewRating.values.firstWhere(
        (value) => value.name == json['rating'],
        orElse: () => MemoryReviewRating.remembered,
      ),
      completedLocalDate: json['completedLocalDate'].toString(),
      completedAtUtc: DateTime.parse(json['completedAtUtc'].toString()).toUtc(),
      previousStage: (json['previousStage'] as num?)?.toInt() ?? 0,
      nextStage: (json['nextStage'] as num?)?.toInt() ?? 0,
      internalAccuracy: (json['internalAccuracy'] as num?)?.toDouble(),
      hintCount: (json['hintCount'] as num?)?.toInt() ?? 0,
      duration: Duration(
        milliseconds: (json['durationMs'] as num?)?.toInt() ?? 0,
      ),
      wasLapse: json['wasLapse'] == true,
      schemaVersion: schemaVersion,
    );
  }
}
