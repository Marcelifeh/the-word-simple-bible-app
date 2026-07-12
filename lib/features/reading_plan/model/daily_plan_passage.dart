class DailyPlanPassage {
  const DailyPlanPassage({
    required this.bookId,
    required this.bookName,
    required this.chapter,
  });

  final String bookId;
  final String bookName;
  final int chapter;

  String get label => '$bookName $chapter';
}
