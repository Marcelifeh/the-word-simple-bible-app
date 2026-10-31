/// User-authored answers from the Abide stage.
///
/// These are personal reflections, not app-generated content.
class DailyAltarReflectionResponse {
  const DailyAltarReflectionResponse({
    this.aboutGod,
    this.aboutMe,
    this.response,
  });

  final String? aboutGod;
  final String? aboutMe;
  final String? response;

  bool get hasAnyResponse =>
      _hasText(aboutGod) || _hasText(aboutMe) || _hasText(response);

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
