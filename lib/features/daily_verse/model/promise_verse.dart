class PromiseVerse {
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final String tag;
  final String commentary;

  const PromiseVerse({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.tag,
    required this.commentary,
  });

  String get reference => '$bookName $chapter:$verse';

  factory PromiseVerse.fromJson(
    Map<String, dynamic> json, {
    required String text,
  }) {
    return PromiseVerse(
      bookId: json['bookId'].toString(),
      bookName: json['bookName'].toString(),
      chapter: int.parse(json['chapter'].toString()),
      verse: int.parse(json['verse'].toString()),
      text: text,
      tag: json['tag'].toString(),
      commentary: json['commentary'].toString(),
    );
  }
}
