import 'package:flutter/material.dart';

import '../models/narration_segment.dart';
import '../models/narration_session.dart';
import '../services/narration_controller.dart';
import '../models/narration_state.dart';
import 'narration_controls.dart';

class NarrationBar extends StatelessWidget {
  final NarrationController controller;

  const NarrationBar({super.key, required this.controller});

  String _sourceLabel(NarrationSourceType sourceType) {
    switch (sourceType) {
      case NarrationSourceType.bible:
        return 'Bible';
      case NarrationSourceType.devotional:
        return 'Devotional';
      case NarrationSourceType.tract:
        return 'Tract';
      case NarrationSourceType.prayer:
        return 'Prayer';
      case NarrationSourceType.sermon:
        return 'Sermon';
      case NarrationSourceType.note:
        return 'Note';
    }
  }

  String _modeLabel(NarrationMode mode) {
    final name = mode.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  String _contextLabel(NarrationSession session) {
    final reference = session.currentSegment?.reference?.trim();
    if (reference != null && reference.isNotEmpty) {
      return NarrationSegment.sanitizeForDisplay(reference);
    }
    return '${_sourceLabel(session.sourceType)} session';
  }

  String _positionLabel(NarrationSession session) {
    final total = session.segments.length;
    if (total <= 0) return 'Ready';

    final hasIntro = session.sourceType == NarrationSourceType.bible &&
        total > 1 &&
        session.segments.first.id == 'intro';
    if (hasIntro) {
      if (session.currentIndex == 0) return 'Chapter intro';
      return 'Verse ${session.currentIndex} of ${total - 1}';
    }

    return 'Segment ${session.currentIndex + 1} of $total';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, controller.syncState]),
      builder: (context, _) {
        final session = controller.currentSession;
        if (session == null ||
            session.status == NarrationStatus.idle ||
            session.status == NarrationStatus.error) {
          return const SizedBox.shrink();
        }

        final syncState = controller.syncState.value;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final progress = syncState.progress.clamp(0.0, 1.0).toDouble();
        final progressPercent = (progress * 100).round();
        final sourceLabel = _sourceLabel(session.sourceType);
        final title = 'Narrating $sourceLabel';
        final contextLabel = _contextLabel(session);
        final positionLabel = _positionLabel(session);

        return Material(
          elevation: 8,
          color: scheme.surfaceContainerHighest,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Icon(
                    Icons.multitrack_audio_rounded,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          contextLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$positionLabel • ${_modeLabel(session.mode)} mode • $progressPercent%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  PopupMenuButton<double>(
                    tooltip: 'Playback speed',
                    icon: const Icon(Icons.speed),
                    constraints: const BoxConstraints(minWidth: 96),
                    initialValue: controller.preferences.speed,
                    onSelected: controller.setSpeed,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 0.75, child: Text('0.75x')),
                      PopupMenuItem(value: 1.0, child: Text('1.0x')),
                      PopupMenuItem(value: 1.25, child: Text('1.25x')),
                      PopupMenuItem(value: 1.5, child: Text('1.5x')),
                      PopupMenuItem(value: 2.0, child: Text('2.0x')),
                    ],
                  ),
                  IconButton(
                    tooltip: syncState.autoScroll
                        ? 'Disable auto-scroll'
                        : 'Enable auto-scroll',
                    onPressed: () =>
                        controller.setAutoScroll(!syncState.autoScroll),
                    icon: Icon(
                      syncState.autoScroll
                          ? Icons.swap_vert_circle_outlined
                          : Icons.swap_vert,
                    ),
                  ),
                  NarrationControls(controller: controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
