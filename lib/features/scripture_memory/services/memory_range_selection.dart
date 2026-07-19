import '../../../core/utils/scripture_reference_parser.dart';
import '../../../domain/entities/bible_translation.dart';
import '../../../domain/entities/verse.dart';
import '../model/memory_verse.dart';

class MemoryRangeSelection {
  const MemoryRangeSelection();

  List<MemoryVerseDraft> buildDrafts({
    required ScriptureReferenceRange reference,
    required List<Verse> verses,
    required Set<int> selectedVerseNumbers,
    required BibleTranslation translation,
    required MemoryVerseSource source,
    List<String> categories = const <String>[],
  }) {
    final availableByNumber = <int, Verse>{
      for (final verse in verses) verse.ref.verse: verse,
    };
    final selected = selectedVerseNumbers
        .where(availableByNumber.containsKey)
        .toList(growable: false)
      ..sort();
    if (selected.isEmpty) return const <MemoryVerseDraft>[];

    final groups = <List<int>>[];
    for (final verseNumber in selected) {
      if (groups.isEmpty || verseNumber != groups.last.last + 1) {
        groups.add(<int>[verseNumber]);
      } else {
        groups.last.add(verseNumber);
      }
    }
    return groups.map((group) {
      final selectedVerses = group
          .map((verseNumber) => availableByNumber[verseNumber]!)
          .toList(growable: false);
      return MemoryVerseDraft(
        bookId: reference.bookId,
        bookName: reference.bookName,
        chapter: reference.chapter,
        startVerse: group.first,
        endVerse: group.last,
        translation: translation,
        text: selectedVerses.map((verse) => verse.text).join(' '),
        source: source,
        categories: categories,
      );
    }).toList(growable: false);
  }
}
