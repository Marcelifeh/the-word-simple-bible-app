import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/core/utils/env.dart';

void main() {
  group('release API URL validation', () {
    test('accepts the production Render HTTPS endpoint', () {
      expect(
        Env.apiUrlValidationError(
          'https://the-word-app-api.onrender.com',
          releaseMode: true,
          required: true,
        ),
        isNull,
      );
    });

    for (final url in const [
      'http://localhost:8000',
      'http://127.0.0.1:8000',
      'http://10.0.2.2:8000',
      'http://api.example.com',
    ]) {
      test('rejects $url in release mode', () {
        expect(
          Env.apiUrlValidationError(
            url,
            releaseMode: true,
            required: true,
          ),
          isNotNull,
        );
      });
    }

    test('rejects an empty required endpoint', () {
      expect(
        Env.apiUrlValidationError('', releaseMode: true, required: true),
        isNotNull,
      );
    });

    test('keeps localhost available for debug development', () {
      expect(
        Env.apiUrlValidationError(
          'http://localhost:8000',
          releaseMode: false,
          required: true,
        ),
        isNull,
      );
    });
  });
}
