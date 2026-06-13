import 'package:hive/hive.dart';

class VerseNote {
  final String verseId;
  final String text;
  final int color;
  final DateTime createdAt;

  VerseNote({
    required this.verseId,
    required this.text,
    required this.color,
    required this.createdAt,
  });

  bool get isHighlightOnly => text.isEmpty;
  bool get isNote => text.isNotEmpty;
}

class VerseNoteAdapter extends TypeAdapter<VerseNote> {
  @override
  final typeId = 2;

  @override
  VerseNote read(BinaryReader reader) {
    return VerseNote(
      verseId: reader.readString(),
      text: reader.readString(),
      color: reader.readInt(),
      createdAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, VerseNote obj) {
    writer.writeString(obj.verseId);
    writer.writeString(obj.text);
    writer.writeInt(obj.color);
    writer.writeString(obj.createdAt.toIso8601String());
  }
}
