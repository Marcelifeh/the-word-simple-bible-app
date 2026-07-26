import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/sermon_notes/utils/scripture_parser.dart';

void main() {
  group('ScriptureParser', () {
    test('detects typed scripture references', () {
      final scriptures = ScriptureParser.extractScriptures(
        'Please open John 3:16 and Romans 8:28 today.',
      );

      expect(scriptures.map((item) => item.displayTitle), [
        'John 3:16',
        'Romans 8:28',
      ]);
    });

    test('detects chapter and verse wording from transcripts', () {
      final scriptures = ScriptureParser.extractScriptures(
        'The sermon text is John chapter 3 verse 16.',
      );

      expect(scriptures.single.bookId, 'john');
      expect(scriptures.single.chapter, 3);
      expect(scriptures.single.startVerse, 16);
    });

    test('detects spoken number references', () {
      final scriptures = ScriptureParser.extractScriptures(
        'Let us read John chapter three verse sixteen.',
      );

      expect(scriptures.single.displayTitle, 'John 3:16');
    });

    test('detects compact spoken references for common sermon phrasing', () {
      final scriptures = ScriptureParser.extractScriptures(
        'The preacher quoted Romans eight twenty eight.',
      );

      expect(scriptures.single.displayTitle, 'Romans 8:28');
    });

    test('detects numbered books and abbreviations', () {
      final scriptures = ScriptureParser.extractScriptures(
        'We moved from First Corinthians 13 to Jn 15:5.',
      );

      expect(scriptures.map((item) => item.displayTitle), [
        '1 Corinthians 13',
        'John 15:5',
      ]);
    });

    test('detects dotted abbreviations with original offsets', () {
      const text =
          'Read Jn. 3:16, Lk. 2:4, Rom. 8:28, Ps. 23:1, and 1 Jn. 4:7.';
      final matches = ScriptureParser.findMatches(text);

      expect(matches.map((item) => item.scripture.displayTitle), [
        'John 3:16',
        'Luke 2:4',
        'Romans 8:28',
        'Psalms 23:1',
        '1 John 4:7',
      ]);
      expect(
          text.substring(matches.first.start, matches.first.end), 'Jn. 3:16');
      expect(text.substring(matches.last.start, matches.last.end), '1 Jn. 4:7');
    });

    test('detects spoken chapter and verse references with number words', () {
      final scriptures = ScriptureParser.extractScriptures(
        'John three verse sixteen and Romans chapter eight verse twenty eight.',
      );

      expect(scriptures.map((item) => item.displayTitle), [
        'John 3:16',
        'Romans 8:28',
      ]);
    });
    test('keeps Psalm twenty three as chapter reference', () {
      final scriptures = ScriptureParser.extractScriptures(
        'The choir sang from Psalm twenty three.',
      );

      expect(scriptures.single.displayTitle, 'Psalms 23');
      expect(scriptures.single.startVerse, isNull);
    });

    test('keeps every repeated reference at its own text range', () {
      const text = 'John 3:16 opens the thought. John 3:16 closes it.';
      final matches = ScriptureParser.findMatches(text);

      expect(matches, hasLength(2));
      expect(
        matches.map((match) => text.substring(match.start, match.end)),
        ['John 3:16', 'John 3:16'],
      );
      expect(matches[0].start, isNot(matches[1].start));
    });

    test('keeps three identical references independently tappable', () {
      const text = 'Romans 8:28, Romans 8:28, and Romans 8:28.';
      final matches = ScriptureParser.findMatches(text);

      expect(matches, hasLength(3));
      for (final match in matches) {
        expect(
          ScriptureParser.matchAtOffset(matches, match.start),
          same(match),
        );
      }
    });

    test('recomputes ranges from the full text after edits', () {
      const initialText = 'Read John 3:16.';
      const appendedText = 'Read John 3:16. Then read John 3:16.';
      const deletedText = ' Then read John 3:16.';

      expect(ScriptureParser.findMatches(initialText), hasLength(1));
      expect(ScriptureParser.findMatches(appendedText), hasLength(2));

      final remainingMatch = ScriptureParser.findMatches(deletedText).single;
      expect(remainingMatch.start, deletedText.indexOf('John 3:16'));
      expect(
        deletedText.substring(remainingMatch.start, remainingMatch.end),
        'John 3:16',
      );
    });

    test('treats omitted chapters in one-chapter books as verse references',
        () {
      const cases = <String, (String, String)>{
        'Obadiah 3-5': ('obadiah', 'Obadiah 1:3-5'),
        'Philemon 4': ('philemon', 'Philemon 1:4'),
        '2 John 7-11': ('2_john', '2 John 1:7-11'),
        '3 John 8': ('3_john', '3 John 1:8'),
        'Jude 20-21': ('jude', 'Jude 1:20-21'),
      };

      for (final MapEntry(key: text, value: expected) in cases.entries) {
        final match = ScriptureParser.findMatches(text).single;

        expect(match.scripture.bookId, expected.$1, reason: text);
        expect(match.scripture.chapter, 1, reason: text);
        expect(match.scripture.displayTitle, expected.$2, reason: text);
        expect(text.substring(match.start, match.end), text);
      }
    });

    test('keeps explicit chapter syntax for one-chapter books', () {
      final scripture =
          ScriptureParser.extractScriptures('Read 2 John 1:7-11.').single;

      expect(scripture.bookId, '2_john');
      expect(scripture.chapter, 1);
      expect(scripture.startVerse, 7);
      expect(scripture.endVerse, 11);
      expect(scripture.displayTitle, '2 John 1:7-11');
    });

    test('does not duplicate explicit one-chapter references', () {
      final withVerseWord =
          ScriptureParser.findMatches('Read Jude 1 verse 20.').single;
      final withSpace = ScriptureParser.findMatches('Read Jude 1 20.').single;

      expect(withVerseWord.scripture.displayTitle, 'Jude 1:20');
      expect(withSpace.scripture.displayTitle, 'Jude 1:20');
    });

    test('does not treat ranges in multi-chapter books as omitted chapters',
        () {
      final scripture =
          ScriptureParser.extractScriptures('Read John 7-11.').single;

      expect(scripture.bookId, 'john');
      expect(scripture.chapter, 7);
      expect(scripture.startVerse, isNull);
      expect(scripture.endVerse, isNull);
      expect(scripture.rawText, 'John 7');
    });

    test('matches taps only inside a scripture character range', () {
      const text = 'Before John 3:16 after';
      final matches = ScriptureParser.findMatches(text);
      final match = matches.single;

      expect(ScriptureParser.matchAtOffset(matches, match.start), same(match));
      expect(
        ScriptureParser.matchAtOffset(matches, match.end - 1),
        same(match),
      );
      expect(ScriptureParser.matchAtOffset(matches, match.start - 1), isNull);
      expect(ScriptureParser.matchAtOffset(matches, match.end), isNull);
      expect(ScriptureParser.matchAtOffset(matches, text.length), isNull);
    });
  });
}
