import '../../../domain/entities/bible_translation.dart';
import 'memory_schedule.dart';

enum MemoryDifficulty { easy, normal, hard }

enum MemoryVerseSource {
  bible,
  dailyVerse,
  promise,
  devotional,
  readingPlan,
  search,
  collection,
}

class MemoryVerseDraft {
  MemoryVerseDraft({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    int? endVerse,
    required this.translation,
    required this.text,
    required this.source,
    this.categories = const <String>[],
    this.collectionIds = const <String>[],
    this.difficulty = MemoryDifficulty.normal,
  }) : endVerse = endVerse ?? startVerse;

  final String bookId;
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final BibleTranslation translation;
  final String text;
  final MemoryVerseSource source;
  final List<String> categories;
  final List<String> collectionIds;
  final MemoryDifficulty difficulty;

  String get dedupeKey => MemoryVerse.buildDedupeKey(
        translation: translation,
        bookId: bookId,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
      );
}

class MemoryVerse {
  const MemoryVerse({
    required this.id,
    required this.dedupeKey,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.translation,
    required this.textSnapshot,
    required this.source,
    required this.categories,
    this.collectionIds = const <String>[],
    required this.difficulty,
    required this.schedule,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.archivedAtUtc,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String id;
  final String dedupeKey;
  final String bookId;
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final BibleTranslation translation;
  final String textSnapshot;
  final MemoryVerseSource source;
  final List<String> categories;
  final List<String> collectionIds;
  final MemoryDifficulty difficulty;
  final MemorySchedule schedule;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? archivedAtUtc;

  String get reference {
    final verses =
        startVerse == endVerse ? '$startVerse' : '$startVerse-$endVerse';
    return '$bookName $chapter:$verses';
  }

  bool get isArchived => schedule.status == MemoryStatus.archived;

  MemoryVerse copyWith({
    List<String>? categories,
    List<String>? collectionIds,
    MemoryDifficulty? difficulty,
    MemorySchedule? schedule,
    DateTime? updatedAtUtc,
    DateTime? archivedAtUtc,
    bool clearArchivedAt = false,
  }) {
    return MemoryVerse(
      schemaVersion: schemaVersion,
      id: id,
      dedupeKey: dedupeKey,
      bookId: bookId,
      bookName: bookName,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
      translation: translation,
      textSnapshot: textSnapshot,
      source: source,
      categories: categories ?? this.categories,
      collectionIds: collectionIds ?? this.collectionIds,
      difficulty: difficulty ?? this.difficulty,
      schedule: schedule ?? this.schedule,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      archivedAtUtc:
          clearArchivedAt ? null : (archivedAtUtc ?? this.archivedAtUtc),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'dedupeKey': dedupeKey,
        'bookId': bookId,
        'bookName': bookName,
        'chapter': chapter,
        'startVerse': startVerse,
        'endVerse': endVerse,
        'translation': translation.name,
        'textSnapshot': textSnapshot,
        'source': source.name,
        'categories': categories,
        'collectionIds': collectionIds,
        'difficulty': difficulty.name,
        'schedule': schedule.toJson(),
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'updatedAtUtc': updatedAtUtc.toIso8601String(),
        'archivedAtUtc': archivedAtUtc?.toIso8601String(),
      };

  factory MemoryVerse.fromJson(Map<String, dynamic> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (schemaVersion < 1 || schemaVersion > currentSchemaVersion) {
      throw FormatException(
        'Unsupported memory verse schema version: $schemaVersion',
      );
    }
    final translationName = json['translation']?.toString();
    final translation = BibleTranslation.values.firstWhere(
      (value) => value.name == translationName,
      orElse: () => throw const FormatException('Unknown translation'),
    );
    final sourceName = json['source']?.toString();
    final source = MemoryVerseSource.values.firstWhere(
      (value) => value.name == sourceName,
      orElse: () => MemoryVerseSource.bible,
    );
    final difficultyName = json['difficulty']?.toString();
    final difficulty = MemoryDifficulty.values.firstWhere(
      (value) => value.name == difficultyName,
      orElse: () => MemoryDifficulty.normal,
    );
    final rawSchedule = json['schedule'];
    if (rawSchedule is! Map) {
      throw const FormatException('Missing memory schedule');
    }

    return MemoryVerse(
      schemaVersion: schemaVersion,
      id: json['id'].toString(),
      dedupeKey: json['dedupeKey'].toString(),
      bookId: json['bookId'].toString(),
      bookName: json['bookName'].toString(),
      chapter: (json['chapter'] as num).toInt(),
      startVerse: (json['startVerse'] as num).toInt(),
      endVerse: (json['endVerse'] as num).toInt(),
      translation: translation,
      textSnapshot: json['textSnapshot'].toString(),
      source: source,
      categories: (json['categories'] as List? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(growable: false),
      collectionIds: (json['collectionIds'] as List? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(growable: false),
      difficulty: difficulty,
      schedule: MemorySchedule.fromJson(
        Map<String, dynamic>.from(rawSchedule),
      ),
      createdAtUtc: DateTime.parse(json['createdAtUtc'].toString()).toUtc(),
      updatedAtUtc: DateTime.parse(json['updatedAtUtc'].toString()).toUtc(),
      archivedAtUtc: json['archivedAtUtc'] == null
          ? null
          : DateTime.parse(json['archivedAtUtc'].toString()).toUtc(),
    );
  }

  static String buildDedupeKey({
    required BibleTranslation translation,
    required String bookId,
    required int chapter,
    required int startVerse,
    int? endVerse,
  }) {
    final normalizedStart =
        startVerse <= (endVerse ?? startVerse) ? startVerse : endVerse!;
    final normalizedEnd = startVerse <= (endVerse ?? startVerse)
        ? (endVerse ?? startVerse)
        : startVerse;
    return '${translation.name.toUpperCase()}|'
        '${bookId.trim().toLowerCase()}|'
        '$chapter|$normalizedStart|$normalizedEnd';
  }
}
