//
//  WidgetIntents.swift
//  BusinessMindsetWidget
//
//  AppIntents pour les interactions du widget
//

import AppIntents
import WidgetKit
import Foundation

// MARK: - App Intents
@available(iOSApplicationExtension 17.0, *)
struct ToggleFavoriteIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Favorite"

    @Parameter(title: "Quote")
    var quote: String

    @Parameter(title: "Category")
    var category: String?

    @Parameter(title: "Signature")
    var signature: String?

    @Parameter(title: "Book Title")
    var bookTitle: String?

    @Parameter(title: "URL")
    var url: String?

    @Parameter(title: "Language Code")
    var languageCode: String

    init() {}

    init(
        quote: String,
        category: String?,
        signature: String?,
        bookTitle: String?,
        url: String?,
        languageCode: String
    ) {
        self.quote = quote
        self.category = category
        self.signature = signature
        self.bookTitle = bookTitle
        self.url = url
        self.languageCode = languageCode
    }

    func perform() async throws -> some IntentResult {
        print("[widget] ToggleFavoriteIntent invoked")

        guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
            print("[widget] ❌ Unable to access suite \(widgetSuiteName)")
            return .result()
        }

        var favorites = defaults.array(forKey: "widgetFavorites") as? [[String: Any]] ?? []

        if let index = favorites.firstIndex(where: { ($0["quote"] as? String) == quote }) {
            favorites.remove(at: index)
            defaults.set(favorites, forKey: "widgetFavorites")
            defaults.synchronize()
            print("[widget] Removed quote from favorites")
        } else {
            let payload = QuoteMetadataPayload(
                quote: quote,
                category: category,
                signature: signature,
                bookTitle: bookTitle,
                url: url,
                languageCode: languageCode,
                date: Date()
            )
            favorites.append(payload.toDayQuoteDictionary())
            defaults.set(favorites, forKey: "widgetFavorites")
            defaults.synchronize()
            print("[widget] Added quote to favorites")
        }

        if #available(iOSApplicationExtension 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "BusinessMindsetWidget")
        }

        return .result()
    }
}

// MARK: - Navigation Intents
// COMMENTÉ: Navigation par flèches désactivée
/*
@available(iOSApplicationExtension 17.0, *)
struct NavigateQuotePreviousIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Quote"
    
    func perform() async throws -> some IntentResult {
        print("[widget] NavigateQuotePreviousIntent invoked")
        
        guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
            print("[widget] ❌ Unable to access suite \(widgetSuiteName)")
            return .result()
        }
        
        // 🔧 FIX: D'abord vérifier si on a une citation sauvegardée avec sa catégorie
        var currentTopic = defaults.string(forKey: "widgetCurrentTopic") ?? "general"
        let currentQuote = defaults.string(forKey: "widgetQuote") ?? ""
        
        // Si on a une citation sauvegardée, vérifier sa catégorie dans les métadonnées
        var forcePremiumForNavigation = false
        if !currentQuote.isEmpty, let storedMetadata = defaults.dictionary(forKey: widgetQuoteDetailsKey) as? [String: Any] {
            if let categoryFromMetadata = storedMetadata["category"] as? String, !categoryFromMetadata.isEmpty {
                currentTopic = categoryFromMetadata
                print("[widget] 🔍 Using topic from metadata: \(currentTopic) for quote '\(currentQuote.prefix(30))...'")
                // Mettre à jour widgetCurrentTopic pour la prochaine fois
                defaults.set(currentTopic, forKey: "widgetCurrentTopic")
                // 🔧 Si on navigue depuis une citation choisie, forcer premium pour voir toutes les citations du topic
                forcePremiumForNavigation = true
            }
        }
        
        print("[widget] 🧭 Navigation Previous - currentTopic=\(currentTopic), currentQuote='\(currentQuote.prefix(30))...'")
        
        let currentIndex = defaults.integer(forKey: "widgetCurrentQuoteIndex")
        let languageCode = defaults.string(forKey: "language") ?? "en"
        var premium = defaults.bool(forKey: "isPremium")
        // 🔧 Force premium si on navigue depuis une citation choisie
        if forcePremiumForNavigation {
            premium = true
            print("[widget] 🔓 Forcing premium=true for navigation in chosen quote topic")
        }
        let gender = defaults.string(forKey: "gender")
        
        let quotes = QuoteGenerator.getQuotesForTopicSortedByLength(
            topicId: currentTopic,
            languageCode: languageCode,
            premium: premium,
            gender: gender
        )
        
        print("[widget] 📊 Found \(quotes.count) quotes in topic '\(currentTopic)'")
        
        guard !quotes.isEmpty else {
            print("[widget] ⚠️ No quotes available for topic \(currentTopic)")
            return .result()
        }
        
        // 🔧 FIX: Vérifier que l'index actuel correspond bien à la citation actuelle
        var actualIndex = currentIndex
        if !currentQuote.isEmpty {
            if let foundIndex = quotes.firstIndex(where: { $0.text == currentQuote }) {
                actualIndex = foundIndex
                if actualIndex != currentIndex {
                    print("[widget] 🔄 Adjusted index from \(currentIndex) to \(actualIndex) to match current quote")
                    defaults.set(actualIndex, forKey: "widgetCurrentQuoteIndex")
                }
            } else {
                print("[widget] ⚠️ Current quote not found in topic \(currentTopic), starting from index 0")
                actualIndex = 0
            }
        }
        
        let newIndex = actualIndex > 0 ? actualIndex - 1 : quotes.count - 1
        let newQuote = quotes[newIndex]
        
        // Sauvegarder la nouvelle citation et ses métadonnées
        defaults.set(newQuote.text, forKey: "widgetQuote")
        defaults.set(newIndex, forKey: "widgetCurrentQuoteIndex")
        defaults.set(currentTopic, forKey: "widgetCurrentTopic")
        
        // Sauvegarder les métadonnées
        let metadata = QuoteMetadataPayload(
            quote: newQuote.text,
            category: newQuote.category,
            signature: newQuote.signature,
            bookTitle: newQuote.bookTitle,
            url: newQuote.url,
            languageCode: languageCode,
            date: Date()
        )
        let cleanedMetadata = cleanDictionaryForUserDefaults(metadata.toDayQuoteDictionary())
        defaults.set(cleanedMetadata, forKey: widgetQuoteDetailsKey)
        defaults.set(newQuote.signature, forKey: "widgetQuoteSignature")
        defaults.set(newQuote.bookTitle, forKey: "widgetQuoteBook")
        defaults.set(newQuote.url, forKey: "widgetQuoteURL")
        
        defaults.set(true, forKey: "widgetForceNewQuote")
        defaults.synchronize()
        
        print("[widget] 🔙 Navigated to previous quote: index \(newIndex)/\(quotes.count - 1), text='\(newQuote.text.prefix(50))...'")
        
        if #available(iOSApplicationExtension 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "BusinessMindsetWidget")
        }
        
        return .result()
    }
}
*/

// COMMENTÉ: Navigation par flèches désactivée - NavigateQuoteNextIntent
/*
@available(iOSApplicationExtension 17.0, *)
struct NavigateQuoteNextIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Quote"
    
    func perform() async throws -> some IntentResult {
        print("[widget] NavigateQuoteNextIntent invoked")
        
        guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
            print("[widget] ❌ Unable to access suite \(widgetSuiteName)")
            return .result()
        }
        
        // 🔧 FIX: D'abord vérifier si on a une citation sauvegardée avec sa catégorie
        var currentTopic = defaults.string(forKey: "widgetCurrentTopic") ?? "general"
        let currentQuote = defaults.string(forKey: "widgetQuote") ?? ""
        
        // Si on a une citation sauvegardée, vérifier sa catégorie dans les métadonnées
        var forcePremiumForNavigation = false
        if !currentQuote.isEmpty, let storedMetadata = defaults.dictionary(forKey: widgetQuoteDetailsKey) as? [String: Any] {
            if let categoryFromMetadata = storedMetadata["category"] as? String, !categoryFromMetadata.isEmpty {
                currentTopic = categoryFromMetadata
                print("[widget] 🔍 Using topic from metadata: \(currentTopic) for quote '\(currentQuote.prefix(30))...'")
                // Mettre à jour widgetCurrentTopic pour la prochaine fois
                defaults.set(currentTopic, forKey: "widgetCurrentTopic")
                // 🔧 Si on navigue depuis une citation choisie, forcer premium pour voir toutes les citations du topic
                forcePremiumForNavigation = true
            }
        }
        
        print("[widget] 🧭 Navigation Next - currentTopic=\(currentTopic), currentQuote='\(currentQuote.prefix(30))...'")
        
        let currentIndex = defaults.integer(forKey: "widgetCurrentQuoteIndex")
        let languageCode = defaults.string(forKey: "language") ?? "en"
        var premium = defaults.bool(forKey: "isPremium")
        // 🔧 Force premium si on navigue depuis une citation choisie
        if forcePremiumForNavigation {
            premium = true
            print("[widget] 🔓 Forcing premium=true for navigation in chosen quote topic")
        }
        let gender = defaults.string(forKey: "gender")
        
        let quotes = QuoteGenerator.getQuotesForTopicSortedByLength(
            topicId: currentTopic,
            languageCode: languageCode,
            premium: premium,
            gender: gender
        )
        
        print("[widget] 📊 Found \(quotes.count) quotes in topic '\(currentTopic)'")
        
        guard !quotes.isEmpty else {
            print("[widget] ⚠️ No quotes available for topic \(currentTopic)")
            return .result()
        }
        
        // 🔧 FIX: Vérifier que l'index actuel correspond bien à la citation actuelle
        var actualIndex = currentIndex
        if !currentQuote.isEmpty {
            if let foundIndex = quotes.firstIndex(where: { $0.text == currentQuote }) {
                actualIndex = foundIndex
                if actualIndex != currentIndex {
                    print("[widget] 🔄 Adjusted index from \(currentIndex) to \(actualIndex) to match current quote")
                    defaults.set(actualIndex, forKey: "widgetCurrentQuoteIndex")
                }
            } else {
                print("[widget] ⚠️ Current quote not found in topic \(currentTopic), starting from index 0")
                actualIndex = 0
            }
        }
        
        let newIndex = (actualIndex + 1) % quotes.count
        let newQuote = quotes[newIndex]
        
        // Sauvegarder la nouvelle citation et ses métadonnées
        defaults.set(newQuote.text, forKey: "widgetQuote")
        defaults.set(newIndex, forKey: "widgetCurrentQuoteIndex")
        defaults.set(currentTopic, forKey: "widgetCurrentTopic")
        
        // Sauvegarder les métadonnées
        let metadata = QuoteMetadataPayload(
            quote: newQuote.text,
            category: newQuote.category,
            signature: newQuote.signature,
            bookTitle: newQuote.bookTitle,
            url: newQuote.url,
            languageCode: languageCode,
            date: Date()
        )
        let cleanedMetadata = cleanDictionaryForUserDefaults(metadata.toDayQuoteDictionary())
        defaults.set(cleanedMetadata, forKey: widgetQuoteDetailsKey)
        defaults.set(newQuote.signature, forKey: "widgetQuoteSignature")
        defaults.set(newQuote.bookTitle, forKey: "widgetQuoteBook")
        defaults.set(newQuote.url, forKey: "widgetQuoteURL")
        
        defaults.set(true, forKey: "widgetForceNewQuote")
        defaults.synchronize()
        
        print("[widget] 🔜 Navigated to next quote: index \(newIndex)/\(quotes.count - 1), text='\(newQuote.text.prefix(50))...'")
        
        if #available(iOSApplicationExtension 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "BusinessMindsetWidget")
        }
        
        return .result()
    }
}
*/

