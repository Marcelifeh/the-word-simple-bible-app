import 'package:flutter/material.dart';

class SermonIntelligenceCard extends StatelessWidget {
  const SermonIntelligenceCard({
    super.key,
    required this.title,
    required this.emptyText,
    required this.content,
    required this.buttonText,
    required this.onPressed,
    this.disabledText,
  });

  final String title;
  final String emptyText;
  final String? content;
  final String buttonText;
  final VoidCallback? onPressed;
  final String? disabledText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasContent = content != null && content!.trim().isNotEmpty;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hasContent
                  ? content!.trim()
                  : onPressed == null && disabledText != null
                      ? disabledText!
                      : emptyText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasContent ? null : theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: const Icon(Icons.auto_awesome),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
