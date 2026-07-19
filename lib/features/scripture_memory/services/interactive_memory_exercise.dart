import '../model/memory_review_event.dart';
import '../model/memory_verse.dart';
import 'memory_exercise_generator.dart';
import 'progressive_fade_generator.dart';

sealed class InteractiveMemoryToken {
  const InteractiveMemoryToken();
}

class VisibleMemoryText extends InteractiveMemoryToken {
  const VisibleMemoryText(this.text);

  final String text;
}

class EditableMemoryBlank extends InteractiveMemoryToken {
  const EditableMemoryBlank({
    required this.index,
    required this.answer,
    required this.trailingText,
  });

  final int index;
  final String answer;
  final String trailingText;
}

class FirstLetterBlank extends InteractiveMemoryToken {
  const FirstLetterBlank({
    required this.index,
    required this.firstLetter,
    required this.remainingAnswer,
    required this.trailingText,
  });

  final int index;
  final String firstLetter;
  final String remainingAnswer;
  final String trailingText;

  String get fullAnswer => '$firstLetter$remainingAnswer';
}

enum MemoryBlankState { unanswered, correct, needsReview, revealed }

class InteractiveMemoryExerciseGenerator {
  const InteractiveMemoryExerciseGenerator({
    MemoryExerciseGenerator exerciseGenerator = const MemoryExerciseGenerator(),
  }) : _exerciseGenerator = exerciseGenerator;

  final MemoryExerciseGenerator _exerciseGenerator;

  List<InteractiveMemoryToken> build({
    required MemoryVerse verse,
    required MemoryExerciseMode mode,
  }) {
    if (mode != MemoryExerciseMode.missingWords &&
        mode != MemoryExerciseMode.firstLetter) {
      throw ArgumentError.value(mode, 'mode', 'Interactive mode required');
    }
    final text = verse.textSnapshot;
    final matches = ProgressiveFadeGenerator.wordPattern
        .allMatches(text)
        .toList(growable: false);
    if (matches.isEmpty) {
      return <InteractiveMemoryToken>[VisibleMemoryText(text)];
    }
    final missingIndexes = mode == MemoryExerciseMode.missingWords
        ? _exerciseGenerator.missingWordIndexes(
            text,
            difficulty: verse.difficulty,
            stage: verse.schedule.stage,
          )
        : <int>{};
    final tokens = <InteractiveMemoryToken>[];
    var blankIndex = 0;
    var cursor = 0;
    for (var wordIndex = 0; wordIndex < matches.length; wordIndex++) {
      final match = matches[wordIndex];
      if (cursor < match.start) {
        tokens.add(VisibleMemoryText(text.substring(cursor, match.start)));
      }
      final nextStart = wordIndex + 1 < matches.length
          ? matches[wordIndex + 1].start
          : text.length;
      final trailing = text.substring(match.end, nextStart);
      final word = match.group(0)!;
      if (mode == MemoryExerciseMode.missingWords &&
          missingIndexes.contains(wordIndex)) {
        tokens.add(
          EditableMemoryBlank(
            index: blankIndex++,
            answer: word,
            trailingText: trailing,
          ),
        );
      } else if (mode == MemoryExerciseMode.firstLetter &&
          _visibleGraphemeLength(word) > 1) {
        final split = _splitFirstGrapheme(word);
        tokens.add(
          FirstLetterBlank(
            index: blankIndex++,
            firstLetter: split.$1,
            remainingAnswer: split.$2,
            trailingText: trailing,
          ),
        );
      } else {
        tokens.add(VisibleMemoryText('$word$trailing'));
      }
      cursor = nextStart;
    }
    return List<InteractiveMemoryToken>.unmodifiable(tokens);
  }

  static (String, String) _splitFirstGrapheme(String word) {
    final runes = word.runes.toList(growable: false);
    var splitAt = 1;
    while (splitAt < runes.length &&
        runes[splitAt] >= 0x0300 &&
        runes[splitAt] <= 0x036f) {
      splitAt++;
    }
    return (
      String.fromCharCodes(runes.take(splitAt)),
      String.fromCharCodes(runes.skip(splitAt)),
    );
  }

  static int _visibleGraphemeLength(String word) {
    var count = 0;
    for (final rune in word.runes) {
      if (rune < 0x0300 || rune > 0x036f) count++;
    }
    return count;
  }
}
