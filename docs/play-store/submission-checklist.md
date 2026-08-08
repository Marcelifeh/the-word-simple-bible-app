# Google Play Submission Checklist

Release: `1.0.0+1`
Package: `org.thewordapp.mobile`

## Release artifact

- [x] Rebuild the signed AAB after the policy and app-name changes.
- [x] Confirm `build/app/outputs/bundle/release/app-release.aab` exists.
- [x] Confirm version code `1`, version name `1.0.0`, target SDK `36`, and package `org.thewordapp.mobile`.
- [x] Inspect the final merged Android manifest and dependency graph.
- [ ] Install the matching signed release APK on the Samsung phone.
- [ ] Test update installation without losing local data.

## Privacy and Data Safety

- [x] Code-level privacy and network audit completed.
- [x] In-app Privacy Policy updated for release behavior.
- [x] Hosted Privacy Policy prepared at the Play Console URL.
- [ ] Push the policy update and verify the public page in an incognito browser.
- [ ] Confirm Render access-log retention and deletion controls.
- [ ] Complete Data Safety from `data-safety-notes.md`.
- [ ] Recheck the declaration after any SDK, backend, or build-flag change.

## App Content

- [ ] Privacy policy URL entered.
- [ ] Ads: No.
- [ ] App access: no login or special access required.
- [ ] Target audience selected from the actual intended audience.
- [ ] Content rating questionnaire completed.
- [ ] News or magazine app: No.
- [ ] Data Safety submitted.
- [ ] Microphone use is accurately described as user-initiated sermon recording.
- [ ] Account deletion marked not applicable because the app has no accounts.

## Store listing

- [x] App name prepared: The Word App.
- [x] Short description prepared and under 80 characters.
- [x] Full description prepared.
- [x] 512x512 32-bit Play icon prepared.
- [x] 1024x500 24-bit feature graphic prepared.
- [ ] Six compliant `1080x1920` phone screenshots prepared.
- [ ] Bible Reader screenshot captured.
- [ ] Screenshot alt text entered.
- [ ] Support email verified and monitored.

## Internal testing

- [ ] Upload the signed AAB to Internal testing.
- [ ] Add the initial release notes.
- [ ] Install through the Google Play opt-in link.
- [ ] Verify cold launch, offline Bible, Search, Devotional, LOGOS Notes, recording, notifications, Word Studio, Scripture Memory, and sharing.
- [ ] Verify notification taps from foreground, background, and terminated states.
- [ ] Verify update installation preserves Hive data and local files.

## Closed testing and production

- [ ] Create the closed-testing track if required for the developer account.
- [ ] Keep the required number of testers continuously opted in for the required period shown by Play Console.
- [ ] Record tester dates, devices, issues, and fixes.
- [ ] Apply for production access when Play Console enables it.
- [ ] Use a staged production rollout and monitor Android vitals, reviews, API errors, and support email.

Official references: [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455), [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469), and [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151).
