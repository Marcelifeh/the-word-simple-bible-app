/// User-authored reflection recorded during Return to the Altar.
class DailyAltarEveningResponse {
  const DailyAltarEveningResponse({
    this.rememberedWord,
    this.obedienceReflection,
    this.relevanceReflection,
    this.heartResponse,
    this.carryForward,
  });

  final String? rememberedWord;
  final String? obedienceReflection;
  final String? relevanceReflection;
  final String? heartResponse;
  final String? carryForward;

  bool get hasAnyResponse =>
      _hasText(rememberedWord) ||
      _hasText(obedienceReflection) ||
      _hasText(relevanceReflection) ||
      _hasText(heartResponse) ||
      _hasText(carryForward);

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
