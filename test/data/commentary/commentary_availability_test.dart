import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/data/commentary/commentary_availability.dart';
import 'package:simple_bible_app/data/commentary/commentary_repository.dart';
import 'package:simple_bible_app/domain/entities/bible_translation.dart';
import 'package:simple_bible_app/domain/entities/verse_ref.dart';
import 'package:simple_bible_app/shared/widgets/verse_insight_panel.dart';

void main() {
  group('commentary availability', () {
    test('enables every English translation', () {
      const englishTranslations = {
        BibleTranslation.kjv,
        BibleTranslation.web,
        BibleTranslation.nkjv,
        BibleTranslation.niv,
        BibleTranslation.esv,
        BibleTranslation.nlt,
      };

      for (final translation in englishTranslations) {
        expect(
          hasCommentaryForTranslation(translation),
          isTrue,
          reason: translation.name,
        );
      }
    });

    test('disables translations without reviewed commentary', () {
      const unavailableTranslations = {
        BibleTranslation.hausa,
        BibleTranslation.igbo,
        BibleTranslation.yoruba,
        BibleTranslation.french,
        BibleTranslation.spanish,
      };

      for (final translation in unavailableTranslations) {
        expect(
          hasCommentaryForTranslation(translation),
          isFalse,
          reason: translation.name,
        );
      }
    });

    test('repository exits before cache or API access for local languages',
        () async {
      final repository = CommentaryRepository();
      const ref = VerseRef(bookId: 'john', chapter: 3, verse: 16);

      for (final translation in const {
        BibleTranslation.hausa,
        BibleTranslation.igbo,
        BibleTranslation.yoruba,
      }) {
        final result = await repository.getOrGenerateAndStore(
          translation: translation,
          ref: ref,
          verseText: 'Translated verse text',
          bookName: 'John',
        );

        expect(result, isNull, reason: translation.name);
      }
    });
  });

  testWidgets('shows coming-soon copy instead of English commentary',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerseInsightPanel(
            translation: BibleTranslation.hausa,
            rawText: 'Understanding: This English insight must stay hidden.',
            accentColor: Color(0xFF8B5CF6),
          ),
        ),
      ),
    );

    expect(
      find.text('Commentary in Hausa is coming soon.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'The verse text is available, but the translated insight for this '
        'language has not been added yet.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('English insight'), findsNothing);
  });
}
