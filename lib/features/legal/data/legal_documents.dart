import '../models/legal_document.dart';

class LegalDocuments {
  static const privacyPolicy = LegalDocument(
    title: 'Privacy Policy',
    content: '''
Last Updated: August 6, 2026

Welcome to The Word App.

This Privacy Policy explains how The Word App handles information when you use the mobile application and its optional online services.

1. Overview

The Word App does not currently require an account. The app does not contain advertising or third-party analytics SDKs. Most app data remains on your device.

2. Information Stored on Your Device

The app may store Bible-reading progress, favorites, bookmarks, highlights, notes, sermon notes and recordings, journal entries, devotional progress, Scripture Memory content and review history, prayer reflections, notification preferences and inbox items, custom Word Studio backgrounds, generated exports, and app settings.

This information is stored locally unless you deliberately use a sharing or online-processing feature. Uninstalling the app generally removes app-managed local data, subject to Android backup or files you exported elsewhere.

3. Custom Images and Shared Content

Images selected for Word Studio are copied into app storage and are not uploaded by the custom-background feature. A finished design leaves the device only when you choose to share or export it using Android or another selected app.

Content you choose to share is handled by the destination app or service under its own privacy terms.

4. Device Permissions

The app may request:
- Microphone access when you choose to record sermon audio.
- Notification access when you enable reminders.
- Access to a user-selected image through Android's photo picker for custom backgrounds.

The app does not need broad photo-library access to select a custom background.

5. Optional Online Services

The release version may connect to The Word App backend hosted on Render when you request supported online features. Depending on the feature, requests may include a Bible translation and Scripture reference, sermon transcript text, or other content you deliberately submit for processing.

Sermon audio is uploaded only when you explicitly request cloud transcription and that feature is enabled. The current release configuration disables cloud transcription. When enabled, the backend writes the upload to a temporary file for transcription and deletes that temporary file after processing.

The hosting provider may process standard technical information such as IP addresses, request timestamps, and error logs to operate and protect the service. The app does not use these services to build advertising profiles.

6. Narration

On-device narration may use voices and speech services supplied by your device manufacturer or operating system. Remote Bible-audio requests contain a Scripture reference and translation, not your notes or account information.

7. Retention and Deletion

Local information remains until you delete it in the app, remove exported files, clear app storage, or uninstall the app. Temporary transcription uploads are deleted after processing as described above.

Because the app does not currently provide accounts or cloud synchronization, there is no account-deletion process. For questions or requests concerning information submitted to an online service, contact us.

8. Security

We use reasonable safeguards and HTTPS for configured production API connections. No storage or transmission method can be guaranteed completely secure. Avoid placing highly sensitive personal information in content you plan to share or submit online.

9. Children's Privacy

The Word App is intended for a general audience and is not specifically directed to children. We do not knowingly collect personal information from children through an account system.

10. Changes to This Policy

We may update this policy as features or legal requirements change. The current version will be available in the app and on the public privacy-policy page.

11. Contact

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
