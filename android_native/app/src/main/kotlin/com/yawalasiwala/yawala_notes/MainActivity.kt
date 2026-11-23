package com.yawalasiwala.yawala_notes

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Native host for Yawala Notes: real SAF document export/import over the
/// `com.yawalasiwala/notes` channel. Markdown rendering stays on the Dart
/// fallback (notImplemented) until a native renderer is added.
class MainActivity : FlutterActivity() {
    private var exportResult: MethodChannel.Result? = null
    private var pendingExportContent: String? = null
    private var importResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "exportNote" -> exportNote(
                        call.argument<String>("fileName") ?: "note.md",
                        call.argument<String>("content") ?: "",
                        result
                    )
                    "importNoteFile" -> importNoteFile(result)
                    "renderMarkdown" -> result.notImplemented()
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_EXPORT -> {
                val result = exportResult
                val content = pendingExportContent ?: ""
                exportResult = null
                pendingExportContent = null
                if (result == null) {
                    return
                }
                val uri: Uri? = data?.data
                if (resultCode != Activity.RESULT_OK || uri == null) {
                    // Cancelled (or unsupported): null means cancelled.
                    result.success(null)
                    return
                }
                try {
                    contentResolver.openOutputStream(uri)?.use { stream ->
                        stream.write(content.toByteArray(Charsets.UTF_8))
                    }
                    result.success(uri.toString())
                } catch (error: Exception) {
                    result.success(null)
                }
            }
            REQUEST_IMPORT -> {
                val result = importResult
                importResult = null
                if (result == null) {
                    return
                }
                val uri: Uri? = data?.data
                if (resultCode != Activity.RESULT_OK || uri == null) {
                    result.success(null)
                    return
                }
                try {
                    val text = contentResolver.openInputStream(uri)?.use { stream ->
                        stream.readBytes().toString(Charsets.UTF_8)
                    } ?: ""
                    val name = queryDisplayName(uri) ?: "imported.md"
                    result.success(mapOf("fileName" to name, "content" to text))
                } catch (error: Exception) {
                    result.success(null)
                }
            }
        }
    }

    private fun exportNote(fileName: String, content: String, result: MethodChannel.Result) {
        try {
            exportResult = result
            pendingExportContent = content
            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "text/markdown"
                putExtra(Intent.EXTRA_TITLE, fileName)
            }
            startActivityForResult(intent, REQUEST_EXPORT)
        } catch (error: Exception) {
            exportResult = null
            pendingExportContent = null
            result.success(null)
        }
    }

    private fun importNoteFile(result: MethodChannel.Result) {
        try {
            importResult = result
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "text/*"
            }
            startActivityForResult(intent, REQUEST_IMPORT)
        } catch (error: Exception) {
            importResult = null
            result.success(null)
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        return try {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }
        } catch (error: Exception) {
            null
        }
    }

    companion object {
        private const val CHANNEL = "com.yawalasiwala/notes"
        private const val REQUEST_EXPORT = 4101
        private const val REQUEST_IMPORT = 4102
    }
}
