import 'package:flutter/foundation.dart';

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

  static const transcriptionEnabled = bool.fromEnvironment(
    'SERMON_TRANSCRIPTION_ENABLED',
    defaultValue: false,
  );

  static bool get hasBackendApiUrl {
    final uri = Uri.tryParse(sermonApiUrl.trim());
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  /// Validates an API root without performing network I/O.
  ///
  /// Local HTTP endpoints remain available to debug builds. Release builds
  /// accept only HTTPS endpoints with non-loopback hosts. The Android Gradle
  /// release guard enforces the same policy at build time.
  static String? apiUrlValidationError(
    String? value, {
    required bool releaseMode,
    required bool required,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return required ? 'A required API endpoint is empty.' : null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'API endpoint is not a valid absolute URL.';
    }
    if (!releaseMode) return null;

    final host = uri.host.toLowerCase();
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host == '10.0.2.2') {
      return 'Release API endpoint must not use a local or loopback host.';
    }
    if (uri.scheme.toLowerCase() != 'https') {
      return 'Release API endpoint must use HTTPS.';
    }
    return null;
  }

  static void validateCurrentBuild() {
    final endpoints = <({String name, String? value, bool required})>[
      (name: 'SERMON_API_URL', value: sermonApiUrl, required: true),
      (name: 'COMMENTARY_API_URL', value: commentaryApiUrl, required: false),
      (name: 'AUDIO_API_URL', value: audioApiUrl, required: false),
      (name: 'BIBLE_API_URL', value: bibleApiUrl, required: false),
    ];
    for (final endpoint in endpoints) {
      final error = apiUrlValidationError(
        endpoint.value,
        releaseMode: kReleaseMode,
        required: endpoint.required,
      );
      if (error != null) {
        throw StateError('${endpoint.name}: $error');
      }
    }
    if (kReleaseMode && transcriptionEnabled) {
      throw StateError(
        'SERMON_TRANSCRIPTION_ENABLED must be false for this release.',
      );
    }
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
