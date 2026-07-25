import 'notification_type.dart';

class ScheduledNotificationRecord {
  const ScheduledNotificationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledAtUtc,
    required this.payload,
  });

  final int id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime scheduledAtUtc;
  final String payload;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.wireName,
        'title': title,
        'body': body,
        'scheduledAtUtc': scheduledAtUtc.toIso8601String(),
        'payload': payload,
      };

  factory ScheduledNotificationRecord.fromJson(Map<String, dynamic> json) {
    final type = NotificationTypeX.fromWireName(json['type'] as String?);
    final scheduledAtUtc =
        DateTime.tryParse(json['scheduledAtUtc'] as String? ?? '');
    if (type == null || scheduledAtUtc == null) {
      throw const FormatException('Invalid scheduled notification record');
    }
    return ScheduledNotificationRecord(
      id: (json['id'] as num).toInt(),
      type: type,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      scheduledAtUtc: scheduledAtUtc.toUtc(),
      payload: json['payload'] as String? ?? '',
    );
  }
}
