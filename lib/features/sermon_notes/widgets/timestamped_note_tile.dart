import 'package:flutter/material.dart';

class TimestampedNoteTile extends StatelessWidget {
  const TimestampedNoteTile({
    super.key,
    required this.timestamp,
    required this.text,
    required this.onTap,
  });

  final Duration timestamp;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Chip(
        visualDensity: VisualDensity.compact,
        label: Text(_formatDuration(timestamp)),
      ),
      title: Text(
        text.trim().isEmpty ? 'Timestamped sermon moment' : text.trim(),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.play_arrow_rounded,
        color: theme.colorScheme.primary,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
