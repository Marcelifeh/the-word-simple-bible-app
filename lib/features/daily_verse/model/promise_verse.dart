import '../../../domain/entities/bible_translation.dart';

class PromiseVerse {
  final String id;
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final String tag;
  final String commentary;
  final String prayer;
  final String reflection;
  final BibleTranslation translation;

  const PromiseVerse({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.tag,
    required this.commentary,
    required this.prayer,
    required this.reflection,
    required this.translation,
  });

  String get reference => '$bookName $chapter:$verse';

  factory PromiseVerse.fromJson(
    Map<String, dynamic> json, {
    required String text,
    required BibleTranslation translation,
  }) {
    return PromiseVerse(
      id: json['id'].toString(),
      bookId: json['bookId'].toString(),
      bookName: json['bookName'].toString(),
      chapter: int.parse(json['chapter'].toString()),
      verse: int.parse(json['verse'].toString()),
      text: text,
      tag: json['tag'].toString(),
      commentary: json['commentary'].toString(),
      prayer: json['prayer'].toString(),
      reflection: json['reflection'].toString(),
      translation: translation,
    );
  }
}
