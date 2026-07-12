import 'package:flutter/material.dart';

import '../models/devotional_audio_session.dart';

class StageProgress extends StatelessWidget {
  const StageProgress({
    super.key,
    required this.currentStage,
  });

  final DevotionalStage currentStage;

  static const _stages = <_StageItem>[
    _StageItem(
      icon: Icons.menu_book_rounded,
      stage: DevotionalStage.scripture,
      label: 'Scripture',
    ),
    _StageItem(
      icon: Icons.lightbulb_outline_rounded,
      stage: DevotionalStage.understanding,
      label: 'Meaning',
    ),
    _StageItem(
      icon: Icons.auto_awesome_rounded,
      stage: DevotionalStage.deepInsight,
      label: 'Insight',
    ),
    _StageItem(
      icon: Icons.verified_rounded,
      stage: DevotionalStage.keyTruth,
      label: 'Truth',
    ),
    _StageItem(
      icon: Icons.eco_rounded,
      stage: DevotionalStage.reflection,
      label: 'Reflect',
    ),
    _StageItem(
      icon: Icons.volunteer_activism_rounded,
      stage: DevotionalStage.prayer,
      label: 'Prayer',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activeIndex =
        _stages.indexWhere((item) => item.stage == currentStage);
    final normalizedActiveIndex = activeIndex < 0 ? 0 : activeIndex;
    final activeStage = _stages[normalizedActiveIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          activeStage.label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 3.0,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            final gap = compact ? 6.0 : 8.0;
            return Row(
              children: [
                for (var index = 0; index < _stages.length; index++) ...[
                  Expanded(
                    child: _StageCard(
                      item: _stages[index],
                      isCurrent: index == normalizedActiveIndex,
                      isPast: index < normalizedActiveIndex,
                      compact: compact,
                    ),
                  ),
                  if (index != _stages.length - 1) SizedBox(width: gap),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.item,
    required this.isCurrent,
    required this.isPast,
    required this.compact,
  });

  final _StageItem item;
  final bool isCurrent;
  final bool isPast;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final opacity = isCurrent
        ? 1.0
        : isPast
            ? 0.72
            : 0.34;
    final borderColor = isCurrent
        ? Colors.white.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.12);
    final backgroundColor = isCurrent
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.06);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: compact ? 54 : 58,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.10),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: Colors.white,
              size: compact ? 17 : 18,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 9 : 10,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageItem {
  const _StageItem({
    required this.icon,
    required this.stage,
    required this.label,
  });

  final IconData icon;
  final DevotionalStage stage;
  final String label;
}
