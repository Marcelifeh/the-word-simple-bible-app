import 'package:flutter/material.dart';

import '../../../features/reading_plan/reading_plan_service.dart';
import '../../../shared/state/app_state.dart';
import '../model/notification_preferences.dart';
import '../model/notification_type.dart';
import '../repository/notification_preferences_repository.dart';
import '../services/app_notification_service.dart';
import '../services/notification_content_service.dart';
import '../services/notification_scheduler.dart';
import '../widgets/notification_permission_card.dart';
import '../widgets/notification_time_tile.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  NotificationPreferencesRepository? _repository;
  AppNotificationPermissionStatus _permissionStatus =
      AppNotificationPermissionStatus.notDetermined;
  bool _sendingTestNotification = false;

  NotificationPreferences get _preferences =>
      _repository?.preferences ?? NotificationPreferences.defaults;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppScope.of(context).notificationPreferencesRepository;
    if (identical(repository, _repository)) return;
    _repository?.removeListener(_handlePreferencesChanged);
    _repository = repository..addListener(_handlePreferencesChanged);
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissionStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _repository?.removeListener(_handlePreferencesChanged);
    super.dispose();
  }

  void _handlePreferencesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshPermissionStatus() async {
    final state = AppScope.of(context);
    final status = await state.appNotificationService.permissionStatus(
      hasPrompted: _preferences.permissionPrompted,
    );
    if (mounted) setState(() => _permissionStatus = status);
  }

  Future<void> _save(NotificationPreferences preferences) async {
    final state = AppScope.of(context);
    await state.notificationPreferencesRepository.save(preferences);
    await state.notificationCoordinator.refresh();
  }

  Future<void> _setCategoryEnabled(
    NotificationType type,
    bool enabled,
  ) async {
    await _save(_preferences.withEnabled(type, enabled));
    if (enabled) await _refreshPermissionStatus();
  }

  Future<void> _requestPermission() async {
    final state = AppScope.of(context);
    await state.notificationPreferencesRepository.save(
      _preferences.copyWith(permissionPrompted: true),
    );
    await state.appNotificationService.requestPermission();
    await _refreshPermissionStatus();
    await state.notificationCoordinator.refresh();
  }

  Future<void> _openSettings() async {
    await AppScope.of(context)
        .appNotificationService
        .openNotificationSettings();
  }

  Future<void> _sendTestNotification() async {
    if (_sendingTestNotification) return;
    final state = AppScope.of(context);
    setState(() => _sendingTestNotification = true);
    try {
      if (!state.notificationsAvailable) {
        _showTestMessage(
          'Notifications are temporarily unavailable. Restart the app and try again.',
        );
        return;
      }

      if (_permissionStatus == AppNotificationPermissionStatus.notDetermined) {
        await _requestPermission();
      }

      final enabled =
          await state.appNotificationService.areAndroidNotificationsEnabled();
      if (!enabled ||
          _permissionStatus == AppNotificationPermissionStatus.denied) {
        if (mounted) {
          setState(
            () => _permissionStatus = AppNotificationPermissionStatus.denied,
          );
        }
        _showTestMessage(
          'Notifications are blocked on this device.',
          actionLabel: 'Open settings',
          onAction: _openSettings,
        );
        return;
      }

      await state.appNotificationService.showTestNotification();
      _showTestMessage(
        'Test sent. Check the Android notification panel.',
      );
    } catch (error) {
      _showTestMessage('Could not send a test notification: $error');
    } finally {
      if (mounted) setState(() => _sendingTestNotification = false);
    }
  }

  void _showTestMessage(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
              ),
      ),
    );
  }

  bool get _hasLocalReminderEnabled =>
      _preferences.dailyVerseEnabled ||
      _preferences.devotionalEnabled ||
      _preferences.readingPlanEnabled ||
      _preferences.scriptureMemoryEnabled ||
      _preferences.prayerEnabled ||
      _preferences.eveningReflectionEnabled;

  String _timeLabel(int minutes) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
  }

  Future<void> _editReminder(NotificationType type) async {
    final state = AppScope.of(context);
    final updated = await showModalBottomSheet<NotificationPreferences>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ReminderEditorSheet(
        type: type,
        initialPreferences: _preferences,
        contentService: state.notificationContentService,
      ),
    );
    if (updated != null) await _save(updated);
  }

  Future<void> _editQuietHours() async {
    final updated = await showModalBottomSheet<NotificationPreferences>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _QuietHoursSheet(
        initialPreferences: _preferences,
      ),
    );
    if (updated != null) await _save(updated);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final reading = ReadingPlanService().getTodayReading();
    final remainingPassages = reading.passages
        .where(
          (passage) => !state.isReadingPlanPassageCompletedToday(passage),
        )
        .length;
    final memoryDue = state.memoryVerseRepo.due().length;
    final showPermission = _preferences.masterEnabled &&
        _hasLocalReminderEnabled &&
        _permissionStatus != AppNotificationPermissionStatus.granted &&
        _permissionStatus != AppNotificationPermissionStatus.unsupported;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Allow notifications'),
            subtitle: const Text('Pause delivery without losing your times'),
            value: _preferences.masterEnabled,
            onChanged: (enabled) =>
                _save(_preferences.copyWith(masterEnabled: enabled)),
          ),
          if (showPermission) ...[
            const SizedBox(height: 8),
            NotificationPermissionCard(
              status: _permissionStatus,
              onAllow: _requestPermission,
              onOpenSettings: _openSettings,
            ),
          ],
          const _SectionLabel('Daily faith'),
          NotificationTimeTile(
            icon: Icons.auto_stories_outlined,
            title: NotificationType.dailyVerse.displayName,
            subtitle:
                'Every day at ${_timeLabel(_preferences.dailyVerseMinutes)}',
            enabled: _preferences.dailyVerseEnabled,
            onChanged: (value) => _setCategoryEnabled(
              NotificationType.dailyVerse,
              value,
            ),
            onTap: () => _editReminder(NotificationType.dailyVerse),
          ),
          NotificationTimeTile(
            icon: Icons.wb_sunny_outlined,
            title: NotificationType.dailyDevotional.displayName,
            subtitle:
                'Every day at ${_timeLabel(_preferences.devotionalMinutes)}',
            enabled: _preferences.devotionalEnabled,
            onChanged: (value) => _setCategoryEnabled(
              NotificationType.dailyDevotional,
              value,
            ),
            onTap: () => _editReminder(NotificationType.dailyDevotional),
          ),
          NotificationTimeTile(
            icon: Icons.nights_stay_outlined,
            title: NotificationType.eveningReflection.displayName,
            subtitle: 'Every day at '
                '${_timeLabel(_preferences.eveningReflectionMinutes)}',
            enabled: _preferences.eveningReflectionEnabled,
            onChanged: (value) => _setCategoryEnabled(
              NotificationType.eveningReflection,
              value,
            ),
            onTap: () => _editReminder(NotificationType.eveningReflection),
          ),
          const _SectionLabel('Habits'),
          NotificationTimeTile(
            icon: Icons.menu_book_outlined,
            title: NotificationType.readingPlan.displayName,
            subtitle: remainingPassages == 0
                ? 'Today is complete; no reminder will be sent'
                : '$remainingPassages passage'
                    '${remainingPassages == 1 ? '' : 's'} remaining today '
                    'at ${_timeLabel(_preferences.readingPlanMinutes)}',
            enabled: _preferences.readingPlanEnabled,
            onChanged: (value) => _setCategoryEnabled(
              NotificationType.readingPlan,
              value,
            ),
            onTap: () => _editReminder(NotificationType.readingPlan),
          ),
          NotificationTimeTile(
            icon: Icons.psychology_alt_outlined,
            title: NotificationType.scriptureMemoryReview.displayName,
            subtitle: memoryDue == 0
                ? 'No verses due; no reminder will be sent'
                : '$memoryDue verse${memoryDue == 1 ? '' : 's'} due today '
                    'at ${_timeLabel(_preferences.scriptureMemoryMinutes)}',
            enabled: _preferences.scriptureMemoryEnabled,
            onChanged: (value) => _setCategoryEnabled(
              NotificationType.scriptureMemoryReview,
              value,
            ),
            onTap: () => _editReminder(NotificationType.scriptureMemoryReview),
          ),
          NotificationTimeTile(
            icon: Icons.self_improvement_outlined,
            title: NotificationType.prayerReminder.displayName,
            subtitle: _prayerTimeLabel(_preferences.prayerMinutes),
            enabled: _preferences.prayerEnabled,
            onChanged: (value) => _setCategoryEnabled(
              NotificationType.prayerReminder,
              value,
            ),
            onTap: () => _editReminder(NotificationType.prayerReminder),
          ),
          const _SectionLabel('Cloud updates'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const Icon(Icons.new_releases_outlined),
            title: Text(NotificationType.appUpdate.displayName),
            subtitle: const Text(
              'Coming later with real-time cloud notifications',
            ),
            trailing: const Tooltip(
              message: 'Unavailable in this version',
              child: Icon(Icons.cloud_off_outlined),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const Icon(Icons.campaign_outlined),
            title: Text(NotificationType.importantAnnouncement.displayName),
            subtitle: const Text(
              'Coming later with real-time cloud notifications',
            ),
            trailing: const Tooltip(
              message: 'Unavailable in this version',
              child: Icon(Icons.cloud_off_outlined),
            ),
          ),
          const _SectionLabel('Delivery'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const Icon(Icons.do_not_disturb_on_outlined),
            title: const Text('Quiet hours'),
            subtitle: Text(
              _preferences.quietHoursEnabled
                  ? '${_timeLabel(_preferences.quietStartMinutes)} - '
                      '${_timeLabel(_preferences.quietEndMinutes)}'
                  : 'Off',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editQuietHours,
          ),
          const _SectionLabel('Device check'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(
              _permissionStatus == AppNotificationPermissionStatus.granted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
            ),
            title: const Text('Notification status'),
            subtitle: Text(
              switch (_permissionStatus) {
                AppNotificationPermissionStatus.granted =>
                  'Notifications are enabled on this device.',
                AppNotificationPermissionStatus.denied =>
                  'Notifications are blocked on this device.',
                AppNotificationPermissionStatus.notDetermined =>
                  'Send a test to allow notifications.',
                AppNotificationPermissionStatus.unsupported =>
                  'System notifications are unavailable on this platform.',
              },
            ),
            trailing:
                _permissionStatus == AppNotificationPermissionStatus.denied
                    ? TextButton(
                        onPressed: _openSettings,
                        child: const Text('Open settings'),
                      )
                    : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: FilledButton.tonalIcon(
              onPressed: _sendingTestNotification ||
                      _permissionStatus ==
                          AppNotificationPermissionStatus.unsupported
                  ? null
                  : _sendTestNotification,
              icon: _sendingTestNotification
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Send Test Notification'),
            ),
          ),
        ],
      ),
    );
  }

  String _prayerTimeLabel(int minutes) {
    final label = switch (minutes) {
      480 => 'Morning',
      780 => 'Afternoon',
      1140 => 'Evening',
      _ => 'Custom time',
    };
    return '$label at ${_timeLabel(minutes)}';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
      ),
    );
  }
}

class _ReminderEditorSheet extends StatefulWidget {
  const _ReminderEditorSheet({
    required this.type,
    required this.initialPreferences,
    required this.contentService,
  });

  final NotificationType type;
  final NotificationPreferences initialPreferences;
  final NotificationContentService contentService;

  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  late NotificationPreferences _preferences = widget.initialPreferences;

  int get _minutes => _preferences.minutesFor(widget.type) ?? 8 * 60;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
    );
    if (picked == null || !mounted) return;
    await _selectMinutes(picked.hour * 60 + picked.minute);
  }

  Future<void> _selectMinutes(int selectedMinutes) async {
    var minutes = selectedMinutes;
    var allowDuringQuietHours = false;
    final picked = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

    if (_preferences.quietHoursEnabled &&
        isInsideQuietHours(
          minutesAfterMidnight: minutes,
          quietStartMinutes: _preferences.quietStartMinutes,
          quietEndMinutes: _preferences.quietEndMinutes,
        )) {
      final choice = await showDialog<_QuietTimeChoice>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inside quiet hours'),
          content: Text(
            '${MaterialLocalizations.of(context).formatTimeOfDay(picked)} '
            'falls inside your quiet hours.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _QuietTimeChoice.useAnyway),
              child: const Text('Use this time'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _QuietTimeChoice.move),
              child: Text(
                'Move to ${MaterialLocalizations.of(context).formatTimeOfDay(
                  TimeOfDay(
                    hour: _preferences.quietEndMinutes ~/ 60,
                    minute: _preferences.quietEndMinutes % 60,
                  ),
                )}',
              ),
            ),
          ],
        ),
      );
      if (choice == null) return;
      allowDuringQuietHours = choice == _QuietTimeChoice.useAnyway;
      if (choice == _QuietTimeChoice.move) {
        minutes = _preferences.quietEndMinutes;
      }
    }

    setState(() {
      _preferences = _preferences.withMinutes(
        widget.type,
        minutes,
        allowDuringQuietHours: allowDuringQuietHours,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = widget.contentService.forType(
      widget.type,
      count: widget.type == NotificationType.readingPlan ||
              widget.type == NotificationType.scriptureMemoryReview
          ? 3
          : null,
    );
    final prayerPreset = _prayerPreset(_minutes);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            '${widget.type.displayName} reminder',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enabled'),
            value: _preferences.isEnabled(widget.type),
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.withEnabled(widget.type, value);
              });
            },
          ),
          if (widget.type == NotificationType.prayerReminder)
            DropdownButtonFormField<String>(
              initialValue: prayerPreset,
              decoration: const InputDecoration(
                labelText: 'Time of day',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'morning', child: Text('Morning')),
                DropdownMenuItem(
                  value: 'afternoon',
                  child: Text('Afternoon'),
                ),
                DropdownMenuItem(value: 'evening', child: Text('Evening')),
                DropdownMenuItem(value: 'custom', child: Text('Custom time')),
              ],
              onChanged: (value) async {
                final minutes = switch (value) {
                  'morning' => 8 * 60,
                  'afternoon' => 13 * 60,
                  'evening' => 19 * 60,
                  _ => null,
                };
                if (minutes == null) {
                  await _pickTime();
                } else {
                  await _selectMinutes(minutes);
                }
              },
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Time'),
            subtitle: Text(
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickTime,
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_today_outlined),
            title: Text('Days'),
            subtitle: Text('Every day'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.volume_down_outlined),
            title: Text('Sound'),
            subtitle: Text('Gentle device default'),
          ),
          const SizedBox(height: 8),
          Text('Preview', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(content.body),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, _preferences),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _prayerPreset(int minutes) => switch (minutes) {
        480 => 'morning',
        780 => 'afternoon',
        1140 => 'evening',
        _ => 'custom',
      };
}

enum _QuietTimeChoice { useAnyway, move }

class _QuietHoursSheet extends StatefulWidget {
  const _QuietHoursSheet({required this.initialPreferences});

  final NotificationPreferences initialPreferences;

  @override
  State<_QuietHoursSheet> createState() => _QuietHoursSheetState();
}

class _QuietHoursSheetState extends State<_QuietHoursSheet> {
  late NotificationPreferences _preferences = widget.initialPreferences;

  Future<void> _pick({required bool start}) async {
    final minutes =
        start ? _preferences.quietStartMinutes : _preferences.quietEndMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null) return;
    final next = picked.hour * 60 + picked.minute;
    setState(() {
      _preferences = _preferences.copyWith(
        quietStartMinutes: start ? next : _preferences.quietStartMinutes,
        quietEndMinutes: start ? _preferences.quietEndMinutes : next,
        quietHoursOverrides: const <NotificationType>{},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    String format(int minutes) => localizations.formatTimeOfDay(
          TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiet hours',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reduce interruptions'),
            subtitle: const Text(
              'Reminders inside this window move to the end time.',
            ),
            value: _preferences.quietHoursEnabled,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(quietHoursEnabled: value);
              });
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Starts'),
            trailing: Text(format(_preferences.quietStartMinutes)),
            onTap: () => _pick(start: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ends'),
            trailing: Text(format(_preferences.quietEndMinutes)),
            onTap: () => _pick(start: false),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _preferences),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
