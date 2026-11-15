package com.example.sample_aplikasi

import android.app.Activity
import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.view.WindowManager
import android.os.Build
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
        MethodChannel(engine.dartExecutor.binaryMessenger, "markaz/exam").setMethodCallHandler { call, reply ->
            val manager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
            val policy = getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
            fun locked(): Boolean = if (Build.VERSION.SDK_INT >= 23) {
                manager.lockTaskModeState == ActivityManager.LOCK_TASK_MODE_LOCKED
            } else false
            try {
                when (call.method) {
                    "active" -> reply.success(locked())
                    "begin" -> {
                        if (Build.VERSION.SDK_INT < 23 || !policy.isLockTaskPermitted(packageName)) {
                            reply.error("not_managed", "Perangkat belum diizinkan oleh pengelola untuk Lock Task. Hubungi pengawas.", null)
                        } else {
                            if (!locked()) startLockTask()
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            window.decorView.post {
                                if (locked()) reply.success(true) else {
                                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                                    reply.error("lock_failed", "Penguncian perangkat gagal. Ujian belum dimulai.", null)
                                }
                            }
                        }
                    }
                    "end" -> {
                        if (locked()) stopLockTask()
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        reply.success(null)
                    }
                    else -> reply.notImplemented()
                }
            } catch (e: Exception) { reply.error("assessment", e.message, null) }
        }
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
