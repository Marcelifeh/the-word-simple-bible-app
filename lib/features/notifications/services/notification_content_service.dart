import 'dart:convert';

import 'package:flutter/services.dart';

import '../model/notification_type.dart';

class NotificationContent {
  const NotificationContent({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class NotificationContentService {
  NotificationContentService({
    Future<String> Function()? assetLoader,
  }) : _assetLoader = assetLoader ??
            (() => rootBundle.loadString(
                  'assets/data/notifications/content.json',
                ));

  final Future<String> Function() _assetLoader;
  Map<String, List<Map<String, String>>> _messages =
      <String, List<Map<String, String>>>{};

  Future<void> init() async {
    try {
      final decoded = jsonDecode(await _assetLoader());
      if (decoded is! Map) return;
      _messages = decoded.map<String, List<Map<String, String>>>(
        (dynamic key, dynamic value) {
          final entries = value is List
              ? value
                  .whereType<Map>()
                  .map(
                    (entry) => entry.map<String, String>(
                      (dynamic field, dynamic text) => MapEntry(
                        field.toString(),
                        text.toString(),
                      ),
                    ),
                  )
                  .toList(growable: false)
              : const <Map<String, String>>[];
          return MapEntry(key.toString(), entries);
        },
      );
    } catch (_) {
      _messages = <String, List<Map<String, String>>>{};
    }
  }

  NotificationContent forType(
    NotificationType type, {
    DateTime? date,
    int? count,
    String? devotionalTitle,
  }) {
    final localDate = date ?? DateTime.now();
    final entries = _messages[type.wireName] ?? const <Map<String, String>>[];
    final selected = entries.isEmpty
        ? _fallback(type)
        : entries[_stableIndex(localDate, entries.length)];
    var body = selected['body'] ?? selected['bodyTemplate'] ?? '';

    if (count != null) {
      body = body
          .replaceAll('{count}', '$count')
          .replaceAll('{passages}', count == 1 ? 'passage' : 'passages')
          .replaceAll('{verses}', count == 1 ? 'verse is' : 'verses are');
    }
    if (devotionalTitle != null && devotionalTitle.trim().isNotEmpty) {
      body = body.replaceAll('{devotionalTitle}', devotionalTitle.trim());
    }

    return NotificationContent(
      title: selected['title'] ?? type.displayName,
      body: body,
    );
  }

  int _stableIndex(DateTime date, int length) {
    final dateKey = date.year * 10000 + date.month * 100 + date.day;
    var hash = 17;
    for (final unit in dateKey.toString().codeUnits) {
      hash = 37 * hash + unit;
    }
    return hash.abs() % length;
  }

  Map<String, String> _fallback(NotificationType type) => switch (type) {
        NotificationType.dailyVerse => const <String, String>{
            'title': 'Today\'s Verse',
            'body': 'Today\'s verse is ready for you.',
          },
        NotificationType.dailyDevotional => const <String, String>{
            'title': 'Your devotional is ready',
            'body': 'Begin today with God\'s Word.',
          },
        NotificationType.readingPlan => const <String, String>{
            'title': 'Continue today\'s reading',
            'bodyTemplate':
                'You still have {count} {passages} remaining today.',
          },
        NotificationType.scriptureMemoryReview => const <String, String>{
            'title': 'Hide God\'s Word in your heart',
            'bodyTemplate': '{count} {verses} ready for review today.',
          },
        NotificationType.prayerReminder => const <String, String>{
            'title': 'Take a quiet moment with God',
            'body': 'Bring your heart before Him in prayer.',
          },
        NotificationType.eveningReflection => const <String, String>{
            'title': 'Pause and reflect',
            'body': 'What did God teach you today?',
          },
        NotificationType.appUpdate => const <String, String>{
            'title': 'New in The Word App',
            'body': 'New content is ready to explore.',
          },
        NotificationType.importantAnnouncement => const <String, String>{
            'title': 'Important announcement',
            'body': 'Open The Word App to learn more.',
          },
      };
}
