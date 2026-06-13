import '../model/prayer_model.dart';
import 'offline_prayer_provider.dart';

class PrayerService {
  static IPrayerProvider provider = OfflinePrayerProvider();

  static Future<PrayerModel> generate(String topic) {
    return provider.generate(topic);
  }
}
