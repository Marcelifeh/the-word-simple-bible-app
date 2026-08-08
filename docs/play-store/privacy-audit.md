# Release Privacy Audit

Release audited: `1.0.0+1`
Package: `org.thewordapp.mobile`
Audit date: August 8, 2026

## Executive finding

The release is local-first, but it should not be declared as collecting no data. Optional production-backend use can expose technical identifiers and feature interactions to access logs. Sermon transcript text can also be sent for summary or outline processing when the user explicitly invokes those features.

No account, advertising, analytics, crash-reporting, attribution, social-login, or Firebase messaging SDK is present.

## Release dependency audit

Relevant Flutter packages:

- `hive` and `hive_flutter`: local structured storage
- `sqlite3` and `sqlite3_flutter_libs`: local Bible search index
- `path_provider`: app-managed files
- `record`: local sermon recording
- `image_picker`: system photo selection for Word Studio
- `flutter_local_notifications`, `timezone`, and `flutter_timezone`: local reminders
- `http`: optional backend requests
- `just_audio` and `flutter_tts`: narration and playback
- `share_plus`, `screenshot`, and `pdf`: user-directed export and sharing

Not present: Firebase, FCM, Google Analytics, Crashlytics, Sentry, advertising, attribution, or social-login SDKs.

## Android release permissions

The merged release manifest contains:

- `INTERNET`: optional backend, commentary, and remote audio
- `RECORD_AUDIO`: user-initiated sermon recording
- `POST_NOTIFICATIONS`: user-enabled local reminders
- `RECEIVE_BOOT_COMPLETED`: restore local schedules after reboot
- `VIBRATE`, `WAKE_LOCK`, and `ACCESS_NETWORK_STATE`: notification and playback dependencies

The app does not request Android's broad photo/video-library permissions. `image_picker` provides a scoped file provider and the system photo picker backport.

## Storage and transmission map

| Feature/data | Stored locally | Leaves device in this release | Destination/condition |
| --- | --- | --- | --- |
| Bible reading and progress | Yes | No personal history | Public reference may be sent for optional commentary/audio |
| Notes, favorites, highlights | Yes | Only through user-directed sharing | Destination selected by user |
| Devotional and reading-plan history | Yes | No | None |
| Scripture Memory and review history | Yes | No | None |
| Prayer reflections | Yes | Only through user-directed sharing | Destination selected by user |
| Notification preferences/inbox | Yes | No | Local notification engine; no FCM token |
| Sermon notes/timestamps | Yes | Transcript text only on explicit summary/outline action | The Word App backend on Render |
| Sermon recordings | Yes | No | Cloud transcription disabled in app and server release configuration |
| Word Studio source images | Yes | No | Finished export leaves only when user shares it |
| Generated exports | Yes or temporary | Only through user-directed sharing | Destination selected by user |
| Network metadata | Server logs | Yes on optional online use | Render/server access logs |

## Backend and processors

- **Render:** hosts the first-party API and may process IP addresses, timestamps, endpoints, response statuses, and errors in operational logs.
- **OpenAI-compatible provider:** receives public Bible verse text and references only when missing commentary is generated. It does not receive local notes or reading history from this request.
- **ElevenLabs:** receives public Bible verse text for optional remote narration. Generated Bible audio may be cached server-side.
- **Sermon processing:** current summary and outline code is deterministic server code. Transcript request bodies are processed in memory and are not intentionally written to the database.
- **Cloud transcription:** disabled in `1.0.0+1`; the server route also returns unavailable. If enabled later, uploaded audio is written to a temporary file and deleted in a `finally` block.

## Code evidence

- Release flags and API URL handling: `lib/core/utils/env.dart`
- Optional commentary request: `lib/data/commentary/commentary_repository.dart`
- Optional remote Bible audio: `lib/data/audio/remote_audio_bible_service.dart`
- Sermon upload/summary/outline client: `lib/features/sermon_notes/services/sermon_ai_service.dart`
- Release transcription gate: `lib/features/sermon_notes/view/sermon_review_screen.dart`
- Local repositories and notification initialization: `lib/shared/state/app_state.dart`
- Temporary transcription deletion: `server/app/routes/sermon.py`
- Commentary provider: `server/app/llm.py`
- Remote narration provider: `server/app/audio.py`
- Production server flags: `render.yaml`
- Final Android permissions: `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`

## Submission blockers to resolve in Play Console

- Verify operational log retention in the active Render service.
- Confirm the legal/developer name entered in Play Console matches the identity represented by The Word App policy.
- Select the intended target age groups based on actual product marketing; do not infer a child-directed audience merely from religious content.
- Rebuild the AAB after the in-app policy and launcher-name update, then repeat the merged-manifest check.

This engineering audit supports the Play Console declaration; it is not a substitute for legal advice.
