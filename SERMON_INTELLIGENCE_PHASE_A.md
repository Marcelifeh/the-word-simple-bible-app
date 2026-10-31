# Sermon Intelligence — Phase A audit and implementation checkpoint

## Existing code (inspected)
- `sermon_recording_service.dart` records AAC/M4A at 44.1 kHz using `record`.
- `sermon_note.dart` already models ordered recording clips, status and timestamped transcript segments.
- `sermon_review_screen.dart` transcribes the **first playable clip only**, and gates transcription behind cloud availability.
- `sermon_ai_service.dart` posts the recording to `/sermon/transcribe`; this is not offline inference.
- Summaries and outlines also call a server; they must remain explicitly optional/cloud-labeled.

## Added now
- `sermon_transcription_engine.dart`: stable platform-neutral recorded/live contract, progress, cancellation and output model.
- `PendingOfflineWhisperEngine`: safe, explicit unavailable implementation; **no upload and no fake transcription**.
- Regression tests for progress and absence of implicit cloud fallback.
- Existing screens and cloud workflow are deliberately unchanged at this checkpoint.

## Required before claiming offline transcription works
1. Pin a reviewed `ggml-org/whisper.cpp` commit and its license; integrate Android arm64-v8a with NDK/CMake/JNI or verified FFI binding. Do not ship unreviewed binaries.
2. Implement model manager: optional English base model download, SHA-256 verification, atomic install, disk-space checks, versioning, removal and cancellation. Do not embed a 142 MiB model in the base app by default.
3. Decode saved M4A clips to mono 16 kHz PCM before inference (the existing recorder uses 44.1 kHz AAC); ensure native audio conversion is supported, not just WAV input.
4. Process **all** playable clips in sequence, using bounded chunks with overlap, timestamp adjustment, de-duplication and durable checkpoints. Do not overwrite prior transcript until successful save.
5. Run inference off the UI thread, with progress/cancel, low-memory handling, lifecycle and call-interruption tests.
6. Wire an explicit Offline/Cloud choice into Sermon Review. Offline must never upload; cloud requires clear user consent.
7. Add future `transcribeLive` adapter using 16 kHz mono PCM streaming, without altering stored transcript/segment format. Keep it disabled until verified.
8. Benchmark 5/30/60-minute sermon recordings on real Android devices, including accents, biblical names, and Scripture references; check transcription quality, thermals, battery and storage.
9. Verify microphone consent and privacy disclosures, and review model licenses and third-party notices.

## Verification
`flutter pub get`, `flutter analyze`, `flutter test`, then Android debug/release builds on Windows. No Flutter SDK or Android NDK was available in this packaging environment; native transcription is NOT yet operational.
