import 'package:flutter/material.dart';

import '../../../shared/state/app_state.dart';
import '../model/app_notification_inbox_item.dart';

class NotificationInboxScreen extends StatelessWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final repository = state.notificationInboxRepository;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed:
                repository.unreadCount == 0 ? null : repository.markAllRead,
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: repository,
        builder: (context, _) {
          final items = repository.items;
          if (items.isEmpty) {
            return const _EmptyInbox();
          }
          final today = DateUtils.dateOnly(DateTime.now());
          final todayItems = items
              .where(
                (item) =>
                    DateUtils.isSameDay(item.receivedAtUtc.toLocal(), today),
              )
              .toList(growable: false);
          final earlierItems = items
              .where(
                (item) => !DateUtils.isSameDay(
                  item.receivedAtUtc.toLocal(),
                  today,
                ),
              )
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (todayItems.isNotEmpty) ...[
                const _InboxSectionLabel('Today'),
                ...todayItems.map(
                  (item) => _InboxTile(
                    item: item,
                    onTap: () => _open(context, state, item),
                  ),
                ),
              ],
              if (earlierItems.isNotEmpty) ...[
                const _InboxSectionLabel('Earlier'),
                ...earlierItems.map(
                  (item) => _InboxTile(
                    item: item,
                    onTap: () => _open(context, state, item),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    AppState state,
    AppNotificationInboxItem item,
  ) async {
    await state.notificationInboxRepository.markRead(item.id);
    if (!context.mounted) return;
    await state.notificationNavigationService.handlePayload(item.payload);
  }
}

class _InboxSectionLabel extends StatelessWidget {
  const _InboxSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.item,
    required this.onTap,
  });

  final AppNotificationInboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Icon(
        item.isRead ? Icons.notifications_none : Icons.notifications_active,
        color: item.isRead ? scheme.onSurfaceVariant : scheme.primary,
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
        ),
      ),
      subtitle: Text(
        item.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 44,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Your recent reminders and updates will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
