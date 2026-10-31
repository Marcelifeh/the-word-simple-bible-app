# Sermon Intelligence Phase C — Android bridge checkpoint

This is a **fail-closed integration checkpoint**, not a working whisper.cpp engine.
It adds the Android MethodChannel registration, Dart adapter, and an explicit preview button.
It does NOT bundle whisper.cpp, download a model, decode M4A, or perform speech recognition.
This distinction is deliberate: a false 'offline ready' indicator could cause users to lose confidence or recordings.

## Install
Back up your project and overlay these files preserving paths. Run `flutter analyze`, `flutter test`, and `flutter build apk --debug`.
Use a physical Android device to check that the preview button reports the native engine unavailable.
Web should remain unaffected. Existing cloud functionality is unchanged.

## Next native engineering steps
1. Vendor a reviewed/pinned whisper.cpp release and licenses in Android source control.
2. Build the JNI library with CMake and Android NDK for supported ABIs.
3. Decode recorded M4A/AAC via Android MediaExtractor/MediaCodec, resample to 16 kHz mono float PCM.
4. Provide verified optional model download/import, integrity checks, storage and deletion.
5. Run native inference on a worker thread with cancellation, segment timestamps and progress.
6. Switch isReady only after native library loads AND a valid model is installed.
7. Connect the existing multi-clip coordinator to the native engine and add the offline action.
8. Benchmark 5/30/60 minute sermons and device interruption handling.

Do not publish this as a functioning offline transcription feature yet.
