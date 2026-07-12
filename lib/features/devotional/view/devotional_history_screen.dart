import 'package:flutter/material.dart';
// Removed unused AppBranding import
// import '../../../core/config/app_branding.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/animated_stagger_list.dart';
import '../model/devotional_model.dart';
import '../service/devotional_service.dart';
import 'devotional_detail_screen.dart';

class DevotionalHistoryScreen extends StatelessWidget {
  const DevotionalHistoryScreen({super.key});

  static const _indigo = Color(0xFF4F46E5);
  static const _violet = Color(0xFF7C3AED);
  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final service = const DevotionalService();
    final history = service.getHistoryDevotionals(
      readHistory: state.devotionalReadHistory,
    );
    final today = service.getTodaysDevotional();

    void openDevotional(DevotionalModel devotional, DateTime? activeDate) {
      state.setCurrentDevotional(
        devotional,
        activeDate: activeDate,
        stage: DevotionalResumeStage.reading,
      );
      AppRouter.push(
        context,
        DevotionalDetailScreen(
          devotional: devotional,
          activeDate: activeDate,
        ),
        transition: AppTransitionType.devotional,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devotional History'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          AnimatedStaggerItem(
            index: 0,
            child: const _HistorySummaryCard(),
          ),
          const SizedBox(height: 18),
          if (history.isEmpty)
            const AnimatedStaggerItem(
              index: 1,
              child: _EmptyHistoryCard(),
            ),
          for (final entry in history.asMap().entries) ...[
            AnimatedStaggerItem(
              index: entry.key + 2,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryItemCard(
                  devotional: entry.value,
                  readAt: state.devotionalReadHistory[entry.value.id],
                  isToday: entry.value.id == today.id,
                  onTap: () => openDevotional(
                    entry.value,
                    state.devotionalReadHistory[entry.value.id],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            DevotionalHistoryScreen._indigo,
            DevotionalHistoryScreen._violet
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'READ HISTORY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your devotional history reflects the journey God is taking you through.',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revisit past reflections and continue growing through every revealed truth.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No read devotionals yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open today’s devotional and it will appear here in your history.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  const _HistoryItemCard({
    required this.devotional,
    required this.readAt,
    required this.onTap,
    required this.isToday,
  });

  final DevotionalModel devotional;
  final DateTime? readAt;
  final VoidCallback onTap;
  final bool isToday;

  String _formatReadAt(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final dateOnly = DateTime(value.year, value.month, value.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    final daysDifference = todayOnly.difference(dateOnly).inDays;
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: false,
    );

    if (daysDifference == 0) {
      return 'Read today at $time';
    }
    if (daysDifference == 1) {
      return 'Read yesterday at $time';
    }
    return 'Read ${localizations.formatShortDate(value)} at $time';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isToday
                ? DevotionalHistoryScreen._amber.withValues(alpha: 0.35)
                : scheme.outline.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _TagChip(
                        label: devotional.theme,
                        color: DevotionalHistoryScreen._indigo,
                      ),
                      if (isToday)
                        _TagChip(
                          label: 'Today',
                          color: DevotionalHistoryScreen._amber,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              devotional.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              devotional.scriptureReference,
              style: theme.textTheme.labelLarge?.copyWith(
                color: DevotionalHistoryScreen._indigo,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (readAt != null) ...[
              const SizedBox(height: 6),
              Text(
                _formatReadAt(context, readAt!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              devotional.finalRevelation,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.55,
                color: scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
