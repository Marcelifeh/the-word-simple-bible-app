/// Ordered stages of a My Daily Altar spiritual formation session.
///
/// The order is intentionally explicit. UI, persistence, billing and AI must
/// never determine spiritual-stage progression independently of this model.
enum DailyAltarStage {
  come,
  receive,
  understand,
  abide,
  pray,
  obey,
  carry,
  returnToAltar,
  completed,
}

extension DailyAltarStageX on DailyAltarStage {
  String get label {
    switch (this) {
      case DailyAltarStage.come:
        return 'Come to the Altar';
      case DailyAltarStage.receive:
        return 'Receive the Word';
      case DailyAltarStage.understand:
        return 'Understand the Word';
      case DailyAltarStage.abide:
        return 'Abide';
      case DailyAltarStage.pray:
        return 'Pray the Word';
      case DailyAltarStage.obey:
        return 'Walk in the Word';
      case DailyAltarStage.carry:
        return 'Carry the Word';
      case DailyAltarStage.returnToAltar:
        return 'Return to the Altar';
      case DailyAltarStage.completed:
        return 'Completed';
    }
  }

  bool get isMorningStage {
    return switch (this) {
      DailyAltarStage.come ||
      DailyAltarStage.receive ||
      DailyAltarStage.understand ||
      DailyAltarStage.abide ||
      DailyAltarStage.pray ||
      DailyAltarStage.obey ||
      DailyAltarStage.carry =>
        true,
      DailyAltarStage.returnToAltar || DailyAltarStage.completed => false,
    };
  }
}
