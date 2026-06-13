import 'package:flutter/material.dart';
// Removed unused AppBranding import
// import '../../../../core/config/app_branding.dart';
import 'package:share_plus/share_plus.dart';

class ClosingPrayerCard extends StatelessWidget {
  const ClosingPrayerCard({
    super.key,
    required this.prayer,
    required this.devotionalTitle,
  });

  final String prayer;
  final String devotionalTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4F46E5).withValues(alpha: 0.15),
            const Color(0xFF7C3AED).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF6D28D9).withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              const Text('🙏', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                'Closing Prayer',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF818CF8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0x226D28D9)),

          // ── Prayer text ──────────────────────────────────────────────
          Text(
            prayer,
            textAlign: TextAlign.justify,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.75,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),

          // ── Share prayer ────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Share.share(
                '🙏 A prayer for $devotionalTitle:\n\n$prayer\n\n'
                '📖 The Word – The Word App\n'
                'https://play.google.com/store/apps/details?id=com.theword.simplebible',
                subject: 'A prayer for $devotionalTitle',
              ),
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Share Prayer'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF818CF8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
