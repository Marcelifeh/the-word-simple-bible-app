import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/spiritual_section.dart';
import '../model/user_tract.dart';
import '../tract_sharer.dart';
import 'tract_image_designer_screen.dart';

class UserTractDetailScreen extends StatelessWidget {
  const UserTractDetailScreen({super.key, required this.tract});

  final UserTract tract;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tract.title),
        actions: [
          // Share button
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: () async {
              await Share.share(
                TractSharer.forUserTract(
                  title: tract.title,
                  message: tract.message,
                ),
                subject: tract.title,
              );
              await AppHaptics.shareTriggered();
            },
          ),
          // Delete button
          IconButton(
            tooltip: 'Delete',
            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header badge ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'YOUR TRACT',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Title ─────────────────────────────────────────────────────
            Text(
              tract.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Written ${_formatDate(tract.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 32),

            // ── Message body ──────────────────────────────────────────────
            SpiritualSection(
              title: 'Your Message',
              body: tract.message,
              icon: '🕊',
              accentColor: cs.primary,
              titleStyle: theme.textTheme.titleSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
              bodyStyle: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Share.share(
                        TractSharer.forUserTract(
                          title: tract.title,
                          message: tract.message,
                        ),
                        subject: tract.title,
                      );
                      await AppHaptics.shareTriggered();
                    },
                    icon: const Icon(Icons.textsms_outlined),
                    label: const Text('Share Text'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TractImageDesignerScreen(
                            title: tract.title,
                            body: tract.message,
                            scripture: '',
                            scriptureRef: '',
                            hook: 'Written by a Disciple',
                            isUserTract: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Share Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tract?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      AppScope.of(context).userTractRepo.delete(tract.id);
      Navigator.pop(context, 'deleted');
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}
