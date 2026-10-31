import 'package:flutter/material.dart';

import '../services/daily_altar_today_status.dart';

/// Reusable presentation of today's Daily Altar status.
///
/// This widget does not:
/// - load or write persistence
/// - know about Hive
/// - calculate lifecycle timing
/// - perform navigation
/// - implement billing or premium access
///
/// Its only responsibility is presenting a [DailyAltarTodaySnapshot]
/// and reporting taps through [onPressed].
class DailyAltarHomeCard extends StatelessWidget {
  const DailyAltarHomeCard({
    super.key,
    required this.snapshot,
    this.onPressed,
  });

  final DailyAltarTodaySnapshot snapshot;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: const Key('dailyAltarHomeCard'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('dailyAltarHomeCardTapTarget'),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(theme),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Daily Altar',
                      key: const Key('dailyAltarHomeCardTitle'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _headline,
                      key: const Key('dailyAltarHomeCardHeadline'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _supportingText,
                      key: const Key('dailyAltarHomeCardSupportingText'),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (_actionLabel != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            _actionLabel!,
                            key: const Key(
                              'dailyAltarHomeCardAction',
                            ),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(
    ThemeData theme,
  ) {
    final icon = switch (snapshot.status) {
      DailyAltarTodayStatus.notStarted => Icons.menu_book_outlined,
      DailyAltarTodayStatus.morningInProgress => Icons.auto_stories_outlined,
      DailyAltarTodayStatus.waitingForEvening => Icons.wb_sunny_outlined,
      DailyAltarTodayStatus.eveningAvailable => Icons.nights_stay_outlined,
      DailyAltarTodayStatus.completed => Icons.check_circle_outline,
    };

    return Icon(
      icon,
      key: Key(
        'dailyAltarHomeCardIcon-${snapshot.status.name}',
      ),
      size: 30,
      color: theme.colorScheme.primary,
    );
  }

  String get _headline {
    return switch (snapshot.status) {
      DailyAltarTodayStatus.notStarted => 'Begin today\'s altar',
      DailyAltarTodayStatus.morningInProgress => 'Continue your altar',
      DailyAltarTodayStatus.waitingForEvening => 'Carry the Word',
      DailyAltarTodayStatus.eveningAvailable => 'Return to your altar',
      DailyAltarTodayStatus.completed => 'Today\'s altar complete',
    };
  }

  String get _supportingText {
    return switch (snapshot.status) {
      DailyAltarTodayStatus.notStarted =>
        'Meet God in His Word and carry His truth into your day.',
      DailyAltarTodayStatus.morningInProgress =>
        'Your place has been saved. Continue where you left off.',
      DailyAltarTodayStatus.waitingForEvening => _waitingMessage,
      DailyAltarTodayStatus.eveningAvailable =>
        'Reflect on how the Word met you through the day.',
      DailyAltarTodayStatus.completed =>
        'Your morning and evening altar journey is complete for today.',
    };
  }

  String? get _actionLabel {
    return switch (snapshot.status) {
      DailyAltarTodayStatus.notStarted => 'Begin',
      DailyAltarTodayStatus.morningInProgress => 'Continue',
      DailyAltarTodayStatus.waitingForEvening => null,
      DailyAltarTodayStatus.eveningAvailable => 'Return',
      DailyAltarTodayStatus.completed => 'Review',
    };
  }

  String get _waitingMessage {
    final returnAt = snapshot.earliestReturnAt;

    if (returnAt == null) {
      return 'Carry today\'s Scripture with you and return later.';
    }

    return 'Return after ${_formatTime(returnAt)} for evening reflection.';
  }

  String _formatTime(
    DateTime value,
  ) {
    final twelveHour = value.hour % 12;
    final hour = twelveHour == 0 ? 12 : twelveHour;

    final minute = value.minute.toString().padLeft(2, '0');

    final period = value.hour < 12 ? 'AM' : 'PM';

    if (minute == '00') {
      return '$hour $period';
    }

    return '$hour:$minute $period';
  }
}
