import '../../sermon_notes/model/sermon_note.dart';

int sermonsCapturedThisWeek(
  Iterable<SermonNote> notes, {
  DateTime? now,
}) {
  final localNow = (now ?? DateTime.now()).toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));

  return notes.where((note) {
    final localDate = note.date.toLocal();
    final sermonDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );
    return !sermonDay.isBefore(weekStart) && !sermonDay.isAfter(today);
  }).length;
}
