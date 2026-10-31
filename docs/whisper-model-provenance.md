# Phase C.4.1: pinned Whisper Base English model

This is the unquantized English-only GGML conversion maintained by whisper.cpp,
not the OpenAI PyTorch checkpoint. The app does not fetch checksums at runtime.

## Trusted artifact

- Repository: https://huggingface.co/ggerganov/whisper.cpp
- Immutable revision: `5359861c739e955e79d9a303bcbc70fb988958b1`
- File: `ggml-base.en.bin`
- Download: https://huggingface.co/ggerganov/whisper.cpp/resolve/5359861c739e955e79d9a303bcbc70fb988958b1/ggml-base.en.bin
- Exact size: `147964211` bytes
- SHA-256: `a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002`
- Independent upstream SHA-1: `137c40403d78fd54d454da0f9bd998f78703390c`

## Verification performed on 2026-10-24

1. Obtained the revision, size, and LFS SHA-256 from the official model
   repository API: https://huggingface.co/api/models/ggerganov/whisper.cpp?blobs=true
2. Downloaded the full artifact from the immutable URL above into ignored local
   validation storage (`.dart_tool/whisper-validation/`).
3. Independently computed SHA-256 with PowerShell `Get-FileHash -Algorithm SHA256`.
   The computed value matched the LFS SHA-256 above.
4. Independently computed SHA-1 over the same bytes and compared it with the
   separate whisper.cpp source repository's published base.en hash:
   https://github.com/ggml-org/whisper.cpp/blob/v1.7.6/models/README.md
   The computed value matched `137c40403d78fd54d454da0f9bd998f78703390c`.

SHA-256 and exact size are compiled application constants in Flutter and Kotlin.
Neither a user-supplied digest nor a sidecar downloaded at runtime is trusted.
Updating the artifact requires repeating this verification and updating both
constants through a reviewed application change.

## Lifecycle and privacy

The installer exists only in Android Sermon Review, outside app startup. Only
model weights are downloaded; recording data is never passed to the installer.
No automatic cloud transcription or fallback is added.

Downloads stream into an app-private cache file named by the trusted digest.
Interrupted transfers can resume after Retry or process restart. The server's
Content-Range and total length must match the pinned artifact; a server that
ignores Range causes a clean restart. Cancel removes partial bytes. Invalid
downloads are removed. Cache eviction safely causes a fresh download.

Flutter verifies SHA-256 before requesting native installation. Kotlin accepts
only files inside the private picker/cache root and independently enforces the
pinned size and SHA-256. It copies to a temporary file beside the final model,
syncs the file, and uses POSIX rename for atomic replacement. An older verified
model is never deleted before replacement. A later model check removes an
abandoned installation temporary file. Readiness and transcription require a
verified model; verification runs on the native serial worker, never the UI
thread. Verification is cached only for an unchanged private file's size/mtime.

Downloads are scoped to Sermon Review: leaving during a download cancels it;
an already-started atomic native install is allowed to finish. No foreground
service or background download permission is introduced.

## Device acceptance gate

Automated tests and a successful APK build do not establish real transcription
success. Acceptance requires installing via **Install Offline Model**, reaching
Ready, and transcribing a real recording successfully on Android with cloud
transcription unused. Record the device and result only after that happens.

## Completed validation

Validation was performed on 2026-10-24 on a Samsung SM-A715F running Android 13,
using `org.thewordapp.mobile.debug`.

- `flutter analyze`: no issues.
- `flutter test`: all 225 tests passed, including 14 installer cases covering
  checksum mismatch, interrupted transfer and resume, cancellation (including
  an actual stalled local HTTP response), storage failures, successful and
  repeated installation, concurrent installation, invalid ranges, deletion,
  and agreement between Flutter and native trusted constants.
- `flutter build apk --debug`: passed after the final decoder correction.
- Installed through **Install Offline Model** in Sermon Review. Observed
  download progress and Ready. The installed private file contained exactly
  147964211 bytes. Android `sha256sum` independently matched the trusted digest.
  The temporary download cache was empty after installation.
- Updated the debug APK without losing the model. Ready returned without
  another download.
- Transcribed the existing 43-second sermon recording using **Transcribe
  Offline**. A nonempty sermon transcript was saved. After force-stop and
  relaunch, reopening Sermon Review produced an identical transcript-card hash.
  Audio was processed by the native engine; no cloud transcription was used.
- Device testing exposed an existing decoder assumption: Android codecs can
  omit optional `KEY_PCM_ENCODING`. The bridge now uses the standard signed
  16-bit PCM default when absent, while retaining float PCM support. The same
  real recording succeeded after this correction.

Native inference was slow in this unoptimized debug build. This validates
functionality and persistence on this device, not release performance or
accuracy across other recordings and devices.

Call-safe startup, the production application ID, release signing, and the
separate debug application ID were preserved. Only the debug app was installed
for validation. Recordings were not pulled off the phone or uploaded.
