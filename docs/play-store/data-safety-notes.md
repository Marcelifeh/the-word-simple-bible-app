# Data Safety Working Notes

Use these notes to complete Play Console. Re-audit before every release.

## Current release profile

- Package: `org.thewordapp.mobile`
- Accounts: none
- Ads: none
- Third-party analytics/crash SDK: none detected
- Cloud transcription build flag: disabled
- Primary storage: local Hive boxes, app documents, and app support directories

## Permissions and access

- `RECORD_AUDIO`: user-initiated sermon recording
- `POST_NOTIFICATIONS`: user-initiated local reminder permission
- System photo picker: user-selected Word Studio background; no broad media permission
- `INTERNET`: optional Render API, remote audio, and configured online content

## Data that can leave the device

- Scripture translation/reference for optional commentary or remote audio requests
- Sermon transcript text when the user requests summary or outline processing
- Sermon audio only when the user explicitly requests transcription and the build enables it; disabled for `1.0.0+1`
- User-selected exports when the user invokes Android sharing
- Standard network metadata processed by hosting/network providers

## Local-only data by default

- Favorites, bookmarks, highlights, notes, and journal entries
- Reading-plan and devotional progress
- Scripture Memory verses, reviews, and session drafts
- Notification preferences, schedules, and inbox items
- Sermon recordings and notes unless an optional cloud action is invoked
- Word Studio custom-image copies and metadata

## Play Console answers to verify

- App access: all functionality is available without login
- Ads: no
- News app: no
- Account deletion: not applicable while the app has no accounts
- Target audience: general audience; do not select child-directed groups unless product strategy changes
- Data encrypted in transit: yes for the production HTTPS API configuration
- User deletion: local records can be removed in feature screens, by clearing app data, or by uninstalling

## Release gate

Re-check dependencies, Android permissions, backend logging/retention, API flags, and every network request before submitting the final Data safety form.
