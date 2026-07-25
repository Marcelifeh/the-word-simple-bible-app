import 'package:flutter/material.dart';

import '../services/app_notification_service.dart';

class NotificationPermissionCard extends StatelessWidget {
  const NotificationPermissionCard({
    super.key,
    required this.status,
    required this.onAllow,
    required this.onOpenSettings,
  });

  final AppNotificationPermissionStatus status;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final blocked = status == AppNotificationPermissionStatus.denied;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                blocked
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_outlined,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  blocked ? 'Notifications are blocked' : 'Stay encouraged',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            blocked
                ? 'Open device settings to allow reminders from The Word App.'
                : 'Allow The Word App to remind you about Scripture, '
                    'devotionals, prayer, and memory reviews.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: blocked ? onOpenSettings : onAllow,
              icon: Icon(
                blocked ? Icons.settings_outlined : Icons.notifications_none,
              ),
              label: Text(
                blocked ? 'Open device settings' : 'Allow notifications',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
