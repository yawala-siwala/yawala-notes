package com.yawalasiwala.yawala_notes

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Yawala Notes - Android runner bootstrap.
 *
 * Registers the `com.yawalasiwala/notes` method channel so the Dart layer can
 * drive secure export/import (SAF ACTION_CREATE_DOCUMENT / ACTION_OPEN_DOCUMENT)
 * and native markdown rendering bridges. Values below are safe-fallback stubs
 * until the real document-picker integration lands.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "exportNote", "importNoteFile" -> result.success(null)
                    "renderMarkdown" -> result.success(
                        mapOf(
                            "html" to "<p>stub</p>",
                            "usedNativeRenderer" to false,
                        ),
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private companion object {
        const val CHANNEL = "com.yawalasiwala/notes"
    }
}
