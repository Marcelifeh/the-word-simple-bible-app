import 'package:hive/hive.dart';

/// A user-authored Gospel tract, stored locally via Hive.
class UserTract {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;

  const UserTract({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });
}

class UserTractAdapter extends TypeAdapter<UserTract> {
  @override
  final typeId = 3; // VerseNote=2 → UserTract=3

  @override
  UserTract read(BinaryReader reader) {
    return UserTract(
      id: reader.readString(),
      title: reader.readString(),
      message: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, UserTract obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.message);
    writer.writeString(obj.createdAt.toIso8601String());
  }
}
