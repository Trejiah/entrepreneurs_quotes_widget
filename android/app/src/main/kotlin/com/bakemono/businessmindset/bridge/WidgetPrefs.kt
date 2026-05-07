package com.bakemono.businessmindset.bridge

import android.content.Context
import android.content.SharedPreferences

/**
 * Single source of truth for the SharedPreferences file shared between the
 * Flutter app and the Glance widget. On Android we use the same process for
 * the app and the widget receiver, so a regular [Context.getSharedPreferences]
 * is enough — there is no equivalent of iOS's "App Group" sandboxing.
 */
object WidgetPrefs {
    const val FILE_NAME = "businessmindset_widget_prefs"

    // Keys mirror those used by [ios/Runner/AppDelegate.swift] so the same
    // Dart-side payloads work on both platforms verbatim.
    object Keys {
        const val WIDGET_QUOTE = "widgetQuote"
        const val WIDGET_QUOTE_TIMESTAMP = "widgetQuoteTimestamp"
        const val WIDGET_QUOTE_SIGNATURE = "widgetQuoteSignature"
        const val WIDGET_QUOTE_BOOK = "widgetQuoteBook"
        const val WIDGET_QUOTE_URL = "widgetQuoteURL"
        const val WIDGET_QUOTE_LANGUAGE = "widgetQuoteLanguageCode"
        const val WIDGET_QUOTE_DETAILS = "widgetQuoteDetails"
        const val WIDGET_QUOTE_WAS_CHOSEN = "widgetQuoteWasChosen"
        const val WIDGET_LOCKSCREEN_QUOTE = "widgetLockScreenQuote"
        const val WIDGET_LOCKSCREEN_SIGNATURE = "widgetLockScreenQuoteSignature"
        const val WIDGET_LOCKSCREEN_BOOK = "widgetLockScreenQuoteBook"
        const val WIDGET_LOCKSCREEN_URL = "widgetLockScreenQuoteURL"
        const val WIDGET_LOCKSCREEN_FONT_SIZE = "widgetLockScreenFontSize"
        const val WIDGET_FORCE_NEW_QUOTE = "widgetForceNewQuote"
        const val WIDGET_FORCE_LOCKSCREEN_ONLY = "widgetForceLockScreenQuoteOnly"
        const val OPENED_FROM_LOCK_SCREEN = "openedFromLockScreen"
        const val LOCKSCREEN_FORCED_QUOTE = "lockscreenForcedQuote"
        const val WIDGET_FAVORITES = "widgetFavorites"
        const val WIDGET_TOPICS = "widgetTopicsSelected"
        const val WIDGET_BUTTONS = "widgetButtonsSelection"
        const val WIDGET_FREQUENCY = "widgetUpdateFrequency"
        const val WIDGET_THEME_INDEX = "widgetThemeIndex"
        const val WIDGET_IS_CUSTOM_THEME = "widgetIsCustomTheme"
        const val WIDGET_CONFIGURED = "widgetConfigured"
        const val THEME_CUSTOM_DATAS = "themeCustomDatasMap"
        const val THEME_INDEX_APP = "themeIndex"
        const val IS_CUSTOM_THEME_APP = "isCustomTheme"
        const val IS_PREMIUM = "isPremium"
        const val PREMIUM_EXPIRATION_EPOCH_MS = "premiumExpirationEpochMs"
        const val LANGUAGE = "language"
        const val USER_NAME = "userName"
        const val USER_NAME_LEGACY = "name"
        const val PLAN_GROWTH = "plan_growth_percentage"
        const val PLAN_DISCIPLINE = "plan_discipline_percentage"
        const val PLAN_CONFIDENCE = "plan_confidence_percentage"
        const val PLAN_STRATEGY = "plan_strategy_percentage"
        const val HARD_PAYWALL_BLOCK_QUOTES = "hardPaywallBlockQuotes"
        const val GENDER = "gender"
        const val TONE_AFFIRMATION = "tone_value_AFFIRMATION"
        const val TONE_NO_MERCY = "tone_value_NO MERCY"
        const val WIDGET_CURRENT_TOPIC = "widgetCurrentTopic"
        const val WIDGET_CURRENT_QUOTE_INDEX = "widgetCurrentQuoteIndex"
    }

    fun get(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(FILE_NAME, Context.MODE_PRIVATE)
}
