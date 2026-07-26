import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/core/narration/content/narratable_verse.dart';

void main() {
  test('builds one clean verse narration segment with stable metadata', () {
    const content = NarratableVerse(
      bookId: 'deuteronomy',
      bookName: 'Deuteronomy',
      chapter: 30,
      verse: 8,
      text: r'The |+w LORD |+w* will guide you.',
    );

    expect(content.id, 'verse-deuteronomy-30-8');
    expect(content.reference, 'Deuteronomy 30:8');
    expect(content.narrationSegments, hasLength(1));

    final segment = content.narrationSegments.single;
    expect(segment.id, content.id);
    expect(segment.reference, content.reference);
    expect(segment.displayText, 'The LORD will guide you.');
    expect(segment.speechText, 'The LORD will guide you.');
    expect(segment.pauseAfter, const Duration(milliseconds: 900));
  });
}
