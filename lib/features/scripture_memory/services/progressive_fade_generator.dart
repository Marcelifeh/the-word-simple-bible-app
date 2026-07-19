class ProgressiveFadeStep {
  const ProgressiveFadeStep({
    required this.visibleText,
    required this.hiddenWordIndexes,
    required this.level,
  });

  final String visibleText;
  final Set<int> hiddenWordIndexes;
  final int level;
}

class ProgressiveFadeGenerator {
  const ProgressiveFadeGenerator();

  static final RegExp wordPattern = RegExp(
    r"[A-Za-zÀ-ÖØ-öø-ÿĀ-ſƀ-ɏẸ-ỹ\u0300-\u036F]+(?:['’][A-Za-zÀ-ÖØ-öø-ÿĀ-ſƀ-ɏẸ-ỹ\u0300-\u036F]+)?(?:-[A-Za-zÀ-ÖØ-öø-ÿĀ-ſƀ-ɏẸ-ỹ\u0300-\u036F]+)*",
    unicode: true,
  );

  static const _hideFractions = <double>[0, 0.20, 0.40, 0.65, 0.85];
  static const _trivialWords = <String>{
    'a',
    'an',
    'and',
    'as',
    'at',
    'but',
    'by',
    'for',
    'from',
    'in',
    'is',
    'it',
    'my',
    'nor',
    'of',
    'on',
    'or',
    'so',
    'the',
    'to',
    'was',
    'with',
  };

  ProgressiveFadeStep generate(String text, {required int level}) {
    final normalizedLevel = level.clamp(0, 4);
    final matches = wordPattern.allMatches(text).toList(growable: false);
    if (matches.isEmpty || normalizedLevel == 0) {
      return ProgressiveFadeStep(
        visibleText: text,
        hiddenWordIndexes: const <int>{},
        level: normalizedLevel,
      );
    }

    final target = (matches.length * _hideFractions[normalizedLevel])
        .round()
        .clamp(1, matches.length);
    final candidates = <_FadeCandidate>[
      for (var index = 0; index < matches.length; index++)
        _FadeCandidate(
          index: index,
          word: matches[index].group(0)!,
          isMeaningful: !_trivialWords.contains(
            matches[index].group(0)!.toLowerCase(),
          ),
          score: _stableScore(text, matches[index].group(0)!, index),
        ),
    ]..sort((a, b) {
        final meaningOrder =
            (b.isMeaningful ? 1 : 0).compareTo(a.isMeaningful ? 1 : 0);
        if (meaningOrder != 0) return meaningOrder;
        final scoreOrder = a.score.compareTo(b.score);
        return scoreOrder != 0 ? scoreOrder : a.index.compareTo(b.index);
      });

    final hidden =
        candidates.take(target).map((candidate) => candidate.index).toSet();
    return ProgressiveFadeStep(
      visibleText: _render(text, matches, hidden),
      hiddenWordIndexes: Set<int>.unmodifiable(hidden),
      level: normalizedLevel,
    );
  }

  ProgressiveFadeStep revealWord(
    String text,
    ProgressiveFadeStep step, {
    int? wordIndex,
  }) {
    if (step.hiddenWordIndexes.isEmpty) return step;
    final revealIndex =
        wordIndex != null && step.hiddenWordIndexes.contains(wordIndex)
            ? wordIndex
            : (step.hiddenWordIndexes.toList()..sort()).first;
    final hidden = Set<int>.from(step.hiddenWordIndexes)..remove(revealIndex);
    final matches = wordPattern.allMatches(text).toList(growable: false);
    return ProgressiveFadeStep(
      visibleText: _render(text, matches, hidden),
      hiddenWordIndexes: Set<int>.unmodifiable(hidden),
      level: step.level,
    );
  }

  static String _render(
    String text,
    List<RegExpMatch> matches,
    Set<int> hidden,
  ) {
    final buffer = StringBuffer();
    var cursor = 0;
    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      buffer.write(text.substring(cursor, match.start));
      final word = match.group(0)!;
      buffer.write(hidden.contains(index) ? _blankFor(word) : word);
      cursor = match.end;
    }
    buffer.write(text.substring(cursor));
    return buffer.toString();
  }

  static String _blankFor(String word) {
    return word.splitMapJoin(
      RegExp(r"['’-]"),
      onMatch: (match) => match.group(0)!,
      onNonMatch: (part) {
        final length = part.runes.length.clamp(3, 12);
        return List.filled(length, '_').join();
      },
    );
  }

  static int _stableScore(String text, String word, int index) {
    var hash = 2166136261;
    for (final rune in '$text|$word|$index'.runes) {
      hash ^= rune;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}

class _FadeCandidate {
  const _FadeCandidate({
    required this.index,
    required this.word,
    required this.isMeaningful,
    required this.score,
  });

  final int index;
  final String word;
  final bool isMeaningful;
  final int score;
}
