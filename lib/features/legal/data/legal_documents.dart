import '../models/legal_document.dart';

class LegalDocuments {
  static const privacyPolicy = LegalDocument(
    title: 'Privacy Policy',
    content: '''
Effective Date: August 23, 2026
Last Updated: August 23, 2026

The Word App (package org.thewordapp.mobile) is published by The Word App. This policy describes the corrected production release and its optional online services.

Public policy: https://marcelifeh.github.io/the-word-simple-bible-app/privacy/

1. Privacy at a Glance

No account is required. This release contains no advertising, analytics, attribution, crash-reporting, authentication, or Firebase Cloud Messaging SDK. We do not sell data or use it for advertising, behavioral marketing, or analytics profiling.

2. Information Stored Locally

The app may store notes, highlights, favorites, saved prayers, devotional journals and reflections, reading and devotional progress, Scripture Memory progress, sermon notes, transcripts and recordings, user-created tracts, selected Word Studio backgrounds, notification settings and inbox items, narration and other settings, and a commentary cache. This data is stored in Android app-private storage. It is not encrypted by a separate application-layer encryption system and relies on normal Android sandbox and device protections. No security method is absolute.

3. Optional Commentary Processing

When requested commentary is not bundled or cached, the app may send Scripture reference fields—such as translation, book, chapter, verse, style, and language—to the first-party HTTPS backend at https://the-word-app-api.onrender.com. The backend may send the public Scripture text and reference to its configured OpenAI-compatible model service provider to generate the requested insight. The app does not add an account ID, advertising ID, or device identifier to this request. Provider configuration, operational logs, and retention are governed by the applicable operational settings and provider terms.

4. Sermon Transcript Processing and Microphone

Recording is started only when you choose it and grant microphone permission. Recordings are stored locally and may be included in a portable backup. Cloud audio transcription is disabled in this production release, so sermon recordings are not uploaded for transcription.

If an existing transcript is available, you may explicitly request a summary or outline. Immediately before submission, the app explains that the transcript text will be sent over HTTPS to The Word App backend; nothing is sent if you cancel. Summary and outline processing is optional. The current server processes the request to return the result and does not intentionally store the transcript body in its application database.

5. Photos and Word Studio

A Word Studio image you select through the Android photo picker is copied into app-private storage. It is not uploaded automatically. The source copy may be included in a user-created portable backup, and a completed design may leave the device when you explicitly share it. Removing a custom background deletes the app-managed copy, not the original gallery item.

6. Notifications and Narration

Notifications are scheduled locally using the device timezone. The app has no FCM token or remote push system. Android notification and text-to-speech engines may process notification or narration requests under the operating-system or selected engine's terms.

7. Backup & Restore

Backup creates a local, integrity-checked snapshot of supported app Documents data. It may include highly personal spiritual notes, journals, audio recordings, selected photos and images, Scripture study data, settings, and caches. The ZIP is NOT encrypted; anyone with the file may be able to read it. The app does not upload the ZIP automatically. The Android share/save chooser lets you select a destination, and that receiving provider controls its copy, privacy, and retention. Store backups securely.

Restore validates the archive, manifest paths, sizes, SHA-256 checksums, and safety limits before replacing current local Documents data. A temporary safety snapshot is created for rollback. It is deleted after confirmed success; if automatic rollback fails, it is preserved temporarily for recovery. Android automatic cloud and device-transfer backup is disabled because this explicit user-controlled backup is available.

8. Sharing and Exporting

Sharing or export occurs only after your action. The receiving application or service governs its copy, which may remain until you or that provider deletes it. Temporary app-created share files are periodically cleaned, but a destination copy is outside the app's control.

9. Services and Providers

The optional first-party backend is hosted on Render. Missing commentary may use the backend's configured OpenAI-compatible model provider. Android supplies the photo picker, notification facilities, and text-to-speech engine. You select any share or storage provider used for exports or backups. Remote ElevenLabs audio is not an active production client feature in this release.

10. Network and Technical Data

HTTPS is required for active production endpoints. Render and ordinary hosting infrastructure necessarily receive network information such as IP address, request time, endpoint, response status, and errors when an online feature is used. Production application logs are designed not to print transcript bodies, notes, prayers, audio contents, or API secrets. We do not use this information for advertising or behavioral profiles.

11. Permissions

The app may request microphone permission for user-initiated sermon recording and notification permission after you enable reminders. It uses the Android photo picker for a selected image and network access for optional commentary, transcript-text processing, and backend availability checks.

12. Purposes and Data Safety

Information is processed to provide app functionality, maintain reliability and security, and complete actions you request. Locally-only data is not transmitted merely because it exists on the device. User-directed sharing destinations receive data only as part of the sharing action you initiate.

13. Retention and Deletion

Local content remains until you delete it using available feature controls, clear Android app data, or uninstall the app. Clearing app data or uninstalling removes app-private local data. Exported files and backups may remain wherever you saved or shared them. Generated commentary, provider processing, server security logs, and related deletion options depend on operational and provider policies; no fixed retention duration is promised here. Contact us about server-held information that can reasonably be identified.

14. International Processing

Optional online processing may occur where Render and the configured service providers operate. Their deployment locations and terms may change; contact us for current operational details.

15. Children's Privacy

The Word App is a general teen and adult Bible-study and reference product and is not specifically designed for young children. It has no child account system and no account-based collection.

16. Changes

We may update this policy when features, providers, or legal requirements change. The effective and last-updated dates identify the current version, which remains available in the app and at the public policy URL.

17. Contact

For privacy questions, requests, or deletion inquiries:
support.thewordapp@gmail.com
''',
  );

  static const terms = LegalDocument(
    title: 'Terms & Conditions',
    content: '''
Last Updated: August 2026

By using The Word App, you agree to the following terms:

1. Purpose of the App

The Word App exists to help users engage with Scripture, devotionals, prayer tools, sermon notes, and Gospel resources.

2. Spiritual Content

Content provided within the app:
• Does not replace pastoral guidance
• Should be studied prayerfully
• May include AI-assisted explanations

Users are encouraged to compare all teachings with Scripture.

3. User-Generated Content

Users may create:
• Notes
• Sermon journals
• Tracts
• Reflections

You are responsible for the content you create and share.

4. Prohibited Usage

Users must not:
• Post hateful or abusive content
• Use the platform unlawfully
• Misrepresent Scripture maliciously
• Share harmful material

5. Intellectual Property

The app design, branding, and original content belong to The Word App unless otherwise stated.

Bible translations may be subject to separate licensing terms.

6. Availability

We do not guarantee uninterrupted access to all features.

7. Updates

Features and services may evolve over time.

8. Acceptance

Continued use of the app constitutes agreement to these terms.
''',
  );

  static const about = LegalDocument(
    title: 'About The Word App',
    content: '''
The Word App

Experience the Living Word

Powered by LOGOS

The Word App is a modern spiritual platform designed to help people engage deeply with Scripture through technology, reflection, and daily spiritual growth.

Features include:
• Bible reading
• Devotionals
• Prayer mode
• Gospel tract sharing
• Sermon intelligence notes
• Scripture insights
• Verse highlights and journaling
• Narration and audio tools

Our mission is simple:
To help people experience the living Word of God daily.

We believe technology should strengthen spiritual growth, not distract from it.

Thank you for being part of this journey.
''',
  );
}
