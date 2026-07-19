import 'memory_text_comparator.dart';
import 'progressive_fade_generator.dart';

class TypedRecallController {
  TypedRecallController({
    required this.expectedText,
    this.phraseWordLimit = 18,
    MemoryTextComparator comparator = const MemoryTextComparator(),
  }) : _comparator = comparator {
    phrases = _buildPhrases(expectedText, phraseWordLimit);
  }

  final String expectedText;
  final int phraseWordLimit;
  final MemoryTextComparator _comparator;
  late final List<String> phrases;

  int currentPhraseIndex = 0;
  final List<MemoryComparisonResult> _results = [];

  bool get isComplete => currentPhraseIndex >= phrases.length;
  String get currentPhrase => phrases[currentPhraseIndex];
  List<MemoryComparisonResult> get results =>
      List<MemoryComparisonResult>.unmodifiable(_results);

  MemoryComparisonResult submit(String actual) {
    if (isComplete) {
      throw StateError('Typed recall is already complete.');
    }
    final result = _comparator.compare(
      expected: currentPhrase,
      actual: actual,
    );
    _results.add(result);
    currentPhraseIndex++;
    return result;
  }

  double get combinedAccuracy {
    if (_results.isEmpty) return 0;
    final total = _results.fold<double>(
      0,
      (sum, result) => sum + result.accuracy,
    );
    return total / _results.length;
  }

  static List<String> _buildPhrases(String text, int wordLimit) {
    final limit = wordLimit.clamp(6, 40);
    final sentenceParts = text
        .split(RegExp(r'(?<=[.!?;:])\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    final phrases = <String>[];
    for (final sentence in sentenceParts) {
      final matches =
          ProgressiveFadeGenerator.wordPattern.allMatches(sentence).toList();
      if (matches.length <= limit) {
        phrases.add(sentence.trim());
        continue;
      }
      var startWord = 0;
      while (startWord < matches.length) {
        final endWord = (startWord + limit).clamp(0, matches.length);
        final startOffset = matches[startWord].start;
        final endOffset = matches[endWord - 1].end;
        phrases.add(sentence.substring(startOffset, endOffset).trim());
        startWord = endWord;
      }
    }
    return phrases.isEmpty ? <String>[text.trim()] : phrases;
  }
}
