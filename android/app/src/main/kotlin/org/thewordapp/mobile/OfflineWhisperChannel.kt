package org.thewordapp.mobile

import android.content.Context
import android.net.Uri
import android.media.MediaExtractor
import android.media.MediaCodec
import android.media.MediaFormat
import java.nio.ByteOrder
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.concurrent.Executors
import android.system.Os

/** Offline-only model lifecycle and inference. Never uploads audio. */
internal class OfflineWhisperChannel(engine: FlutterEngine, private val context: Context) {
    companion object {
        // Independently verified artifact; see docs/whisper-model-provenance.md.
        private const val MODEL_SHA256 = "a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002"
        private const val MODEL_BYTES = 147964211L
    }
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "the_word/offline_whisper")
    private val io = Executors.newSingleThreadExecutor()
    private val modelFile: File get() = File(context.filesDir, "whisper_models/ggml-base.en.bin")
    private var verifiedStamp: Pair<Long, Long>? = null

    // Called only on the serial IO executor; no hashing on Android's UI thread.
    private fun verifiedModel(): Boolean {
        val file = modelFile
        if (!file.isFile || file.length() != MODEL_BYTES) return false
        val stamp = Pair(file.length(), file.lastModified())
        if (verifiedStamp == stamp) return true
        if (sha256(file) != MODEL_SHA256) return false
        verifiedStamp = stamp
        return true
    }

    private external fun nativeTranscribe(modelPath: String, pcm16k: FloatArray): String?
    private external fun nativeCancel()
    private val nativeLoaded: Boolean = try { System.loadLibrary("the_word_whisper"); true } catch (_: UnsatisfiedLinkError) { false }
    @Volatile private var cancellationRequested = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isReady" -> io.execute {
                    try {
                        val ready = nativeLoaded && verifiedModel()
                        context.mainExecutor.execute { result.success(ready) }
                    } catch (e: Exception) {
                        context.mainExecutor.execute { result.error("MODEL_CHECK_FAILED", e.message, null) }
                    }
                }
                "modelStatus" -> result.success(if (!nativeLoaded) "Native Whisper library unavailable" else "Check modelInfo for verified installation status")
                "modelInfo" -> io.execute {
                    try {
                    val file = modelFile
                    // A previous process may have died during the private install copy.
                    File(file.parentFile, "model.download.tmp").delete()
                    val valid = verifiedModel()
                    val info = mapOf("installed" to valid, "bytes" to if (valid) file.length() else 0L,
                        "sha256" to if (valid) MODEL_SHA256 else "", "nativeAvailable" to nativeLoaded)
                    context.mainExecutor.execute { result.success(info) }
                    } catch (e: Exception) {
                        context.mainExecutor.execute { result.error("MODEL_CHECK_FAILED", e.message, null) }
                    }
                }
                "importModel" -> {
                    val uri = call.argument<String>("uri")
                    if (uri.isNullOrBlank()) {
                        result.error("INVALID_MODEL_REQUEST", "Private model cache URI is required", null)
                    } else io.execute {
                        try {
                            val target = modelFile
                            check(target.parentFile!!.isDirectory || target.parentFile!!.mkdirs()) { "Model storage is unavailable" }
                            check(target.parentFile!!.usableSpace > MODEL_BYTES + 8L * 1024L * 1024L) { "Free at least 160 MB to install the model" }
                            val temporary = File(target.parentFile, "model.download.tmp")
                            try {
                                val parsed = Uri.parse(uri)
                                val inputStream = if (parsed.scheme == "file") {
                                    val candidate = File(requireNotNull(parsed.path))
                                    val canonical = candidate.canonicalFile
                                    val cacheRoot = context.cacheDir.canonicalFile
                                    require(canonical.path.startsWith(cacheRoot.path + File.separator)) {
                                        "Selected model must be in the app's private picker cache"
                                    }
                                    canonical.inputStream()
                                } else error("Model must be downloaded into private cache")
                                inputStream.use { input ->
                                    requireNotNull(input) { "Cannot open selected model" }
                                    FileOutputStream(temporary).use { output ->
                                        val buffer = ByteArray(64 * 1024)
                                        var total = 0L
                                        while (true) {
                                            val count = input.read(buffer)
                                            if (count < 0) break
                                            total += count
                                            require(total <= MODEL_BYTES) { "Model exceeds expected size" }
                                            output.write(buffer, 0, count)
                                        }
                                        output.fd.sync()
                                    }
                                }
                                require(temporary.length() == MODEL_BYTES) { "Model size does not match" }
                                require(sha256(temporary) == MODEL_SHA256) { "Model checksum does not match" }
                                // POSIX rename atomically replaces the old file on the same filesystem.
                                // Never delete a working model before the replacement is verified.
                                Os.rename(temporary.absolutePath, target.absolutePath)
                                verifiedStamp = Pair(target.length(), target.lastModified())
                                context.mainExecutor.execute { result.success(mapOf("installed" to true, "bytes" to target.length())) }
                            } finally { temporary.delete() }
                        } catch (e: Exception) {
                            val storageFailure = e is java.io.IOException ||
                                e is android.system.ErrnoException ||
                                e.message?.contains("storage", ignoreCase = true) == true ||
                                e.message?.contains("space", ignoreCase = true) == true ||
                                e.message?.contains("Free at least", ignoreCase = true) == true
                            context.mainExecutor.execute { result.error(if (storageFailure) "MODEL_STORAGE_FAILED" else "MODEL_IMPORT_FAILED", e.message, null) }
                        }
                    }
                }
                "deleteModel" -> io.execute {
                    val removed = !modelFile.exists() || modelFile.delete()
                    verifiedStamp = null
                    File(modelFile.parentFile, "model.download.tmp").delete()
                    context.mainExecutor.execute { result.success(removed) }
                }
                "transcribe" -> {
                    val path = call.argument<String>("path")
                    if (!nativeLoaded) result.error("ENGINE_NOT_READY", "Native engine is unavailable", null)
                    else if (path.isNullOrBlank()) result.error("INVALID_AUDIO", "Missing recording path", null)
                    else io.execute {
                        try {
                            check(verifiedModel()) { "Install a verified offline model first" }
                            cancellationRequested = false
                            val audio = decodeAudio(path)
                            val output = StringBuilder()
                            // Bounded native allocations; process up to 60 seconds per inference.
                            val window = 16000 * 60
                            var offset = 0
                            while (offset < audio.size) {
                                if (cancellationRequested) throw IllegalStateException("Transcription cancelled")
                                val end = minOf(offset + window, audio.size)
                                val text = nativeTranscribe(modelFile.absolutePath, audio.copyOfRange(offset, end))
                                    ?: throw IllegalStateException("Native inference cancelled or failed")
                                if (output.isNotEmpty()) output.append(' ')
                                output.append(text.trim())
                                offset = end
                            }
                            context.mainExecutor.execute { result.success(mapOf("text" to output.toString(), "language" to "en", "segments" to emptyList<Any>())) }
                        } catch (e: Exception) {
                            android.util.Log.e("OfflineWhisper", "Offline transcription failed", e)
                            context.mainExecutor.execute { result.error("OFFLINE_TRANSCRIPTION_FAILED", e.message, null) }
                        }
                    }
                }
                "cancel" -> {
                    cancellationRequested = true
                    if (nativeLoaded) nativeCancel()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Decode Android-supported audio (including AAC/M4A) to mono float PCM at 16 kHz. */
    private fun decodeAudio(path: String): FloatArray {
        val extractor = MediaExtractor()
        val codec: MediaCodec
        try {
            extractor.setDataSource(path)
            val track = (0 until extractor.trackCount).firstOrNull {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
            } ?: error("No audio track in recording")
            extractor.selectTrack(track)
            val format = extractor.getTrackFormat(track)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: error("Unknown audio codec")
            codec = MediaCodec.createDecoderByType(mime)
            codec.configure(format, null, null, 0)
            codec.start()
            try {
                val pcm = ArrayList<Float>()
                val info = MediaCodec.BufferInfo()
                var inputDone = false
                var outputDone = false
                var rate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                while (!outputDone) {
                    if (cancellationRequested) error("Cancelled")
                    if (!inputDone) {
                        val index = codec.dequeueInputBuffer(10000)
                        if (index >= 0) {
                            val buffer = codec.getInputBuffer(index)!!
                            buffer.clear()
                            val size = extractor.readSampleData(buffer, 0)
                            if (size < 0) {
                                codec.queueInputBuffer(index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                inputDone = true
                            } else {
                                codec.queueInputBuffer(index, 0, size, extractor.sampleTime, 0)
                                extractor.advance()
                            }
                        }
                    }
                    val index = codec.dequeueOutputBuffer(info, 10000)
                    if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        val f = codec.outputFormat
                        rate = f.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                        channels = f.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    } else if (index >= 0) {
                        val buffer = codec.getOutputBuffer(index)!!
                        buffer.position(info.offset)
                        buffer.limit(info.offset + info.size)
                        // PCM encoding is optional in MediaCodec output. Decoders
                        // default to signed 16-bit PCM unless float was requested.
                        val outputFormat = codec.outputFormat
                        val encoding = if (outputFormat.containsKey(MediaFormat.KEY_PCM_ENCODING))
                            outputFormat.getInteger(MediaFormat.KEY_PCM_ENCODING)
                        else android.media.AudioFormat.ENCODING_PCM_16BIT
                        require(encoding == android.media.AudioFormat.ENCODING_PCM_16BIT ||
                            encoding == android.media.AudioFormat.ENCODING_PCM_FLOAT) { "Unsupported decoder PCM encoding" }
                        val bytesPerSample = if (encoding == 4) 4 else 2
                        val frameSize = bytesPerSample * channels
                        buffer.order(ByteOrder.LITTLE_ENDIAN)
                        while (buffer.remaining() >= frameSize) {
                            var sum = 0f
                            repeat(channels) { sum += if (encoding == 4) buffer.float else buffer.short / 32768f }
                            pcm.add(sum / channels)
                        }
                        codec.releaseOutputBuffer(index, false)
                        outputDone = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                    }
                }
                require(pcm.isNotEmpty()) { "Recording contains no decoded audio" }
                val size = (pcm.size.toLong() * 16000L / rate).toInt()
                return FloatArray(size) { i ->
                    val position = i.toDouble() * rate / 16000.0
                    val low = position.toInt().coerceIn(0, pcm.lastIndex)
                    val high = (low + 1).coerceAtMost(pcm.lastIndex)
                    (pcm[low] * (1.0 - (position - low)) + pcm[high] * (position - low)).toFloat()
                }
            } finally { codec.stop(); codec.release() }
        } finally { extractor.release() }
    }

    private fun sha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().buffered().use { input ->
            val buffer = ByteArray(64 * 1024)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }
}
