import '../../utils/bible_text_sanitizer.dart';
import '../contracts/narratable_content.dart';
import '../models/narration_segment.dart';

class NarratableVerse implements NarratableContent {
  const NarratableVerse({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;

  String get id => 'verse-$bookId-$chapter-$verse';

  String get reference => '$bookName $chapter:$verse';

  @override
  List<NarrationSegment> get narrationSegments {
    final cleanedText = BibleTextSanitizer.clean(text);
    return [
      NarrationSegment(
        id: id,
        text: cleanedText,
        displayText: cleanedText,
        speechText: cleanedText,
        reference: reference,
        pauseAfter: const Duration(milliseconds: 900),
      ),
    ];
  }
}
