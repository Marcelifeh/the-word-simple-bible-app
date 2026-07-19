import '../model/memory_review_event.dart';
import '../model/memory_schedule.dart';
import '../model/memory_verse.dart';
import 'progressive_fade_generator.dart';

class MemoryExercise {
  const MemoryExercise({
    required this.mode,
    required this.prompt,
    required this.answer,
  });

  final MemoryExerciseMode mode;
  final String prompt;
  final String answer;
}

class MemoryExerciseGenerator {
  const MemoryExerciseGenerator({
    ProgressiveFadeGenerator fadeGenerator = const ProgressiveFadeGenerator(),
  }) : _fadeGenerator = fadeGenerator;

  final ProgressiveFadeGenerator _fadeGenerator;

  static RegExp get _wordPattern => ProgressiveFadeGenerator.wordPattern;

  MemoryExerciseMode activeModeFor(MemoryVerse verse) {
    return chooseMode(verse: verse, recentlyUsedModes: const {});
  }

  MemoryExerciseMode chooseMode({
    required MemoryVerse verse,
    required Set<MemoryExerciseMode> recentlyUsedModes,
  }) {
    final schedule = verse.schedule;
    final candidates = switch (schedule.status) {
      MemoryStatus.newVerse || MemoryStatus.learning => <MemoryExerciseMode>[
          MemoryExerciseMode.missingWords,
          MemoryExerciseMode.firstLetter,
        ],
      MemoryStatus.reviewing when schedule.stage <= 3 => <MemoryExerciseMode>[
          MemoryExerciseMode.missingWords,
          MemoryExerciseMode.progressiveFade,
          MemoryExerciseMode.firstLetter,
        ],
      MemoryStatus.reviewing => <MemoryExerciseMode>[
          MemoryExerciseMode.progressiveFade,
          MemoryExerciseMode.typeIt,
          MemoryExerciseMode.missingWords,
        ],
      MemoryStatus.established => <MemoryExerciseMode>[
          MemoryExerciseMode.typeIt,
          MemoryExerciseMode.firstLetter,
          MemoryExerciseMode.progressiveFade,
        ],
      MemoryStatus.archived => const <MemoryExerciseMode>[],
    };
    if (candidates.isEmpty) return MemoryExerciseMode.read;

    final difficultyPreferred = switch (verse.difficulty) {
      MemoryDifficulty.easy => candidates.reversed.toList(growable: false),
      MemoryDifficulty.normal => candidates,
      MemoryDifficulty.hard => candidates,
    };
    for (final mode in difficultyPreferred) {
      if (!recentlyUsedModes.contains(mode)) return mode;
    }
    return candidates[schedule.reviewCount % candidates.length];
  }

  MemoryExercise build({
    required MemoryVerse verse,
    required MemoryExerciseMode mode,
  }) {
    return switch (mode) {
      MemoryExerciseMode.read => MemoryExercise(
          mode: mode,
          prompt: verse.textSnapshot,
          answer: verse.textSnapshot,
        ),
      MemoryExerciseMode.firstLetter => MemoryExercise(
          mode: mode,
          prompt: firstLetterPrompt(verse.textSnapshot),
          answer: verse.textSnapshot,
        ),
      MemoryExerciseMode.missingWords => MemoryExercise(
          mode: mode,
          prompt: missingWordsPrompt(
            verse.textSnapshot,
            difficulty: verse.difficulty,
            stage: verse.schedule.stage,
          ),
          answer: verse.textSnapshot,
        ),
      MemoryExerciseMode.progressiveFade => MemoryExercise(
          mode: mode,
          prompt: _fadeGenerator
              .generate(
                verse.textSnapshot,
                level: _fadeLevelFor(verse),
              )
              .visibleText,
          answer: verse.textSnapshot,
        ),
      MemoryExerciseMode.typeIt => MemoryExercise(
          mode: mode,
          prompt: 'Recall the passage in your own typing.',
          answer: verse.textSnapshot,
        ),
    };
  }

  int _fadeLevelFor(MemoryVerse verse) {
    final base = switch (verse.difficulty) {
      MemoryDifficulty.easy => 1,
      MemoryDifficulty.normal => 2,
      MemoryDifficulty.hard => 3,
    };
    return (base + verse.schedule.stage ~/ 4).clamp(1, 4);
  }

  String firstLetterPrompt(String text) {
    return text.replaceAllMapped(_wordPattern, (match) {
      final word = match.group(0)!;
      return word
          .split('-')
          .map((part) => '${part.substring(0, 1)}...')
          .join('-');
    });
  }

  String missingWordsPrompt(
    String text, {
    required MemoryDifficulty difficulty,
    required int stage,
  }) {
    final matches = _wordPattern.allMatches(text).toList(growable: false);
    if (matches.isEmpty) return text;

    final baseStride = switch (difficulty) {
      MemoryDifficulty.easy => 4,
      MemoryDifficulty.normal => 3,
      MemoryDifficulty.hard => 2,
    };
    final stride = (baseStride - (stage ~/ 3)).clamp(2, 4);
    var wordIndex = 0;
    return text.replaceAllMapped(_wordPattern, (match) {
      final word = match.group(0)!;
      final shouldHide = wordIndex++ % stride == stride - 1;
      if (!shouldHide) return word;
      return List.filled(word.runes.length.clamp(3, 12).toInt(), '_').join();
    });
  }
}
