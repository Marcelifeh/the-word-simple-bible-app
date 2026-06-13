class NarrationTextProcessor {
  const NarrationTextProcessor._();

  static String humanize(String text) {
    var output = text.trim();
    if (output.isEmpty) {
      return output;
    }

    output = output
        .replaceAll('—', ', ')
        .replaceAll(';', '. ')
        .replaceAll(':', '. ')
        .replaceAll(RegExp(r'\s+'), ' ');

    output = output.replaceAllMapped(
      RegExp(r'([.!?])\s+'),
      (match) => '${match.group(1)}\n\n',
    );

    output = output.replaceAllMapped(
      RegExp(r'\b(Lord|God|Jesus|Christ|Holy Spirit)\b'),
      (match) => match.group(0)!,
    );

    return output.trim();
  }

  static List<String> splitIntoNaturalChunks(String text) {
    final processed = humanize(text);

    return processed
        .split(RegExp(r'\n\n+'))
        .map((chunk) => chunk.trim())
        .where((chunk) => chunk.isNotEmpty)
        .toList();
  }
}
