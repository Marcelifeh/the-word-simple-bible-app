import '../../domain/entities/verse_ref.dart';

sealed class SearchQuery {
  const SearchQuery();
}

class KeywordQuery extends SearchQuery {
  const KeywordQuery(this.keyword);

  final String keyword;
}

class ChapterQuery extends SearchQuery {
  const ChapterQuery(
      {required this.bookId, required this.chapter, required this.bookName});

  final String bookId;
  final int chapter;
  final String bookName;
}

class VerseQuery extends SearchQuery {
  const VerseQuery({required this.ref, required this.bookName});

  final VerseRef ref;
  final String bookName;
}
