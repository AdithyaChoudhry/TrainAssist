package com.example.train_assist_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.Context
import android.util.Log

class AccessibilityAutoSendService : AccessibilityService() {

    override fun onServiceConnected() {
        val info = AccessibilityServiceInfo()
        // We want to receive window content changes and view clicked events
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.packageNames = arrayOf("com.whatsapp", "com.whatsapp.w4b")
        info.flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        try {
            val pkg = event.packageName?.toString() ?: return
                Log.d("AutoSendService", "onAccessibilityEvent pkg=$pkg eventType=${event.eventType}")
                if (pkg != "com.whatsapp" && pkg != "com.whatsapp.w4b") return

            val prefs = getSharedPreferences("train_assist_prefs", Context.MODE_PRIVATE)
            val until = prefs.getLong("auto_whatsapp_send_until", 0L)
            if (System.currentTimeMillis() > until) return

            val root = rootInActiveWindow ?: return
            Log.d("AutoSendService", "rootInActiveWindow present, searching for send nodes")
            // Search for common WhatsApp send button by resource-id or text
            val sendNodes = ArrayList<AccessibilityNodeInfo>()
            // Try by view id (typical WhatsApp id)
            root.findAccessibilityNodeInfosByViewId("com.whatsapp:id/send")?.let { sendNodes.addAll(it) }
            root.findAccessibilityNodeInfosByViewId("com.whatsapp:id/send_button")?.let { sendNodes.addAll(it) }

            // Try by text 'Send' — covers different locales poorly but often works
            root.findAccessibilityNodeInfosByText("Send")?.let { sendNodes.addAll(it) }

            Log.d("AutoSendService", "found sendNodes=${sendNodes.size}")
            // If we found something clickable, click the first and clear the flag
            for (node in sendNodes) {
                try {
                    if (node.isClickable) {
                        Log.d("AutoSendService", "clicking node")
                        node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                        prefs.edit().putLong("auto_whatsapp_send_until", 0L).apply()
                        break
                    } else {
                        // try to click parent
                        var p = node.parent
                        while (p != null) {
                            if (p.isClickable) {
                                Log.d("AutoSendService", "clicking parent node")
                                p.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                                prefs.edit().putLong("auto_whatsapp_send_until", 0L).apply()
                                break
                            }
                            p = p.parent
                        }
                    }
                } catch (e: Exception) {
                    Log.d("AutoSendService", "click attempt failed: ${e.message}")
                }
            }
        } catch (e: Exception) {
            // Swallow errors — accessibility service should be robust
        }
    }

    override fun onInterrupt() {}
}
