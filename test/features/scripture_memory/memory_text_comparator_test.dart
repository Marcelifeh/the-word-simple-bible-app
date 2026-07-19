import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/scripture_memory/services/memory_text_comparator.dart';

void main() {
  const comparator = MemoryTextComparator();

  test('case and punctuation do not prevent acceptable recall', () {
    final result = comparator.compare(
      expected: 'The Lord is my shepherd; I shall not want.',
      actual: 'the lord is my shepherd i shall not want',
    );

    expect(result.isAcceptable, isTrue);
    expect(result.punctuationDifferences, isTrue);
  });

  test('omitted, additional, and out-of-order words are reported', () {
    final missing = comparator.compare(
      expected: 'The Lord is my shepherd',
      actual: 'The Lord my shepherd',
    );
    final extra = comparator.compare(
      expected: 'The Lord is my shepherd',
      actual: 'The gentle Lord is my shepherd',
    );
    final reordered = comparator.compare(
      expected: 'The Lord is my shepherd',
      actual: 'The shepherd is my Lord',
    );

    expect(missing.missingWords, contains('is'));
    expect(extra.extraWords, contains('gentle'));
    expect(reordered.outOfOrderWords, isNotEmpty);
  });

  test('apostrophes and supported African Unicode remain words', () {
    final result = comparator.compare(
      expected: "Ọlọ́run kì í kọ̀ wá; Chineke anaghị ahapụ anyị; Allah's love.",
      actual: "ọlọ́run kì í kọ̀ wá chineke anaghị ahapụ anyị Allah's love",
    );

    expect(result.isAcceptable, isTrue);
    expect(result.missingWords, isEmpty);
    expect(result.extraWords, isEmpty);
  });
}
