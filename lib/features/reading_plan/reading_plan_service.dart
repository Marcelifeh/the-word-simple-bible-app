import '../../data/bible/book_catalog.dart';
import '../../domain/entities/book.dart';

class DailyReading {
  final String title;
  final List<String> passages; // e.g. ["Genesis 1-2", "Matthew 1"]
  const DailyReading({required this.title, required this.passages});
}

class ReadingPlanService {
  static final List<_ChapterRef> _oldTestamentChapters =
      _flattenChapters(Testament.old);
  static final List<_ChapterRef> _newTestamentChapters =
      _flattenChapters(Testament.newTestament);
  static final List<DailyReading> _plan = _buildPlan();

  List<DailyReading> get fullPlan => List<DailyReading>.unmodifiable(_plan);

  DailyReading getReadingForDate(DateTime date) {
    final index = dayIndexForDate(date);
    return _plan[index];
  }

  DailyReading getTodayReading() {
    return getReadingForDate(DateTime.now());
  }

  int dayIndexForDate(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    var dayOfYear = date.difference(startOfYear).inDays + 1;

    if (_isLeapYear(date.year) &&
        (date.month > 2 || (date.month == 2 && date.day == 29))) {
      dayOfYear -= 1;
    }

    final normalizedDay = dayOfYear.clamp(1, _plan.length);
    return normalizedDay - 1;
  }

  static List<DailyReading> _buildPlan() {
    const totalDays = 365;

    return List<DailyReading>.generate(totalDays, (index) {
      final dayNumber = index + 1;
      final oldSegment = _sliceForDay(_oldTestamentChapters, index, totalDays);
      final newSegment = _newTestamentSegmentForDay(index);
      final passages = <String>[
        ..._compressSegments(oldSegment),
        ..._compressSegments(newSegment),
      ];

      return DailyReading(
        title: 'Day $dayNumber',
        passages: passages,
      );
    });
  }

  static List<_ChapterRef> _flattenChapters(Testament testament) {
    return BookCatalog.books
        .where((book) => book.testament == testament)
        .expand(
          (book) => List<_ChapterRef>.generate(
            book.chapterCount,
            (index) => _ChapterRef(book: book, chapter: index + 1),
          ),
        )
        .toList(growable: false);
  }

  static List<_ChapterRef> _sliceForDay(
    List<_ChapterRef> chapters,
    int dayIndex,
    int totalDays,
  ) {
    final start = (chapters.length * dayIndex) ~/ totalDays;
    final end = (chapters.length * (dayIndex + 1)) ~/ totalDays;
    return chapters.sublist(start, end);
  }

  static List<_ChapterRef> _newTestamentSegmentForDay(int dayIndex) {
    if (dayIndex >= _newTestamentChapters.length) {
      return const <_ChapterRef>[];
    }

    return <_ChapterRef>[_newTestamentChapters[dayIndex]];
  }

  static List<String> _compressSegments(List<_ChapterRef> segment) {
    if (segment.isEmpty) {
      return const <String>[];
    }

    final passages = <String>[];
    var rangeStart = segment.first;
    var previous = segment.first;

    for (final current in segment.skip(1)) {
      final isContiguousInSameBook = current.book.id == previous.book.id &&
          current.chapter == previous.chapter + 1;

      if (!isContiguousInSameBook) {
        passages.add(_formatPassage(rangeStart, previous));
        rangeStart = current;
      }

      previous = current;
    }

    passages.add(_formatPassage(rangeStart, previous));
    return passages;
  }

  static String _formatPassage(_ChapterRef start, _ChapterRef end) {
    if (start.book.id != end.book.id) {
      return '${start.book.name} ${start.chapter}';
    }

    if (start.chapter == end.chapter) {
      return '${start.book.name} ${start.chapter}';
    }

    return '${start.book.name} ${start.chapter}-${end.chapter}';
  }

  static bool _isLeapYear(int year) {
    if (year % 400 == 0) return true;
    if (year % 100 == 0) return false;
    return year % 4 == 0;
  }
}

class _ChapterRef {
  const _ChapterRef({required this.book, required this.chapter});

  final Book book;
  final int chapter;
}
