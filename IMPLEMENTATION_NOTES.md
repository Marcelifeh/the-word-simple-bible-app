# Sermon Intelligence — Phase B: multi-clip offline orchestration

Apply this overlay on top of the latest project (or the Phase A overlay).

## Implemented
- Recorded-sermon coordinator processes all completed playable clips in sequence.
- Combines transcript text and offsets per-clip timestamps into a sermon-wide timeline.
- Aggregates progress and supports cancellation; output is returned only after all clips complete.
- Rejects cloud engines for offline requests; no recording is uploaded.
- Includes regression tests with a fake on-device engine.
- Preserves the Phase A recorded/live interface for future streaming transcription.

## Not yet implemented
- Android whisper.cpp JNI/NDK binary or inference (the pending engine remains unavailable).
- Model download, verification, installation, and removal.
- M4A -> mono 16 kHz PCM decoding.
- Sermon Review UI wiring and durable per-clip checkpoint/resume.
- Physical Android validation.

## Verification on Windows
flutter pub get
flutter analyze
flutter test

## Next integration step
Pin a reviewed whisper.cpp revision, install Android NDK/CMake, build an arm64-v8a native library, implement Android audio decode and a platform bridge, then implement the offline model manager. Do not present the offline option as working until an actual Android recording has been transcribed locally.
