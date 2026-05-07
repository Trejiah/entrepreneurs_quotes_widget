package com.bakemono.businessmindset.bridge

import android.content.Context
import android.net.Uri
import androidx.core.content.edit
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import android.util.Log

/**
 * Clears the stored widget quote and enqueues a Glance [updateAll] **without**
 * blocking the UI thread and **without** waiting for Dart — used when the user
 * opens the app from `businessmindset://home` so the widget can show a new quote
 * immediately after, independently of the MethodChannel round-trip.
 */
object WidgetAutonomousRegenerator {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private const val REGEN_DELAY_MS = 300L

    fun startAfterHomeDeepLink(context: Context, url: String) {
        val uri = Uri.parse(url)
        if (!uri.host.equals("home", ignoreCase = true)) return

        val appCtx = context.applicationContext
        val fromLock = uri.getQueryParameter("source") == "lockscreen"

        scope.launch {
            // Small delay to let the app transition/open animation start before
            // the widget updates to the next quote.
            delay(REGEN_DELAY_MS)
            Log.d("WidgetTap", "AutonomousRegenerator: clearing prefs + forceNewQuote fromLock=$fromLock")
            val prefs = WidgetPrefs.get(appCtx)
            prefs.edit {
                if (fromLock) {
                    remove(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_QUOTE)
                    remove(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_FONT_SIZE)
                    putBoolean(WidgetPrefs.Keys.WIDGET_FORCE_NEW_QUOTE, true)
                    putBoolean(WidgetPrefs.Keys.WIDGET_FORCE_LOCKSCREEN_ONLY, true)
                } else {
                    remove(WidgetPrefs.Keys.WIDGET_QUOTE)
                    remove(WidgetPrefs.Keys.WIDGET_QUOTE_TIMESTAMP)
                    putBoolean(WidgetPrefs.Keys.WIDGET_FORCE_NEW_QUOTE, true)
                    putBoolean(WidgetPrefs.Keys.WIDGET_FORCE_LOCKSCREEN_ONLY, false)
                }
            }
            WidgetReloader.reloadAll(appCtx)
        }
    }
}
