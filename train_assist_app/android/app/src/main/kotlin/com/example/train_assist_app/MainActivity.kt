package com.example.train_assist_app

import android.content.Intent
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SmsManager
import android.view.KeyEvent
import android.media.MediaRecorder
import android.util.Log
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        /** Shared with SosPowerService so it can call back into Flutter */
        var sosChannel: MethodChannel? = null
    }

    // ── Volume-UP triple-press detection ─────────────────────────────────────
    // Counts volume-UP key-down events; fires SOS if 3 within 2 seconds.
    // Only works while the app is in the foreground / screen on.
    private val volUpTimes = mutableListOf<Long>()

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP &&
            event.action  == KeyEvent.ACTION_DOWN) {

            val now = System.currentTimeMillis()
            volUpTimes.add(now)
            volUpTimes.removeAll { now - it > 2_000L }   // 2-second window

            if (volUpTimes.size >= 3) {
                volUpTimes.clear()
                // Fire SOS — same as notification button / screen-off trigger
                Handler(Looper.getMainLooper()).post {
                    sosChannel?.invokeMethod("power_sos", null)
                }
                return true   // Consume event so volume doesn't change
            }
        }
        return super.dispatchKeyEvent(event)
    }

    // ── Flutter Engine / MethodChannel setup ─────────────────────────────────
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sosChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.trainassist/sos"
        )

        // Recorder state (native fallback for reliable file creation)
        var mediaRecorder: MediaRecorder? = null
        var currentRecordingPath: String? = null

        sosChannel?.setMethodCallHandler { call, result ->
            when (call.method) {

                // ── Start / stop SOS guard foreground service ──────────────
                "startSosService" -> {
                    startService(Intent(this, SosPowerService::class.java))
                    result.success(null)
                }
                "stopSosService" -> {
                    stopService(Intent(this, SosPowerService::class.java))
                    result.success(null)
                }

                // ── Auto-send a single SMS without opening the composer ────
                // Requires android.permission.SEND_SMS granted at runtime.
                // Flutter should request the permission first; if denied, use
                // the SMS composer fallback (url_launcher sms: URI).
                "sendSms" -> {
                    val phone = call.argument<String>("phone")
                    val body  = call.argument<String>("body")
                    if (phone.isNullOrBlank() || body.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "phone and body required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val sm = if (Build.VERSION.SDK_INT >= 31)
                            getSystemService(SmsManager::class.java)
                        else
                            @Suppress("DEPRECATION") SmsManager.getDefault()

                        val parts = sm.divideMessage(body)
                        sm.sendMultipartTextMessage(phone, null, parts, null, null)
                        result.success("sent")
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", e.message, null)
                    }
                }

                // Start native audio recording and return file path in app files dir
                "startRecording" -> {
                    try {
                        val recordingsDir = File(filesDir, "TrainAssist/SOSRecordings")
                        if (!recordingsDir.exists()) recordingsDir.mkdirs()
                        val outFile = File(recordingsDir, "sos_${System.currentTimeMillis()}.m4a")

                        mediaRecorder = MediaRecorder()
                        mediaRecorder?.setAudioSource(MediaRecorder.AudioSource.MIC)
                        mediaRecorder?.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                        mediaRecorder?.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                        mediaRecorder?.setAudioSamplingRate(44100)
                        mediaRecorder?.setAudioEncodingBitRate(96000)
                        mediaRecorder?.setOutputFile(outFile.absolutePath)
                        mediaRecorder?.prepare()
                        mediaRecorder?.start()

                        currentRecordingPath = outFile.absolutePath
                        result.success(currentRecordingPath)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "startRecording failed", e)
                        try { mediaRecorder?.release() } catch (_: Exception) {}
                        mediaRecorder = null
                        currentRecordingPath = null
                        result.error("RECORD_FAILED", e.message, null)
                    }
                }

                // Stop native recording and return saved file path (or error)
                "stopRecording" -> {
                    try {
                        mediaRecorder?.stop()
                        mediaRecorder?.release()
                        mediaRecorder = null
                        val saved = currentRecordingPath
                        currentRecordingPath = null
                        if (saved == null) {
                            result.error("NO_RECORDING", "No recording in progress", null)
                        } else {
                            result.success(saved)
                        }
                    } catch (e: Exception) {
                        Log.e("MainActivity", "stopRecording failed", e)
                        try { mediaRecorder?.release() } catch (_: Exception) {}
                        mediaRecorder = null
                        currentRecordingPath = null
                        result.error("STOP_FAILED", e.message, null)
                    }
                }

                "enableAutoWhatsAppSend" -> {
                    val duration = call.argument<Number>("durationMs")?.toLong() ?: 15000L
                    try {
                        val prefs = getSharedPreferences("train_assist_prefs", Context.MODE_PRIVATE)
                        prefs.edit().putLong("auto_whatsapp_send_until", System.currentTimeMillis() + duration).apply()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("PREF_ERROR", e.message, null)
                    }
                }
                "disableAutoWhatsAppSend" -> {
                    try {
                        val prefs = getSharedPreferences("train_assist_prefs", Context.MODE_PRIVATE)
                        prefs.edit().putLong("auto_whatsapp_send_until", 0L).apply()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("PREF_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
