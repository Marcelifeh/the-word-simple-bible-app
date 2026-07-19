import '../../../core/utils/scripture_reference_parser.dart';
import '../../../data/bible/bible_repository.dart';
import '../../../domain/entities/bible_translation.dart';
import '../../../domain/entities/verse.dart';

class ResolvedMemoryPassage {
  const ResolvedMemoryPassage({
    required this.reference,
    required this.translation,
    required this.verses,
  });

  final ScriptureReferenceRange reference;
  final BibleTranslation translation;
  final List<Verse> verses;

  bool get isAvailable =>
      verses.length == reference.endVerse - reference.startVerse + 1;
  String get text => verses.map((verse) => verse.text).join(' ');
}

class MemoryPassageResolver {
  const MemoryPassageResolver(this.repository);

  final BibleRepository repository;

  Future<ResolvedMemoryPassage> resolve({
    required ScriptureReferenceRange reference,
    required BibleTranslation translation,
  }) async {
    final chapter = await repository.loadChapter(
      translation: translation,
      bookId: reference.bookId,
      chapter: reference.chapter,
    );
    final verses = chapter
        .where(
          (verse) =>
              verse.ref.verse >= reference.startVerse &&
              verse.ref.verse <= reference.endVerse &&
              !verse.isFallback &&
              verse.text.trim().isNotEmpty &&
              !verse.text.startsWith('This verse is not available'),
        )
        .toList(growable: false);
    final expectedCount = reference.endVerse - reference.startVerse + 1;
    return ResolvedMemoryPassage(
      reference: reference,
      translation: translation,
      verses: verses.length == expectedCount ? verses : const <Verse>[],
    );
  }
}
