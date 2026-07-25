import 'notification_type.dart';

class AppNotificationInboxItem {
  const AppNotificationInboxItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.receivedAtUtc,
    required this.payload,
    required this.isRead,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime receivedAtUtc;
  final String payload;
  final bool isRead;

  AppNotificationInboxItem copyWith({bool? isRead}) {
    return AppNotificationInboxItem(
      id: id,
      type: type,
      title: title,
      body: body,
      receivedAtUtc: receivedAtUtc,
      payload: payload,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.wireName,
        'title': title,
        'body': body,
        'receivedAtUtc': receivedAtUtc.toIso8601String(),
        'payload': payload,
        'isRead': isRead,
      };

  factory AppNotificationInboxItem.fromJson(Map<String, dynamic> json) {
    final type = NotificationTypeX.fromWireName(json['type'] as String?);
    final receivedAtUtc =
        DateTime.tryParse(json['receivedAtUtc'] as String? ?? '');
    if (type == null || receivedAtUtc == null) {
      throw const FormatException('Invalid notification inbox item');
    }
    return AppNotificationInboxItem(
      id: json['id'] as String,
      type: type,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      receivedAtUtc: receivedAtUtc.toUtc(),
      payload: json['payload'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
