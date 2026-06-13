import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/bible_translation.dart';
import '../../domain/entities/verse.dart';
import 'bible_repository.dart';

class BibleApiRepository implements BibleRepository {
  BibleApiRepository({required this.baseUrl});

  final String baseUrl;

  @override
  Future<List<Verse>> loadChapter({
    required BibleTranslation translation,
    required String bookId,
    required int chapter,
  }) async {
    final uri = Uri.parse(baseUrl).replace(
      path: '${Uri.parse(baseUrl).path}/chapter',
      queryParameters: {
        'translation': translation.name,
        'bookId': bookId,
        'chapter': chapter.toString(),
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return const [];
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return const [];
      final verses = decoded['verses'];
      if (verses is! List) return const [];

      return verses
          .whereType<Map>()
          .map((v) => Verse.fromJson(v.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<Verse>> searchKeyword({
    required BibleTranslation translation,
    required String query,
    int limit = 50,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final uri = Uri.parse(baseUrl).replace(
      path: '${Uri.parse(baseUrl).path}/search',
      queryParameters: {
        'translation': translation.name,
        'q': q,
        'limit': limit.toString(),
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return const [];
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return const [];
      final verses = decoded['verses'];
      if (verses is! List) return const [];

      return verses
          .whereType<Map>()
          .map((v) => Verse.fromJson(v.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
