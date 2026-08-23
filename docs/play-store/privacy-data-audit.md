# The Word App — Privacy & Google Play Data Safety Audit

Audit date: 2026-08-22
Audited package: `org.thewordapp.mobile`
Audited source version: `1.0.2+3`
Scope: Flutter Android production application, Android release merge outputs, current APK/AAB, bundled FastAPI backend, and repository documentation.

This is an engineering and Play Console evidence report, not legal advice. Google Play defines collection as transmission off the device, excludes solely on-device processing, and requires SDK behavior to be included. It also excludes some service-provider and expected user-initiated transfers from “sharing.” See the official [Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469) and [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311).

## Executive Summary

The app is predominantly offline and account-free. Notes, highlights, favorites, reading/devotional progress, Scripture Memory activity, sermon notes and recordings, notification state, user tracts, selected Word Studio photos, and settings are stored in app-private storage. There is no evidence in the production dependency tree of advertising, analytics, crash reporting, attribution, Firebase Cloud Messaging, authentication, billing, social, location, contacts, advertising-ID, or device-ID SDKs.

There is one confirmed release blocker: the current `1.0.2+3` APK and AAB package `http://localhost:8000`. On Android this points to the user's own device, not the Render service, and is cleartext HTTP. This was verified directly in each artifact's AOT `libapp.so` on 2026-08-22. The repository contains a safe release recipe using `https://the-word-app-api.onrender.com`, but `package.json` builds from a local `.env`, and the audited `.env` URL variables resolve to localhost. The current artifacts must not be uploaded.

The new portable backup feature exports the complete private Documents directory—including unencrypted Hive data, sermon recordings, and selected photos—to an unencrypted ZIP and presents the Android share sheet. The backup screen warns the user, but the in-app and hosted-policy source still describes release `1.0.0+1`, does not disclose portable backup/restore, and contains statements now contradicted by backup export. The restore validator checks files listed in its manifest but does not reject extra or duplicate archive entries and imposes no archive-size/entry-count limits.

Recommended Play Data Safety posture for a corrected HTTPS release is conservative: **Data collected: Yes** for optional App interactions (Scripture references used for missing commentary) and optional Other user-generated content (a restored/existing transcript can be submitted for summary/outline). **Data shared: No, VERIFY BEFORE SUBMISSION**, provided Render and any model provider are service providers acting on the developer's instructions and the live deployment does not add logging/analytics not represented here. Locally stored notes, photos, audio, files, progress, and preferences are not “collected” under Play's off-device definition.

Severity count: **1 Critical, 3 High, 5 Medium, 4 Low**. A release blocker exists.

## Production Data Flow Summary

| Flow | Data | Destination | Trigger | Required? | Persistence |
|---|---|---|---|---|---|
| Core Bible, devotionals, prayers, reading plans | Bundled Scripture/content | On-device only | Normal use | Core | Bundled assets; progress in Hive |
| Missing commentary | Translation, book ID, chapter, verse, style, language | First-party API; API may send public verse/reference to an OpenAI-compatible provider | Commentary requested and not bundled/cached | Optional | Generated commentary stored in backend DB and local `commentary` Hive box |
| Remote Bible API | Translation/chapter or user search query | Configured `BIBLE_API_URL` | Only when configured | Optional | Responses used in memory; search index is local |
| Sermon health check | No body; network metadata/IP necessarily reaches host | First-party `/health` | Opening Sermon Review | Optional screen | No app-side persistence |
| Sermon transcription | User-selected app recording | First-party `/sermon/transcribe` | User taps Transcribe and build flag is true | Optional; disabled in audited intended production config | Server temp file deleted in `finally`; transcript stored locally |
| Sermon summary/outline | Transcript and optional derived insight | First-party API | User taps Generate; a transcript must already exist | Optional | Response stored in `sermon_notes` |
| Remote verse audio | Scripture reference; server sends public verse text to ElevenLabs | First-party API then ElevenLabs | No production instantiation found | Unreachable/dead client path | Server caches MP3 if invoked |
| On-device TTS | Scripture/devotional text | Android TTS engine/system service | User starts narration | Optional | Provider behavior beyond the Android API is not verifiable from repository |
| Share/export | User-selected text, image, DOCX/PDF, or backup ZIP | User-chosen installed app/service | Explicit Share/Export action | Optional | Destination-controlled; temporary source files may remain in app cache |
| Notifications | Reminder content, schedule, local route payload | Android notification scheduler only | User enables reminders | Optional | Hive plus OS scheduler; no push token/server |

Evidence: `lib/core/utils/env.dart:4-45`; `lib/data/commentary/commentary_repository.dart:69-98,229-263`; `lib/data/bible/bible_api_repository.dart:15-85`; `lib/features/sermon_notes/services/sermon_ai_service.dart:57-165`; `lib/features/sermon_notes/view/sermon_review_screen.dart:55-91,129-185,637-646`; `server/app/main.py:422-515,518-561`; `server/app/routes/sermon.py:45-119,122-153`.

## Android Permissions

The current merged release manifest is `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`, version `1.0.2`/code `3`, min SDK 24 and target SDK 36 (`:3-9`).

| Permission in release | Source | Why/where used | Runtime request | Optional? | Play implication |
|---|---|---|---|---|---|
| `INTERNET` | Main manifest | Optional backend HTTP calls and media playback (`Env`, commentary/sermon services) | No runtime prompt | Network features optional | Disclose off-device flows; use HTTPS only |
| `RECORD_AUDIO` | Main manifest | User-initiated sermon recording (`SermonRecordingService.start`) | `record.hasPermission()` when Record is tapped | Yes | Microphone prominent disclosure/policy; Data Safety audio is No while local only |
| `POST_NOTIFICATIONS` | Main manifest | Local faith reminders | Requested from Notification Settings after user action | Yes | Notification declaration; no push data |
| `RECEIVE_BOOT_COMPLETED` | Main manifest | Reschedule local reminders after boot/update | No runtime prompt | Only useful when reminders enabled | Normal local-notification use |
| `VIBRATE` | Plugin merge | Notification alert behavior | No | Yes | No special Play declaration |
| `ACCESS_NETWORK_STATE` | Plugin merge | Media/network state support | No | Supporting | No sensitive-data permission |
| `WAKE_LOCK` | Plugin merge | Media/local-notification scheduling support | No | Supporting | No foreground-service/exact-alarm declaration |
| `org.thewordapp.mobile.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX merge | Signature-level protection for dynamic receivers | No | Internal | Not user data |

There is **no** release permission for camera, broad photos/media, legacy/external storage, location, contacts, phone state, Bluetooth, calendar, foreground service, exact alarms, advertising ID, or package enumeration. Image selection uses `ImageSource.gallery` and the Android system/backported photo picker without broad media permission. Notification scheduling explicitly uses `AndroidScheduleMode.inexactAllowWhileIdle`, so `SCHEDULE_EXACT_ALARM` is not required.

The debug/profile manifests add only `INTERNET`; it is already in main. The merged release adds file providers for image-picker/share-plus and a disabled Google Play services photo-picker module service, not a Google analytics service.

Evidence: `android/app/src/main/AndroidManifest.xml:1-49`; merged manifest `:11-43,85-182`; `lib/features/sermon_notes/services/sermon_recording_service.dart:15-35`; `lib/features/sermon_notes/view/sermon_editor_screen.dart:369-410`; `lib/features/notifications/services/app_notification_service.dart:132-149,225-244`; `lib/features/tracts/view/tract_image_designer_screen.dart:399-407`.

## Third-Party SDKs and Dependencies

Versions are resolved versions from `pubspec.lock`, not merely constraints.

| Package/version | Purpose and data behavior | Data Safety effect |
|---|---|---|
| `http 1.6.0` | Direct first-party HTTP requests | Yes when a user-data type is transmitted; see endpoint table |
| `hive 2.2.3`, `hive_flutter 1.1.0` | Unencrypted local key/value persistence | No collection while on-device |
| `sqlite3 2.9.4`, `sqlite3_flutter_libs 0.5.41` | Local FTS search database | No collection |
| `path_provider 2.1.5`, `path 1.9.1` | App-private Documents/Support/temp paths | No collection |
| `record 6.1.0` (`record_android 1.5.2`) | Microphone recording to local M4A | Audio remains local unless transcription or backup/share is explicitly used |
| `just_audio 0.10.5`, `audio_session 0.2.2` | Local/URL audio playback | No independent collection shown |
| `flutter_tts 4.2.5` | Android system TTS | OS/voice provider behavior not verifiable from repository |
| `video_player 2.11.1` | Media playback dependency | No production data flow found |
| `image_picker 1.2.3` | User-selects one gallery photo; app copies bytes | Photo local; backup/share is explicit |
| `file_picker 8.3.7` | User selects a backup ZIP for local restore | File local; no upload |
| `share_plus 10.1.4` | Android chooser for explicit shares/exports | User-initiated transfer; normally excluded from Play “sharing” per official exception |
| `screenshot 3.0.0` | Renders Word Studio image | On-device only |
| `pdf 3.8.4` | Local document export | On-device until explicit share/save |
| `archive 3.6.1`, `crypto 3.0.6` | ZIP and SHA-256 backup integrity | No encryption; no network |
| `flutter_local_notifications 22.1.0`, `timezone 0.11.1`, `flutter_timezone 5.1.0` | Local notification scheduling and device timezone | Local only; no FCM token |
| `uuid 4.5.3` | Random local record IDs | No device/install identifier and not transmitted as an account ID |
| `intl 0.20.2`, `scrollable_positioned_list 0.3.5`, `cupertino_icons 1.0.8`, `web 1.1.1` | UI/formatting/platform support | No independent data flow found |

The generated Android registrant contains audio session, file picker, local notifications, lifecycle, timezone, TTS, image picker, just_audio, path provider, recorder, share, SQLite, and video player only. The Gradle `releaseRuntimeClasspath` inspection succeeded and showed AndroidX/Media3/Gson/SQLite support libraries but no ads, analytics, Firebase, auth, billing, attribution, or tracking SDK.

Evidence: `pubspec.yaml:10-46`; `pubspec.lock`; `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java:17-83`; Gradle task `app:dependencies --configuration releaseRuntimeClasspath` on 2026-08-22.

## Network/API Endpoints

### Client endpoints

| Method/path | Source and trigger | Request data/headers | Identifiers/content | Storage |
|---|---|---|---|---|
| `GET {SERMON_API_URL}/health` | `BackendHealthService.check`; automatically warms when Sermon Review opens and before cloud action | No custom headers/body | Host receives normal network metadata/IP; no app ID/account ID | None in app |
| `POST /commentary/ensure` | Missing commentary requested | JSON: `translation`, `bookId`, `chapter`, `verse`, `style`, `language`; content-type only | Scripture reference; no notes, search history, device/account ID, or verse text from client | Response cached in `commentary` Hive; backend stores generated commentary |
| `GET {BIBLE_API_URL}/chapter` | Remote Bible repository only if `BIBLE_API_URL` configured | Query: translation, book ID, chapter | Scripture navigation/app interaction | Response not deliberately persisted by this class |
| `GET {BIBLE_API_URL}/search` | Remote Bible search only if configured | Query: translation, user's search string, limit | In-app search history | Response not deliberately persisted by this class |
| `POST /audio` | `RemoteAudioBibleService`, but no instantiation/reference found | JSON Scripture reference | App interaction only | Returns URL; server caches generated MP3 |
| `POST /sermon/transcribe` | Explicit user action and `SERMON_TRANSCRIPTION_ENABLED=true` | Multipart audio file; no auth header | Voice/sound recording and its spoken UGC | Server temp deleted; transcript stored locally |
| `POST /sermon/summary` | Explicit Generate Summary on existing transcript | JSON `transcript` | Other UGC, potentially religious/personal | Derived result stored in sermon note |
| `POST /sermon/outline` | Explicit Generate Outline on existing transcript | JSON `transcript`, optional derived `insight` | Other UGC, potentially religious/personal | Derived result stored locally |

No client request adds authorization, cookies, email, account ID, advertising ID, installation ID, or device ID. TLS depends entirely on the build-time URL.

### Production versus development

- `Env.sermonApiUrl` defaults to `http://localhost:8000`; commentary and audio fall back to it (`lib/core/utils/env.dart:4,11-26`).
- `tools/build_split_apk.ps1:1-30` defaults to the intended HTTPS Render URL, disables transcription, and does not configure remote Bible/search unless supplied.
- `package.json:6-10` builds release artifacts from `.env`. The audited ignored `.env` contains localhost URL configuration (values were inspected only in redacted/sanitized form; secrets were not reported).
- `docs/play-store/release-artifact.md:21-25,41-44` documents the older `1.0.0+1` HTTPS build, not the current `1.0.2+3` artifacts.
- Direct binary inspection of both current artifacts found `http://localhost:8000` and did not find the Render host. This is decisive artifact evidence.

### Backend onward transfers

- Missing commentary: the backend retrieves the public verse from Postgres, sends its reference/text to an OpenAI-compatible Chat Completions endpoint, and stores the result. Default endpoint/model are `https://api.openai.com/v1` and `gpt-4o-mini`, but actual deployed provider/model are **Not verifiable from repository** because live environment values are external (`server/app/llm.py:77-140`; `render.yaml:25-28`).
- Remote audio: if invoked, the backend sends public verse text to ElevenLabs over HTTPS and caches the MP3 (`server/app/audio.py:24-69`). No production client path instantiates this service.
- Sermon transcription uses server-side faster-whisper and a temporary file, deleted in `finally`; production Render config says disabled (`server/app/routes/sermon.py:15-17,45-119`; `render.yaml:17-24`).
- Summary and outline are deterministic server-side text processing in the current code, not an external LLM transfer (`server/app/routes/sermon.py:122-180,282-436`).

## AI/Cloud Processing

| Feature | Actual implementation | Sent data | Third party? | Consent/disclosure |
|---|---|---|---|---|
| Verse commentary/insight | Bundled/cache first; API only when missing | Scripture reference from client; public verse text from backend to model | First-party backend plus configured model service provider | Explain optional network generation and provider; App interactions, app functionality |
| Sermon transcription | faster-whisper on first-party backend | Entire recording | No onward provider shown; model download may use external host operationally | Disabled in audited intended release; if enabled, prominent pre-upload disclosure and Audio + UGC Data Safety entries are required |
| Sermon summary/outline | Backend heuristics despite `SermonAiService` name | Entire transcript and optional insight | No onward transfer shown | Optional user action; disclose first-party transcript processing |
| Prayer generation | Offline template provider | Nothing | No | No cloud disclosure needed |
| Devotionals | Bundled Dart/assets | Nothing | No | No cloud disclosure needed |
| Narration | Android system TTS | Text passed to OS TTS engine | Vendor behavior not verifiable | Describe as device/OS speech service; do not promise universally offline |
| Remote audio | Unused client class; backend ElevenLabs implementation exists | Public verse reference/text | ElevenLabs if reachable in a future build | Do not describe as active unless wired and tested; update Data Safety if behavior changes |

Generated commentary is retained locally; backend-generated commentary is retained in Postgres. Sermon results are retained in the local sermon note. No AI request contains account/device identifiers added by app code. Standard IP/network logs remain **Not verifiable from repository** beyond the existing policy statement that hosting logs may process them.

## Local Storage Inventory

No `HiveCipher`, Android Keystore encryption layer, or SQLCipher use was found. These stores rely on Android app sandbox/file-based encryption, not application-layer encryption. Unless otherwise noted, data remains until feature deletion, app-data clear, restore replacement, or uninstall. Android OS backup behavior is discussed separately.

| Data | Technology / exact name | Path category | Portable backup | Deletion/retention |
|---|---|---|---|---|
| Translation/theme/font/home size, last-read verse, reading/devotional/promise/faith activity | Hive `settings` | Application Documents via `Hive.initFlutter` | Yes | Mostly indefinite; no comprehensive in-app reset found |
| Favorites and favorite note | Hive `favorites` | Documents | Yes | Toggle/delete per item |
| Verse notes/highlights/prayers saved as notes | Typed Hive `notes` | Documents | Yes | Per-item delete |
| Sermon notes, transcript, insights, outline, audio paths | Hive `sermon_notes` | Documents | Yes | Per-note delete also deletes referenced recordings |
| Active sermon draft | Hive `sermon_note_drafts` | Documents | Yes | Cleared on save/discard; otherwise retained |
| Sermon recordings | `sermon_<id>_<time>.m4a` | Documents root | Yes | Deleted with note or explicit cleanup; otherwise retained |
| Scripture Memory verses/schedule | Hive `memory_verses` | Documents | Yes | Archive or permanent delete |
| Scripture Memory reviews | Hive `memory_review_history` | Documents | Yes | Deleted with corresponding verse |
| Memory daily goal / active session | Hive `memory_preferences`, `memory_session_draft` | Documents | Yes | Replaced/cleared by feature actions |
| User tracts | Typed Hive `user_tracts` | Documents | Yes | Per-item delete |
| Devotional journal/reflections/prayer | Typed Hive `devotional_journal` | Documents | Yes | Per-entry delete |
| Notification preferences/inbox/schedule | Hive `notification_preferences`, `notification_inbox`, `scheduled_notifications` | Documents | Yes | Inbox capped at 100; schedules replaced; preferences retained |
| Narration voice/speed/highlight preferences | Hive `narration_preferences` | Documents | Yes | Retained until change/uninstall |
| Custom-background metadata/privacy acknowledgment | Hive `word_studio_custom_backgrounds` | Documents | Yes | Per-background delete |
| Selected Word Studio image copies | `word_studio/backgrounds/bg_<id>.<ext>` | Documents | Yes | Per-background delete; original gallery file untouched |
| Commentary cache | Hive `commentary` | Documents | Yes | Indefinite cache; box can be rebuilt if corrupt |
| Legacy search indexes | Hive `search_index_<translation>_v<version>` | Documents | Yes at filesystem level, though not in flush allowlist | Derived/rebuildable |
| Current FTS search indexes | SQLite `search_fts_<translation>_v1.sqlite` | Application Support | **No** | Derived/rebuildable; app uninstall removes it |
| Generated share images/documents/backups | Files in app temporary/cache or Documents depending exporter | Temp/Documents | Backup ZIP source in temp is not recursively included; Documents exports are included | No systematic immediate cleanup verified |

Evidence: `lib/main.dart:11-20`; `lib/shared/state/app_state.dart:517-543,599-843`; repositories under `lib/data` and `lib/features`; `lib/data/search/smart_offline_search_repository_io.dart:257-272`; `lib/features/sermon_notes/services/sermon_recording_service.dart:17-35`; `lib/features/tracts/services/word_studio_background_storage_io.dart:12-59`.

## Backup & Restore

### What is exported

`AppBackupService` recursively includes every regular file in `getApplicationDocumentsDirectory`, excluding only `.lock` files. This includes all Android Hive boxes, sermon M4A files, Word Studio photos, and any other/future file placed in Documents—not just the named boxes. It excludes Application Support (the derived FTS SQLite database), cache, temp, APK assets, server code, `.env`, signing configuration, and keystores.

The manifest contains schema version, package name, UTC export time, and for each listed file its archive path, byte size, and SHA-256. The archive is created in app temp and handed to `Share.shareXFiles`, allowing Files, Drive, OneDrive, email, messaging, or any other compatible chooser target. The app does not automatically upload it. User choice determines the destination.

### Security and restore behavior

- **Encryption:** none. ZIP compression plus SHA-256 integrity is not encryption (`app_backup_service.dart:146-190`). The UI clearly warns that the ZIP can contain private notes, journals, recordings, and study data (`backup_restore_screen.dart:138-151,188-191`), but the privacy policy does not.
- **Path traversal:** direct traversal is blocked. Absolute paths, NUL, `.`, `..`, and empty path segments are rejected; extraction joins validated segments under Documents (`app_backup_service.dart:277-307,333-338`).
- **Integrity:** ZIP structure verification, manifest schema/package, listed-file size, and listed-file SHA-256 are checked (`:193-295`).
- **Gap:** extra files under `documents/` that are not in the manifest are not rejected and are still extracted. Duplicate entry names are not rejected. Therefore “integrity-checked ZIP” does not mean every extracted entry is authenticated (`:272-295` versus `:298-308`).
- **Resource exhaustion:** the whole ZIP and entries are read/decompressed in memory and there is no compressed/uncompressed size, entry-count, or per-file cap (`:193-199,232-237,289-307`). A malicious ZIP can crash or exhaust storage before/while validation.
- **Overwrite:** restore closes Hive, clears the entire Documents directory, then extracts (`:202-217`). The user gets a confirmation dialog.
- **Safety snapshot:** a pre-restore snapshot is written to temp. On failure the code attempts to clear Documents and restore it. If rollback itself fails, the catch suppresses that failure while the thrown message still says “was rolled back”; the temp snapshot remains for possible recovery (`:134-143,218-228`).
- **Cleanup:** successful portable and safety ZIPs are not explicitly deleted. Android may eventually purge temp, but retention timing is not guaranteed.
- **Tests:** existing tests cover round trip, nested audio, and corrupt ZIP (`test/features/settings/backup/app_backup_service_test.dart:26-68`). They do not cover traversal, extra/duplicate entries, checksum mismatch, zip bombs/limits, rollback failure, symlinks, or cleanup.

Privacy policy requirements: explicitly describe the unencrypted portable ZIP; categories included; user-directed third-party destination; no automatic upload; retention controlled by destination/user; restore replacement and safety snapshot; and advice to store the ZIP securely.

## User-Generated Content

| UGC | Local only by default | Can leave device | Export/share | Delete |
|---|---|---|---|---|
| Verse notes/highlights/favorite notes and saved prayers | Yes | No automatic transmission | Text share and portable backup | Per item |
| Devotional journal/reflections/prayer | Yes | No automatic transmission | Portable backup; devotional content may be explicitly shared | Per entry |
| Sermon title, preacher, notes, timestamps | Yes | Not sent by transcription; transcript only is sent for summary/outline | Text/DOCX/PDF share; portable backup | Per note |
| Sermon transcript/derived insight/outline | Yes after creation | Optional first-party summary/outline submission | Share/export/backup | With note |
| Sermon recording | Yes in audited intended release | Only if transcription is enabled and explicitly invoked; currently disabled | Portable backup; no direct recording share found | With note |
| User-authored Gospel tract | Yes | No automatic transmission | Explicit text/image share; portable backup | Per item |
| Custom photo/background | Yes | No upload by background feature | Finished design share and **portable backup of source copy** | Per background |
| Saved verses/reading plan/devotional/memory progress | Yes | No active sync | Portable backup | Some per-item controls; no global erase UI |

There is no public feed, social graph, chat, moderation system, or user-to-user hosting. Private local UGC does not make this an IARC “users share content with other users” product. Explicit Android shares are expected user actions.

## Audio/Microphone/Media

- Recording is user-initiated from the sermon editor. The `record` plugin requests microphone access at that moment and writes 96 kbps/44.1 kHz M4A to Documents (`sermon_recording_service.dart:15-35`; `sermon_editor_screen.dart:369-410`).
- App code does not record in background and declares no foreground service.
- Recordings are played locally using `just_audio`, included in portable backups, and deleted when the corresponding sermon note is deleted (`sermon_note_repository.dart:73-100`).
- Cloud transcription is build-flagged off in the documented production configuration and Render manifest. If turned on, the whole selected audio is uploaded to first party and temporarily stored; Audio and Other UGC must then be declared.
- TTS uses Android's speech engine. Whether a user-installed/default engine processes speech text online is **Not verifiable from repository**.
- Image picker uses only gallery/system picker. No camera request and no broad photo permission were found. Selected bytes are copied into private Documents and can be exported by backup.
- File picker is limited in UI to one `.zip` restore file. The app itself reads it locally.
- `video_player` is registered but no personal video capture/selection flow exists.

## Notifications

Notifications are local only. `flutter_local_notifications` schedules daily faith, habit, prayer, reading-plan, Scripture Memory, and app-update channels. Payloads contain a type, local route, date, and sometimes tab—not remote content or identifiers. Scheduling uses inexact alarms. Preferences, scheduled records, and the local inbox are Hive data; inbox is capped at 100. Device timezone is read to schedule local time.

There is no Firebase dependency, FCM service, push token, server registration, or server-delivered payload. `RECEIVE_BOOT_COMPLETED` exists only to restore schedules. Notification permission is requested from the settings workflow after the user enables reminders.

Evidence: `lib/features/notifications/services/app_notification_service.dart:31-149,225-359`; `notification_scheduler.dart:40-132,320-354`; notification repositories; merged manifest `:85-97`.

## Device/Identifier Data

| Data | Finding | Data Safety |
|---|---|---|
| Advertising ID | Not collected; no ads/attribution SDK or AD_ID permission | No |
| Android/device/install ID | No API or SDK use found | No |
| Account/user ID | No account system. UUIDs are random local content IDs | No |
| Email/name/phone/address | No collection UI or auth system | No |
| Locale | App has translation/language choices; no transmission found | Local only |
| Timezone | Read by `flutter_timezone` for local scheduling | Local only |
| Device model/OS version | No collection found | No |
| Crash logs/diagnostics/performance | No crash/analytics SDK and no custom uploader | No; backend access/error logs remain deployment-dependent |
| IP address | Necessarily visible to backend/host when HTTPS requests work | Repository does not show location inference or identifier/profile use. Live Render log retention/use is **Not verifiable from repository** |
| App interactions | Scripture references are sent for missing commentary in corrected production | Yes, optional, app functionality |
| In-app search history | Only sent if remote `BIBLE_API_URL` is configured | No for intended release tool; **VERIFY artifact** |

Google states that IP-derived location must be declared when location is inferred. The repository does not infer location. Do not mark approximate location solely because TCP exposes an IP unless the live host/provider uses it to infer location; verify Render settings/log processing before submission.

## Sign-In / App Access

No account creation, sign-in, Google sign-in, email/password, anonymous cloud identity, entitlement, role, or restricted content gate exists. All screens are usable without credentials.

Play Console App access answer: **Unrestricted / all functionality is available without special access.** Do not provide login credentials. Account creation supported: **No**. Account deletion requirement: **Not applicable**.

Evidence: dependency/search audit; `lib/features/legal/data/legal_documents.dart:14-16,78-82`.

## Ads / Monetization

No Google Mobile Ads/AdMob, banner, interstitial, rewarded ad, attribution, sponsorship, affiliate tracking, or ad identifier code/dependency was found. No store listing links or WebViews that serve ads were found.

Play Console Contains ads: **No**.

## Financial Features

No in-app purchase, subscription, donation, payment, wallet, money transfer, loan, banking, insurance, trading, crypto, rewards, crowdfunding, or financial-advice dependency or UI was found.

Play Console Financial features: **No — select “My app doesn't provide any financial features.”** Google requires even no-feature apps to complete this declaration; see [official guidance](https://support.google.com/googleplay/android-developer/answer/13849271).

## Health

No health data, fitness tracking, symptom/condition management, medical advice, Health Connect, Google Fit, clinical research, or medical-device feature was found. Religious encouragement and prayer are not implemented as health diagnosis/treatment.

Play Console Health apps declaration: **No — select “My app doesn't provide any health features.”** See [official guidance](https://support.google.com/googleplay/android-developer/answer/14738291).

## Government App Status

The app is a privately published Bible/reference app. It does not claim to represent a government, embassy, public agency, or official government service.

Play Console Government app: **No**.

## Target Audience Recommendation

Recommended based on repository evidence: **Ages 13–15, 16–17, and 18+**, if the developer genuinely intends and markets the product for teens and adults. The UI, sermon recording, long-form study, journaling, full unabridged Bible text, backup/export, and privacy copy are general/older-user features; there are no child-directed characters, games, early-learning design, parental controls, or child-specific marketing.

Do not select 5 and under, 6–8, or 9–12 merely because Scripture has educational value. Selecting child age groups invokes additional Families obligations. If the actual product/marketing intent is adults only, select only 18+ (or 16–17 and 18+) and align store copy; that reduces child-policy scope but unnecessarily limits teen discovery. Business/marketing intent is **Not verifiable from repository** and must be confirmed before submission. Google says age groups should only be selected when the app was designed and made appropriate for them; see [Target audience guidance](https://support.google.com/googleplay/android-developer/answer/9867159).

## Content Rating Recommendation

Recommended based on repository evidence; answer the exact IARC wording shown in the Console and let IARC calculate the regional rating.

| Topic | Recommended answer | Evidence/reasoning |
|---|---|---|
| Violence | Yes, non-graphic textual/historical/religious violence; disclose stronger passages if questionnaire distinguishes intensity | Full KJV includes killings, war, blood and death (for example `assets/data/bibles/kjv/1_chronicles/18.json:24`, `1_samuel/22.json:76`) |
| Blood/death | Yes, textual references | Full Bible plus commentary/devotionals |
| Sexual content/nudity | Yes, non-visual textual references to sexual conduct, prostitution, lust and nakedness | `assets/data/bibles/kjv/1_corinthians/6.json:64`; `1_samuel/20.json:124`; Song of Songs assets |
| Alcohol/drugs | Alcohol references: Yes. Illegal drugs/tobacco: No evidence | Wine/drunkenness in `1_peter/4.json:16`, `1_corinthians/11.json:88` |
| Fear/horror | Mild frightening/religious themes: Yes if asked (judgment, demons, death, danger); no horror imagery | Full Scripture/commentary |
| Profanity/crude humor | No evidence of designed profanity or crude humor; review archaic translation language against exact wording | Bundled KJV is unabridged |
| Gambling | No | No feature/content mechanic found |
| Purchases | No | No billing/commerce |
| User-generated content shared publicly | No | UGC is private/local; explicit external share only |
| User-to-user communication/online interaction | No | No accounts, chat, feed, or multiplayer/community |
| Location sharing | No | No location permission/API |
| Unrestricted web access | No | No browser/WebView feature; API calls are fixed/configured endpoints |
| Ads | No | No ad SDK/content |

The likely rating is not safely predictable from repository alone because regional authorities score the questionnaire. Content rating must be regenerated whenever content/features change. See [Google/IARC content rating requirements](https://support.google.com/googleplay/android-developer/answer/9859655).

## Google Play Data Safety Draft

### Proposed applicable entries for a corrected HTTPS release

| Data type | Collected | Shared | Required/optional | Purpose | Ephemeral | Encrypted in transit | Deletion/control | Evidence/qualification |
|---|---|---|---|---|---|---|---|---|
| App activity — App interactions | Yes | No, **VERIFY service-provider status** | Optional | App functionality | No for missing commentary because result/reference-associated commentary is stored; health check alone has no user payload | Yes only after corrected HTTPS build | User can avoid online commentary; server-log deletion process not verifiable | Scripture reference sent by `commentary_repository.dart:229-247`; no analytics |
| App activity — In-app search history | No for intended build | No | N/A | N/A | N/A | N/A | Local search index is rebuildable | Becomes Yes/optional/app functionality if `BIBLE_API_URL` is configured (`bible_api_repository.dart:50-68`) |
| App activity — Other user-generated content | Yes, conservative | No, **VERIFY** | Optional | App functionality | Server summary/outline request body is processed in memory by code, but host logs are not verifiable | Yes only after corrected HTTPS build | Transcript/note deletable locally; no verified server deletion workflow | Existing/restored transcript can be submitted to `/sermon/summary` or `/outline`; UI is not gated by transcription flag (`sermon_review_screen.dart:129-185`) |

Why “Shared: No” is conditional: Render and an OpenAI-compatible processor can qualify as service providers rather than third parties under Play's sharing definition if they act on the developer's instructions. Contracts, live environment, provider retention/training settings, and host logging are not in the repository. Verify those facts. User-initiated Android sharing/export is an official sharing exception when the user reasonably expects the transfer.

### All remaining Google data types

These are **No** for collection/sharing in the audited intended release because they are absent or remain solely on-device. A local data type can still require privacy-policy disclosure even though it is outside Play Data Safety collection.

| Category/data type | Collected? | Notes |
|---|---|---|
| Personal info — Name | No | “Preacher” may contain a name but is local sermon UGC; only transcript, not title/preacher field, is posted |
| Personal info — Email address | No | No account/contact form |
| Personal info — User IDs | No | Local UUIDs are not account/install IDs |
| Personal info — Address | No | No field/API |
| Personal info — Phone number | No | No field/API |
| Personal info — Race/ethnicity | No | No field/API |
| Personal info — Political or religious beliefs | No as a separate type | Bible use/reference is classified as app interaction, not an explicit user belief declaration. If personal prayer/journal/sermon UGC is uploaded in a future build, reassess this category |
| Personal info — Sexual orientation | No | No field/API |
| Personal info — Other personal info | No | No account/profile |
| Financial info — Payment/purchase/credit/other | No | No commerce |
| Health and fitness — Health info | No | No health feature |
| Health and fitness — Fitness info | No | No fitness feature |
| Messages — Emails | No | No email access |
| Messages — SMS/MMS | No | No SMS permission/API |
| Messages — Other in-app messages | No | No chat/messaging |
| Photos and videos — Photos | No | User-selected background remains local; explicit share/backup is user initiated |
| Photos and videos — Videos | No | No capture/import flow |
| Audio — Voice or sound recordings | No for audited flag-off release | Local sermon audio; becomes Yes if cloud transcription is enabled |
| Audio — Music/other audio | No | No user music collection |
| Files and docs | No | Backup import/export and DOCX/PDF share are local/user-initiated |
| Calendar | No | No permission/API |
| Contacts | No | No permission/API |
| App activity — Installed apps | No | Share chooser query is an Android system action; no inventory collection |
| App activity — Other actions | No separate entry | Reading/progress actions remain local; submitted Scripture reference is covered as App interactions |
| Web browsing | No | No browsing feature/history |
| App info/performance — Crash logs | No | No crash SDK/uploader |
| App info/performance — Diagnostics | No | No client diagnostics uploader; first-party HTTP response/error logs must be verified operationally |
| Device or other identifiers | No | No advertising/device/install ID API; IP handling does not automatically map here without identifier use |
| Approximate location | No, **VERIFY live provider** | No location permission or location inference in code; mark Yes only if host/provider uses IP to infer location |
| Precise location | No | No permission/API |

Security-practice answers:

- Encryption in transit: **Yes only for a rebuilt artifact whose every collected flow is HTTPS. Current artifact: No/not acceptable.**
- Users can request data deletion: local content can be deleted feature-by-feature or by clearing/uninstalling the app. There is no comprehensive in-app erase and no repository-verifiable server-log deletion workflow. Existing policy gives an email contact. Answer the Console's deletion question conservatively and **VERIFY BEFORE SUBMISSION** against the exact form wording and operational process.
- Data is not sold or used for ads/analytics based on repository evidence.

## Privacy Policy Requirements

The policy should contain these exact factual sections/statements after the blockers are fixed:

1. **Identity and contact:** The Word App, package `org.thewordapp.mobile`, publisher entity exactly matching the Play listing, privacy contact placeholder, effective-date placeholder, and public policy URL.
2. **No account/ads/analytics:** No account is required; no advertising, analytics, crash-reporting, attribution, or FCM SDK is included in this release.
3. **Local data:** Enumerate notes/highlights/favorites, saved prayers, devotional journal, reading/devotional/faith history, Scripture Memory progress, sermon notes/transcripts/recordings, user tracts, notification state, selected backgrounds, narration/settings, and local caches. State they are app-private and not application-layer encrypted.
4. **Optional first-party network:** State the production backend domain; HTTPS requirement; missing-commentary Scripture fields; optional remote Bible chapter/search fields only if enabled; sermon transcript processing; and ordinary IP/request metadata visible to hosting.
5. **AI/providers:** State that missing commentary may send public verse text/reference from the backend to the actually configured OpenAI-compatible provider. Name the actual provider/model policy only after live configuration is verified. Explain current summary/outline are first-party processing. Do not call remote audio active unless wired/tested.
6. **Audio/microphone:** Recording is user-initiated, stored locally, included in portable backup, and deleted with its note. Cloud transcription is disabled for this release. State what changes if enabled.
7. **Photos/files:** Selected Word Studio photo is copied into private storage, not automatically uploaded, can be included in portable backup, and can be shared in a finished design. Restore ZIP selection is local.
8. **Notifications:** Local scheduling only; timezone used on-device; no push token/server transmission.
9. **Backup/restore:** Full Documents snapshot; categories included; ZIP is integrity-checked but **not encrypted**; created locally; no automatic upload; Android chooser destinations; destination retention/privacy; restore replaces current data after a temp safety snapshot; keep backups private.
10. **Sharing/export:** Explicit user action, receiving app/service controls its copy, exported files persist until user/destination deletes them.
11. **Third parties:** Render, actual model provider, Android/Google system photo picker, Android TTS engine, and user-selected share/storage provider. ElevenLabs only if active.
12. **Purposes:** App functionality only; no advertising/marketing/analytics/personalization profiles.
13. **Security:** HTTPS for production, Android sandbox, unencrypted portable backup limitation, no absolute guarantee.
14. **Retention/deletion:** Feature-specific deletion, uninstall/clear-app-data, temp/export caveats, backend commentary/log retention, provider retention, and a verifiable deletion-request channel. Do not claim an operational log retention duration without evidence.
15. **Android backup:** Explain OS-managed backup may occur unless disabled/excluded, after the manifest decision is made.
16. **Children:** General audience/not specifically child-directed; no child account collection. Align with selected age groups.
17. **International processing:** Only claim locations after Render/model/provider deployment regions are verified; otherwise say processing may occur where service providers operate.
18. **Changes:** Effective date and policy update mechanism.

The existing policy already covers many older flows but must not be submitted unchanged. Google requires privacy text/links both in app and Play Console, a public non-PDF URL, security and retention/deletion practices, and consistency with Data Safety. The repository contains in-app privacy text (`settings_screen.dart:243-252`) and hosted HTML source, but public URL availability was **Not verifiable from repository** and the URL could not be independently confirmed during this audit.

## Release-Blocking Risks

### CRITICAL

1. **Current APK and AAB contain `http://localhost:8000`.** Online functions target the user's device and cleartext; policy claim “Production API connections use HTTPS” is false for the artifacts. Root cause is conflicting build paths: safe `build_split_apk.ps1` versus `.env`-driven `package.json`. Rebuild with explicit HTTPS defines, then inspect the final AAB binary and test on a physical release install. Evidence: `env.dart:4-26`; `package.json:8-10`; artifact inspection; policy `legal_documents.dart:74-76`.

### HIGH

1. **Privacy disclosures are stale/inaccurate for `1.0.2+3`.** Both in-app and hosted sources cite `1.0.0+1` and omit portable backup. The custom-photo prompt says the source photo stays on device unless the finished design is shared, but backup exports the source copy. Evidence: `legal_documents.dart:28-38`; `docs/privacy/index.html:75`; `tract_image_designer_screen.dart:374-381`; backup service `:153-168`.
2. **Portable backups contain highly personal spiritual content and audio/photos in an unencrypted ZIP.** This is user-directed and warned in UI, but creates material confidentiality risk and needs policy disclosure. Evidence: `app_backup_service.dart:146-190`; `backup_restore_screen.dart:138-151,188-191`.
3. **Restore integrity is incomplete and lacks resource limits.** Manifest-unlisted/duplicate entries can be extracted; oversized/zip-bomb inputs can exhaust memory/storage before safe restore. This undermines the “integrity-checked” UI claim. Evidence: `app_backup_service.dart:193-199,272-308`; `backup_restore_screen.dart:149-151`.

### MEDIUM

1. **Android OS backup scope is uncontrolled.** The application declares neither `android:allowBackup` nor `dataExtractionRules/fullBackupContent`, so platform defaults apply to private spiritual data. Decide whether to disable cloud/device transfer or define exclusions, test it, and disclose the result. Evidence: `AndroidManifest.xml:6-9` (absence); policy `legal_documents.dart:80` only says “subject to operating-system backups.”
2. **Live provider/log retention and service-provider status are not verifiable.** Render secrets/config, LLM retention/training settings, host access logs, regions, DPA, and deletion workflow are external. They directly affect sharing, location/IP, retention, and international-processing answers. Evidence: `render.yaml:25-28`; `server/app/llm.py:105-140`.
3. **Transcript submission remains reachable for an existing/restored transcript even when transcription is disabled.** Summary/outline are not gated by `SERMON_TRANSCRIPTION_ENABLED`; Data Safety/policy must cover optional transcript collection or the UI must be gated. Evidence: `sermon_review_screen.dart:129-185,389-400,522-559`.
4. **Backend exposes unauthenticated `/debug/info`.** It redacts password text but reveals database URL topology, counts, styles, translations, and sample IDs. Remove/disable it in production or protect it. Evidence: `server/app/main.py:189-249`.
5. **Sensitive temp ZIPs are not explicitly cleaned and no global erase control exists.** Portable/safety backups remain until OS temp cleanup; local categories have uneven deletion controls. Add cleanup after sharing/restore lifecycle and consider “Delete all local data.” Evidence: `app_backup_service.dart:125-143,205-229`; `backup_restore_screen.dart:22-43`.

### LOW

1. **Optional microphone permission is declared for every install.** It is justified and requested contextually, but feature modularization/removal should be considered if recording is not part of release scope. Evidence: manifest `:3`; editor `:369-410`.
2. **Unused/dead network/media paths increase audit surface.** `RemoteAudioBibleService` has no instantiation, while policy describes remote audio; `video_player` is registered without a personal-video flow. Remove unused code/dependencies or clearly mark future features. Evidence: search references; `remote_audio_bible_service.dart:10-42`.
3. **Release documentation is stale.** `release-artifact.md` records `1.0.0+1` while current source/merge is `1.0.2+3`; update hashes, commands, flags, and artifact evidence for every submission.
4. **Backup test coverage is not adversarial.** Only three basic tests exist. Add extra/duplicate/traversal/limit/checksum/rollback/cleanup cases. Evidence: `app_backup_service_test.dart:26-68`.

## Recommended Fixes Before Closed Testing

1. Replace the default `SERMON_API_URL` with no endpoint or a production HTTPS endpoint; make release build fail if URL is empty, localhost, loopback, or non-HTTPS. Remove/replace `.env`-driven release scripts.
2. Rebuild AAB with explicit production defines and `SERMON_TRANSCRIPTION_ENABLED=false`; leave `BIBLE_API_URL` absent unless remote search is intentionally disclosed. Inspect packaged `libapp.so`, verify manifest/version/signature, and run physical-device network tests.
3. Update both `LegalDocuments.privacyPolicy` and `docs/privacy/index.html` for version-neutral wording and backup/restore. Correct the Word Studio photo disclosure. Publish and verify the live non-PDF URL before Console submission.
4. For backup restore, reject any non-manifest file, duplicate name/path, directory/symlink entry, and manifest/archive mismatch; enforce compressed/uncompressed total, entry-count, per-entry, and manifest-size limits before clearing Documents. Make rollback result truthful.
5. Consider password-based authenticated encryption for portable backup. At minimum, preserve the explicit warning and require confirmation before sharing an unencrypted archive.
6. Delete temporary portable/safety snapshots when they are no longer needed, with a documented recovery window if intentionally retained.
7. Decide Android Auto Backup policy and implement `dataExtractionRules`/`fullBackupContent` or `allowBackup=false`; include sensitive file exclusions if enabled.
8. Remove or protect `/debug/info` in production. Verify Render access-log retention, region, subprocessors/DPA, deletion handling, and LLM provider settings.
9. Either gate summary/outline with the release cloud-processing flag or declare optional Other UGC collection. Add a pre-submit transcript disclosure if enabled.
10. Add a local “Delete all app data” flow if desired; ensure it handles Hive, recordings, selected images, FTS, notification schedules/inbox, and temp exports.
11. Run the adversarial backup tests and the full Flutter suite outside the current slow/blocked test environment.
12. Complete Play Console using the corrected final artifact, not source intent, and save screenshots/CSV of the submitted answers alongside the release record.

## Evidence Appendix

### Principal source evidence

- Identity/version/build: `pubspec.yaml:1-8`; `android/app/build.gradle.kts:31-74`; merged release manifest `:3-14`.
- Release URLs/build commands: `lib/core/utils/env.dart:1-45`; `package.json:6-10`; `tools/build_split_apk.ps1:1-47`; `docs/play-store/release-artifact.md:21-25,41-44`.
- Permissions/providers: `android/app/src/main/AndroidManifest.xml:1-61`; merged release manifest `:11-43,85-182`.
- Network: `lib/core/network/backend_health_service.dart:22-37`; Bible/commentary/audio repositories; `sermon_ai_service.dart:57-165`.
- Backend/third parties: `server/app/main.py:179-186,292-376,422-561`; `server/app/llm.py:77-140`; `server/app/audio.py:24-69`; `server/app/routes/sermon.py:45-153`; `render.yaml:1-28`.
- Storage: `lib/main.dart:11-20`; `app_state.dart:517-843`; feature repositories; search repository `:257-272`.
- Backup: `lib/features/settings/backup/app_backup_service.dart:87-349`; `backup_restore_screen.dart:22-196`; tests `:26-68`.
- Media: sermon recording/editor/repository; Word Studio picker/storage.
- Notifications: app notification service/scheduler/repositories.
- Privacy UI/policy: `lib/features/settings/view/settings_screen.dart:243-252`; `lib/features/legal/data/legal_documents.dart:3-94`; `docs/privacy/index.html:49-149`.
- Content: `assets/data/bibles/kjv/**`; `pubspec.yaml:54-660`.

### Validation performed

- `flutter analyze`: **passed, no issues** (145.1 seconds).
- Targeted backup test and full `flutter test --reporter expanded`: **inconclusive**. Each remained in silent active compilation for several minutes and was terminated; no assertion failure was emitted. This is not recorded as a test pass or product failure.
- `gradlew app:dependencies --configuration releaseRuntimeClasspath`: **passed** after the declared Gradle wrapper was downloaded; no ad/analytics/auth/billing/tracking SDK found.
- Merged release manifest inspection: **passed**; permissions enumerated above.
- Current APK/AAB AOT string inspection: **failed release criterion**; both contain `http://localhost:8000`.
- `flutter pub get`: not run because dependencies were already resolved and `pubspec.yaml`/`pubspec.lock` contain user changes; avoiding an audit-induced dependency rewrite.
- Public GitHub Pages policy availability and Play Console's current saved declarations: **Not verifiable from repository**.
- Live Render environment variables, logs, contracts, regions, provider retention, and actual model provider: **Not verifiable from repository**.

### Repository state caution

The audit began with pre-existing user changes in `pubspec.yaml`, `pubspec.lock`, `lib/features/settings/view/settings_screen.dart`, generated macOS registration, the new backup feature/tests, and ZIP archives. These were not modified. Only this report was added.

## EXACT PLAY CONSOLE ANSWERS

Use these for the corrected, re-verified HTTPS release. Items marked **VERIFY BEFORE SUBMISSION** depend on the final artifact or external operations.

| Console item | Best-evidence answer |
|---|---|
| Privacy policy required | **Yes** |
| App access/sign-in | **Unrestricted** — no login or restricted access |
| Contains ads | **No** |
| Government app | **No** |
| Financial features | **No** — select “My app doesn't provide any financial features”; no subcategories |
| Health features | **No** — select “My app doesn't provide any health features” |
| Target audience | **13–15, 16–17, 18+ recommended; VERIFY BEFORE SUBMISSION against actual marketing intent** |
| Data collected | **Yes** — optional App interactions; conservatively optional Other UGC for transcript summary/outline |
| Data shared | **No — VERIFY BEFORE SUBMISSION** that Render/model providers qualify as service providers and no live SDK/log onward sharing exists |
| Encryption in transit | **Yes for corrected HTTPS artifact; current artifact is unacceptable/Conditional** |
| Account creation supported | **No** |
| Account deletion requirement likely applicable | **No** — no account system |
| Primary app category | **Books & Reference** |

Additional direct answers:

- Ads SDK certification: not applicable.
- News app: No.
- COVID/contact tracing/status app: No.
- Teacher Approved/Families: do not opt in unless child age groups are intentionally selected and all Families requirements are completed.
- Content rating: answer Yes for textual violence/death, sexual/nudity references, alcohol references, and mild frightening themes; No for gambling, purchases, location sharing, public UGC, user-to-user communication, and unrestricted web access. These are **recommended based on repository evidence**.
- Current `1.0.2+3` AAB: **DO NOT SUBMIT**. Rebuild and verify first.
