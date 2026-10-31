/// Translation-independent precision filter for keyword search candidates.
/// Never alters Scripture text; it only ranks existing verse references.
class SearchRelevance {
  static const _common = <String>{
    'the','and','of','to','a','in','that','is','for','with','on','upon',
    'as','be','are','was','were','it','this','but','his','her','their',
    'your','you','i','we','they','he','she','them','who','what','when',
    'where','why','how','from','by','at','or','an','into','out','up',
    'down','so','shall','will','have','has','had','do','does','did',
  };

  static List<String> words(String text) => RegExp(r'[a-z0-9]+')
      .allMatches(text.toLowerCase())
      .map((m) => m.group(0)!)
      .toList(growable: false);

  static List<String> important(String text) {
    final seen = <String>{};
    return words(text).where((w) => !_common.contains(w) && seen.add(w))
        .toList(growable: false);
  }

  static String _stem(String word) {
    if (word.endsWith('ing') && word.length > 6) return word.substring(0, word.length - 3);
    if (word.endsWith('ed') && word.length > 5) return word.substring(0, word.length - 2);
    if (word.endsWith('es') && word.length > 5) return word.substring(0, word.length - 2);
    if (word.endsWith('s') && word.length > 4) return word.substring(0, word.length - 1);
    return word;
  }

  /// Returns zero for weak matches; larger values indicate stronger matches.
  /// Negations are retained as meaningful terms.
  static double score(String query, String verse) {
    final q = important(query);
    if (q.isEmpty) return 0;
    final v = words(verse);
    final vs = v.map(_stem).toSet();
    final matched = q.where((w) => vs.contains(_stem(w))).length;
    final coverage = matched / q.length;
    // For multi-term queries, reject single-word and low-coverage hits.
    if (q.length >= 3 && (matched < 2 || coverage < 0.75)) return 0;
    if (q.length == 2 && matched < 2) return 0;
    if (q.length == 1 && matched == 0) return 0;
    final normalized = words(query).join(' ');
    final verseNormalized = v.join(' ');
    final exact = verseNormalized.contains(normalized);
    final importantSequence = q.join(' ');
    final verseImportant = v.where((w) => !_common.contains(w)).join(' ');
    final ordered = verseImportant.contains(importantSequence);
    return coverage * 100 + (ordered ? 50 : 0) + (exact ? 200 : 0);
  }
}
