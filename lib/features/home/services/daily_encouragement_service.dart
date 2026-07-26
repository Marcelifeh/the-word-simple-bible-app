import '../model/daily_encouragement.dart';

class DailyEncouragementService {
  const DailyEncouragementService();

  DailyEncouragement select(DailyEncouragementContext context) {
    final kind = _kindFor(context);
    final matches = _encouragements
        .where((item) => item.kind == kind)
        .toList(growable: false);
    final pool = matches.isEmpty
        ? _encouragements
            .where((item) => item.kind == DailyEncouragementKind.general)
            .toList(growable: false)
        : matches;
    final day = DateTime.utc(
      context.now.year,
      context.now.month,
      context.now.day,
    ).difference(DateTime.utc(2026, 1, 1)).inDays;
    final index = _positiveModulo(day + kind.index * 7, pool.length);
    return pool[index];
  }

  DailyEncouragementKind _kindFor(DailyEncouragementContext context) {
    final now = context.now;
    if ((now.month == 12 && now.day == 31) ||
        (now.month == 1 && now.day <= 3)) {
      return DailyEncouragementKind.newYear;
    }
    if (now.month == 12 && now.day >= 20 && now.day <= 26) {
      return DailyEncouragementKind.christmas;
    }
    final daysFromEaster =
        _dateOnly(now).difference(_easterSunday(now.year)).inDays;
    if (daysFromEaster >= -7 && daysFromEaster <= 1) {
      return DailyEncouragementKind.easter;
    }
    if (context.missedTwoDays) {
      return DailyEncouragementKind.returning;
    }
    if (context.readingPlanCompleted) {
      return DailyEncouragementKind.readingPlanComplete;
    }
    if (context.devotionalCompleted) {
      return DailyEncouragementKind.devotionalComplete;
    }
    if (_isStreakMilestone(context.streakDays)) {
      return DailyEncouragementKind.streak;
    }
    if (now.hour >= 17) {
      return context.hasReadToday
          ? DailyEncouragementKind.eveningComplete
          : DailyEncouragementKind.eveningUnread;
    }
    if (now.hour < 12 && !context.hasReadToday) {
      return DailyEncouragementKind.morning;
    }
    if (now.weekday == DateTime.sunday) {
      return DailyEncouragementKind.sunday;
    }
    if (context.hasReadToday) {
      return DailyEncouragementKind.activeToday;
    }
    if (now.weekday == DateTime.saturday) {
      return DailyEncouragementKind.weekend;
    }
    return DailyEncouragementKind.general;
  }

  bool _isStreakMilestone(int days) {
    return const {7, 14, 21, 30, 60, 90, 180, 365}.contains(days);
  }

  DateTime _easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int _positiveModulo(int value, int divisor) {
    return ((value % divisor) + divisor) % divisor;
  }
}

const _encouragements = <DailyEncouragement>[
  DailyEncouragement(
      id: 'general-1',
      kind: DailyEncouragementKind.general,
      tone: DailyEncouragementTone.grace,
      message: 'Grace meets you here. Begin again in the Word.',
      reference: 'Psalm 51:12',
      body:
          'God restores the joy of salvation and renews the heart that returns to Him.'),
  DailyEncouragement(
      id: 'general-2',
      kind: DailyEncouragementKind.general,
      tone: DailyEncouragementTone.hope,
      message: 'Take heart. The Lord restores your steps.',
      reference: 'Joel 2:25',
      body:
          'Nothing surrendered to God is wasted. He is able to restore what was lost.'),
  DailyEncouragement(
      id: 'general-3',
      kind: DailyEncouragementKind.general,
      tone: DailyEncouragementTone.wisdom,
      message: 'Let the Word dwell richly in you.',
      reference: 'Colossians 3:16',
      body:
          'Scripture forms the heart over time. Every faithful return to the Word matters.'),
  DailyEncouragement(
      id: 'morning-1',
      kind: DailyEncouragementKind.morning,
      tone: DailyEncouragementTone.newBeginning,
      message: 'His mercies are new this morning.',
      reference: 'Lamentations 3:22-23',
      body:
          'Receive this day as a fresh gift of mercy and walk into it with God.'),
  DailyEncouragement(
      id: 'morning-2',
      kind: DailyEncouragementKind.morning,
      tone: DailyEncouragementTone.wisdom,
      message: 'Begin today\'s walk in the Word.',
      reference: 'Psalm 119:105',
      body:
          'God gives enough light for the next faithful step, even when the full path is not visible.'),
  DailyEncouragement(
      id: 'morning-3',
      kind: DailyEncouragementKind.morning,
      tone: DailyEncouragementTone.prayer,
      message: 'Seek His face before the day grows loud.',
      reference: 'Psalm 5:3',
      body:
          'A quiet beginning with God can steady every conversation and decision that follows.'),
  DailyEncouragement(
      id: 'active-1',
      kind: DailyEncouragementKind.activeToday,
      tone: DailyEncouragementTone.faith,
      message: 'Keep abiding in His Word.',
      reference: 'John 15:5',
      body:
          'The strength to bear lasting fruit comes from remaining close to Christ.'),
  DailyEncouragement(
      id: 'active-2',
      kind: DailyEncouragementKind.activeToday,
      tone: DailyEncouragementTone.wisdom,
      message: 'Carry today\'s truth with you.',
      reference: 'James 1:22',
      body:
          'Let what you have read shape one concrete act of faith and love today.'),
  DailyEncouragement(
      id: 'active-3',
      kind: DailyEncouragementKind.activeToday,
      tone: DailyEncouragementTone.hope,
      message: 'The seed of the Word is growing.',
      reference: 'Isaiah 55:11',
      body:
          'God uses every attentive moment in Scripture to accomplish His purpose in you.'),
  DailyEncouragement(
      id: 'evening-unread-1',
      kind: DailyEncouragementKind.eveningUnread,
      tone: DailyEncouragementTone.peace,
      message: 'End today resting in His promises.',
      reference: 'Matthew 11:28',
      body:
          'There is still room for a quiet moment with Jesus before this day closes.'),
  DailyEncouragement(
      id: 'evening-unread-2',
      kind: DailyEncouragementKind.eveningUnread,
      tone: DailyEncouragementTone.comfort,
      message: 'Let Scripture quiet your heart tonight.',
      reference: 'Psalm 4:8',
      body:
          'Bring the unfinished parts of today to God and receive His peace.'),
  DailyEncouragement(
      id: 'evening-unread-3',
      kind: DailyEncouragementKind.eveningUnread,
      tone: DailyEncouragementTone.grace,
      message: 'A few faithful minutes still matter.',
      reference: 'James 4:8',
      body:
          'Draw near without guilt. God welcomes the heart that turns toward Him.'),
  DailyEncouragement(
      id: 'evening-read-1',
      kind: DailyEncouragementKind.eveningComplete,
      tone: DailyEncouragementTone.peace,
      message: 'Rest in the truth you received today.',
      reference: 'Psalm 63:6',
      body:
          'Let God\'s Word settle gently into your thoughts as the day comes to an end.'),
  DailyEncouragement(
      id: 'evening-read-2',
      kind: DailyEncouragementKind.eveningComplete,
      tone: DailyEncouragementTone.prayer,
      message: 'Close the day with thanksgiving.',
      reference: '1 Thessalonians 5:18',
      body: 'Remember one truth God showed you today and thank Him for it.'),
  DailyEncouragement(
      id: 'evening-read-3',
      kind: DailyEncouragementKind.eveningComplete,
      tone: DailyEncouragementTone.comfort,
      message: 'The Keeper of Israel watches over you.',
      reference: 'Psalm 121:4',
      body: 'You can release the day and sleep beneath God\'s faithful care.'),
  DailyEncouragement(
      id: 'devotional-1',
      kind: DailyEncouragementKind.devotionalComplete,
      tone: DailyEncouragementTone.celebration,
      message: 'Hide today\'s truth in your heart.',
      reference: 'Psalm 119:11',
      body:
          'Your devotional is complete; now carry its central truth into the rest of your day.'),
  DailyEncouragement(
      id: 'devotional-2',
      kind: DailyEncouragementKind.devotionalComplete,
      tone: DailyEncouragementTone.prayer,
      message: 'Let reflection become prayer.',
      reference: 'Psalm 19:14',
      body:
          'Offer what you learned back to God and invite Him to form it within you.'),
  DailyEncouragement(
      id: 'devotional-3',
      kind: DailyEncouragementKind.devotionalComplete,
      tone: DailyEncouragementTone.hope,
      message: 'Today\'s reflection is still unfolding.',
      reference: 'Philippians 1:6',
      body:
          'God continues the work He begins through every honest encounter with His Word.'),
  DailyEncouragement(
      id: 'plan-1',
      kind: DailyEncouragementKind.readingPlanComplete,
      tone: DailyEncouragementTone.celebration,
      message: 'Today\'s reading is complete.',
      reference: 'Romans 12:2',
      body: 'God\'s Word is renewing your mind and shaping you day by day.'),
  DailyEncouragement(
      id: 'plan-2',
      kind: DailyEncouragementKind.readingPlanComplete,
      tone: DailyEncouragementTone.wisdom,
      message: 'You made room for the whole counsel of God.',
      reference: 'Acts 20:27',
      body:
          'Let the breadth of today\'s reading deepen your understanding of His story.'),
  DailyEncouragement(
      id: 'plan-3',
      kind: DailyEncouragementKind.readingPlanComplete,
      tone: DailyEncouragementTone.faith,
      message: 'Faithfulness grows one day at a time.',
      reference: 'Luke 16:10',
      body:
          'Today\'s completed reading is another steady step in a lifelong walk with God.'),
  DailyEncouragement(
      id: 'return-1',
      kind: DailyEncouragementKind.returning,
      tone: DailyEncouragementTone.grace,
      message: 'You are not behind God\'s mercy.',
      reference: 'Lamentations 3:22-23',
      body:
          'There is no shame in beginning again. Today\'s mercy is already waiting.'),
  DailyEncouragement(
      id: 'return-2',
      kind: DailyEncouragementKind.returning,
      tone: DailyEncouragementTone.newBeginning,
      message: 'Return gently. Grace has kept your place.',
      reference: 'Joel 2:13',
      body:
          'God is gracious and compassionate; your next faithful step can begin now.'),
  DailyEncouragement(
      id: 'return-3',
      kind: DailyEncouragementKind.returning,
      tone: DailyEncouragementTone.comfort,
      message: 'The Shepherd still knows the way home.',
      reference: 'Luke 15:4',
      body:
          'A missed day does not erase your journey. Let Christ lead you forward again.'),
  DailyEncouragement(
      id: 'streak-1',
      kind: DailyEncouragementKind.streak,
      tone: DailyEncouragementTone.celebration,
      message: 'Your faithfulness is becoming a habit.',
      reference: 'Galatians 6:9',
      body: 'Do not grow weary. These daily choices are forming deep roots.'),
  DailyEncouragement(
      id: 'streak-2',
      kind: DailyEncouragementKind.streak,
      tone: DailyEncouragementTone.faith,
      message: 'A steady walk builds a steadfast heart.',
      reference: 'Colossians 2:6-7',
      body: 'Keep walking in Christ, rooted and strengthened by the truth.'),
  DailyEncouragement(
      id: 'streak-3',
      kind: DailyEncouragementKind.streak,
      tone: DailyEncouragementTone.wisdom,
      message: 'Consistency is making room for wisdom.',
      reference: 'Psalm 1:2-3',
      body:
          'Delighting in God\'s Word day after day produces fruit in its season.'),
  DailyEncouragement(
      id: 'weekend-1',
      kind: DailyEncouragementKind.weekend,
      tone: DailyEncouragementTone.peace,
      message: 'Let this weekend deepen your walk.',
      reference: 'Psalm 46:10',
      body:
          'Slow down enough to notice God\'s presence and listen for His voice.'),
  DailyEncouragement(
      id: 'weekend-2',
      kind: DailyEncouragementKind.weekend,
      tone: DailyEncouragementTone.comfort,
      message: 'Make room for holy rest.',
      reference: 'Mark 6:31',
      body: 'Rest can become worship when it restores your attention to God.'),
  DailyEncouragement(
      id: 'weekend-3',
      kind: DailyEncouragementKind.weekend,
      tone: DailyEncouragementTone.prayer,
      message: 'Bring the week before God.',
      reference: 'Psalm 139:23',
      body:
          'Invite Him to search, renew, and prepare your heart for what comes next.'),
  DailyEncouragement(
      id: 'sunday-1',
      kind: DailyEncouragementKind.sunday,
      tone: DailyEncouragementTone.celebration,
      message: 'Worship with expectation today.',
      reference: 'Psalm 122:1',
      body:
          'Gather with joy and expect God to meet His people through worship and the Word.'),
  DailyEncouragement(
      id: 'sunday-2',
      kind: DailyEncouragementKind.sunday,
      tone: DailyEncouragementTone.prayer,
      message: 'Prepare your heart for worship.',
      reference: 'Psalm 95:6',
      body:
          'Come with reverence, gratitude, and an open heart before the Lord.'),
  DailyEncouragement(
      id: 'sunday-3',
      kind: DailyEncouragementKind.sunday,
      tone: DailyEncouragementTone.faith,
      message: 'Let gathered faith strengthen you.',
      reference: 'Hebrews 10:25',
      body:
          'The encouragement of God\'s people helps us remain faithful through the week ahead.'),
  DailyEncouragement(
      id: 'new-year-1',
      kind: DailyEncouragementKind.newYear,
      tone: DailyEncouragementTone.newBeginning,
      message: 'Behold, God is doing a new thing.',
      reference: 'Isaiah 43:19',
      body:
          'Enter this new year attentive to the paths God is opening before you.'),
  DailyEncouragement(
      id: 'new-year-2',
      kind: DailyEncouragementKind.newYear,
      tone: DailyEncouragementTone.hope,
      message: 'Commit the year ahead to the Lord.',
      reference: 'Proverbs 16:3',
      body:
          'Place your plans in His hands and let His wisdom establish your steps.'),
  DailyEncouragement(
      id: 'new-year-3',
      kind: DailyEncouragementKind.newYear,
      tone: DailyEncouragementTone.faith,
      message: 'Walk forward with renewed hope.',
      reference: 'Philippians 3:13-14',
      body:
          'Release what is behind and press toward what God is calling you to become.'),
  DailyEncouragement(
      id: 'easter-1',
      kind: DailyEncouragementKind.easter,
      tone: DailyEncouragementTone.celebration,
      message: 'Christ is risen indeed.',
      reference: 'Matthew 28:6',
      body:
          'The empty tomb declares that sin and death do not have the final word.'),
  DailyEncouragement(
      id: 'easter-2',
      kind: DailyEncouragementKind.easter,
      tone: DailyEncouragementTone.hope,
      message: 'Resurrection hope is alive today.',
      reference: '1 Peter 1:3',
      body:
          'Because Jesus lives, your hope rests in a victory that cannot be taken away.'),
  DailyEncouragement(
      id: 'easter-3',
      kind: DailyEncouragementKind.easter,
      tone: DailyEncouragementTone.grace,
      message: 'The cross has opened the way home.',
      reference: 'Romans 5:8',
      body: 'Receive again the depth of God\'s love revealed through Christ.'),
  DailyEncouragement(
      id: 'christmas-1',
      kind: DailyEncouragementKind.christmas,
      tone: DailyEncouragementTone.celebration,
      message: 'Rejoice. The Savior has come.',
      reference: 'Luke 2:11',
      body: 'God has drawn near in Jesus, bringing good news of great joy.'),
  DailyEncouragement(
      id: 'christmas-2',
      kind: DailyEncouragementKind.christmas,
      tone: DailyEncouragementTone.peace,
      message: 'Receive the peace of Christ.',
      reference: 'Luke 2:14',
      body:
          'Let the wonder of God with us quiet your heart and shape your celebrations.'),
  DailyEncouragement(
      id: 'christmas-3',
      kind: DailyEncouragementKind.christmas,
      tone: DailyEncouragementTone.hope,
      message: 'The Light shines in the darkness.',
      reference: 'John 1:5',
      body:
          'No darkness can overcome the hope that entered the world through Jesus.'),
];
