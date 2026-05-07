package com.bakemono.businessmindset.widget

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

/**
 * Worker scheduled by [WidgetRefreshScheduler] to trigger a widget refresh
 * at the next slot boundary. Re-enqueues itself on completion so the widget
 * keeps updating every N seconds, matching the iOS `Timeline` policy.
 *
 * Bails out early when no widget instance is placed, to avoid keeping a
 * scheduled job alive for a widget the user has removed.
 */
class WidgetRefreshWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        try {
            val hasInstances = try {
                BusinessMindsetWidget.hasActiveInstances(applicationContext)
            } catch (_: Throwable) {
                true
            }

            if (!hasInstances) {
                // Widget was removed — stop the self-scheduling loop.
                return Result.success()
            }

            BusinessMindsetWidget.updateAll(applicationContext)
        } catch (_: Throwable) {
            // Swallow to keep the chain alive; we'll get another chance at
            // the next slot.
        }

        // Chain the next slot. REPLACE semantics in the scheduler means
        // any Dart-driven reload that ran in between already queued the
        // correct next slot — re-enqueueing here is idempotent.
        WidgetRefreshScheduler.enqueueNext(applicationContext)
        return Result.success()
    }
}
