class PrayerModel {
  final String topic;
  final String verse;
  final String reference;
  final String prayer;
  final String reflection;

  PrayerModel({
    required this.topic,
    required this.verse,
    required this.reference,
    required this.prayer,
    required this.reflection,
  });
}

abstract class IPrayerProvider {
  Future<PrayerModel> generate(String topic);
}
