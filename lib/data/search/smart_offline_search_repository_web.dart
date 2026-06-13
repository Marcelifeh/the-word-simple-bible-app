import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse.dart';

import '../bible/bible_asset_repository.dart';
import 'smart_offline_search_repository_api.dart';

class _WebSmartOfflineSearchRepository implements SmartOfflineSearchRepository {
  @override
  Future<void> ensureBuilt({
    required BibleTranslation translation,
    required BibleAssetRepository bibleRepo,
  }) async {
    // Web: prefer API search when available. Offline smart search not supported.
  }

  @override
  Future<List<Verse>> search({
    required BibleTranslation translation,
    required String query,
    int limit = 50,
  }) async {
    return const [];
  }
}

SmartOfflineSearchRepository createSmartOfflineSearchRepository() =>
    _WebSmartOfflineSearchRepository();
