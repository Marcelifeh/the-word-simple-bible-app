import 'progressive_fade_generator.dart';

class MemoryComparisonResult {
  const MemoryComparisonResult({
    required this.isAcceptable,
    required this.accuracy,
    required this.missingWords,
    required this.extraWords,
    required this.outOfOrderWords,
    required this.punctuationDifferences,
  });

  final bool isAcceptable;
  final double accuracy;
  final List<String> missingWords;
  final List<String> extraWords;
  final List<String> outOfOrderWords;
  final bool punctuationDifferences;

  String get feedbackTitle {
    if (isAcceptable) return 'Excellent recall';
    if (accuracy >= 0.72) return 'Almost there';
    return 'Keep going';
  }

  String get feedbackMessage {
    if (isAcceptable) return 'You remembered the verse clearly.';
    if (accuracy >= 0.72) return 'Review this phrase once more.';
    return 'A few words need another look.';
  }
}

class MemoryTextComparator {
  const MemoryTextComparator();

  MemoryComparisonResult compare({
    required String expected,
    required String actual,
  }) {
    final expectedWords = _words(expected);
    final actualWords = _words(actual);
    final lcs = _longestCommonSubsequence(expectedWords, actualWords);
    final denominator = expectedWords.length.clamp(1, 1 << 20);
    final accuracy = (lcs.length / denominator).clamp(0.0, 1.0);

    final missing = _multisetDifference(expectedWords, actualWords);
    final extra = _multisetDifference(actualWords, expectedWords);
    final outOfOrder = missing.isEmpty &&
            extra.isEmpty &&
            !_sameSequence(expectedWords, actualWords)
        ? _outOfOrderWords(expectedWords, actualWords)
        : const <String>[];
    final punctuationDifferences =
        _punctuationSignature(expected) != _punctuationSignature(actual);
    final acceptable = accuracy >= 0.90 &&
        missing.length <= 1 &&
        extra.length <= 1 &&
        outOfOrder.isEmpty;

    return MemoryComparisonResult(
      isAcceptable: acceptable,
      accuracy: accuracy,
      missingWords: List<String>.unmodifiable(missing),
      extraWords: List<String>.unmodifiable(extra),
      outOfOrderWords: List<String>.unmodifiable(outOfOrder),
      punctuationDifferences: punctuationDifferences,
    );
  }

  List<String> _words(String value) {
    return ProgressiveFadeGenerator.wordPattern
        .allMatches(value)
        .map((match) => match.group(0)!.toLowerCase())
        .toList(growable: false);
  }

  static List<String> _longestCommonSubsequence(
    List<String> expected,
    List<String> actual,
  ) {
    final rows = List.generate(
      expected.length + 1,
      (_) => List<int>.filled(actual.length + 1, 0),
    );
    for (var i = 1; i <= expected.length; i++) {
      for (var j = 1; j <= actual.length; j++) {
        rows[i][j] = expected[i - 1] == actual[j - 1]
            ? rows[i - 1][j - 1] + 1
            : (rows[i - 1][j] > rows[i][j - 1]
                ? rows[i - 1][j]
                : rows[i][j - 1]);
      }
    }
    final result = <String>[];
    var i = expected.length;
    var j = actual.length;
    while (i > 0 && j > 0) {
      if (expected[i - 1] == actual[j - 1]) {
        result.add(expected[i - 1]);
        i--;
        j--;
      } else if (rows[i - 1][j] >= rows[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }
    return result.reversed.toList(growable: false);
  }

  static List<String> _multisetDifference(
    List<String> source,
    List<String> comparison,
  ) {
    final counts = <String, int>{};
    for (final word in comparison) {
      counts[word] = (counts[word] ?? 0) + 1;
    }
    final difference = <String>[];
    for (final word in source) {
      final count = counts[word] ?? 0;
      if (count == 0) {
        difference.add(word);
      } else {
        counts[word] = count - 1;
      }
    }
    return difference;
  }

  static bool _sameSequence(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  static List<String> _outOfOrderWords(
    List<String> expected,
    List<String> actual,
  ) {
    final words = <String>[];
    for (var index = 0; index < expected.length; index++) {
      if (expected[index] != actual[index] && !words.contains(actual[index])) {
        words.add(actual[index]);
      }
    }
    return words;
  }

  static String _punctuationSignature(String value) {
    return value
        .replaceAll(ProgressiveFadeGenerator.wordPattern, '')
        .replaceAll(RegExp(r'\s+'), '');
  }
}
