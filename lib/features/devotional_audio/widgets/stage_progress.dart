import 'package:flutter/material.dart';
import '../models/devotional_audio_session.dart';

class StageProgress extends StatelessWidget {
  final DevotionalStage currentStage;

  const StageProgress({super.key, required this.currentStage});

  @override
  Widget build(BuildContext context) {
    const stages = [
      {'icon': '📖', 'stage': DevotionalStage.scripture,    'label': 'Scripture'},
      {'icon': '🕊',  'stage': DevotionalStage.understanding, 'label': 'Understanding'},
      {'icon': '🔥', 'stage': DevotionalStage.deepInsight,   'label': 'Deep Insight'},
      {'icon': '✨', 'stage': DevotionalStage.keyTruth,      'label': 'Key Truth'},
      {'icon': '🌱', 'stage': DevotionalStage.reflection,    'label': 'Reflection'},
      {'icon': '🙏', 'stage': DevotionalStage.prayer,        'label': 'Prayer'},
      {'icon': '📝', 'stage': DevotionalStage.journal,       'label': 'Journal'},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: stages.asMap().entries.map((entry) {
            final idx   = entry.key;
            final data  = entry.value;
            final stage = data['stage'] as DevotionalStage;
            final icon  = data['icon'] as String;
            final isPast    = currentStage.index > stage.index;
            final isCurrent = currentStage == stage;

            Widget iconWidget = Text(
              icon,
              style: TextStyle(
                fontSize: isCurrent ? 22 : 16,
              ),
            );

            if (isCurrent) {
              iconWidget = Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.12),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: iconWidget,
              );
            } else {
              iconWidget = Opacity(
                opacity: isPast ? 0.8 : 0.3,
                child: iconWidget,
              );
            }

            final children = <Widget>[iconWidget];
            if (idx < stages.length - 1) {
              children.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '→',
                    style: TextStyle(
                      color: isPast
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.2),
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }
            return Row(mainAxisSize: MainAxisSize.min, children: children);
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Stage label
        Text(
          (stages.firstWhere(
            (s) => s['stage'] == currentStage,
            orElse: () => stages.last,
          )['label'] as String).toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 4.0,
          ),
        ),
      ],
    );
  }
}
