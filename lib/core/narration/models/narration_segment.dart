class NarrationSegment {
  final String id;
  final String text;
  final String? _displayText;
  final String? _speechText;
  final String? reference;
  final Duration? pauseAfter;

  const NarrationSegment({
    required this.id,
    required this.text,
    String? displayText,
    String? speechText,
    this.reference,
    this.pauseAfter,
  })  : _displayText = displayText,
        _speechText = speechText;

  String get displayText => sanitizeForDisplay(_displayText ?? text);

  String get speechText => _speechText ?? sanitizeForDisplay(text);

  static String sanitizeForDisplay(String input) {
    var output = input.trim();
    if (output.isEmpty) return output;

    output = output
        .replaceAll(RegExp(r'\\f\s+.*?\\f\*', dotAll: true), ' ')
        .replaceAll(RegExp(r'\\x\s+.*?\\x\*', dotAll: true), ' ')
        .replaceAll(RegExp(r'\\\s*[+\-]?\s*[A-Za-z0-9*]+'), ' ')
        .replaceAll(RegExp(r'\|strong="[^"]*"'), '')
        .replaceAll(RegExp(r'\$\d+'), '')
        .replaceAll(r'$', '')
        .replaceAll(RegExp(r'\[\[?[A-Za-z]+\]?\]'), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ');

    output = output.replaceAllMapped(
      RegExp(r'\s+([,.;:!?])'),
      (match) => match.group(1)!,
    );
    output = output.replaceAll(RegExp(r'\s+'), ' ');

    return output.trim();
  }
}
