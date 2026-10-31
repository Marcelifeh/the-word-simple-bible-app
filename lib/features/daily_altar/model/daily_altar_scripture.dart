/// Canonical Scripture content used within a Daily Altar encounter.
///
/// Scripture has its own type so explanatory or generated material cannot be
/// confused with biblical text.
///
/// [translationId] identifies the Bible translation/source used by the app.
/// Licensing and availability policy remain outside this domain model.
class DailyAltarScripture {
  const DailyAltarScripture({
    required this.reference,
    required this.translationId,
    required this.text,
  });

  final String reference;
  final String translationId;
  final String text;
}
