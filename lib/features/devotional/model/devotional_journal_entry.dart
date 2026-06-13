import 'package:hive/hive.dart';

/// A saved spiritual moment — stores the full devotional experience
/// so users can revisit their prayers, reflections, and breakthroughs.
class DevotionalJournalEntry {
  final String id;
  final String devotionalId;
  final String devotionalTitle;
  final String theme;
  final String scriptureReference;
  final String scripture;
  final String prayer;
  final List<String> reflections; // user-written answers
  final DateTime savedAt;

  const DevotionalJournalEntry({
    required this.id,
    required this.devotionalId,
    required this.devotionalTitle,
    required this.theme,
    required this.scriptureReference,
    required this.scripture,
    required this.prayer,
    required this.reflections,
    required this.savedAt,
  });
}

class DevotionalJournalEntryAdapter
    extends TypeAdapter<DevotionalJournalEntry> {
  @override
  final typeId = 4; // VerseNote=2, UserTract=3, this=4

  @override
  DevotionalJournalEntry read(BinaryReader reader) {
    return DevotionalJournalEntry(
      id: reader.readString(),
      devotionalId: reader.readString(),
      devotionalTitle: reader.readString(),
      theme: reader.readString(),
      scriptureReference: reader.readString(),
      scripture: reader.readString(),
      prayer: reader.readString(),
      reflections: (reader.readList()).cast<String>(),
      savedAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, DevotionalJournalEntry obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.devotionalId);
    writer.writeString(obj.devotionalTitle);
    writer.writeString(obj.theme);
    writer.writeString(obj.scriptureReference);
    writer.writeString(obj.scripture);
    writer.writeString(obj.prayer);
    writer.writeList(obj.reflections);
    writer.writeString(obj.savedAt.toIso8601String());
  }
}
