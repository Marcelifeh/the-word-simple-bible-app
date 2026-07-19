import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/scripture_memory/services/progressive_fade_generator.dart';

void main() {
  const generator = ProgressiveFadeGenerator();

  test('output is deterministic and preserves punctuation', () {
    const text = 'The Lord is my shepherd; I shall not want.';
    final first = generator.generate(text, level: 3);
    final second = generator.generate(text, level: 3);

    expect(first.visibleText, second.visibleText);
    expect(first.hiddenWordIndexes, second.hiddenWordIndexes);
    expect(first.visibleText, contains(';'));
    expect(first.visibleText, endsWith('.'));
  });

  test('apostrophes, hyphens, Unicode, and numbers stay intact', () {
    const text = "Ọlọ́run's well-being in Psalm 23:1 is certain.";
    final step = generator.generate(text, level: 2);

    expect(step.visibleText, contains('23:1'));
    expect(step.visibleText, contains('-'));
    expect(step.visibleText, contains("'"));
  });

  test('short verses and text without words remain safe', () {
    expect(
        generator.generate('Jesus wept.', level: 4).visibleText, endsWith('.'));
    expect(generator.generate('23:1 — …', level: 4).hiddenWordIndexes, isEmpty);
  });

  test('all-trivial wording still produces a stable exercise', () {
    final step = generator.generate('and the of in', level: 4);

    expect(step.hiddenWordIndexes, isNotEmpty);
    expect(step.visibleText, isNotEmpty);
  });

  test('revealing one word removes one hidden index', () {
    const text = 'The Lord is my shepherd and my strength.';
    final step = generator.generate(text, level: 4);
    final revealed = generator.revealWord(text, step);

    expect(
      revealed.hiddenWordIndexes.length,
      step.hiddenWordIndexes.length - 1,
    );
  });
}
