class Env {
  static String? get bibleApiUrl {
    const value = String.fromEnvironment('BIBLE_API_URL');
    if (value.trim().isEmpty) return null;
    return value;
  }

  static String? get commentaryApiUrl {
    const value = String.fromEnvironment('COMMENTARY_API_URL');
    if (value.trim().isEmpty) return null;
    return value;
  }

  static String? get audioApiUrl {
    const value = String.fromEnvironment('AUDIO_API_URL');
    if (value.trim().isEmpty) return null;
    return value;
  }

  static String? get sermonApiUrl {
    const value = String.fromEnvironment('SERMON_API_URL');
    if (value.trim().isEmpty) return null;
    return value;
  }
}
