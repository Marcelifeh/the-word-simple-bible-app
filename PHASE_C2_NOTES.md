# Sermon Intelligence — Phase C.2 model lifecycle checkpoint

This source overlay builds on the **Phase C bridge checkpoint** and does not replace the whole app.

## Implemented
- Android private-storage model import via Android content URI (e.g. ACTION_OPEN_DOCUMENT), using a caller-provided, independently verified SHA-256 digest.
- Import runs on a worker thread, verifies the complete file before installation, and cleans temporary files after failures.
- Query installed model metadata (size and checksum) and delete installed model.
- Dart methods for model info, import, and removal; existing `isReady` remains false.
- No automatic cloud upload or network calls.

## Not implemented / important
- **No native whisper.cpp library, JNI inference, M4A decoding, model downloader, or functional offline transcription yet.**
- No model-picker UI is wired up. A `content://` URI and trustworthy SHA-256 must be supplied by future UI logic.
- Model authenticity requires a trusted digest from a pinned model release, not a hash computed from the downloaded file itself.
- Do not publish the feature as functional, and do not enable offline transcription controls.

## Why this checkpoint is limited
The execution environment cannot retrieve or review the upstream whisper.cpp source, model weights, or build dependencies. Shipping a fabricated JNI implementation would be unsafe. The next implementation must vendor a pinned, licensed whisper.cpp source snapshot and compile the native library with CMake/NDK, then add Android audio decoding and on-device inference.

## Apply and validate
Back up the existing project. Apply these files preserving paths, then run:

    flutter pub get
    flutter analyze
    flutter test
    flutter build apk --debug

Check that the preview still says inference unavailable. A successful build verifies compilation, not speech recognition.
