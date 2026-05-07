package com.bakemono.businessmindset.widget.quotes

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Kotlin port of [ios/BusinessMindsetWidget/WidgetModels.swift].
 *
 * Everything here has a 1:1 equivalent on the iOS side. Keep the two in
 * sync when adding fields.
 */

data class QuoteResult(
    val text: String,
    val category: String?,
    val signature: String?,
    val bookTitle: String?,
    val url: String?,
)

data class QuoteWithMetadata(
    val quote: QuoteData,
    val category: String,
    val topicSource: String,
    val tone: String?,
    val planCategory: String?,
) {
    fun toQuoteResult(languageCode: String): QuoteResult {
        val fr = languageCode.lowercase().startsWith("fr")
        val text = if (fr) (quote.fr ?: quote.en ?: "") else (quote.en ?: quote.fr ?: "")
        val book = if (fr) (quote.bookTitle?.fr ?: quote.bookTitle?.en)
                   else (quote.bookTitle?.en ?: quote.bookTitle?.fr)
        return QuoteResult(
            text = text,
            category = category,
            signature = quote.signature,
            bookTitle = book,
            url = quote.url,
        )
    }
}

enum class WidgetUpdateFrequency(val id: String) {
    OncePerDay("once_per_day"),
    TwicePerDay("twice_per_day"),
    EverySixHours("every_6_hours"),
    EveryThreeHours("every_3_hours"),
    EveryHour("every_hour"),
    TwicePerHour("twice_per_hour");

    companion object {
        fun from(value: String?): WidgetUpdateFrequency =
            value?.let { v -> values().firstOrNull { it.id == v } } ?: EveryThreeHours
    }
}

data class FrequencySchedule(
    val currentSlotStart: Instant,
    val nextTrigger: Instant,
)

object QuoteLibrary {

    fun defaultQuoteResult(languageCode: String): QuoteResult =
        if (languageCode.lowercase().startsWith("fr")) {
            QuoteResult(
                text = "La vue seule de ce widget suffit à combler de joie quiconque en son for intérieur",
                category = null,
                signature = null,
                bookTitle = null,
                url = null,
            )
        } else {
            QuoteResult(
                text = "Tap to configure your widget",
                category = null,
                signature = null,
                bookTitle = null,
                url = null,
            )
        }

    /**
     * Port of `QuoteLibrary.schedule(for:at:calendar:)`. Returns the start
     * instant of the current slot and the trigger time of the next one,
     * using the same slot durations as the iOS widget.
     */
    fun schedule(
        frequency: WidgetUpdateFrequency,
        now: Instant,
        zone: ZoneId = ZoneId.systemDefault(),
    ): FrequencySchedule {
        val startOfDay: Instant = LocalDate.ofInstant(now, zone).atStartOfDay(zone).toInstant()
        val secondsSinceStart = now.epochSecond - startOfDay.epochSecond

        fun slotSchedule(slotSeconds: Int): FrequencySchedule {
            val currentIndex = maxOf(0L, secondsSinceStart / slotSeconds)
            val currentStart = startOfDay.plusSeconds(currentIndex * slotSeconds)
            val nextIndex = currentIndex + 1
            val dayInSeconds = 24L * 3600L
            return if (nextIndex * slotSeconds >= dayInSeconds) {
                val nextDay = startOfDay.plusSeconds(dayInSeconds)
                FrequencySchedule(currentStart, nextDay)
            } else {
                val next = startOfDay.plusSeconds(nextIndex * slotSeconds)
                FrequencySchedule(currentStart, next)
            }
        }

        return when (frequency) {
            WidgetUpdateFrequency.OncePerDay -> {
                val nextDay = startOfDay.plusSeconds(24L * 3600L)
                FrequencySchedule(startOfDay, nextDay)
            }
            WidgetUpdateFrequency.TwicePerDay -> {
                val midday = startOfDay.plusSeconds(12L * 3600L)
                if (secondsSinceStart < 12L * 3600L) {
                    FrequencySchedule(startOfDay, midday)
                } else {
                    val nextMidnight = startOfDay.plusSeconds(24L * 3600L)
                    FrequencySchedule(midday, nextMidnight)
                }
            }
            WidgetUpdateFrequency.EverySixHours -> slotSchedule(6 * 3600)
            WidgetUpdateFrequency.EveryThreeHours -> slotSchedule(3 * 3600)
            WidgetUpdateFrequency.EveryHour -> slotSchedule(3600)
            WidgetUpdateFrequency.TwicePerHour -> slotSchedule(30 * 60)
        }
    }
}

/**
 * Replace the `%NAME%` placeholder with the given user name. Mirror of
 * `replaceNamePlaceholder(_:userName:)` in WidgetQuoteLayoutEngine.swift.
 */
fun replaceNamePlaceholder(text: String, userName: String?): String {
    if (userName.isNullOrEmpty()) return text
    return text.replace("%NAME%", userName)
}
