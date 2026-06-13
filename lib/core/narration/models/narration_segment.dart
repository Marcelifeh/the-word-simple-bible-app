class NarrationSegment {
  final String id;
  final String text;
  final String? reference;
  final Duration? pauseAfter;

  const NarrationSegment({
    required this.id,
    required this.text,
    this.reference,
    this.pauseAfter,
  });
}
