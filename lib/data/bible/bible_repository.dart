import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse.dart';

abstract class BibleRepository {
  Future<List<Verse>> loadChapter({
    required BibleTranslation translation,
    required String bookId,
    required int chapter,
  });

  Future<List<Verse>> searchKeyword({
    required BibleTranslation translation,
    required String query,
    int limit = 50,
  });
}
