/// Centralised share text builder for all Gospel Tracts.
///
/// Every share — text or image caption — goes through this helper so the
/// app link and footer are always consistent.
class TractSharer {
  TractSharer._();

  /// The store / landing-page link appended to every share.
  static const _appLink =
      'https://play.google.com/store/apps/details?id=com.theword.simplebible';

  static const _footer = '📖 Download The Word – The Word App\n$_appLink';

  /// Full share text for an **official** seeded tract.
  ///
  /// Includes hook, key verse + reference, the full body, and the app link.
  static String forOfficialTract({
    required String hook,
    required String title,
    required String keyVerse,
    required String keyVerseRef,
    required String body,
  }) {
    return '''$hook ✝️

📖 $title

"$keyVerse"
— $keyVerseRef

$body

—————
$_footer''';
  }

  /// Full share text for a **user-created** tract.
  ///
  /// Includes the title, the full message, and the app link.
  static String forUserTract({
    required String title,
    required String message,
  }) {
    return '''✝️ $title

$message

—————
$_footer''';
  }

  /// Caption shown alongside a **shared image** (official tract).
  static String imageCaption(String title) => '✝️ $title\n\n$_footer';
}
