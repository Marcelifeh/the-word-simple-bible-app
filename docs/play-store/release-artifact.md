# Release Artifact Record

Build date: August 23, 2026

Source state: release-hardening working tree based on commit
`2778d9b43f13ffe81e6bd983afa6d80649ec96d7`. The release changes were not yet
committed when this artifact was produced, so preserve or commit the exact
working tree before rebuilding.

## Google Play App Bundle

- Path: `build/app/outputs/bundle/release/app-release.aab`
- Package: `org.thewordapp.mobile`
- Version name: `1.0.3`
- Version code: `4`
- Minimum SDK: `24`
- Target SDK: `36`
- Display name: `The Word App`
- Size: `90,552,669` bytes
- SHA-256: `D477226012F3B8FFC0AE8E46C0646B3F287997D6E524765829A937D2C169E0C0`
- JAR signature verification: passed (`jar verified`)
- Upload signer: `CN=The Word App, O=The Word App, C=CA`

The upload certificate is self-signed, as expected for a Google Play upload
key. Google Play App Signing uses the distribution signing key after upload.

Build command:

```powershell
C:\flutter\bin\flutter.bat build appbundle `
  --release `
  --dart-define=SERMON_API_URL=https://the-word-app-api.onrender.com `
  --dart-define=SERMON_TRANSCRIPTION_ENABLED=false
```

No `BIBLE_API_URL`, `COMMENTARY_API_URL`, or `AUDIO_API_URL` was supplied.
Android Gradle release guards reject a missing/loopback/non-HTTPS sermon API,
reject insecure optional API URLs, and reject enabled cloud transcription.

## Packaged Artifact Verification

The packaged release manifest reports:

- `org.thewordapp.mobile`, version `1.0.3+4`
- `minSdkVersion=24`, `targetSdkVersion=36`
- `android:allowBackup=false`
- `android:usesCleartextTraffic=false`
- `android:fullBackupContent=@xml/backup_rules`
- `android:dataExtractionRules=@xml/data_extraction_rules`

The three compiled `libapp.so` files (`armeabi-v7a`, `arm64-v8a`, and `x86_64`)
were extracted from the AAB and searched as binary data:

- Each ABI contains `https://the-word-app-api.onrender.com`.
- No ABI contains `http://localhost`, `http://127.0.0.1`,
  `http://10.0.2.2`, or `SERMON_TRANSCRIPTION_ENABLED=true`.

## Verification Results

- Dart formatting: passed; 10 changed/new Dart files already formatted.
- `flutter analyze --no-pub`: passed; no issues found.
- Full Flutter suite: passed; 200 tests.
- Release URL validation: passed; 8 tests.
- Adversarial backup/restore validation: passed; 22 tests.
- Backend production-route check: passed; `/debug/info` is not registered when
  `ENVIRONMENT=production`.
- `git diff --check`: passed.
- AAB build: passed.
- AAB JAR signature: passed.

## Release Scope and Follow-up

This record covers the AAB intended for Google Play. A matching installable APK
and physical-device update test were not produced for this exact `1.0.3+4`
working tree. Build and record an APK separately if device-side regression or
update-retention evidence is required.

External checks still required before Play submission:

1. **Publication blocker:** the public privacy-policy URL returned HTTP 200 on
   August 23, 2026, but still served the August 8 policy and did not contain the
   new Backup and Restore disclosure. Publish `docs/privacy/index.html` and
   verify the live page before submission.
2. Verify Render/model-provider contracts, retention, logging, deletion,
   service-provider status, and region assumptions used by the Data Safety form.
3. Confirm the intended target-audience selection with product/marketing intent.
4. Recompute this record if the source, defines, signing configuration, or AAB
   changes for any reason.
