# Google Play Data Safety Worksheet

Release audited: `1.0.0+1` (`org.thewordapp.mobile`)
Audit date: August 8, 2026

Use this as the working answer sheet for Play Console. Re-audit the final AAB and production server configuration before submission.

## Data collection and security

| Play Console question | Recommended answer | Basis |
| --- | --- | --- |
| Does the app collect or share required user data types? | **Yes** | Optional backend requests can transmit technical identifiers, feature interactions, and sermon transcript text. |
| Is all collected data encrypted in transit? | **Yes** | The production app is built with an HTTPS Render URL; upstream OpenAI-compatible and ElevenLabs requests use HTTPS. |
| Can users request deletion? | **Yes** | Local records can be deleted in the app or with app-data removal; server-related requests can be sent to `support.thewordapp@gmail.com`. |
| Does the app share user data? | **No** | Render and configured upstream processors act as service providers. OS sharing is a specific user-initiated action. Confirm contracts and production settings before submission. |

## Data types to declare

### Device or other IDs

- **Collected:** Yes
- **Shared:** No
- **Processed ephemerally:** No
- **Required or optional:** Optional
- **Purpose:** App functionality; fraud prevention, security, and compliance
- **Why:** Backend and hosting access logs may process an IP address and request metadata when an optional online feature is used.

### App activity - App interactions

- **Collected:** Yes
- **Shared:** No
- **Processed ephemerally:** No
- **Required or optional:** Optional
- **Purpose:** App functionality
- **Why:** Server logs may record the requested endpoint and, for remote Bible audio, the requested translation and Scripture reference.

### App activity - Other user-generated content

- **Collected:** Yes
- **Shared:** No
- **Processed ephemerally:** Yes
- **Required or optional:** Optional
- **Purpose:** App functionality
- **Why:** If transcript text is available and the user chooses summary or outline processing, the text is sent to the backend. Current server code processes it in memory and does not intentionally persist request bodies.

## Do not declare for release 1.0.0+1

These data types are accessed or stored only on-device, are public Scripture data, or are excluded user-directed transfers:

- **Voice or sound recordings:** local sermon recordings; cloud transcription is disabled by the app build flag and server configuration.
- **Photos:** Word Studio uses a user-selected image locally and does not upload it.
- **Files and documents:** exports remain local until the user deliberately invokes the system share sheet.
- **Religious beliefs:** reading activity, prayer reflections, journals, and memory reviews stay local.
- **In-app search history:** the release uses the bundled Bible repository; no `BIBLE_API_URL` is configured.
- **Crash logs or diagnostics:** no analytics or crash-reporting SDK is included.
- **Notification tokens:** notifications are local; Firebase Cloud Messaging is not included.
- **Name, email, user ID, phone number, contacts, location, financial data, health data:** not requested or collected by the app.

Public Bible references and verse text sent for commentary or narration are content data, not a user's private content. They are covered in the privacy policy because the request still creates technical and interaction metadata.

## Other App Content answers

| Declaration | Answer |
| --- | --- |
| Ads | No |
| App access | All functionality is available without login or special access |
| Accounts | No account creation |
| Account deletion | Not applicable |
| News or magazine app | No |
| Category | Books & Reference |
| Target audience | General audience; select only age groups the product is intentionally designed and marketed for |
| Sensitive permissions | Microphone is used only for user-initiated local sermon recording |

## Required release checks

- Confirm Render's access-log retention and deletion controls.
- Confirm Render, the configured LLM provider, and ElevenLabs are used as service providers under appropriate terms.
- Confirm `SERMON_TRANSCRIPTION_ENABLED=false` in both the Flutter build and Render environment.
- Confirm `BIBLE_API_URL` is absent unless remote Bible search/reading is intentionally disclosed.
- Inspect the final merged manifest and dependency graph after every SDK change.
- Update this worksheet before enabling FCM, analytics, crash reporting, accounts, cloud sync, or cloud transcription.

Official references: [Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469) and [Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311).
