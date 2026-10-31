/// Provenance for non-Scripture Daily Altar material.
///
/// Scripture itself uses [DailyAltarScripture] and never this enum.
/// This distinction prevents explanation, generated reflection, prayer,
/// or application from being represented as biblical text.
enum DailyAltarSupportOrigin {
  /// Human-reviewed material bundled or otherwise curated by the app.
  curated,

  /// Assistive material generated dynamically.
  ///
  /// Generated content is never authoritative Scripture and must not be
  /// presented as a direct statement from God.
  generatedAssistive,
}
