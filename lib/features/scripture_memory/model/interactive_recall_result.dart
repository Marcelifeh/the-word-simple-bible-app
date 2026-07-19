import 'memory_review_event.dart';

class InteractiveRecallResult {
  const InteractiveRecallResult({
    required this.totalBlanks,
    required this.correctOnFirstCheck,
    required this.correctAfterRetry,
    required this.hintCount,
    required this.fullVerseRevealed,
    required this.duration,
  });

  final int totalBlanks;
  final int correctOnFirstCheck;
  final int correctAfterRetry;
  final int hintCount;
  final bool fullVerseRevealed;
  final Duration duration;

  double get accuracy {
    if (totalBlanks == 0) return 0;
    return (correctAfterRetry / totalBlanks).clamp(0, 1);
  }

  MemoryReviewRating get suggestedRating {
    if (fullVerseRevealed) return MemoryReviewRating.almostThere;
    if (correctOnFirstCheck == totalBlanks && hintCount == 0) {
      return MemoryReviewRating.remembered;
    }
    if (correctAfterRetry == totalBlanks) {
      return MemoryReviewRating.almostThere;
    }
    return MemoryReviewRating.needsPractice;
  }
}
