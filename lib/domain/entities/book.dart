enum Testament { old, newTestament }

class Book {
  const Book({
    required this.id,
    required this.name,
    required this.testament,
    required this.chapterCount,
  });

  final String id;
  final String name;
  final Testament testament;
  final int chapterCount;
}
