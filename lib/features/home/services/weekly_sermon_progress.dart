import '../../sermon_notes/model/sermon_note.dart';
import 'weekly_date_utils.dart';

int sermonsCapturedThisWeek(
  Iterable<SermonNote> notes, {
  DateTime? now,
}) {
  final currentDate = now ?? DateTime.now();
  return notes
      .where((note) => isWithinSundayWeek(note.date, currentDate))
      .length;
}
