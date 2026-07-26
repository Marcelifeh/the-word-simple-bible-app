import 'word_studio_background_storage_base.dart';
import 'word_studio_background_storage_stub.dart'
    if (dart.library.io) 'word_studio_background_storage_io.dart'
    if (dart.library.html) 'word_studio_background_storage_web.dart'
    as platform;

export 'word_studio_background_storage_base.dart';

WordStudioBackgroundStorage createWordStudioBackgroundStorage() {
  return platform.createWordStudioBackgroundStorage();
}
