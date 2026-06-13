import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse_ref.dart';

abstract class AudioBibleService {
  Future<Uri?> getVerseAudioUrl(BibleTranslation translation, VerseRef ref);
}
