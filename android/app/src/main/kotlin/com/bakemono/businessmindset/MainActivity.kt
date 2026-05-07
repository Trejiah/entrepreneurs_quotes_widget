package com.bakemono.businessmindset

import android.content.Intent
import android.os.Bundle
import android.net.Uri
import android.util.Log
import com.bakemono.businessmindset.bridge.DeepLinkChannelHandler
import com.bakemono.businessmindset.bridge.StoreChannelHandler
import com.bakemono.businessmindset.bridge.WidgetAutonomousRegenerator
import com.bakemono.businessmindset.bridge.WidgetOpenSnapshot
import com.bakemono.businessmindset.widget.WidgetRefreshScheduler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var deepLinkChannel: MethodChannel? = null
    private var pendingDeepLink: String? = null

    /** Dedupe rapid double delivery (e.g. same tap firing through multiple paths). */
    private var lastDispatchedDeepLinkUrl: String? = null
    private var lastDispatchedDeepLinkAtMs: Long = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        deepLinkChannel = MethodChannel(messenger, CHANNEL_DEEPLINK).also {
            it.setMethodCallHandler(DeepLinkChannelHandler(applicationContext))
        }
        MethodChannel(messenger, CHANNEL_STORE).setMethodCallHandler(
            StoreChannelHandler(applicationContext),
        )

        // Flush any deep link that arrived before the engine was ready.
        pendingDeepLink?.let {
            deepLinkChannel?.invokeMethod(METHOD_DEEP_LINK, it)
            pendingDeepLink = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.let { dispatchIntent(it) }

        // Make sure a slot-aligned widget refresh is queued every time the
        // app is launched — guarantees the schedule survives app updates,
        // reboots and WorkManager housekeeping. REPLACE semantics keep
        // this idempotent.
        try {
            WidgetRefreshScheduler.enqueueNext(applicationContext)
        } catch (_: Throwable) {
            // Non-fatal — the next Dart `reloadWidgets` will retry.
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        dispatchIntent(intent)
    }

    private fun dispatchIntent(intent: Intent) {
        val data = intent.data ?: return
        if (data.scheme?.lowercase() != DEEP_LINK_SCHEME) return
        val url = data.toString()
        val now = android.os.SystemClock.elapsedRealtime()
        if (url == lastDispatchedDeepLinkUrl && now - lastDispatchedDeepLinkAtMs < 400L) {
            return
        }
        lastDispatchedDeepLinkUrl = url
        lastDispatchedDeepLinkAtMs = now

        // 1) Copy quote off prefs so Flutter can show exactly what was on the widget.
        // 2) Tell Flutter (single deep-link delivery).
        // 3) Regenerate natively in the background — no Dart round-trip, no blocking wait.
        val uri = Uri.parse(url)
        if (uri.host.equals("home", ignoreCase = true)) {
            Log.d("WidgetTap", "dispatchIntent: 1) snapshot BEFORE deep link + regen url=$url")
            WidgetOpenSnapshot.captureFromIntent(this, url)
        }

        val channel = deepLinkChannel
        if (channel != null) {
            Log.d("WidgetTap", "dispatchIntent: 2) invokeMethod deepLink to Flutter")
            channel.invokeMethod(METHOD_DEEP_LINK, url)
        } else {
            Log.d("WidgetTap", "dispatchIntent: 2) engine not ready → pendingDeepLink")
            pendingDeepLink = url
        }

        if (uri.host.equals("home", ignoreCase = true)) {
            Log.d("WidgetTap", "dispatchIntent: 3) startAfterHomeDeepLink (async prefs clear + reload)")
            WidgetAutonomousRegenerator.startAfterHomeDeepLink(this, url)
        }
    }

    companion object {
        private const val CHANNEL_DEEPLINK = "businessmindset/deeplink"
        private const val CHANNEL_STORE = "businessmindset/store"
        private const val METHOD_DEEP_LINK = "deepLink"
        private const val DEEP_LINK_SCHEME = "businessmindset"
    }
}
