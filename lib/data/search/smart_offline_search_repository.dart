export 'smart_offline_search_repository_api.dart';

import 'smart_offline_search_repository_api.dart';
import 'smart_offline_search_repository_io.dart'
    if (dart.library.html) 'smart_offline_search_repository_web.dart' as impl;

SmartOfflineSearchRepository createSmartOfflineSearchRepository() =>
    impl.createSmartOfflineSearchRepository();
