#include <jni.h>
#include <atomic>
#include <string>
#include <vector>
#include "whisper.h"
static std::atomic<bool> cancelled{false};
static bool abort_callback(void *) { return cancelled.load(); }
extern "C" JNIEXPORT void JNICALL Java_org_thewordapp_mobile_OfflineWhisperChannel_nativeCancel(JNIEnv *, jobject) { cancelled.store(true); }
extern "C" JNIEXPORT jstring JNICALL Java_org_thewordapp_mobile_OfflineWhisperChannel_nativeTranscribe(JNIEnv * env, jobject, jstring modelPath, jfloatArray audio) {
    const char * path = env->GetStringUTFChars(modelPath, nullptr);
    whisper_context_params cp = whisper_context_default_params();
    whisper_context * ctx = whisper_init_from_file_with_params(path, cp);
    env->ReleaseStringUTFChars(modelPath, path);
    if (!ctx) return nullptr;
    jsize count = env->GetArrayLength(audio);
    std::vector<float> samples(count);
    env->GetFloatArrayRegion(audio, 0, count, samples.data());
    cancelled.store(false);
    whisper_full_params p = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    p.print_progress = false; p.print_realtime = false; p.print_timestamps = false;
    p.language = "en"; p.translate = false;
    p.abort_callback = abort_callback;
    int status = whisper_full(ctx, p, samples.data(), static_cast<int>(samples.size()));
    std::string output;
    if (status == 0 && !cancelled.load()) {
        const int n = whisper_full_n_segments(ctx);
        for (int i=0; i<n; ++i) {
            if (i) output += " ";
            output += whisper_full_get_segment_text(ctx,i);
        }
    }
    whisper_free(ctx);
    return status == 0 && !cancelled.load() ? env->NewStringUTF(output.c_str()) : nullptr;
}
