import '../../domain/entities/bible_translation.dart';

const supportedCommentaryLanguageCodes = <String>{'en'};

bool hasTranslatedCommentary(String languageCode) {
  return supportedCommentaryLanguageCodes.contains(languageCode.toLowerCase());
}

bool hasCommentaryForTranslation(BibleTranslation translation) {
  return hasTranslatedCommentary(commentaryLanguageCode(translation));
}

String commentaryLanguageCode(BibleTranslation translation) {
  return switch (translation) {
    BibleTranslation.kjv ||
    BibleTranslation.web ||
    BibleTranslation.nkjv ||
    BibleTranslation.niv ||
    BibleTranslation.esv ||
    BibleTranslation.nlt =>
      'en',
    BibleTranslation.hausa => 'ha',
    BibleTranslation.igbo => 'ig',
    BibleTranslation.yoruba => 'yo',
    BibleTranslation.french => 'fr',
    BibleTranslation.spanish => 'es',
  };
}

String commentaryLanguageName(BibleTranslation translation) {
  return switch (commentaryLanguageCode(translation)) {
    'en' => 'English',
    'ha' => 'Hausa',
    'ig' => 'Igbo',
    'yo' => 'Yoruba',
    'fr' => 'French',
    'es' => 'Spanish',
    _ => 'this language',
  };
}
