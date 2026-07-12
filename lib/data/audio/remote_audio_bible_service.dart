import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/utils/env.dart';
import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse_ref.dart';
import 'audio_bible_service.dart';

class RemoteAudioBibleService implements AudioBibleService {
  @override
  Future<Uri?> getVerseAudioUrl(
      BibleTranslation translation, VerseRef ref) async {
    final apiUrl = Env.audioApiUrl;
    if (apiUrl == null) return null;

    try {
      final res = await http.post(
        Env.apiUri('/audio'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'translation': translation.id,
          'bookId': ref.bookId,
          'chapter': ref.chapter,
          'verse': ref.verse
        }),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return null;

      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['url'] is String) {
        final urlStr = (decoded['url'] as String).trim();
        if (urlStr.isEmpty) return null;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return Uri.parse('$urlStr?t=$timestamp');
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
