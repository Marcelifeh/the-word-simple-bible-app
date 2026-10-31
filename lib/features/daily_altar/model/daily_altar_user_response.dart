import 'daily_altar_evening_response.dart';
import 'daily_altar_obedience_response.dart';
import 'daily_altar_personal_prayer.dart';
import 'daily_altar_reflection_response.dart';

/// User-owned response data for one My Daily Altar session.
///
/// This object intentionally contains no Scripture, commentary or generated
/// support material. It records only the believer's own responses.
class DailyAltarUserResponse {
  const DailyAltarUserResponse({
    required this.sessionId,
    this.reflection,
    this.personalPrayer,
    this.obedience,
    this.evening,
    this.updatedAt,
  });

  final String sessionId;

  final DailyAltarReflectionResponse? reflection;
  final DailyAltarPersonalPrayer? personalPrayer;
  final DailyAltarObedienceResponse? obedience;
  final DailyAltarEveningResponse? evening;

  final DateTime? updatedAt;

  bool get hasMorningResponse =>
      (reflection?.hasAnyResponse ?? false) ||
      !(personalPrayer?.isEmpty ?? true) ||
      _hasText(obedience?.commitment);

  bool get hasEveningResponse => evening?.hasAnyResponse ?? false;

  bool get hasAnyResponse => hasMorningResponse || hasEveningResponse;

  DailyAltarUserResponse copyWith({
    DailyAltarReflectionResponse? reflection,
    DailyAltarPersonalPrayer? personalPrayer,
    DailyAltarObedienceResponse? obedience,
    DailyAltarEveningResponse? evening,
    DateTime? updatedAt,
  }) {
    return DailyAltarUserResponse(
      sessionId: sessionId,
      reflection: reflection ?? this.reflection,
      personalPrayer: personalPrayer ?? this.personalPrayer,
      obedience: obedience ?? this.obedience,
      evening: evening ?? this.evening,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
