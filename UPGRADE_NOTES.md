# The Word Bible App — upgrade candidate

This package is based on the uploaded project ZIP. The original Google Play submission is not modified.

## Changes
- `lib/features/search/view/search_screen.dart`: exception recovery, stale-search result guard, guaranteed loading cleanup.
- `lib/features/home/view/home_screen.dart`: allows unfinished today's devotional to appear in the continuation card; still requires device validation of persisted resume state.
- `lib/features/tracts/view/widgets/tract_canvas.dart`: Scripture card now precedes the body in single- and multi-column layouts.
- `assets/videos/the_word_landing_page.mp4`: H.264 Constrained Baseline, level 3.0, 720x1280, 30fps, no audio stream, faststart.
- Word Studio footer already says 'The Word Bible App' in this source baseline; no additional branding edit needed.

## Not yet verified
- Flutter analyze/tests and Android build (Flutter SDK not installed in this environment).
- Real-device phone-call interruption, audio-focus and video-player lifecycle behavior.
- Devotional resume ordering across app restart/history navigation and other states.
- Word Studio preview/export visual fidelity, long-text overflow and multi-page layouts.
- Slow/offline search performance on actual Android devices.

## Suggested verification
Run `flutter pub get`, `flutter analyze`, `flutter test`, and a debug/release Android build in your development environment. Check rapid searches, failed searches, offline search, devotional history/restart, Word Studio preview and exported images, and call interruptions before publishing.


## Follow-up: Home logo widget test fix
The branding logo path in `lib/core/config/app_branding.dart` was corrected to `assets/images/the_word_app_icon.png`, which is bundled in the project. This resolves the source-level missing-asset mismatch reported by `flutter test`. Re-run the Flutter suite to verify; no Flutter SDK test run was performed in this environment.

## Keyword-search candidate (2026-10-18)
- Web token index now scores partial keyword overlaps, ranking matches with more tokens first.
- Native SQLite FTS now permits partial token matches, using BM25 for ranking.
- KJV and WEB search each other for additional verse references, while always displaying the user's selected translation.
- Search-index build futures are removed after completion or failure, allowing retries.
- Limitations: approximate matches are not yet labeled per verse; generic single-keyword matches may outrank a cross-translation exact phrase. Requires real-device and browser relevance testing, especially Isaiah 28:10, before production.
- Flutter SDK is unavailable in this environment; run `flutter analyze` and `flutter test` locally. Do not upload to Play Console until verified.

## Word Studio slide Scripture placement correction
- Full Page retains Scripture before the devotional body.
- Slide 1 now includes the Scripture card before the first body chunk.
- The final Invitation slide no longer repeats Scripture; its height estimate was updated accordingly.
- Added `test/features/tracts/word_studio_slide_scripture_test.dart` covering full page, first slide, and invitation.
- Run `flutter analyze`, `flutter test`, and inspect Word Studio preview and exported images on Chrome and Android. Flutter tooling is unavailable in this packaging environment; tests have not been executed here.

## Precision-first Bible search refinement (2026-10-19)
- Adds `SearchRelevance` shared verse-text scorer to suppress weak OR matches and rank full phrases first.
- Checks cross-translation verse text before adding references; displays selected translation only.
- Suppresses weaker candidates when a strong phrase match exists; no forced filler results.
- Adds `test/data/search_relevance_test.dart` for John 3:16, Isaiah 28:10, and negation.
- This is an unverified source candidate: run `flutter analyze`, `flutter test`, and Android/Web checks before release.
