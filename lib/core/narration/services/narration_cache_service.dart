abstract class NarrationCacheService {
  Future<String?> getAudioPath(String segmentId);

  Future<void> setAudioPath(String segmentId, String path);

  Future<void> clear();
}

class LocalNarrationCacheService implements NarrationCacheService {
  final Map<String, String> _cache = <String, String>{};

  @override
  Future<String?> getAudioPath(String segmentId) async {
    return _cache[segmentId];
  }

  @override
  Future<void> setAudioPath(String segmentId, String path) async {
    _cache[segmentId] = path;
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }
}