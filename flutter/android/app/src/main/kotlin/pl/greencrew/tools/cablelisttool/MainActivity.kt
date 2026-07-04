package pl.greencrew.tools.cablelisttool

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pl.greencrew.tools/document_saver"
        ).setMethodCallHandler { call, result ->
            if (call.method == "saveBytes") {
                saveBytes(call, result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveBytes(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Inny zapis jest juz w toku.", null)
            return
        }

        val suggestedName = call.argument<String>("suggestedName") ?: "export"
        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
        val bytes = call.argument<ByteArray>("bytes")
        if (bytes == null) {
            result.error("missing_bytes", "Brak danych do zapisania.", null)
            return
        }

        pendingResult = result
        pendingBytes = bytes

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, suggestedName)
        }
        startActivityForResult(intent, SAVE_DOCUMENT_REQUEST)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != SAVE_DOCUMENT_REQUEST) {
            return
        }

        val result = pendingResult
        val bytes = pendingBytes
        pendingResult = null
        pendingBytes = null

        if (result == null || bytes == null) {
            return
        }
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri: Uri? = data?.data
        if (uri == null) {
            result.error("missing_uri", "Nie wybrano lokalizacji pliku.", null)
            return
        }

        try {
            contentResolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
                stream.flush()
            } ?: run {
                result.error("open_failed", "Nie mozna otworzyc wybranego pliku.", null)
                return
            }
            result.success(uri.toString())
        } catch (error: Exception) {
            result.error("write_failed", error.message, null)
        }
    }

    companion object {
        private const val SAVE_DOCUMENT_REQUEST = 4207
    }
}
