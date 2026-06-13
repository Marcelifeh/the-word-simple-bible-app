import 'narration_state.dart';

class NarrationProfile {
  const NarrationProfile({
    required this.id,
    required this.label,
    required this.mode,
    required this.speed,
    required this.pitch,
  });

  final String id;
  final String label;
  final NarrationMode mode;
  final double speed;
  final double pitch;

  static const reading = NarrationProfile(
    id: 'reading',
    label: 'Reading',
    mode: NarrationMode.reading,
    speed: 0.38, // Clear, focused reading pace
    pitch: 1.0,
  );

  static const prayer = NarrationProfile(
    id: 'prayer',
    label: 'Prayer',
    mode: NarrationMode.prayer,
    speed: 0.30, // Slow, reverent
    pitch: 1.02,
  );

  static const meditation = NarrationProfile(
    id: 'meditation',
    label: 'Meditation',
    mode: NarrationMode.meditation,
    speed: 0.30, // Deeply unhurried
    pitch: 1.0,
  );

  static const sermon = NarrationProfile(
    id: 'sermon',
    label: 'Sermon',
    mode: NarrationMode.sermon,
    speed: 0.36, // Authoritative, natural speech pace
    pitch: 1.05,
  );

  static const children = NarrationProfile(
    id: 'children',
    label: 'Children',
    mode: NarrationMode.children,
    speed: 0.34, // Warm, elevated pitch for Bible stories
    pitch: 1.12,
  );

  static const presets = <NarrationProfile>[
    reading,
    prayer,
    meditation,
    sermon,
    children,
  ];
}
