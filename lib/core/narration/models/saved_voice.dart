import 'narration_voice.dart';

class SavedVoice {
  final String id;
  final String locale;
  final String displayName;
  final VoiceProvider provider;

  const SavedVoice({
    required this.id,
    required this.locale,
    required this.displayName,
    this.provider = VoiceProvider.device,
  });

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'locale': locale,
      'displayName': displayName,
      'provider': provider.name,
    };
  }

  factory SavedVoice.fromJson(Map<dynamic, dynamic> json) {
    final providerName = json['provider'] as String?;
    final provider = VoiceProvider.values
        .where((p) => p.name == providerName)
        .firstOrNull ??
        VoiceProvider.device;
        
    return SavedVoice(
      id: json['id'] as String? ?? '',
      locale: json['locale'] as String? ?? 'en-US',
      displayName: json['displayName'] as String? ?? 'Unknown Voice',
      provider: provider,
    );
  }
}
