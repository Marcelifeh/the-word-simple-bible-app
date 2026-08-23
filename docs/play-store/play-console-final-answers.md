# The Word App — Play Console Final Answers

Applies to package `org.thewordapp.mobile`, release candidate `1.0.3+4`.

| Play Console declaration | Proposed answer |
|---|---|
| Privacy policy | **Yes** — use `https://marcelifeh.github.io/the-word-simple-bible-app/privacy/`; verify the published page matches repository text |
| App access / sign-in | **Unrestricted** — no credentials or special access |
| Contains ads | **No** |
| Government app | **No** |
| Financial features | **No — My app doesn't provide any financial features** |
| Health features | **No — My app doesn't provide any health features** |
| Account creation | **No** |
| Account deletion requirement | **No / not applicable**, because no account exists |
| Primary category | **Books & Reference** |
| Target audience | **13–15, 16–17, 18+ — VERIFY WITH PRODUCT/MARKETING INTENT** |
| Data collected | **Yes** — optional App interactions and optional Other user-generated content |
| Data shared | **No — VERIFY BEFORE SUBMISSION** for service-provider contracts and live behavior |
| Encryption in transit | **Yes** for all active collected flows in the inspected production artifact |

## Data Safety selections

- Select **App activity > App interactions**: collected, optional, app functionality, not ephemeral, encrypted in transit.
- Select **Other user-generated content**: collected, optional, app functionality, encrypted in transit. Treat ephemerality conservatively until live infrastructure logging is verified.
- Do not select In-app search history: the release has no `BIBLE_API_URL`.
- Do not select Audio: cloud audio transcription is disabled; recordings remain local except user-directed backup.
- Do not select Photos or Files/docs: those remain local except user-directed share/export.
- Do not select Device identifiers, Location, or Diagnostics based on repository behavior; complete the provider checks in `data-safety-final.md` first.

## Content rating recommendations

Answer the exact IARC questions shown; do not try to select a rating directly.

- Textual violence, blood, and death: **Yes**, where asked.
- Textual sexual or nudity references: **Yes**, where applicable to unabridged Scripture.
- Alcohol references: **Yes**.
- Mild frightening or religious themes: **Yes**, where asked.
- Gambling: **No**.
- Purchases: **No**.
- Public user-generated content: **No**.
- User-to-user communication: **No**.
- Location sharing: **No**.
- Unrestricted web access: **No**.
- Ads: **No**.

## Other declarations

- News app: **No**.
- Ads SDK certification: **Not applicable**.
- Teacher Approved / Families: do not opt in unless younger child groups are intentionally selected and all Families requirements are met.
- Microphone permission: explain user-initiated local sermon recording.
- Notification permission: explain local reminders; there is no remote push.

## VERIFY BEFORE SUBMISSION

1. Target-audience selection against actual store listing and marketing intent.
2. Published privacy-policy availability and text.
3. Render/model-provider service-provider status, contracts, logs, retention, deletion, location inference, and international regions.
4. Exact Console deletion-question wording against the operational privacy-contact process.
