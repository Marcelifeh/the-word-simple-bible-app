# Release Artifact Record

Build date: August 8, 2026

Source commit: `37dba41405521d8abe3ae967ddc52271b01b29ab`

## App Bundle

- Path: `build/app/outputs/bundle/release/app-release.aab`
- Package: `org.thewordapp.mobile`
- Version name: `1.0.0`
- Version code: `1`
- Target SDK: `36`
- Display name: `The Word App`
- Size: `90,350,104` bytes
- SHA-256: `E0315D53223E8B80854F967395D94648CFEF99D391E314E9F42C188E5D549182`
- Signature verification: `jar verified`

Build command:

```powershell
C:\flutter\bin\flutter.bat build appbundle `
  --release `
  --dart-define=SERMON_API_URL=https://the-word-app-api.onrender.com `
  --dart-define=SERMON_TRANSCRIPTION_ENABLED=false
```

The upload certificate is self-signed, as expected for a Google Play upload key. Google Play App Signing will use the distribution signing key after upload.

## Matching Release APK

- Path: `build/app/outputs/flutter-apk/app-release.apk`
- Size: `109,170,611` bytes
- SHA-256: `31F6EDCBEA4F89787F66D370055DAB4271204F70946CFC4422D9505C95C9382C`
- APK Signature Scheme v2 verification: passed
- Number of signers: `1`

Build command:

```powershell
C:\flutter\bin\flutter.bat build apk `
  --release `
  --dart-define=SERMON_API_URL=https://the-word-app-api.onrender.com `
  --dart-define=SERMON_TRANSCRIPTION_ENABLED=false
```

## Samsung Update Verification

- Device: Samsung Galaxy A71 (`SM-A715F`)
- ADB serial: `RZ8N2120GWT`
- Install command: `adb install -r build/app/outputs/flutter-apk/app-release.apk`
- Install result: `Success`
- First install time remained `2026-08-06 23:07:02`
- Update time changed to `2026-08-08 13:14:54`
- Package data directory remained `/data/user/0/org.thewordapp.mobile`
- Cold-launch log inspection found no Flutter exception or Android crash
- Daily Verse narration completed on-device without a Flutter or player error

The unchanged first-install time and package data directory confirm that Android
installed the APK as an update rather than uninstalling or clearing the app.
After unlocking the device, the saved `Walking by Faith` sermon note, speaker,
date, and detected scripture were still present and opened successfully. This
provides an additional visual check that the update retained local user data.

## Live Backend Check

- `GET https://the-word-app-api.onrender.com/health` returned `{"status":"healthy"}`.
- A KJV chapter request and `POST /commentary/ensure` test returned
  `Verse not found`, so the live Bible/commentary database needs separate
  investigation before it is treated as a release dependency.
- This artifact contains all 1,189 bundled KJV commentary chapters and was
  built with `SERMON_TRANSCRIPTION_ENABLED=false`. Consequently, version
  `1.0.0+1` has no user-facing Render AI action that can be truthfully marked
  as verified. Re-test the cloud workflow before enabling it in a later build.

Recompute the hash and update this record if the bundle is rebuilt for any reason.
