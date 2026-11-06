package com.example.sample_aplikasi

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var saveReply: MethodChannel.Result? = null
    private var document: ByteArray? = null
    private val createDocument = 8051

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "markaz/documents").setMethodCallHandler { call, reply ->
            if (call.method != "save") { reply.notImplemented(); return@setMethodCallHandler }
            if (saveReply != null) { reply.error("busy", "Pemilihan lokasi sedang berlangsung.", null); return@setMethodCallHandler }
            val bytes = call.argument<ByteArray>("bytes")
            val mime = call.argument<String>("mime")
            if (bytes == null || mime !in listOf("application/pdf","image/png","image/jpeg")) {
                reply.error("format", "Format dokumen tidak didukung.", null); return@setMethodCallHandler
            }
            saveReply = reply
            document = bytes
            try {
                startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = mime
                    putExtra(Intent.EXTRA_TITLE, call.argument<String>("name"))
                }, createDocument)
            } catch (_: Exception) {
                saveReply = null; document = null; reply.error("picker", "Pemilih berkas tidak tersedia.", null)
            }
        }
    }

    @Deprecated("Used for compatibility with FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode,resultCode,data)
        if (requestCode != createDocument) return
        val reply = saveReply ?: return
        val bytes = document
        saveReply = null; document = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || bytes == null) { reply.success(false); return }
        Thread {
            try {
                val stream = contentResolver.openOutputStream(uri) ?: error("Dokumen tidak dapat dibuka")
                stream.use { it.write(bytes) }
                runOnUiThread { reply.success(true) }
            } catch (_: Exception) {
                runOnUiThread { reply.error("write", "Dokumen gagal disimpan.", null) }
            }
        }.start()
    }
}
