package com.bakemono.businessmindset.bridge

import android.content.Context
import android.util.Log
import com.bakemono.businessmindset.widget.BusinessMindsetWidget
import com.bakemono.businessmindset.widget.WidgetRefreshScheduler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Triggers a refresh of every widget instance currently placed on the
 * user's homescreen / lockscreen. Mirrors `WidgetCenter.shared.reloadAllTimelines()`
 * on iOS.
 *
 * Two variants are provided:
 *
 * - [reloadAllSuspend] — awaits the full widget repaint before returning.
 *   Use this for user-initiated actions (e.g. forceWidgetNewQuote) where the
 *   caller needs to know the launcher already has the new RemoteViews before
 *   returning control to Flutter. Mirrors how iOS's WidgetCenter.reloadTimelines
 *   completes before the AppDelegate returns result(nil) to Flutter.
 *
 * - [reloadAll] — fire-and-forget; fine for background/automatic refreshes.
 */
object WidgetReloader {
    private const val TAG = "WidgetReloader"

    /**
     * Suspending version: awaits [BusinessMindsetWidget.updateAll] so the
     * caller can be sure the Launcher already holds the new RemoteViews when
     * this function returns. Must be called from a coroutine.
     */
    suspend fun reloadAllSuspend(context: Context) {
        val appCtx = context.applicationContext
        Log.d(TAG, "⏳ [Reloader] updateAll START (thread=${Thread.currentThread().name})")
        val t0 = System.currentTimeMillis()
        try {
            BusinessMindsetWidget.updateAll(appCtx)
            Log.d(TAG, "✅ [Reloader] updateAll DONE in ${System.currentTimeMillis() - t0}ms")
        } catch (t: Throwable) {
            Log.w(TAG, "❌ [Reloader] updateAll FAILED in ${System.currentTimeMillis() - t0}ms: ${t.message}")
        }
        // Re-align the next-slot worker.
        try {
            WidgetRefreshScheduler.enqueueNext(appCtx)
            Log.d(TAG, "📅 [Reloader] next WorkManager slot enqueued")
        } catch (t: Throwable) {
            Log.w(TAG, "Scheduler enqueue failed: ${t.message}")
        }
    }

    /** Fire-and-forget variant for callers that do not need to await the result. */
    fun reloadAll(context: Context) {
        val appCtx = context.applicationContext
        Log.d(TAG, "🔥 [Reloader] reloadAll (fire-and-forget)")
        CoroutineScope(Dispatchers.Default).launch {
            reloadAllSuspend(appCtx)
        }
    }

    /** True when at least one widget instance is currently placed. */
    suspend fun hasActiveInstances(context: Context): Boolean = try {
        BusinessMindsetWidget.hasActiveInstances(context.applicationContext)
    } catch (t: Throwable) {
        false
    }
}
