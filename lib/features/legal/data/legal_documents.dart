import '../models/legal_document.dart';

class LegalDocuments {
  static const privacyPolicy = LegalDocument(
    title: 'Privacy Policy',
    content: '''
Effective Date: August 8, 2026
Last Updated: August 8, 2026

The Word App (package org.thewordapp.mobile) is published by The Word App. This Privacy Policy explains how the mobile application and its optional online services access, use, store, and share information.

Public policy: https://marcelifeh.github.io/the-word-simple-bible-app/privacy/

1. Privacy at a Glance

No account is required. The app contains no advertising, analytics, crash-reporting, attribution, or Firebase Cloud Messaging SDKs. Most personal and spiritual activity is processed and stored only on your device.

2. Information Stored on Your Device

The app may store Bible-reading progress and history, favorites, bookmarks, highlights, verse notes, devotional progress and journal entries, reading-plan completion, Scripture Memory verses and review history, prayer reflections, sermon notes and recordings, notification preferences and inbox items, custom Word Studio backgrounds, generated exports, and app settings.

This information stays in app-managed storage unless you deliberately use a sharing or online-processing feature. It is not used for advertising or sold.

3. Bible Reading and Spiritual Activity

Reading history, devotional completion, saved Scripture, prayer content, weekly activity, and Scripture Memory activity are processed locally. The production release does not synchronize this information to an account or cloud profile.

4. LOGOS Notes and Sermon Recordings

Sermon notes, timestamps, and audio recordings are stored locally. Microphone access is requested only after you choose to record. Deleting a sermon note also deletes its app-managed recording files.

Cloud transcription is disabled in release 1.0.0+1. Therefore, this release does not upload sermon audio for transcription. If a future release enables cloud transcription, the app will disclose that change before audio is uploaded.

5. AI, Commentary, and Transcript Processing

When you request an online commentary that is not bundled with the app, the app may send the Bible translation and Scripture reference to The Word App backend on Render. The backend may send the public Bible verse and reference to an OpenAI-compatible language-model provider to create the commentary. Personal notes, reading history, and account information are not included in that request.

If transcript text is available and you choose sermon summary or outline processing, that transcript is sent to The Word App backend. The current server processes summary and outline requests in memory and does not intentionally store transcript bodies in its database. Generated results are returned to and stored on your device.

6. Narration and Remote Bible Audio

On-device narration may use voices and speech services supplied by your device manufacturer or operating system. When you request remote Bible audio, the app sends a Bible translation and Scripture reference to The Word App backend. The backend may send the public verse text to ElevenLabs and may cache the generated Bible audio. Your notes and recordings are not included.

7. Notifications

Reminder preferences, schedules, and notification inbox items are stored locally. Notifications are scheduled on the device and do not require an account, a Firebase token, or Render to deliver. Notification permission is requested only after you enable reminders.

8. Scripture Memory, Saved Content, and Journals

Memory verses, review results, notes, favorites, devotional journals, and saved content remain on the device unless you choose to share them or submit supported content for online processing.

9. Word Studio Images

Images selected for Word Studio are copied into app storage and are not uploaded by the custom-background feature. The app uses the system photo picker where supported and does not request broad photo-library access on Android. Removing a custom background deletes the app-managed copy, not your original gallery image.

10. Sharing and Exporting

Content leaves the app through another application only after you choose Share or Export. The destination app or service handles that content under its own privacy terms. Exported files remain until you delete them from their saved location.

11. Third-Party Services

Optional online features may use Render for hosting, an OpenAI-compatible provider for missing commentary generation, and ElevenLabs for remote Bible narration. Operating-system services provide notifications, speech, photo selection, and sharing. These providers process information under their own terms and privacy policies.

The app does not include third-party advertising, analytics, crash-reporting, or social-login SDKs.

12. Permissions

The app may request microphone permission for user-initiated sermon recording and notification permission for reminders. It uses the system photo picker for a user-selected Word Studio image. Network access supports optional online Scripture, commentary, audio, and backend availability requests.

13. Technical and Network Data

When the app connects to the production backend, Render and standard server access logs may process an IP address, request time, endpoint, response status, and error information. Some feature logs may include the requested Bible translation and reference. This information supports service delivery, reliability, abuse prevention, and security. It is not used for advertising profiles.

14. Security

Production API connections use HTTPS. We use reasonable technical and organizational safeguards, but no storage or transmission method can be guaranteed completely secure. Avoid submitting highly sensitive personal information through sharing or optional online-processing features.

15. Retention and Deletion

Local information remains until you delete it in a feature screen, clear app storage, remove exported files, or uninstall the app, subject to operating-system backups. The app has no account or cloud synchronization, so there is no account-deletion process.

The server does not intentionally store sermon summary or outline request bodies in its database. Hosting and security logs are retained according to operational and provider settings. To request deletion of server-held information that can reasonably be identified, contact the address below.

16. Children's Privacy

The Word App is intended for a general audience and is not specifically directed to children. It does not knowingly collect children's personal information through an account system.

17. Changes and Contact

We may update this policy when features, providers, or legal requirements change. The current version is available in the app and at the public policy URL above.

For questions regarding privacy:
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
