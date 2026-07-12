class Env {
  const Env._();

  static const _defaultSermonApiUrl = 'http://localhost:8000';

  static String? get bibleApiUrl {
    const value = String.fromEnvironment('BIBLE_API_URL');
    if (value.trim().isEmpty) return null;
    return value;
  }

  static String? get commentaryApiUrl {
    const value = String.fromEnvironment('COMMENTARY_API_URL');
    if (value.trim().isEmpty) return sermonApiUrl;
    return value;
  }

  static String? get audioApiUrl {
    const value = String.fromEnvironment('AUDIO_API_URL');
    if (value.trim().isEmpty) return sermonApiUrl;
    return value;
  }

  static const sermonApiUrl = String.fromEnvironment(
    'SERMON_API_URL',
    defaultValue: _defaultSermonApiUrl,
  );

  static bool get hasBackendApiUrl {
    final uri = Uri.tryParse(sermonApiUrl.trim());
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  static Uri apiUri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final root = sermonApiUrl.trim().replaceAll(RegExp(r'/$'), '');

    return Uri.parse('$root$normalizedPath').replace(
      queryParameters: queryParameters,
    );
  }
}
