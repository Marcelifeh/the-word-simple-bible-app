class MemoryCollectionReference {
  const MemoryCollectionReference({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
  });

  final String bookId;
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;

  String get id => '$bookId|$chapter|$startVerse|$endVerse';

  String get label {
    final verses =
        startVerse == endVerse ? '$startVerse' : '$startVerse-$endVerse';
    return '$bookName $chapter:$verses';
  }

  factory MemoryCollectionReference.fromJson(Map<String, dynamic> json) {
    final start = (json['startVerse'] as num).toInt();
    final end = (json['endVerse'] as num?)?.toInt() ?? start;
    return MemoryCollectionReference(
      bookId: json['bookId'].toString().trim().toLowerCase(),
      bookName: json['bookName'].toString().trim(),
      chapter: (json['chapter'] as num).toInt(),
      startVerse: start <= end ? start : end,
      endVerse: start <= end ? end : start,
    );
  }
}

class MemoryCollection {
  const MemoryCollection({
    required this.id,
    required this.title,
    required this.description,
    required this.theme,
    required this.estimatedDays,
    required this.references,
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String id;
  final String title;
  final String description;
  final String theme;
  final int estimatedDays;
  final List<MemoryCollectionReference> references;

  factory MemoryCollection.fromJson(Map<String, dynamic> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported memory collection schema version: $schemaVersion',
      );
    }
    final references = (json['references'] as List? ?? const <dynamic>[])
        .map(
          (value) => MemoryCollectionReference.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList(growable: false);
    if (references.isEmpty) {
      throw const FormatException('Memory collection has no references');
    }
    return MemoryCollection(
      id: json['id'].toString(),
      title: json['title'].toString(),
      description: json['description'].toString(),
      theme: json['theme'].toString(),
      estimatedDays: (json['estimatedDays'] as num?)?.toInt() ?? 14,
      references: List<MemoryCollectionReference>.unmodifiable(references),
      schemaVersion: schemaVersion,
    );
  }
}
