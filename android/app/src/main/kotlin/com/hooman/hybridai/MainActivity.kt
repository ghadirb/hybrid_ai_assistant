
package com.hooman.hybridai

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.vosk.Model
import org.vosk.Recognizer
import java.io.File
import java.io.FileInputStream
import kotlin.concurrent.thread
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val CHANNEL = "hybrid_ai/engine"
    private var model: Model? = null
    private var modelPathLoaded: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val path = (call.arguments as? Map<*, *>)?.get("path") as? String ?: ""
                    if (path.isEmpty()) { result.error("NO_PATH", "Empty model path", null); return@setMethodCallHandler }
                    thread {
                        try {
                            if (modelPathLoaded == path && model != null) { runOnUiThread { result.success("Model already loaded") }; return@thread }
                            model?.close()
                            model = Model(path)
                            modelPathLoaded = path
                            runOnUiThread { result.success("Model loaded") }
                        } catch (e: Exception) { runOnUiThread { result.error("MODEL_ERROR", e.toString(), null) } }
                    }
                }
                "recognizeFile" -> {
                    val path = (call.arguments as? Map<*, *>)?.get("path") as? String ?: ""
                    if (path.isEmpty()) { result.error("NO_PATH", "Empty path provided", null); return@setMethodCallHandler }
                    thread {
                        try {
                            val text = recognizeWavFile(path)
                            try { File(path).delete() } catch (e: Exception) {}
                            runOnUiThread { result.success(text) }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "recognize error", e)
                            runOnUiThread { result.error("RECOGNIZE_ERROR", e.toString(), null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun recognizeWavFile(wavPath: String): String? {
        if (model == null) throw IllegalStateException("Model not loaded")
        val file = File(wavPath)
        if (!file.exists()) throw java.io.IOException("File does not exist: $wavPath")
        val sampleRate = 16000.0f
        val rec = Recognizer(model, sampleRate)
        val fis = FileInputStream(file)
        try {
            val header = ByteArray(44)
            val readHeader = fis.read(header)
            if (readHeader != 44) { fis.channel.position(0) }
            val buffer = ByteArray(4096)
            var bytesRead: Int
            while (fis.read(buffer).also { bytesRead = it } > 0) { rec.acceptWaveForm(buffer, bytesRead) }
            val finalJson = rec.finalResult
            val j = JSONObject(finalJson)
            val text = j.optString("text", "")
            rec.close()
            return text
        } finally { fis.close() }
    }
}
