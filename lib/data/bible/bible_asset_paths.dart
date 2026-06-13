import '../../domain/entities/bible_translation.dart';

class BibleAssetPaths {
  static String? legacyAllVersesPath(BibleTranslation t) {
    switch (t) {
      case BibleTranslation.kjv:
        return 'assets/data/bibles/kjv_sample.json';
      case BibleTranslation.web:
        return 'assets/data/bibles/web_sample.json';
      case BibleTranslation.french:
        return 'assets/data/bibles/french_sample.json';
      case BibleTranslation.spanish:
        return 'assets/data/bibles/spanish_sample.json';
      case BibleTranslation.nkjv:
      case BibleTranslation.niv:
      case BibleTranslation.esv:
      case BibleTranslation.nlt:
        return null; // requires licensed data
      default:
        return null;
    }
  }

  static String? chapterRoot(BibleTranslation t) {
    const roots = {
      BibleTranslation.kjv: 'assets/data/bibles/kjv',
      BibleTranslation.web: 'assets/data/bibles/web',
      BibleTranslation.hausa: 'assets/data/bibles/hausa',
      BibleTranslation.igbo: 'assets/data/bibles/igbo',
      BibleTranslation.yoruba: 'assets/data/bibles/yoruba',
    };
    return roots[t];
  }
}
