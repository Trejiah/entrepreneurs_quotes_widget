package com.bakemono.businessmindset.widget

import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.bakemono.businessmindset.bridge.WidgetPrefs
import com.bakemono.businessmindset.widget.quotes.QuoteLibrary
import com.bakemono.businessmindset.widget.quotes.WidgetUpdateFrequency
import java.time.Instant
import java.util.concurrent.TimeUnit

/**
 * Aligns widget refreshes with the same per-slot contract used by the iOS
 * `Timeline(policy: .after(nextTrigger))`:
 *
 *   - On every relevant lifecycle event (widget added, reload from Dart,
 *     user-initiated refresh, worker finishing), compute the next slot
 *     boundary via [QuoteLibrary.schedule] and enqueue a single
 *     [WidgetRefreshWorker] `OneTimeWorkRequest` with an `initialDelay`
 *     equal to `nextTrigger - now`.
 *   - Use [ExistingWorkPolicy.REPLACE] on the unique work name so the new
 *     target always overrides any previously-queued slot — this keeps us
 *     in sync when the user switches frequencies.
 *
 * The OneTimeWorkRequest is intentionally inexact: we don't care about
 * second-level precision, we care about "a quote refresh every N hours
 * within the user's chosen cadence". This is also why we don't hold
 * SCHEDULE_EXACT_ALARM — requesting it would be rejected on Android 14+
 * for an app that isn't an alarm clock.
 */
object WidgetRefreshScheduler {
    const val UNIQUE_WORK_NAME = "business_mindset_widget_refresh"

    private const val MIN_DELAY_MS = 60_000L

    fun enqueueNext(context: Context) {
        val appCtx = context.applicationContext
        val prefs = WidgetPrefs.get(appCtx)
        val frequency = WidgetUpdateFrequency.from(
            prefs.getString(WidgetPrefs.Keys.WIDGET_FREQUENCY, null),
        )
        val now = Instant.now()
        val schedule = QuoteLibrary.schedule(frequency, now)

        val rawDelay = schedule.nextTrigger.toEpochMilli() - now.toEpochMilli()
        val delay = rawDelay.coerceAtLeast(MIN_DELAY_MS)

        val request = OneTimeWorkRequestBuilder<WidgetRefreshWorker>()
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setConstraints(Constraints.NONE)
            .build()

        WorkManager.getInstance(appCtx).enqueueUniqueWork(
            UNIQUE_WORK_NAME,
            ExistingWorkPolicy.REPLACE,
            request,
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context.applicationContext)
            .cancelUniqueWork(UNIQUE_WORK_NAME)
    }
}
