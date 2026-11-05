package com.thodar.app

import android.content.Intent
import android.provider.Settings
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vernacura/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // The TTS engine's voice download screen (Google: "Install voice data"),
                    // falling back to system TTS settings, then general settings.
                    "openTtsInstaller" -> result.success(
                        tryStart(Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA)) ||
                            tryStart(Intent("com.android.settings.TTS_SETTINGS")) ||
                            tryStart(Intent(Settings.ACTION_SETTINGS))
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun tryStart(intent: Intent): Boolean = try {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }
}
