package com.example.train_assist_app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        // Shared so SosPowerService can call back into Flutter
        var sosChannel: MethodChannel? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sosChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.trainassist/sos"
        )

        sosChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startSosService" -> {
                    startService(Intent(this, SosPowerService::class.java))
                    result.success(null)
                }
                "stopSosService" -> {
                    stopService(Intent(this, SosPowerService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
