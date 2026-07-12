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
