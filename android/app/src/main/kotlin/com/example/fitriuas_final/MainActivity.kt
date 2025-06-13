package com.example.fitriuas_final

import io.flutter.embedding.android.FlutterActivity // Gunakan FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() { // Ganti FlutterFragmentActivity menjadi FlutterActivity
    private val CHANNEL = "samples.flutter.dev/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            // Logika channel (bisa dihapus jika tidak digunakan)
            result.notImplemented()
        }
    }
}