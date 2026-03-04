package com.example.train_assist_app

import android.app.*
import android.content.*
import android.os.*
import androidx.core.app.NotificationCompat

/**
 * Foreground service that listens for rapid screen-off events.
 * When the user presses the power button 3× within 3 seconds → calls Flutter
 * via MethodChannel("com.trainassist/sos") → "power_sos".
 *
 * Note: ACTION_SCREEN_OFF/ON must be registered dynamically (cannot be in manifest).
 * This service keeps the registration alive even when the app is in the background.
 */
class SosPowerService : Service() {

    private val channelId = "sos_guard_channel"
    private val notifId   = 9001

    // Timestamps of recent screen-OFF events
    private val screenOffTimes = mutableListOf<Long>()

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            if (intent.action != Intent.ACTION_SCREEN_OFF) return

            val now = System.currentTimeMillis()
            screenOffTimes.add(now)
            // Keep only events within last 3 seconds
            screenOffTimes.removeAll { now - it > 3_000L }

            if (screenOffTimes.size >= 3) {
                screenOffTimes.clear()
                // Fire the Flutter callback on main thread
                Handler(Looper.getMainLooper()).post {
                    MainActivity.sosChannel?.invokeMethod("power_sos", null)
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(screenReceiver, filter)
        startForeground(notifId, buildNotification())
    }

    override fun onDestroy() {
        try { unregisterReceiver(screenReceiver) } catch (_: Exception) {}
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(): Notification {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(channelId) == null) {
            nm.createNotificationChannel(
                NotificationChannel(channelId, "SOS Guard", NotificationManager.IMPORTANCE_LOW)
            )
        }
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("TrainAssist SOS Guard")
            .setContentText("Press power button 3× quickly for emergency SOS")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setOngoing(true)
            .build()
    }
}
