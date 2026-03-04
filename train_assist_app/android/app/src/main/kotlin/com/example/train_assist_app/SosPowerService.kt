package com.example.train_assist_app

import android.app.*
import android.content.*
import android.os.*
import androidx.core.app.NotificationCompat

/**
 * SosPowerService — Foreground service that provides two reliable SOS triggers:
 *
 *  1. NOTIFICATION ACTION BUTTON — "🆘 TRIGGER SOS" in the persistent
 *     notification. Tappable from lock screen at any time. PRIMARY trigger.
 *
 *  2. SCREEN-OFF COUNTING (power-button backup) — 3 screen-off events within
 *     3 seconds fires the SOS. Works when phone is idle/locked.
 *
 * On trigger → invokes MethodChannel "power_sos" → Flutter handles GPS,
 * voice-note auto-record, upload, and auto-SMS send.
 */
class SosPowerService : Service() {

    private val channelId = "sos_guard_channel"
    private val notifId   = 9001

    companion object {
        const val ACTION_TRIGGER_SOS = "com.trainassist.TRIGGER_SOS"
    }

    // ── Screen-off counting (power-button backup) ────────────────────────────
    private val screenOffTimes = mutableListOf<Long>()

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            if (intent.action != Intent.ACTION_SCREEN_OFF) return
            val now = System.currentTimeMillis()
            screenOffTimes.add(now)
            screenOffTimes.removeAll { now - it > 3_000L }
            if (screenOffTimes.size >= 3) {
                screenOffTimes.clear()
                fireSos()
            }
        }
    }

    // ── Notification-button receiver ─────────────────────────────────────────
    private val sosButtonReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            if (intent.action == ACTION_TRIGGER_SOS) fireSos()
        }
    }

    override fun onCreate() {
        super.onCreate()
        registerReceiver(screenReceiver, IntentFilter(Intent.ACTION_SCREEN_OFF))
        val btnFilter = IntentFilter(ACTION_TRIGGER_SOS)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(sosButtonReceiver, btnFilter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(sosButtonReceiver, btnFilter)
        }
        startForeground(notifId, buildNotification())
    }

    override fun onDestroy() {
        try { unregisterReceiver(screenReceiver) }    catch (_: Exception) {}
        try { unregisterReceiver(sosButtonReceiver) } catch (_: Exception) {}
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun fireSos() {
        Handler(Looper.getMainLooper()).post {
            MainActivity.sosChannel?.invokeMethod("power_sos", null)
        }
    }

    private fun buildNotification(): Notification {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(channelId) == null) {
            nm.createNotificationChannel(
                NotificationChannel(channelId, "SOS Guard", NotificationManager.IMPORTANCE_HIGH)
                    .apply { description = "TrainAssist emergency SOS guard" }
            )
        }

        // Notification body tap → open app
        val openApp = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(
                this, 0, it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        // Action button → broadcast ACTION_TRIGGER_SOS
        val triggerPi = PendingIntent.getBroadcast(
            this, 1,
            Intent(ACTION_TRIGGER_SOS).setPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("TrainAssist SOS Guard Active")
            .setContentText("Vol-UP×3 in app  •  Tap button below for instant SOS →")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(openApp)
            .addAction(android.R.drawable.ic_delete, "🆘 TRIGGER SOS NOW", triggerPi)
            .build()
    }
}
