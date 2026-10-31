# Phase C.3 native inference — experimental Android integration

This overlay builds on **Phase C.2**. It includes the user-supplied whisper.cpp source snapshot (archive git hash `231638a0717b7822784297e5980965ffcec05810`, source version 1.9.5-dev). The original whisper.cpp license is retained under `android/app/src/main/cpp/whisper.cpp/LICENSE`.

## Implemented
- Android Gradle externalNativeBuild/CMake compiling a JNI bridge against the bundled whisper.cpp and ggml sources.
- Kotlin `MediaExtractor`/`MediaCodec` audio decoding and mono 16 kHz resampling; intended for device-supported M4A/AAC and other supported audio codecs.
- Native offline inference, chunked at 60 seconds, returning text to the existing Dart transcription adapter.
- Explicit readiness dependent on both native library and an installed model; no cloud fallback; best-effort cancellation.
- Existing private model import still requires a trusted SHA-256 provided by the caller.

## Known limitations / must fix before release
- **UNTESTED Android NDK build**: this environment lacks Flutter and Android SDK/NDK. Native compile errors are possible.
- **Not connected to a production user-facing offline transcription workflow**: Sermon Review still needs a real model-import/setup UI and coordinator wiring.
- Decoder currently accumulates full decoded audio in RAM; long sermons can exhaust memory. Before production, implement streamed disk-backed 16 kHz PCM and bounded chunk processing.
- Native model is reloaded for each 60-second chunk (slow); improve with a persistent per-job context.
- Timestamped segments are not returned yet. Chunk boundaries may reduce accuracy. Progress events not yet implemented.
- Cancellation is best effort and not robust for simultaneous jobs; implement per-job lifecycle and locking before enabling widely.
- Requires a correctly formatted, independently verified `ggml-base.en.bin` model installed through Phase C.2 import. No model is bundled.
- Test audio interruption, non-PCM output formats, codec behavior, Android ABI support, memory use and transcription accuracy on a physical device.
- Keep the prior stable Phase C.2 checkpoint backed up.

## Verify on Windows
```
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
If NDK/CMake fails, send the **first error block** (not only the final Gradle failure). If build passes, this is **not** sufficient to declare the feature ready: perform offline on-device inference and memory tests before release.
