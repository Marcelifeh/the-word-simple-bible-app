import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse.dart';
import '../bible/bible_asset_repository.dart';

abstract class SmartOfflineSearchRepository {
  Future<void> ensureBuilt({
    required BibleTranslation translation,
    required BibleAssetRepository bibleRepo,
  });

  Future<List<Verse>> search({
    required BibleTranslation translation,
    required String query,
    int limit = 50,
  });
}
