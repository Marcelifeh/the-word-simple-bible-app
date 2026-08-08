# Release Artifact Record

Build date: August 8, 2026

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

Recompute the hash and update this record if the bundle is rebuilt for any reason.
