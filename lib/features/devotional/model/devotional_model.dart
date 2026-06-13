import '../../../core/narration/contracts/narratable_content.dart';
import '../../../core/narration/models/narration_segment.dart';
import 'devotional_section.dart';

/// The full data model for one devotional experience.
class DevotionalModel implements NarratableContent {
  final String id;
  final String title;
  final String theme;
  final String scripture;
  final String scriptureReference;
  final List<DevotionalSection> sections;
  final String finalRevelation;
  final List<String> reflectionQuestions;
  final String prayer;
  final DateTime createdAt;

  const DevotionalModel({
    required this.id,
    required this.title,
    required this.theme,
    required this.scripture,
    required this.scriptureReference,
    required this.sections,
    required this.finalRevelation,
    required this.reflectionQuestions,
    required this.prayer,
    required this.createdAt,
  });

  @override
  List<NarrationSegment> get narrationSegments {
    final segments = <NarrationSegment>[
      NarrationSegment(
        id: '${id}_title',
        text: title,
        pauseAfter: const Duration(seconds: 1),
      ),
      NarrationSegment(
        id: '${id}_verse',
        text: '$scriptureReference... $scripture',
        reference: scriptureReference,
        pauseAfter: const Duration(seconds: 4),
      ),
    ];
    for (int i = 0; i < sections.length; i++) {
      final s = sections[i];
      segments.add(
        NarrationSegment(
          id: '${id}_section_$i',
          text: '${s.heading}... ${s.body}',
          pauseAfter: const Duration(seconds: 2),
        ),
      );
    }
    segments.add(
      NarrationSegment(
        id: '${id}_revelation',
        text: 'Final Revelation... $finalRevelation',
        pauseAfter: const Duration(seconds: 5),
      ),
    );
    segments.add(
      NarrationSegment(
        id: '${id}_prayer',
        text: 'Let us pray... $prayer',
        pauseAfter: const Duration(seconds: 2),
      ),
    );
    return segments;
  }

  List<NarrationSegment> get audioJourneySegments {
    final segments = <NarrationSegment>[
      NarrationSegment(
        id: 'stage_scripture',
        // Clean connector: reference, brief pause word, then the verse
        text: '$scriptureReference. $scripture',
        reference: scriptureReference,
        pauseAfter: const Duration(seconds: 4),
      ),
    ];

    if (sections.isNotEmpty) {
      segments.add(
        NarrationSegment(
          id: 'stage_understanding',
          text: sections.first.body,
          pauseAfter: const Duration(seconds: 3),
        ),
      );
    }

    if (sections.length > 1) {
      final insightText = sections.skip(1).map((s) => s.body).join('. ');
      segments.add(
        NarrationSegment(
          id: 'stage_insight',
          text: insightText,
          pauseAfter: const Duration(seconds: 4),
        ),
      );
    }

    segments.add(
      NarrationSegment(
        id: 'stage_key_truth',
        text: finalRevelation,
        pauseAfter: const Duration(seconds: 5),
      ),
    );

    if (reflectionQuestions.isNotEmpty) {
      segments.add(
        NarrationSegment(
          id: 'stage_reflection',
          text: reflectionQuestions.first,
          pauseAfter: const Duration(seconds: 25), // Silent reflection pause
        ),
      );
    }

    segments.add(
      NarrationSegment(
        id: 'stage_prayer',
        text: prayer,
        pauseAfter: const Duration(seconds: 2),
      ),
    );

    return segments;
  }
}
