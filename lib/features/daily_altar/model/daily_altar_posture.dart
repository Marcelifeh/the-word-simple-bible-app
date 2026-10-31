/// A user's self-selected posture when coming to My Daily Altar.
///
/// These values describe what the user says they are experiencing.
/// They must never be presented as a diagnosis or a claim that God has
/// specifically declared something about the user.
enum DailyAltarPosture {
  hearFromScripture,
  seekingDirection,
  thankful,
  discouraged,
  waitingOnGod,
  spirituallyDry,
  facingTemptation,
  anxious,
  needingStrength,
  seekingDeeperFellowship,
}

extension DailyAltarPostureX on DailyAltarPosture {
  String get label {
    switch (this) {
      case DailyAltarPosture.hearFromScripture:
        return 'I simply want to hear from Scripture';
      case DailyAltarPosture.seekingDirection:
        return 'Seeking direction';
      case DailyAltarPosture.thankful:
        return 'Thankful';
      case DailyAltarPosture.discouraged:
        return 'Discouraged';
      case DailyAltarPosture.waitingOnGod:
        return 'Waiting on God';
      case DailyAltarPosture.spirituallyDry:
        return 'Spiritually dry';
      case DailyAltarPosture.facingTemptation:
        return 'Facing temptation';
      case DailyAltarPosture.anxious:
        return 'Anxious';
      case DailyAltarPosture.needingStrength:
        return 'Needing strength';
      case DailyAltarPosture.seekingDeeperFellowship:
        return 'Seeking deeper fellowship with God';
    }
  }
}
