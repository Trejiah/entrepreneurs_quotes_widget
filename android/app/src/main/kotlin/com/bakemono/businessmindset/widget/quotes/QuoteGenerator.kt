package com.bakemono.businessmindset.widget.quotes

import kotlin.random.Random

/**
 * Kotlin port of [ios/BusinessMindsetWidget/QuoteGenerator.swift]. The
 * logic follows the Swift implementation branch-for-branch so any behavior
 * difference between iOS and Android should be treated as a port bug.
 */
object QuoteGenerator {

    private const val PERSONALIZED_FEED_TOPIC_ID = "personalized_feed"

    // ------------------------------------------------------------------
    // Navigation helpers
    // ------------------------------------------------------------------

    fun getQuotesForTopicSortedByLength(
        topicId: String,
        languageCode: String,
        premium: Boolean,
        gender: String?,
    ): List<QuoteResult> {
        val quotes = quotesTot[topicId] ?: return emptyList()
        val isFemale = gender == "Female"
        val results = mutableListOf<QuoteResult>()

        val fr = languageCode.lowercase().startsWith("fr")
        for (q in quotes) {
            if (!premium && q.isFree != true) continue
            if (topicId == "womenemp" && !isFemale) continue

            val text = if (fr) (q.fr ?: q.en ?: "") else (q.en ?: q.fr ?: "")
            if (text.isEmpty()) continue

            val book = if (fr) (q.bookTitle?.fr ?: q.bookTitle?.en)
                       else (q.bookTitle?.en ?: q.bookTitle?.fr)
            results.add(
                QuoteResult(
                    text = text,
                    category = topicId,
                    signature = q.signature,
                    bookTitle = book,
                    url = q.url,
                ),
            )
        }

        return results.sortedBy { it.text.length }
    }

    // ------------------------------------------------------------------
    // Random selection
    // ------------------------------------------------------------------

    fun getRandomQuoteFromTopics(
        topics: List<String>,
        languageCode: String,
        premium: Boolean,
        gender: String?,
        affirmationPercentage: Int,
        noMercyPercentage: Int,
        favorites: List<Map<String, Any?>>,
        planPercentages: Map<String, Double>,
    ): QuoteResult {
        val selectedTopics = if (topics.isEmpty()) listOf("general") else topics

        val randomTopicIndex = Random.nextInt(selectedTopics.size)
        val selectedTopicId = selectedTopics[randomTopicIndex]

        val availableQuotes = getAvailableQuotesForTopic(
            topicId = selectedTopicId,
            lang = languageCode,
            premium = premium,
            gender = gender,
            favorites = favorites,
            planPercentages = planPercentages,
        )

        if (availableQuotes.isEmpty()) {
            val allTopics = quotesTot.keys.toList()
            if (allTopics.isEmpty()) {
                return QuoteLibrary.defaultQuoteResult(languageCode)
            }
            val randomCat = allTopics[Random.nextInt(allTopics.size)]
            val list = quotesTot[randomCat] ?: return QuoteLibrary.defaultQuoteResult(languageCode)
            if (list.isEmpty()) return QuoteLibrary.defaultQuoteResult(languageCode)
            val randomQuote = list[Random.nextInt(list.size)]

            val fr = languageCode.lowercase().startsWith("fr")
            val text = if (fr) (randomQuote.fr ?: randomQuote.en ?: "")
                       else (randomQuote.en ?: randomQuote.fr ?: "")
            val book = if (fr) (randomQuote.bookTitle?.fr ?: randomQuote.bookTitle?.en)
                       else (randomQuote.bookTitle?.en ?: randomQuote.bookTitle?.fr)
            return QuoteResult(
                text = text,
                category = randomCat,
                signature = randomQuote.signature,
                bookTitle = book,
                url = randomQuote.url,
            )
        }

        val weights = availableQuotes.map { meta ->
            when (meta.tone) {
                "affirmative" -> maxOf(0.01, 1.0 + affirmationPercentage / 100.0)
                "no mercy" -> maxOf(0.01, 1.0 + noMercyPercentage / 100.0)
                else -> 1.0
            }
        }

        val totalWeight = weights.sum()
        if (totalWeight <= 0.0) {
            return availableQuotes.first().toQuoteResult(languageCode)
        }

        val randomValue = Random.nextDouble(totalWeight)
        var cumulative = 0.0
        var selectedIndex = 0
        for ((index, weight) in weights.withIndex()) {
            cumulative += weight
            if (randomValue <= cumulative) {
                selectedIndex = index
                break
            }
        }
        return availableQuotes[selectedIndex].toQuoteResult(languageCode)
    }

    // ------------------------------------------------------------------
    // Per-topic filtering (mirrors the 8 Swift branches)
    // ------------------------------------------------------------------

    fun getAvailableQuotesForTopic(
        topicId: String,
        lang: String,
        premium: Boolean,
        gender: String?,
        favorites: List<Map<String, Any?>>,
        planPercentages: Map<String, Double>,
    ): List<QuoteWithMetadata> {
        val available = mutableListOf<QuoteWithMetadata>()
        val isFemale = gender == "Female"
        val fr = lang.lowercase().startsWith("fr")

        when (topicId) {
            PERSONALIZED_FEED_TOPIC_ID -> {
                val planCategories = listOf("growth", "discipline", "confidence", "strategy")
                val planDict = mutableMapOf<String, Double>()
                var totalPercentage = 0.0
                for (cat in planCategories) {
                    val pct = planPercentages[cat]
                    if (pct != null && pct > 0.0) {
                        planDict[cat] = pct
                        totalPercentage += pct
                    }
                }

                val selectedPlanCategory: String = if (planDict.isEmpty() || totalPercentage == 0.0) {
                    planCategories[Random.nextInt(planCategories.size)]
                } else {
                    val randomValue = Random.nextDouble(totalPercentage)
                    var cumulative = 0.0
                    var result: String = planCategories.first()
                    // Swift sorted entries by key for a stable sweep; match that.
                    for ((key, value) in planDict.entries.sortedBy { it.key }) {
                        cumulative += value
                        if (randomValue <= cumulative) {
                            result = key
                            break
                        }
                    }
                    result
                }

                val planToTopics = mapOf(
                    "growth" to listOf("growsucces", "leadership", "entrepreneurship"),
                    "discipline" to listOf("focdic", "vispurp"),
                    "confidence" to listOf("confmind", "resilience", "womenemp"),
                    "strategy" to listOf("salebranding", "wealthmoney"),
                )

                var topicsForPlan = planToTopics[selectedPlanCategory] ?: emptyList()
                topicsForPlan = topicsForPlan.filter { topic ->
                    !(topic == "womenemp" && !isFemale)
                }

                if (topicsForPlan.isEmpty()) return available

                val selectedTopic = topicsForPlan[Random.nextInt(topicsForPlan.size)]

                quotesTot[selectedTopic]?.let { quotes ->
                    for (quote in quotes) {
                        if (!premium && quote.isFree != true) continue
                        val text = if (fr) (quote.fr ?: quote.en ?: "") else (quote.en ?: quote.fr ?: "")
                        if (text.isEmpty()) continue
                        available.add(
                            QuoteWithMetadata(
                                quote = quote,
                                category = selectedTopic,
                                topicSource = "personalized_feed",
                                tone = quote.tone,
                                planCategory = quote.personalizedPlan,
                            ),
                        )
                    }
                }
            }

            "favoritesquotes" -> {
                for (fav in favorites) {
                    val quoteText = fav["quote"] as? String ?: continue
                    if (quoteText.isEmpty()) continue

                    val bookTitleStruct: BookTitle? = when (val raw = fav["bookTitle"]) {
                        is String -> if (raw.isNotEmpty()) BookTitle(en = raw, fr = raw) else null
                        is Map<*, *> -> BookTitle(
                            en = raw["en"] as? String,
                            fr = raw["fr"] as? String,
                        )
                        else -> null
                    }

                    val quote = QuoteData(
                        en = quoteText,
                        fr = quoteText,
                        signature = fav["signature"] as? String,
                        bookTitle = bookTitleStruct,
                        url = fav["url"] as? String,
                        personalizedPlan = null,
                        isFree = null,
                        businessic = null,
                        frombook = null,
                        tone = null,
                    )

                    available.add(
                        QuoteWithMetadata(
                            quote = quote,
                            category = (fav["category"] as? String) ?: "",
                            topicSource = "favoritesquotes",
                            tone = null,
                            planCategory = null,
                        ),
                    )
                }
            }

            "general" -> {
                for ((category, quotes) in quotesTot) {
                    if (category == "womenemp" && !isFemale) continue
                    for (quote in quotes) {
                        if (!premium && quote.isFree != true) continue
                        val text = if (fr) (quote.fr ?: quote.en ?: "") else (quote.en ?: quote.fr ?: "")
                        if (text.isEmpty()) continue
                        available.add(
                            QuoteWithMetadata(
                                quote = quote,
                                category = category,
                                topicSource = "general",
                                tone = quote.tone,
                                planCategory = quote.personalizedPlan,
                            ),
                        )
                    }
                }
            }

            "businessic" -> {
                for ((category, quotes) in quotesTot) {
                    for (quote in quotes) {
                        if (quote.businessic != true) continue
                        if (!premium && quote.isFree != true) continue
                        val text = if (fr) (quote.fr ?: quote.en ?: "") else (quote.en ?: quote.fr ?: "")
                        if (text.isEmpty()) continue
                        available.add(
                            QuoteWithMetadata(
                                quote = quote,
                                category = category,
                                topicSource = "businessic",
                                tone = quote.tone,
                                planCategory = quote.personalizedPlan,
                            ),
                        )
                    }
                }
            }

            "frombook" -> {
                for ((category, quotes) in quotesTot) {
                    for (quote in quotes) {
                        if (quote.frombook != true) continue
                        if (!premium && quote.isFree != true) continue
                        val text = if (fr) (quote.fr ?: quote.en ?: "") else (quote.en ?: quote.fr ?: "")
                        if (text.isEmpty()) continue
                        available.add(
                            QuoteWithMetadata(
                                quote = quote,
                                category = category,
                                topicSource = "frombook",
                                tone = quote.tone,
                                planCategory = quote.personalizedPlan,
                            ),
                        )
                    }
                }
            }

            "no_mercy" -> {
                for ((category, quotes) in quotesTot) {
                    if (category == "womenemp" && !isFemale) continue
                    for (quote in quotes) {
                        if (quote.tone != "no mercy") continue
                        if (!premium && quote.isFree != true) continue
                        val text = if (fr) (quote.fr ?: quote.en ?: "") else (quote.en ?: quote.fr ?: "")
                        if (text.isEmpty()) continue
                        available.add(
                            QuoteWithMetadata(
                                quote = quote,
                                category = category,
                                topicSource = "no_mercy",
                                tone = quote.tone,
                                planCategory = quote.personalizedPlan,
                            ),
                        )
                    }
                }
            }

            "affirmative" -> {
                for ((category, quotes) in quotesTot) {
                    if (category == "womenemp" && !isFemale) continue
                    for (quote in quotes) {
                        if (quote.tone != "affirmative") continue
                        if (!premium && quote.isFree != true) continue
                        val text = if (fr) (quote.fr ?: quote.en ?: "") else (quote.en ?: quote.fr ?: "")
                        if (text.isEmpty()) continue
                        available.add(
                            QuoteWithMetadata(
                                quote = quote,
                                category = category,
                                topicSource = "affirmative",
                                tone = quote.tone,
                                planCategory = quote.personalizedPlan,
                            ),
                        )
                    }
                }
            }

            else -> {
                quotesTot[topicId]?.let { quotes ->
                    for (quote in quotes) {
                        if (!premium && quote.isFree != true) continue
                        val text = if (fr) (quote.fr ?: quote.en ?: "") else (quote.en ?: quote.fr ?: "")
                        if (text.isEmpty()) continue
                        available.add(
                            QuoteWithMetadata(
                                quote = quote,
                                category = topicId,
                                topicSource = topicId,
                                tone = quote.tone,
                                planCategory = quote.personalizedPlan,
                            ),
                        )
                    }
                }
            }
        }

        return available
    }
}
