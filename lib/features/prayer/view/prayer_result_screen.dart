import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/spiritual_section.dart';
import '../../notes/model/verse_note.dart';
import '../model/prayer_model.dart';
import '../../../shared/widgets/branding_widgets.dart';

class PrayerResultScreen extends StatelessWidget {
  final PrayerModel prayer;

  const PrayerResultScreen({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: LogosHeader(prayer.topic),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                prayer.reference,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '"${prayer.verse}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayer.prayer,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3)),
                        ),
                        child: SpiritualSection(
                          title: 'Reflection',
                          body: prayer.reflection,
                          icon: '🌱',
                          accentColor: Theme.of(context).colorScheme.primary,
                          titleStyle: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          bodyStyle: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.bookmark_add_outlined,
                    label: 'Save',
                    onTap: () => _savePrayerAsNote(context),
                  ),
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () => _sharePrayer(context),
                  ),
                  _ActionButton(
                    icon: Icons.refresh,
                    label: 'Pray Again',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _savePrayerAsNote(BuildContext context) {
    final state = AppScope.of(context);
    // Determine a canonical ID for the reference (approximate based on standard format)
    // E.g., "John 14:27" -> "john-14-27"
    final refLower = prayer.reference.toLowerCase().replaceAll(' ', '');
    final match = RegExp(r'^([a-z]+)(\d+):(\d+)').firstMatch(refLower);

    String verseId;
    if (match != null) {
      final bookId = match.group(1);
      final chapter = match.group(2);
      final verse = match.group(3);
      verseId = '$bookId-$chapter-$verse';
    } else {
      // Fallback
      verseId = prayer.reference.replaceAll(' ', '-').toLowerCase();
    }

    final note = VerseNote(
      verseId: verseId,
      text: 'Prayer on ${prayer.topic}:\n${prayer.prayer}',
      color: Colors.purple.toARGB32(), // Special color for prayers
      createdAt: DateTime.now(),
    );

    state.notesRepo.save(note);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prayer saved to Notes!')),
    );
  }

  void _sharePrayer(BuildContext context) {
    final text =
        'A prayer for ${prayer.topic}:\n\n${prayer.prayer}\n\nBased on ${prayer.reference}: "${prayer.verse}"';
    Share.share(text);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
