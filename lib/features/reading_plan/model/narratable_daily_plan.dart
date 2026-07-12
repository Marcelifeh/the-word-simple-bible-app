import '../../../core/narration/contracts/narratable_content.dart';
import '../../../core/narration/models/narration_segment.dart';
import '../../../core/utils/bible_text_sanitizer.dart';
import '../../../domain/entities/verse.dart';
import 'daily_plan_passage.dart';

class DailyPlanChapterContent {
  const DailyPlanChapterContent({
    required this.passage,
    required this.verses,
  });

  final DailyPlanPassage passage;
  final List<Verse> verses;
}

class NarratableDailyPlan implements NarratableContent {
  const NarratableDailyPlan({required this.chapters});

  final List<DailyPlanChapterContent> chapters;

  @override
  List<NarrationSegment> get narrationSegments {
    final segments = <NarrationSegment>[];

    for (final chapter in chapters) {
      segments.add(
        NarrationSegment(
          id: 'daily_plan_${chapter.passage.bookId}_${chapter.passage.chapter}_heading',
          text: chapter.passage.label,
          reference: chapter.passage.label,
          pauseAfter: const Duration(seconds: 1),
        ),
      );

      for (final verse in chapter.verses) {
        final verseNumber = verse.ref.verse;
        segments.add(
          NarrationSegment(
            id: 'daily_plan_${chapter.passage.bookId}_${chapter.passage.chapter}_$verseNumber',
            text: '$verseNumber. ${BibleTextSanitizer.clean(verse.text)}',
            reference: '${chapter.passage.label}:$verseNumber',
            pauseAfter: const Duration(milliseconds: 700),
          ),
        );
      }
    }

    return segments;
  }
}
