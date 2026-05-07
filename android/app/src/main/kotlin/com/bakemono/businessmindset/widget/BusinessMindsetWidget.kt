package com.bakemono.businessmindset.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.edit
import com.bakemono.businessmindset.MainActivity
import com.bakemono.businessmindset.R
import com.bakemono.businessmindset.bridge.WidgetPrefs
import com.bakemono.businessmindset.bridge.getDouble
import com.bakemono.businessmindset.bridge.putDouble
import com.bakemono.businessmindset.widget.quotes.QuoteGenerator
import com.bakemono.businessmindset.widget.quotes.QuoteLibrary
import com.bakemono.businessmindset.widget.quotes.QuoteResult
import com.bakemono.businessmindset.widget.quotes.WidgetUpdateFrequency
import com.bakemono.businessmindset.widget.quotes.replaceNamePlaceholder
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object BusinessMindsetWidget {
    fun updateAll(context: Context) {
        val appCtx = context.applicationContext
        val manager = AppWidgetManager.getInstance(appCtx)
        val ids = manager.getAppWidgetIds(
            ComponentName(appCtx, BusinessMindsetWidgetReceiver::class.java),
        )
        ids.forEach { id ->
            manager.updateAppWidget(id, buildRemoteViews(appCtx, id))
        }
    }

    fun hasActiveInstances(context: Context): Boolean {
        val appCtx = context.applicationContext
        val manager = AppWidgetManager.getInstance(appCtx)
        return manager.getAppWidgetIds(
            ComponentName(appCtx, BusinessMindsetWidgetReceiver::class.java),
        ).isNotEmpty()
    }

    private fun buildRemoteViews(context: Context, appWidgetId: Int): RemoteViews {
        val prefs = WidgetPrefs.get(context)
        val views = RemoteViews(context.packageName, R.layout.widget_home)

        val isPremium = prefs.getBoolean(WidgetPrefs.Keys.IS_PREMIUM, false)
        val premiumExpirationEpochMs = prefs.getLong(WidgetPrefs.Keys.PREMIUM_EXPIRATION_EPOCH_MS, 0L)
        val premiumStateStale = isPremium && premiumExpirationEpochMs <= 0L
        val premiumExpired = premiumExpirationEpochMs > 0L && System.currentTimeMillis() >= premiumExpirationEpochMs
        val hardPaywall = prefs.getBoolean(WidgetPrefs.Keys.HARD_PAYWALL_BLOCK_QUOTES, false)
        val configured = prefs.getBoolean(WidgetPrefs.Keys.WIDGET_CONFIGURED, false)
        if (premiumExpirationEpochMs > 0L) {
            val formatted = runCatching {
                SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.FRANCE).format(Date(premiumExpirationEpochMs))
            }.getOrElse { "invalid-date-format" }
            android.util.Log.d("WidgetPremium", "expiration(RevenueCat)=$formatted stale=$premiumStateStale expired=$premiumExpired")
        } else {
            android.util.Log.w("WidgetPremium", "expiration missing/invalid in widget payload stale=$premiumStateStale expired=$premiumExpired")
        }
        val languageCode = prefs.getString(WidgetPrefs.Keys.LANGUAGE, null)
            ?: context.resources.configuration.locales.get(0)?.language
            ?: "en"
        val isFrench = languageCode.lowercase().startsWith("fr")
        val userName = prefs.getString(WidgetPrefs.Keys.USER_NAME, null)
            ?: prefs.getString(WidgetPrefs.Keys.USER_NAME_LEGACY, null)

        val rawQuote = if (configured && !hardPaywall && isPremium && !premiumExpired && !premiumStateStale) {
            resolveOrGenerateQuote(prefs, languageCode)
        } else {
            null
        }
        val quote = rawQuote?.let { replaceNamePlaceholder(it, userName) }
        val quoteSignature = prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE_SIGNATURE, null)
        val quoteBook = prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE_BOOK, null)
        val quoteUrl = prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE_URL, null)

        val buttons = prefs.getStringSet(WidgetPrefs.Keys.WIDGET_BUTTONS, null) ?: emptySet()
        val hasNone = buttons.contains("none")
        val showShare = !hasNone && (buttons.isEmpty() || buttons.contains("share"))
        val showLike = !hasNone && (buttons.isEmpty() || buttons.contains("like"))
        val isFavorite = rawQuote != null && isQuoteFavorite(
            favoritesJson = prefs.getString(WidgetPrefs.Keys.WIDGET_FAVORITES, null),
            quote = rawQuote,
        )

        val theme = resolveWidgetTheme(prefs, configured)
        applyBackground(context, views, theme)

        val stateText: String
        val textSizeSp: Float
        val deepLink: String
        val showIcons: Boolean
        when {
            !configured -> {
                stateText = if (isFrench) TAP_TO_CONFIGURE_FR else TAP_TO_CONFIGURE_EN
                textSizeSp = 18f
                deepLink = DEEP_LINK_CONFIGURE
                showIcons = false
            }
            premiumExpired || premiumStateStale -> {
                stateText = if (isFrench) OPEN_APP_TO_UPDATE_FR else OPEN_APP_TO_UPDATE_EN
                textSizeSp = 16f
                deepLink = DEEP_LINK_OPEN_HOME
                showIcons = false
            }
            hardPaywall || !isPremium -> {
                stateText = if (isFrench) PREMIUM_REQUIRED_FR else PREMIUM_REQUIRED_EN
                textSizeSp = 16f
                deepLink = DEEP_LINK_OPEN_HOME
                showIcons = false
            }
            quote.isNullOrBlank() -> {
                stateText = if (isFrench) DEFAULT_EMPTY_FR else DEFAULT_EMPTY_EN
                textSizeSp = 16f
                deepLink = DEEP_LINK_OPEN_HOME
                showIcons = false
            }
            else -> {
                stateText = quote
                textSizeSp = 15f
                deepLink = DEEP_LINK_OPEN_HOME
                showIcons = true
            }
        }

        views.setTextViewText(R.id.widget_text, stateText)
        views.setTextColor(R.id.widget_text, theme.fontColor)
        views.setFloat(R.id.widget_text, "setTextSize", textSizeSp)

        val shouldShowShare = showIcons && showShare
        val shouldShowFav = showIcons && showLike
        views.setViewVisibility(R.id.widget_share, if (shouldShowShare) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.widget_favorite, if (shouldShowFav) View.VISIBLE else View.GONE)
        views.setImageViewResource(
            R.id.widget_favorite,
            if (isFavorite) R.drawable.ic_widget_favorite_filled else R.drawable.ic_widget_favorite,
        )
        views.setInt(R.id.widget_share, "setColorFilter", theme.fontColor)
        views.setInt(R.id.widget_favorite, "setColorFilter", theme.fontColor)
        val rootDeepLink = when (deepLink) {
            DEEP_LINK_OPEN_HOME -> buildHomeDeepLinkWithSnapshot(
                quote = quote,
                signature = quoteSignature,
                book = quoteBook,
                url = quoteUrl,
            )
            else -> deepLink
        }
        views.setOnClickPendingIntent(
            R.id.widget_root,
            pendingDeepLink(context, rootDeepLink, appWidgetId, 0),
        )
        views.setOnClickPendingIntent(
            R.id.widget_share,
            pendingDeepLink(context, DEEP_LINK_SHARE, appWidgetId, 1),
        )
        views.setOnClickPendingIntent(
            R.id.widget_favorite,
            pendingDeepLink(context, DEEP_LINK_FAVORITE, appWidgetId, 2),
        )
        return views
    }

    private fun applyBackground(context: Context, views: RemoteViews, theme: WidgetTheme) {
        val bitmap = if (theme.isImage) {
            val imageRes = themeBackgroundDrawableRes(context, theme)
            if (imageRes != 0) {
                val src = BitmapFactory.decodeResource(context.resources, imageRes)
                src?.let { roundedBitmap(it, WIDGET_CORNER_RADIUS_PX) }
            } else {
                roundedBitmap(renderThemeGradientBitmap(theme, 600, 320), WIDGET_CORNER_RADIUS_PX)
            }
        } else {
            roundedBitmap(renderThemeGradientBitmap(theme, 600, 320), WIDGET_CORNER_RADIUS_PX)
        }
        if (bitmap != null) {
            views.setImageViewBitmap(R.id.widget_background, bitmap)
        }
    }

    private fun pendingDeepLink(
        context: Context,
        deepLink: String,
        appWidgetId: Int,
        actionSlot: Int,
    ): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse(deepLink)
            setClass(context, MainActivity::class.java)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val requestCode = appWidgetId * 10 + actionSlot
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun buildHomeDeepLinkWithSnapshot(
        quote: String?,
        signature: String?,
        book: String?,
        url: String?,
    ): String {
        val base = Uri.parse(DEEP_LINK_OPEN_HOME)
        val builder = base.buildUpon().clearQuery()
        quote?.takeIf { it.isNotBlank() }?.let { builder.appendQueryParameter(QUERY_QUOTE, it) }
        signature?.takeIf { it.isNotBlank() }?.let { builder.appendQueryParameter(QUERY_SIGNATURE, it) }
        book?.takeIf { it.isNotBlank() }?.let { builder.appendQueryParameter(QUERY_BOOK, it) }
        url?.takeIf { it.isNotBlank() }?.let { builder.appendQueryParameter(QUERY_URL, it) }
        return builder.build().toString()
    }

    private fun roundedBitmap(src: Bitmap, radiusPx: Float): Bitmap {
        val output = Bitmap.createBitmap(src.width, src.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val rect = RectF(0f, 0f, src.width.toFloat(), src.height.toFloat())
        val path = Path().apply { addRoundRect(rect, radiusPx, radiusPx, Path.Direction.CW) }
        canvas.clipPath(path)
        canvas.drawBitmap(src, 0f, 0f, Paint(Paint.ANTI_ALIAS_FLAG))
        return output
    }

    private fun resolveOrGenerateQuote(
        prefs: android.content.SharedPreferences,
        languageCode: String,
    ): String {
        val topicsSet = prefs.getStringSet(WidgetPrefs.Keys.WIDGET_TOPICS, null)
        val topics = if (topicsSet.isNullOrEmpty()) listOf("general") else topicsSet.toList()
        val favorites = parseFavorites(prefs.getString(WidgetPrefs.Keys.WIDGET_FAVORITES, null))
        val gender = prefs.getString(WidgetPrefs.Keys.GENDER, null)
        val affirmationPercentage = prefs.getInt(WidgetPrefs.Keys.TONE_AFFIRMATION, 0)
        val noMercyPercentage = prefs.getInt(WidgetPrefs.Keys.TONE_NO_MERCY, 0)
        val premium = prefs.getBoolean(WidgetPrefs.Keys.IS_PREMIUM, false)

        val planPercentages = mapOf(
            "growth" to prefs.getDouble(WidgetPrefs.Keys.PLAN_GROWTH, 0.0),
            "discipline" to prefs.getDouble(WidgetPrefs.Keys.PLAN_DISCIPLINE, 0.0),
            "confidence" to prefs.getDouble(WidgetPrefs.Keys.PLAN_CONFIDENCE, 0.0),
            "strategy" to prefs.getDouble(WidgetPrefs.Keys.PLAN_STRATEGY, 0.0),
        )

        val frequency = WidgetUpdateFrequency.from(prefs.getString(WidgetPrefs.Keys.WIDGET_FREQUENCY, null))
        val now = Instant.now()
        val schedule = QuoteLibrary.schedule(frequency, now)
        val savedQuote = prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE, null)
        val savedTimestampSeconds = prefs.getDouble(WidgetPrefs.Keys.WIDGET_QUOTE_TIMESTAMP, 0.0)
        val lastInstant = if (savedTimestampSeconds > 0.0) Instant.ofEpochSecond(savedTimestampSeconds.toLong()) else null
        val forceNewQuote = prefs.getBoolean(WidgetPrefs.Keys.WIDGET_FORCE_NEW_QUOTE, false)
        val forceLockScreenOnly = prefs.getBoolean(WidgetPrefs.Keys.WIDGET_FORCE_LOCKSCREEN_ONLY, false)
        val wasChosen = prefs.getBoolean(WidgetPrefs.Keys.WIDGET_QUOTE_WAS_CHOSEN, false)
        val savedLanguage = prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE_LANGUAGE, null)
        val languageChanged = savedLanguage != null && savedLanguage != languageCode
        val slotPassed = if (lastInstant != null) lastInstant.isBefore(schedule.currentSlotStart) else savedQuote.isNullOrBlank()
        val shouldRegenerate = forceNewQuote || (!forceLockScreenOnly && (slotPassed || languageChanged))

        if (!shouldRegenerate && !savedQuote.isNullOrBlank()) {
            if (wasChosen) {
                persistChosenQuote(prefs, savedQuote, languageCode, premium, gender, now)
            }
            return savedQuote
        }
        if (wasChosen && !savedQuote.isNullOrBlank()) {
            persistChosenQuote(prefs, savedQuote, languageCode, premium, gender, now)
            return savedQuote
        }

        val generated = QuoteGenerator.getRandomQuoteFromTopics(
            topics = topics,
            languageCode = languageCode,
            premium = premium,
            gender = gender,
            affirmationPercentage = affirmationPercentage,
            noMercyPercentage = noMercyPercentage,
            favorites = favorites,
            planPercentages = planPercentages,
        )
        val quoteResult = if (generated.text.isEmpty()) QuoteLibrary.defaultQuoteResult(languageCode) else generated
        persistGeneratedQuote(prefs, quoteResult, languageCode, premium, gender, now)
        if (forceNewQuote) {
            prefs.edit {
                putBoolean(WidgetPrefs.Keys.WIDGET_FORCE_NEW_QUOTE, false)
                putBoolean(WidgetPrefs.Keys.WIDGET_FORCE_LOCKSCREEN_ONLY, false)
            }
        }
        return quoteResult.text
    }

    private fun persistChosenQuote(
        prefs: android.content.SharedPreferences,
        quoteText: String,
        languageCode: String,
        premium: Boolean,
        gender: String?,
        now: Instant,
    ) {
        val storedMetadata = prefs.getString(WidgetPrefs.Keys.WIDGET_QUOTE_DETAILS, null)
            ?.let { runCatching { JSONObject(it) }.getOrNull() }
        val category = storedMetadata?.optString("category", null)
            ?: prefs.getString(WidgetPrefs.Keys.WIDGET_CURRENT_TOPIC, null)
        if (category != null) {
            val quotes = QuoteGenerator.getQuotesForTopicSortedByLength(
                topicId = category,
                languageCode = languageCode,
                premium = true,
                gender = gender,
            )
            val index = quotes.indexOfFirst { it.text == quoteText }
            prefs.edit {
                putString(WidgetPrefs.Keys.WIDGET_CURRENT_TOPIC, category)
                if (index >= 0) putInt(WidgetPrefs.Keys.WIDGET_CURRENT_QUOTE_INDEX, index)
            }
        }
        prefs.edit {
            putDouble(WidgetPrefs.Keys.WIDGET_QUOTE_TIMESTAMP, now.epochSecond.toDouble())
            putString(WidgetPrefs.Keys.WIDGET_QUOTE_LANGUAGE, languageCode)
            putBoolean(WidgetPrefs.Keys.WIDGET_QUOTE_WAS_CHOSEN, false)
            putBoolean(WidgetPrefs.Keys.WIDGET_FORCE_NEW_QUOTE, false)
            putBoolean(WidgetPrefs.Keys.WIDGET_FORCE_LOCKSCREEN_ONLY, false)
        }
    }

    private fun persistGeneratedQuote(
        prefs: android.content.SharedPreferences,
        quote: QuoteResult,
        languageCode: String,
        premium: Boolean,
        gender: String?,
        now: Instant,
    ) {
        val metadata = JSONObject().apply {
            put("quote", quote.text)
            put("category", quote.category)
            put("signature", quote.signature)
            put("bookTitle", quote.bookTitle)
            put("url", quote.url)
            put("languageCode", languageCode)
        }
        val category = quote.category
        val navIndex = if (category != null) {
            val sorted = QuoteGenerator.getQuotesForTopicSortedByLength(
                topicId = category,
                languageCode = languageCode,
                premium = premium,
                gender = gender,
            )
            sorted.indexOfFirst { it.text == quote.text }
        } else {
            -1
        }
        prefs.edit {
            putString(WidgetPrefs.Keys.WIDGET_QUOTE, quote.text)
            putString(WidgetPrefs.Keys.WIDGET_QUOTE_DETAILS, metadata.toString())
            putString(WidgetPrefs.Keys.WIDGET_QUOTE_LANGUAGE, languageCode)
            if (quote.signature != null) putString(WidgetPrefs.Keys.WIDGET_QUOTE_SIGNATURE, quote.signature)
            if (quote.bookTitle != null) putString(WidgetPrefs.Keys.WIDGET_QUOTE_BOOK, quote.bookTitle)
            if (quote.url != null) putString(WidgetPrefs.Keys.WIDGET_QUOTE_URL, quote.url)
            putDouble(WidgetPrefs.Keys.WIDGET_QUOTE_TIMESTAMP, now.epochSecond.toDouble())
            if (category != null) putString(WidgetPrefs.Keys.WIDGET_CURRENT_TOPIC, category)
            if (navIndex >= 0) putInt(WidgetPrefs.Keys.WIDGET_CURRENT_QUOTE_INDEX, navIndex)
        }
    }

    private fun parseFavorites(raw: String?): List<Map<String, Any?>> {
        if (raw.isNullOrBlank()) return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { i ->
                array.optJSONObject(i)?.let { obj ->
                    val map = mutableMapOf<String, Any?>()
                    val keys = obj.keys()
                    while (keys.hasNext()) {
                        val key = keys.next()
                        val value = obj.opt(key)
                        map[key] = if (value === JSONObject.NULL) null else value
                    }
                    map
                }
            }
        } catch (_: Throwable) {
            emptyList()
        }
    }

    private fun isQuoteFavorite(favoritesJson: String?, quote: String): Boolean {
        if (favoritesJson.isNullOrBlank()) return false
        return try {
            val array = JSONArray(favoritesJson)
            (0 until array.length()).any { i ->
                array.optJSONObject(i)?.optString("quote") == quote
            }
        } catch (_: Throwable) {
            false
        }
    }

    private const val DEEP_LINK_CONFIGURE = "businessmindset://widget"
    private const val DEEP_LINK_OPEN_HOME = "businessmindset://home"
    private const val DEEP_LINK_SHARE = "businessmindset://widget/share"
    private const val DEEP_LINK_FAVORITE = "businessmindset://widget/favorite"
    private const val QUERY_QUOTE = "quote"
    private const val QUERY_SIGNATURE = "signature"
    private const val QUERY_BOOK = "book"
    private const val QUERY_URL = "url"
    private const val TAP_TO_CONFIGURE_FR = "Touchez pour configurer ce widget"
    private const val TAP_TO_CONFIGURE_EN = "Tap to configure"
    private const val PREMIUM_REQUIRED_FR = "Abonnez-vous pour débloquer vos citations"
    private const val PREMIUM_REQUIRED_EN = "Subscribe to unlock your motivational quotes"
    private const val OPEN_APP_TO_UPDATE_FR = "Touchez le widget pour mettre à jour"
    private const val OPEN_APP_TO_UPDATE_EN = "Tap the widget to update"
    private const val DEFAULT_EMPTY_FR = "Touchez le widget pour recevoir votre première citation."
    private const val DEFAULT_EMPTY_EN = "Tap the widget to get your first quote."
    private const val WIDGET_CORNER_RADIUS_PX = 36f
}
