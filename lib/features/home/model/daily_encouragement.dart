enum DailyEncouragementKind {
  general,
  morning,
  activeToday,
  eveningUnread,
  eveningComplete,
  devotionalComplete,
  readingPlanComplete,
  returning,
  streak,
  weekend,
  sunday,
  newYear,
  easter,
  christmas,
}

enum DailyEncouragementTone {
  grace,
  peace,
  hope,
  protection,
  faith,
  prayer,
  wisdom,
  newBeginning,
  celebration,
  comfort,
}

class DailyEncouragement {
  const DailyEncouragement({
    required this.id,
    required this.kind,
    required this.tone,
    required this.message,
    required this.reference,
    required this.body,
  });

  final String id;
  final DailyEncouragementKind kind;
  final DailyEncouragementTone tone;
  final String message;
  final String reference;
  final String body;
}

class DailyEncouragementContext {
  const DailyEncouragementContext({
    required this.now,
    required this.hasReadToday,
    required this.readingPlanCompleted,
    required this.devotionalCompleted,
    required this.missedTwoDays,
    required this.streakDays,
  });

  final DateTime now;
  final bool hasReadToday;
  final bool readingPlanCompleted;
  final bool devotionalCompleted;
  final bool missedTwoDays;
  final int streakDays;
}
