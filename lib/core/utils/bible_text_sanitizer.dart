class BibleTextSanitizer {
  /// Cleans common USFM/WordLink artifacts from verse text.
  ///
  /// This intentionally mirrors the backend's cleaning to keep verse rendering
  /// consistent across assets and API.
  static String clean(String input) {
    var s = input.trim();
    if (s.isEmpty) return s;

    // Remove USFM footnotes/cross-refs.
    s = s.replaceAll(RegExp(r'\\f\s+.*?\\f\*', dotAll: true), ' ');
    s = s.replaceAll(RegExp(r'\\x\s+.*?\\x\*', dotAll: true), ' ');

    // Remove generic USFM tags and WordLink markers (\w ... \w*).
    // Some converted sources include spaces inside markers, such as "\ +w".
    s = s.replaceAll(RegExp(r'\\\s*[+\-]?\s*[a-zA-Z0-9*]+'), ' ');

    // Remove strong attributes when present (mostly a USFM conversion artifact).
    s = s.replaceAll(RegExp(r'\|strong="[^"]*"'), '');

    // Remove WordLink/footnote marker artifacts (e.g. "Verily$1" or "$12").
    s = s.replaceAll(RegExp(r'\$\d+'), '');
    s = s.replaceAll(r'$', ''); // Remove any remaining dollar signs

    // Strip Psalm 119 acrostic section headers appended to the last verse of
    // each 8-verse block (e.g. "ב BETH", "ש Sin na Shin", "TZADHE").
    // Keeping these isolated Hebrew markers causes Flutter web font warnings.
    s = s.replaceAll(
      RegExp(
        r'[.\s]+[\u0590-\u05FF]\s+(SIN\s+(?:AND|NA|DA)\s+SHIN|ALEPH|SAMEKH|LAMEDH|TZADHE|TSADHE|SAMECH|GIMEL|DALETH|ZAYIN|HETH|CHETH|YODH|KAPF|KAPH|CAPH|LAMED|TETH|RESH|SHIN|SCHIN|BETH|AYIN|QOPH|KOPH|KWO?F|KAP|VAV|VAU|NUN|MEM|HE|PE|FE|TAV|TAU|BET)\b[.\s]*$',
        caseSensitive: false,
      ),
      '',
    );

    s = s.replaceAll(
      RegExp(
        r'[.\s]+(SIN\s+AND\s+SHIN|ALEPH|SAMEKH|LAMEDH|TZADHE|TSADHE|SAMECH|GIMEL|DALETH|ZAYIN|HETH|CHETH|YODH|KAPF|KAPH|CAPH|LAMED|TETH|RESH|SHIN|SCHIN|BETH|AYIN|QOPH|KOPH|VAV|VAU|NUN|MEM|HE|PE|TAV|TAU)\b[.\s]*$',
      ),
      '',
    );

    // Normalize whitespace/punctuation spacing.
    // NOTE: Dart's replaceAll does NOT support $1 backreferences.
    // Use replaceAllMapped to properly strip leading whitespace before punctuation.
    s = s.replaceAllMapped(
      RegExp(r'\s+([,.;:!?])'),
      (m) => m.group(1)!,
    );
    s = s.replaceAll(RegExp(r'\s+'), ' ');

    return s.trim();
  }
}
