import 'package:flutter/material.dart';

import '../../../shared/widgets/reading_text_scale.dart';
import '../../scripture_memory/model/memory_verse.dart';
import '../../scripture_memory/widgets/add_to_memory_sheet.dart';
import '../model/promise_verse.dart';

class PromiseVerseScreen extends StatelessWidget {
  final PromiseVerse promise;

  const PromiseVerseScreen({
    super.key,
    required this.promise,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Promise"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Row(
            children: [
              Expanded(
                child: ReadingTextScale(
                  child: Text(
                    promise.reference,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
              _PromiseTagLarge(tag: promise.tag),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [
                  Color(0x332D1B69),
                  Color(0x22111427),
                ],
              ),
              border: Border.all(
                color: Color(0x558B5CF6),
              ),
            ),
            child: ReadingTextScale(
              child: Text(
                '"${promise.text}"',
                style: theme.textTheme.headlineSmall?.copyWith(
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ReadingTextScale(
            child: Text(
              'Promise Insight',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ReadingTextScale(
            child: Text(
              promise.commentary,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.65,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _PromiseSection(
            icon: Icons.self_improvement_rounded,
            title: 'Prayer',
            body: promise.prayer,
          ),
          const SizedBox(height: 24),
          _PromiseSection(
            icon: Icons.edit_note_rounded,
            title: 'Reflect',
            body: promise.reflection,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => showAddToMemorySheet(
              context,
              draft: MemoryVerseDraft(
                bookId: promise.bookId,
                bookName: promise.bookName,
                chapter: promise.chapter,
                startVerse: promise.verse,
                translation: promise.translation,
                text: promise.text,
                source: MemoryVerseSource.promise,
                categories: [promise.tag],
              ),
            ),
            icon: const Icon(Icons.psychology_alt_rounded),
            label: const Text('Hide This Promise in My Heart'),
          ),
        ],
      ),
    );
  }
}

class _PromiseSection extends StatelessWidget {
  const _PromiseSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 10),
            ReadingTextScale(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ReadingTextScale(
          child: Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.65,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _PromiseTagLarge extends StatelessWidget {
  final String tag;

  const _PromiseTagLarge({
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFFFF7AB6),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
