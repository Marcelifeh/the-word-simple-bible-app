# The Word App — Final Google Play Data Safety Mapping

Release candidate: `1.0.3+4`
Package: `org.thewordapp.mobile`
Production API: `https://the-word-app-api.onrender.com`
Cloud audio transcription: disabled
Remote `BIBLE_API_URL`: absent

This is an engineering mapping to the final client behavior. Google Play treats data transmitted off-device as collected, while solely on-device processing is not collection. User-directed Android sharing/export is treated under Google's user-initiated sharing exception because the user chooses the content and receiving app. Contracts, live provider configuration, and operational logging remain external facts and are marked for verification.

## Proposed top-level answers

- Does the app collect or share required user data types? **Yes — it collects two optional types for user-requested online features.**
- Is all collected data encrypted in transit? **Yes — the release guard and artifact require HTTPS.**
- Is data shared? **No — VERIFY BEFORE PLAY SUBMISSION** that Render and the configured model provider act only as service providers under the developer's instructions and that live logging/subprocessor behavior matches this repository.
- Can users request deletion? **Answer against the exact Console wording only after confirming the operational contact workflow.** Local feature data can be deleted, and clearing app data/uninstall removes app-private data.

## Applicable collected data

| Play data type | Collected | Shared | Optional / required | Purpose | Ephemeral | Encrypted in transit | Deletion / control | Source evidence |
|---|---|---|---|---|---|---|---|---|
| App activity > App interactions | **Yes** | **No — VERIFY service-provider status** | Optional | App functionality: generate missing commentary | No; generated commentary is cached locally and may be stored by the backend | **Yes** | User can avoid online generation and delete local app data; backend/provider deletion process must be verified | `commentary_repository.dart` posts Scripture reference fields; release endpoint is HTTPS |
| Other user-generated content | **Yes** | **No — VERIFY service-provider status** | Optional | App functionality: user-requested sermon summary/outline | Request is processed in memory by application code; infrastructure-log behavior is **VERIFY** | **Yes** | User can cancel the pre-submit disclosure, avoid the feature, delete the sermon locally, or clear app data; server-log deletion process is **VERIFY** | `sermon_review_screen.dart` requires explicit Generate action and confirmation; `sermon_ai_service.dart` posts transcript text |

## Data types not collected or shared in this release

| Play data type | Collected | Shared | Optional / required | Purpose | Ephemeral | Encrypted in transit | Deletion / control | Source evidence |
|---|---|---|---|---|---|---|---|---|
| App activity > In-app search history | No | No | N/A | Local Bible search only | N/A | N/A | Local derived index can be cleared with app data | `BIBLE_API_URL` is absent from the production build |
| Audio > Voice or sound recordings | No | No | N/A | User-initiated local sermon recording | N/A | N/A | Deleted with sermon/local data | Cloud transcription is build-flagged false; recordings can leave only through user-directed backup |
| Photos and videos > Photos | No | No | N/A | Local Word Studio background | N/A | N/A | Per-background deletion or clear app data | Android picker copy remains local; backup/share is user-directed |
| Files and docs | No | No | N/A | Local import/export and backup | N/A | N/A | User controls local and destination copies | Backup is created locally and shared only through the user's Android chooser |
| Device or other identifiers | No | No | N/A | N/A | N/A | N/A | N/A | No advertising, device, account, or installation ID API/SDK |
| Approximate location | No — **VERIFY provider IP handling** | No | N/A | N/A | N/A | N/A | N/A | No permission or client inference; ordinary IP is visible to network providers |
| Precise location | No | No | N/A | N/A | N/A | N/A | N/A | No location permission/API |
| App info and performance > Diagnostics | No | No | N/A | N/A | N/A | N/A | N/A | No client diagnostics uploader; verify hosting logs |
| App info and performance > Crash logs | No | No | N/A | N/A | N/A | N/A | N/A | No crash-reporting SDK |
| App info and performance > Other app performance data | No | No | N/A | N/A | N/A | N/A | N/A | No performance SDK/uploader |
| Personal info > Name | No | No | N/A | N/A | N/A | N/A | Local preacher/title fields can be deleted | No profile/account; preacher name is not posted by the implemented routes |
| Personal info > Email address | No | No | N/A | N/A | N/A | N/A | N/A | No account/contact submission UI |
| Personal info > User IDs | No | No | N/A | N/A | N/A | N/A | N/A | Local UUIDs identify content only and are not transmitted as user IDs |
| Personal info > Address | No | No | N/A | N/A | N/A | N/A | N/A | No field/API |
| Personal info > Phone number | No | No | N/A | N/A | N/A | N/A | N/A | No field/API |
| Personal info > Race and ethnicity | No | No | N/A | N/A | N/A | N/A | N/A | No field/API |
| Personal info > Political or religious beliefs | No as a separate declared type | No | N/A | N/A | N/A | N/A | Local spiritual data deletable | Scripture reference is App interactions; transcript is Other UGC. Reassess if Play guidance/classification changes |
| Personal info > Sexual orientation | No | No | N/A | N/A | N/A | N/A | N/A | No field/API |
| Personal info > Other info | No | No | N/A | N/A | N/A | N/A | N/A | No account/profile |
| Financial info > All categories | No | No | N/A | N/A | N/A | N/A | N/A | No commerce, billing, wallet, credit, or financial feature |
| Health and fitness > Health info | No | No | N/A | N/A | N/A | N/A | N/A | No health feature/API |
| Health and fitness > Fitness info | No | No | N/A | N/A | N/A | N/A | N/A | No fitness feature/API |
| Messages > Emails | No | No | N/A | N/A | N/A | N/A | N/A | No email access |
| Messages > SMS or MMS | No | No | N/A | N/A | N/A | N/A | N/A | No SMS permission/API |
| Messages > Other in-app messages | No | No | N/A | N/A | N/A | N/A | N/A | No chat or user-to-user messaging |
| Photos and videos > Videos | No | No | N/A | N/A | N/A | N/A | N/A | No user video capture/import |
| Audio > Music files | No | No | N/A | N/A | N/A | N/A | N/A | No user music collection |
| Audio > Other audio files | No | No | N/A | N/A | N/A | N/A | N/A | No applicable collection |
| Calendar | No | No | N/A | N/A | N/A | N/A | N/A | No permission/API |
| Contacts | No | No | N/A | N/A | N/A | N/A | N/A | No permission/API |
| App activity > Installed apps | No | No | N/A | N/A | N/A | N/A | N/A | Android system chooser does not create an app inventory in app code |
| App activity > Other user-generated content/actions not listed above | No separate entry | No | N/A | N/A | N/A | N/A | Local data deletable | Online transcript is already mapped as Other UGC; other activity remains local |
| Web browsing | No | No | N/A | N/A | N/A | N/A | N/A | No browser/WebView history |

## User-directed sharing exception

Text, completed images, PDF/DOCX exports, and the unencrypted backup ZIP can leave the device only after the user selects Share/Export and chooses an Android receiving app. Those transfers are not marked as developer sharing in this draft because they meet the expected user-initiated transfer pattern. The receiving provider governs its retained copy.

## VERIFY BEFORE PLAY SUBMISSION

1. Confirm Render and the configured OpenAI-compatible provider meet Google's service-provider definition and operate under appropriate contracts/instructions.
2. Confirm actual provider/model, retention/training settings, subprocessors, deployment region, access-log content, and deletion workflow.
3. Confirm the hosting/provider stack does not infer or retain approximate location from IP for a separate purpose.
4. Confirm the published privacy-policy URL serves the August 23, 2026 text.
5. Reassess immediately if `BIBLE_API_URL` or cloud audio transcription is enabled.
