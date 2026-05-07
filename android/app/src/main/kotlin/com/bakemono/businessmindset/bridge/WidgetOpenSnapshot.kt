package com.bakemono.businessmindset.bridge

import android.content.Context
import android.net.Uri
import android.util.Log

/**
 * One-shot copy of the quote shown on the widget **before** native code clears
 * prefs for regeneration. Filled in [MainActivity] when the user taps
 * `businessmindset://home`, consumed once by Flutter via [consumeWidgetOpenSnapshot].
 */
object WidgetOpenSnapshot {

    private val lock = Any()
    private var payload: HashMap<String, Any?>? = null

    /**
     * Snapshot prefs for the quote the user actually tapped (home vs lock-screen URL).
     * Must run **before** [WidgetAutonomousRegenerator] clears keys.
     */
    fun captureFromIntent(context: Context, url: String) {
        val uri = Uri.parse(url)
        if (!uri.host.equals("home", ignoreCase = true)) return

        val fromLock = uri.getQueryParameter("source") == "lockscreen"
        val quoteFromIntent = uri.getQueryParameter("quote")
        val signatureFromIntent = uri.getQueryParameter("signature")
        val bookFromIntent = uri.getQueryParameter("book")
        val urlFromIntent = uri.getQueryParameter("url")
        val hasIntentSnapshot = !quoteFromIntent.isNullOrBlank()
        val prefs = WidgetPrefs.get(context.applicationContext)

        synchronized(lock) {
            payload = if (fromLock) {
                hashMapOf(
                    "quote" to prefs.getString(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_QUOTE, null),
                    "signature" to prefs.getString(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_SIGNATURE, null),
                    "book" to prefs.getString(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_BOOK, null),
                    "url" to prefs.getString(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_URL, null),
                    "timestamp" to prefs.getDouble(WidgetPrefs.Keys.WIDGET_QUOTE_TIMESTAMP, 0.0),
                )
            } else {
                hashMapOf(
                    "quote" to (quoteFromIntent ?: prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE, null)),
                    "signature" to (signatureFromIntent ?: prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE_SIGNATURE, null)),
                    "book" to (bookFromIntent ?: prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE_BOOK, null)),
                    "url" to (urlFromIntent ?: prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE_URL, null)),
                    "timestamp" to prefs.getDouble(WidgetPrefs.Keys.WIDGET_QUOTE_TIMESTAMP, 0.0),
                )
            }
            val qlen = (payload?.get("quote") as? String)?.length ?: 0
            Log.d(
                "WidgetTap",
                "captureFromIntent fromLock=$fromLock quoteLen=$qlen intentSnapshot=$hasIntentSnapshot",
            )
        }
    }

    fun takeAndClear(): Map<String, Any?>? {
        synchronized(lock) {
            val p = payload
            payload = null
            val qlen = (p?.get("quote") as? String)?.length ?: 0
            Log.d("WidgetTap", "takeAndClear consumed quoteLen=$qlen hadPayload=${p != null}")
            return p
        }
    }
}
