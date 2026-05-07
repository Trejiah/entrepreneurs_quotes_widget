package com.bakemono.businessmindset.bridge

import android.app.NotificationManager
import android.content.Context
import androidx.core.content.edit
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONArray
import org.json.JSONObject

/**
 * Implementation of the `businessmindset/deeplink` MethodChannel — Android
 * counterpart of the Swift handler in [ios/Runner/AppDelegate.swift]. Every
 * key in this file matches the iOS implementation 1:1 so the same Dart-side
 * payloads work unchanged.
 */
class DeepLinkChannelHandler(
    private val context: Context,
) : MethodChannel.MethodCallHandler {

    // Scope tied to this handler instance. SupervisorJob so one failing
    // launch doesn't cancel the others. Dispatchers.Main.immediate so
    // result callbacks are delivered on the platform thread (required by
    // the Flutter MethodChannel contract).
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    /**
     * Serializes [forceWidgetNewQuote] / [forceLockScreenWidgetNewQuote] so two
     * concurrent calls do not interleave prefs edits before [WidgetReloader.reloadAll].
     */
    private val forceWidgetMutex = Mutex()
    private val updateWidgetMutex = Mutex()

    private val prefs get() = WidgetPrefs.get(context)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "reloadWidgets" -> {
                WidgetReloader.reloadAll(context)
                result.success(null)
            }
            "updateWidgetData" -> scope.launch { handleUpdateWidgetData(call, result) }
            "getWidgetFavorites" -> result.success(getStringList(WidgetPrefs.Keys.WIDGET_FAVORITES))
            "getWidgetStoredQuote" -> handleGetWidgetStoredQuote(result)
            "consumeWidgetOpenSnapshot" -> {
                result.success(WidgetOpenSnapshot.takeAndClear())
            }
            "setOpenedFromLockScreen" -> {
                prefs.edit { putBoolean(WidgetPrefs.Keys.OPENED_FROM_LOCK_SCREEN, true) }
                result.success(null)
            }
            "getOpenedFromLockScreen" -> {
                result.success(prefs.getBoolean(WidgetPrefs.Keys.OPENED_FROM_LOCK_SCREEN, false))
            }
            "resetOpenedFromLockScreen" -> {
                prefs.edit { putBoolean(WidgetPrefs.Keys.OPENED_FROM_LOCK_SCREEN, false) }
                result.success(null)
            }
            "forceWidgetNewQuote" -> scope.launch { handleForceWidgetNewQuote(result) }
            "forceLockScreenWidgetNewQuote" -> scope.launch { handleForceLockScreenWidgetNewQuote(result) }
            "setLockscreenForcedQuote" -> handleSetLockscreenForcedQuote(call, result)
            "getLockscreenForcedQuote" -> {
                result.success(prefs.getString(WidgetPrefs.Keys.LOCKSCREEN_FORCED_QUOTE, null))
            }
            "clearLockscreenForcedQuote" -> {
                prefs.edit { remove(WidgetPrefs.Keys.LOCKSCREEN_FORCED_QUOTE) }
                result.success(null)
            }
            "generateShareImage", "generateShareImageBytes" -> {
                // On Android we render the share card with Flutter's
                // RepaintBoundary (see [lib/services/share_quotes.dart]),
                // so the native side intentionally has no equivalent of the
                // SwiftUI generator. Returning notImplemented signals Dart to
                // take the cross-platform fallback path.
                result.notImplemented()
            }
            "shareImageDirect" -> MediaChannelHandler.shareImage(context, call, result)
            "saveImageToGallery" -> MediaChannelHandler.saveImage(context, call, result)
            "getAppGroupPath" -> {
                // Android has no App Group concept — both the app and the
                // widget run in the same process, so the regular files dir
                // is the equivalent shared sandbox.
                result.success(context.filesDir.absolutePath)
            }
            "cancelAllIosPendingNotifications" -> {
                // Same name as iOS for backwards compatibility (the Dart side
                // calls this method on both platforms).
                NotificationManagerCompat.from(context).cancelAll()
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                nm?.cancelAll()
                result.success(null)
            }
            "setHardPaywallQuotesBlocked" -> {
                val blocked = (call.arguments as? Map<*, *>)?.get("blocked") as? Boolean ?: false
                prefs.edit { putBoolean(WidgetPrefs.Keys.HARD_PAYWALL_BLOCK_QUOTES, blocked) }
                WidgetReloader.reloadAll(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------------
    // Handlers
    // ---------------------------------------------------------------------

    private fun handleGetWidgetStoredQuote(result: MethodChannel.Result) {
        val openedFromLockScreen = prefs.getBoolean(WidgetPrefs.Keys.OPENED_FROM_LOCK_SCREEN, false)

        val payload = if (openedFromLockScreen) {
            mapOf(
                "quote" to prefs.getString(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_QUOTE, null),
                "signature" to prefs.getString(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_SIGNATURE, null),
                "book" to prefs.getString(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_BOOK, null),
                "url" to prefs.getString(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_URL, null),
                "timestamp" to prefs.getDouble(WidgetPrefs.Keys.WIDGET_QUOTE_TIMESTAMP, 0.0),
            )
        } else {
            mapOf(
                "quote" to prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE, null),
                "signature" to prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE_SIGNATURE, null),
                "book" to prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE_BOOK, null),
                "url" to prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE_URL, null),
                "timestamp" to prefs.getDouble(WidgetPrefs.Keys.WIDGET_QUOTE_TIMESTAMP, 0.0),
            )
        }
        result.success(payload)
    }

    private suspend fun handleForceWidgetNewQuote(result: MethodChannel.Result) {
        forceWidgetMutex.withLock {
            handleForceWidgetNewQuoteLocked(result)
        }
    }

    private fun handleForceWidgetNewQuoteLocked(result: MethodChannel.Result) {
        val openedFromLockScreen = prefs.getBoolean(WidgetPrefs.Keys.OPENED_FROM_LOCK_SCREEN, false)
        android.util.Log.d("WidgetDebug", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        android.util.Log.d("WidgetDebug", "🔄 [Bridge] forceWidgetNewQuote called (mutex acquired)")
        android.util.Log.d("WidgetDebug", "   openedFromLockScreen=$openedFromLockScreen")
        prefs.edit(commit = true) {
            if (openedFromLockScreen) {
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
        WidgetReloader.reloadAll(context)
        android.util.Log.d("WidgetDebug", "   reloadAll (fire-and-forget) → result.success")
        android.util.Log.d("WidgetDebug", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        result.success(null)
    }

    private suspend fun handleForceLockScreenWidgetNewQuote(result: MethodChannel.Result) {
        forceWidgetMutex.withLock {
            android.util.Log.d("WidgetDebug", "🔄 [Bridge] forceLockScreenWidgetNewQuote (mutex acquired)")
            prefs.edit {
                remove(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_QUOTE)
                remove(WidgetPrefs.Keys.WIDGET_LOCKSCREEN_FONT_SIZE)
                putBoolean(WidgetPrefs.Keys.WIDGET_FORCE_NEW_QUOTE, true)
            }
            WidgetReloader.reloadAll(context)
            android.util.Log.d("WidgetDebug", "🔄 [Bridge] forceLockScreenWidgetNewQuote done")
            result.success(null)
        }
    }

    private fun handleSetLockscreenForcedQuote(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val quote = args?.get("quote") as? String
        if (quote == null) {
            result.error("INVALID_ARGUMENTS", "Expected quote parameter", null)
            return
        }
        prefs.edit { putString(WidgetPrefs.Keys.LOCKSCREEN_FORCED_QUOTE, quote) }
        result.success(null)
    }

    @Suppress("UNCHECKED_CAST")
    private suspend fun handleUpdateWidgetData(call: MethodCall, result: MethodChannel.Result) {
        val payload = call.arguments as? Map<String, Any?>
        if (payload == null) {
            result.error("INVALID_ARGUMENTS", "Expected dictionary for updateWidgetData", null)
            return
        }

        // Mirror the iOS write semantics: the explicit `configured:true` call
        // is the only one allowed to mutate widgetThemeIndex once the widget
        // has been added to the homescreen.
        val widgetAlreadyConfigured = prefs.getBoolean(WidgetPrefs.Keys.WIDGET_CONFIGURED, false)
        val isWidgetConfigCall = (payload["configured"] as? Boolean) == true

        updateWidgetMutex.withLock {
            prefs.edit(commit = true) {
                (payload["configured"] as? Boolean)?.let {
                    putBoolean(WidgetPrefs.Keys.WIDGET_CONFIGURED, it)
                }

                (payload["themeIndex"] as? Int)?.let { themeIndex ->
                    if (!widgetAlreadyConfigured || isWidgetConfigCall) {
                        putInt(WidgetPrefs.Keys.WIDGET_THEME_INDEX, themeIndex)
                    }
                    if (payload["isCustomTheme"] != null) {
                        putInt(WidgetPrefs.Keys.THEME_INDEX_APP, themeIndex)
                    }
                }
                (payload["isCustomTheme"] as? Boolean)?.let {
                    putBoolean(WidgetPrefs.Keys.WIDGET_IS_CUSTOM_THEME, it)
                    putBoolean(WidgetPrefs.Keys.IS_CUSTOM_THEME_APP, it)
                }

                (payload["customThemes"] as? List<Map<String, Any?>>)?.let { customThemes ->
                    putString(WidgetPrefs.Keys.THEME_CUSTOM_DATAS, customThemes.toJsonArray().toString())
                }

                (payload["language"] as? String)?.let { putString(WidgetPrefs.Keys.LANGUAGE, it) }

                (payload["quote"] as? String)?.let { quote ->
                    putString(WidgetPrefs.Keys.WIDGET_QUOTE, quote)
                    putDouble(WidgetPrefs.Keys.WIDGET_QUOTE_TIMESTAMP, System.currentTimeMillis() / 1000.0)
                    putBoolean(WidgetPrefs.Keys.WIDGET_QUOTE_WAS_CHOSEN, true)
                }

                (payload["widgetQuoteDetails"] as? Map<String, Any?>)?.let { details ->
                    putString(WidgetPrefs.Keys.WIDGET_QUOTE_DETAILS, details.toJsonObject().toString())
                    (details["signature"] as? String)?.let { putString(WidgetPrefs.Keys.WIDGET_QUOTE_SIGNATURE, it) }
                    (details["bookTitle"] as? String)?.let { putString(WidgetPrefs.Keys.WIDGET_QUOTE_BOOK, it) }
                    (details["url"] as? String)?.let { putString(WidgetPrefs.Keys.WIDGET_QUOTE_URL, it) }
                    (details["languageCode"] as? String)?.let { putString(WidgetPrefs.Keys.WIDGET_QUOTE_LANGUAGE, it) }
                }

                (payload["topics"] as? List<*>)?.let { topics ->
                    putStringSet(WidgetPrefs.Keys.WIDGET_TOPICS, topics.filterIsInstance<String>().toSet())
                }

                (payload["favorites"] as? List<Map<String, Any?>>)?.let { favorites ->
                    putString(WidgetPrefs.Keys.WIDGET_FAVORITES, favorites.toJsonArray().toString())
                }

                (payload["frequency"] as? String)?.let { putString(WidgetPrefs.Keys.WIDGET_FREQUENCY, it) }

                (payload["buttons"] as? List<*>)?.let { buttons ->
                    putStringSet(WidgetPrefs.Keys.WIDGET_BUTTONS, buttons.filterIsInstance<String>().toSet())
                }

                (payload["isPremium"] as? Boolean)?.let { putBoolean(WidgetPrefs.Keys.IS_PREMIUM, it) }
                val premiumExpirationEpochMs = (payload["premiumExpirationEpochMs"] as? Number)?.toLong()
                if (premiumExpirationEpochMs != null && premiumExpirationEpochMs > 0L) {
                    putLong(WidgetPrefs.Keys.PREMIUM_EXPIRATION_EPOCH_MS, premiumExpirationEpochMs)
                } else {
                    remove(WidgetPrefs.Keys.PREMIUM_EXPIRATION_EPOCH_MS)
                }

                (payload["planGrowthPercentage"] as? Number)?.let {
                    putDouble(WidgetPrefs.Keys.PLAN_GROWTH, it.toDouble())
                }
                (payload["planDisciplinePercentage"] as? Number)?.let {
                    putDouble(WidgetPrefs.Keys.PLAN_DISCIPLINE, it.toDouble())
                }
                (payload["planConfidencePercentage"] as? Number)?.let {
                    putDouble(WidgetPrefs.Keys.PLAN_CONFIDENCE, it.toDouble())
                }
                (payload["planStrategyPercentage"] as? Number)?.let {
                    putDouble(WidgetPrefs.Keys.PLAN_STRATEGY, it.toDouble())
                }

                (payload["userName"] as? String)?.let { name ->
                    putString(WidgetPrefs.Keys.USER_NAME, name)
                    putString(WidgetPrefs.Keys.USER_NAME_LEGACY, name)
                }

                (payload["gender"] as? String)?.let {
                    putString(WidgetPrefs.Keys.GENDER, it)
                }
                (payload["affirmationPercentage"] as? Number)?.let {
                    putInt(WidgetPrefs.Keys.TONE_AFFIRMATION, it.toInt())
                }
                (payload["noMercyPercentage"] as? Number)?.let {
                    putInt(WidgetPrefs.Keys.TONE_NO_MERCY, it.toInt())
                }
            }

            val payloadThemeIndex = payload["themeIndex"] as? Int
            val payloadIsCustom = payload["isCustomTheme"] as? Boolean
            android.util.Log.d(
                "WidgetTap",
                "handleUpdateWidgetData committed: payload(themeIndex=$payloadThemeIndex isCustom=$payloadIsCustom) " +
                    "stored(themeIndex=${prefs.getInt(WidgetPrefs.Keys.WIDGET_THEME_INDEX, -1)} " +
                    "isCustom=${prefs.getBoolean(WidgetPrefs.Keys.WIDGET_IS_CUSTOM_THEME, false)}) " +
                    "configured=${prefs.getBoolean(WidgetPrefs.Keys.WIDGET_CONFIGURED, false)} " +
                    "isPremium=${prefs.getBoolean(WidgetPrefs.Keys.IS_PREMIUM, false)} " +
                    "hardPaywall=${prefs.getBoolean(WidgetPrefs.Keys.HARD_PAYWALL_BLOCK_QUOTES, false)}",
            )
            WidgetReloader.reloadAllSuspend(context)
            // Some Android launchers/glance sessions coalesce rapid updates and may
            // visually miss one theme frame. For explicit theme mutations, run a
            // second pass shortly after to make the homescreen repaint deterministic.
            val themeMutated = payload.containsKey("themeIndex") || payload.containsKey("isCustomTheme")
            if (themeMutated) {
                delay(120)
                android.util.Log.d("WidgetTap", "handleUpdateWidgetData second-pass refresh (theme mutation)")
                WidgetReloader.reloadAllSuspend(context)
            }
        }
        result.success(null)
    }

    // ---------------------------------------------------------------------
    // Helpers (SharedPreferences <-> JSON / collections)
    // ---------------------------------------------------------------------

    private fun getStringList(key: String): List<Map<String, Any?>> {
        val raw = prefs.getString(key, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).mapNotNull { i ->
                (arr.opt(i) as? JSONObject)?.toMap()
            }
        } catch (t: Throwable) {
            emptyList()
        }
    }

}

// Doubles aren't first-class in SharedPreferences (only float / long).
// We encode them as the bit pattern of a long so we don't lose precision.
internal fun android.content.SharedPreferences.Editor.putDouble(key: String, value: Double) =
    putLong(key, java.lang.Double.doubleToRawLongBits(value))

internal fun android.content.SharedPreferences.getDouble(key: String, default: Double): Double =
    if (!contains(key)) default else java.lang.Double.longBitsToDouble(getLong(key, 0L))

private fun List<Map<String, Any?>>.toJsonArray(): JSONArray {
    val arr = JSONArray()
    forEach { arr.put(it.toJsonObject()) }
    return arr
}

private fun Map<String, Any?>.toJsonObject(): JSONObject {
    val obj = JSONObject()
    for ((k, v) in this) {
        if (v == null) continue
        when (v) {
            is Map<*, *> -> {
                @Suppress("UNCHECKED_CAST")
                obj.put(k, (v as Map<String, Any?>).toJsonObject())
            }
            is List<*> -> {
                val nested = JSONArray()
                v.filterNotNull().forEach { item ->
                    when (item) {
                        is Map<*, *> -> {
                            @Suppress("UNCHECKED_CAST")
                            nested.put((item as Map<String, Any?>).toJsonObject())
                        }
                        else -> nested.put(item)
                    }
                }
                obj.put(k, nested)
            }
            else -> obj.put(k, v)
        }
    }
    return obj
}

private fun JSONObject.toMap(): Map<String, Any?> {
    val out = mutableMapOf<String, Any?>()
    val it = keys()
    while (it.hasNext()) {
        val key = it.next()
        out[key] = when (val raw = opt(key)) {
            JSONObject.NULL -> null
            is JSONObject -> raw.toMap()
            is JSONArray -> (0 until raw.length()).map { raw.opt(it) }
            else -> raw
        }
    }
    return out
}
