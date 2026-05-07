import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Constants (for Provider use)
private let defaultUpdateFrequencyId = "every_3_hours"
private let defaultButtonsSelection = ["none"]
let widgetQuoteDetailsKey = "widgetQuoteDetails"
let widgetQuoteLanguageKey = "widgetQuoteLanguageCode"
private let widgetPremiumExpirationKey = "premiumExpirationEpochMs"

// MARK: - Helper Functions for Custom Theme Images

/// Charge une image depuis l'App Group (pour les thèmes custom)
/// Retourne l'UIImage si trouvée, nil sinon
private func loadImageFromAppGroup(_ fileName: String) -> UIImage? {
    guard let groupURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: widgetSuiteName
    ) else {
        print("[widget] ⚠️ Cannot access App Group container")
        return nil
    }
    
    let imagePath = groupURL.appendingPathComponent("custom_themes/\(fileName)").path
    
    if FileManager.default.fileExists(atPath: imagePath) {
        if let image = UIImage(contentsOfFile: imagePath) {
            print("[widget] ✅ Image chargée depuis App Group: \(fileName)")
            return image
        } else {
            print("[widget] ⚠️ Impossible de charger l'image: \(fileName)")
            return nil
        }
    } else {
        print("[widget] ⚠️ Image introuvable dans App Group: \(fileName)")
        return nil
    }
}

/// Charge une image de thème (bundle ou App Group)
/// Essaie d'abord depuis le bundle (thèmes app), puis depuis l'App Group (thèmes custom)
private func loadThemeImage(_ imageName: String, isCustomTheme: Bool = false, widgetImageName: String? = nil) -> UIImage? {
    // Si c'est un thème custom avec une image widget, charger depuis l'App Group
    if isCustomTheme, let widgetImage = widgetImageName, !widgetImage.isEmpty {
        print("[widget] 🎨 Chargement image custom widget: \(widgetImage)")
        if let image = loadImageFromAppGroup(widgetImage) {
            return image
        }
        // Si l'image widget n'existe pas, ne pas afficher l'image
        print("[widget] ⚠️ Image widget introuvable, affichage couleur fallback")
        return nil
    }
    
    // Sinon, essayer de charger depuis le bundle (thèmes app)
    if let image = UIImage(named: imageName) {
        print("[widget] ✅ Image chargée depuis bundle: \(imageName)")
        return image
    }
    
    print("[widget] ⚠️ Image introuvable dans bundle: \(imageName)")
    return nil
}


// MARK: - Widget Entry
struct BusinessMindsetEntry: TimelineEntry {
    let date: Date
    let themeIndex: Int
    let quoteText: String
    let category: String?
    let signature: String?
    let bookTitle: String?
    let url: String?
    let languageCode: String
    let isConfigured: Bool
    let isPreview: Bool
    let showShareButton: Bool
    let showLikeButton: Bool
    let isFavorite: Bool
    let isPremium: Bool
    let isSubscriptionStale: Bool
    let lockScreenFontSize: CGFloat // Taille de police pour le lock screen (16.0 à 10.0)
    let widgetFontSize: CGFloat // Taille de police pour le widget principal (themeFontSize à 12.0)

    var sharePayload: String {
        if let signature, !signature.isEmpty {
            return "\"\(quoteText)\"\n— \(signature)"
        }
        return quoteText
    }

    func shareMetadata() -> (quote: String, signature: String?, book: String?, url: String?) {
        (quoteText, signature, bookTitle, url)
    }
}

// MARK: - Widget Provider
struct BusinessMindsetWidgetProvider: TimelineProvider {
    
    init() {
        print("[widget] 🔧 Widget Provider initialized")
    }
    
    func placeholder(in context: Context) -> BusinessMindsetEntry {
        print("[widget] 🏗️ placeholder() called")
        let defaults = widgetUserDefaults()
        let appLanguage = defaults.string(forKey: "language") ?? Locale.current.languageCode ?? "en"

        // Choix du thème comme dans getTimeline
        let isConfigured = defaults.bool(forKey: "widgetConfigured")
        let themeIndex = getWidgetThemeIndex(defaults: defaults, isConfigured: isConfigured)

        // Citation de prévisualisation (FR/EN)
        let quoteText: String
        if appLanguage.lowercased().hasPrefix("fr") {
            quoteText = "Un entrepreneur, c’est quelqu’un qui saute d’une falaise et construit un avion pendant sa chute."
        } else {
            quoteText = "An entrepreneur is someone who jumps off a cliff and builds a plane on the way down."
        }

        let safeThemeIndex = max(0, min(themeIndex, allAppThemes.count - 1))
        let theme = allAppThemes[safeThemeIndex]
        
        return BusinessMindsetEntry(
            date: Date(),
            themeIndex: themeIndex,
            quoteText: quoteText,
            category: "confmind",
            signature: "Business Mindset",
            bookTitle: nil,
            url: nil,
            languageCode: appLanguage,
            isConfigured: isConfigured,
            isPreview: true,
            showShareButton: true,
            showLikeButton: true,
            isFavorite: false,
            isPremium: true,
            isSubscriptionStale: false,
            lockScreenFontSize: 12.0,
            widgetFontSize: CGFloat(theme.fontSize)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (BusinessMindsetEntry) -> Void) {
        print("[widget] 📸 getSnapshot() called - isPreview=\(context.isPreview)")
        let defaults = widgetUserDefaults()
        let appLanguage = defaults.string(forKey: "language") ?? Locale.current.languageCode ?? "en"
        let languageCode = appLanguage
        
        // Choix du thème comme dans getTimeline
        let isConfigured = defaults.bool(forKey: "widgetConfigured")
        let themeIndex = getWidgetThemeIndex(defaults: defaults, isConfigured: isConfigured)
        
        // DEBUG: Vérifier si c'est un thème custom
        let isCustomTheme = defaults.bool(forKey: "widgetIsCustomTheme")
        print("[widget] 🔍 DEBUG getSnapshot - isCustomTheme=\(isCustomTheme), themeIndex=\(themeIndex)")
        if isCustomTheme {
            if let customThemes = defaults.array(forKey: "themeCustomDatasMap") as? [[String: Any]] {
                print("[widget] 🔍 DEBUG getSnapshot - customThemes count=\(customThemes.count)")
                if themeIndex < customThemes.count {
                    let theme = customThemes[themeIndex]
                    print("[widget] 🔍 DEBUG getSnapshot - theme=\(theme)")
                }
            } else {
                print("[widget] ⚠️ DEBUG getSnapshot - themeCustomDatasMap is nil!")
            }
        }
        
        // Même citation de prévisualisation que dans placeholder
        let previewQuote: String
        if languageCode.lowercased().hasPrefix("fr") {
            previewQuote = "Un entrepreneur, c’est quelqu’un qui saute d’une falaise et construit un avion pendant sa chute."
        } else {
            previewQuote = "An entrepreneur is someone who jumps off a cliff and builds a plane on the way down."
        }
        
        let safeThemeIndex = max(0, min(themeIndex, allAppThemes.count - 1))
        let theme = allAppThemes[safeThemeIndex]
        
        let entry = BusinessMindsetEntry(
            date: Date(),
            themeIndex: themeIndex,
            quoteText: previewQuote,
            category: "confmind",
            signature: "Business Mindset",
            bookTitle: nil,
            url: nil,
            languageCode: languageCode,
            isConfigured: isConfigured,
            isPreview: true,
            showShareButton: true,
            showLikeButton: true,
            isFavorite: false,
            isPremium: true,
            isSubscriptionStale: false,
            lockScreenFontSize: 12.0,
            widgetFontSize: CGFloat(theme.fontSize)
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<BusinessMindsetEntry>) -> Void) {
        print("[widget] 🚀 Timeline getTimeline() START - isPreview=\(context.isPreview)")
        let defaults = widgetUserDefaults()
        let premium = defaults.bool(forKey: "isPremium")
        let premiumExpirationEpochMs = defaults.double(forKey: widgetPremiumExpirationKey)
        let premiumStateStale = premium && premiumExpirationEpochMs <= 0
        let premiumExpired = premiumExpirationEpochMs > 0 && Date().timeIntervalSince1970 * 1000 >= premiumExpirationEpochMs
        let isConfigured = defaults.bool(forKey: "widgetConfigured")
        // Récupérer le nom d'utilisateur pour remplacer %NAME% AVANT de calculer la taille de police
        let userName = defaults.string(forKey: "userName") ?? defaults.string(forKey: "name")
        print("[widget] 👤 userName=\(userName ?? "nil")")
        // Largeur et hauteur utiles mesurées depuis la vue (si déjà affichée), sinon estimation
        let measuredWidth = defaults.double(forKey: "widgetMeasuredWidth")
        let effectiveWidth = measuredWidth > 0 ? measuredWidth : widgetTextWidthEstimate
        let measuredMaxHeight = defaults.double(forKey: "widgetMeasuredMaxHeight")
        let effectiveMaxHeight = measuredMaxHeight > 0 ? measuredMaxHeight : widgetMaxHeightEstimate
        print("[widget] 📏 Measured dimensions: width=\(measuredWidth) → effective=\(effectiveWidth) (estimate=\(widgetTextWidthEstimate)), maxHeight=\(measuredMaxHeight) → effective=\(effectiveMaxHeight) (estimate=\(widgetMaxHeightEstimate))")

        // Choix du thème :
        // - Tant que le widget n'a pas été configuré via "Add widget", suivre le thème de l'app (home_page) : themeIndex.
        // - Une fois configuré, toujours utiliser widgetThemeIndex, quelle que soit la valeur de premium.
        let themeIndex = getWidgetThemeIndex(defaults: defaults, isConfigured: isConfigured)

        if !context.isPreview {
            if premiumExpirationEpochMs > 0 {
                let expDate = Date(timeIntervalSince1970: premiumExpirationEpochMs / 1000.0)
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "fr_FR")
                formatter.dateFormat = "dd/MM/yyyy HH:mm"
                print("[widget] Premium expiration (RevenueCat): \(formatter.string(from: expDate))")
            } else {
                print("[widget] ⚠️ Premium expiration missing/invalid in widget payload")
            }
        }

        // PRIORITY: if widget isn't configured yet, always show "Tap to configure"
        // before any premium/expiration checks.
        if !isConfigured {
            let savedLanguage = defaults.string(forKey: "language")
            let languageCode = savedLanguage ?? "en"
            let isFrench = languageCode.lowercased().hasPrefix("fr")
            let quoteText = isFrench
                ? "Touchez pour configurer ce widget"
                : "Tap to configure"
            let safeIdx = max(0, min(themeIndex, allAppThemes.count - 1))
            let theme = allAppThemes[safeIdx]
            let now = Date()
            let entry = BusinessMindsetEntry(
                date: now,
                themeIndex: themeIndex,
                quoteText: quoteText,
                category: nil,
                signature: nil,
                bookTitle: nil,
                url: nil,
                languageCode: languageCode,
                isConfigured: false,
                isPreview: false,
                showShareButton: false,
                showLikeButton: false,
                isFavorite: false,
                isPremium: false,
                isSubscriptionStale: false,
                lockScreenFontSize: 12.0,
                widgetFontSize: CGFloat(theme.fontSize)
            )
            let next = now.addingTimeInterval(3600)
            let timeline = Timeline(entries: [entry], policy: .after(next))
            completion(timeline)
            return
        }

        // Paywall forcé (essai expiré + Remote Config) : pas de nouvelles citations, ouverture app → paywall
        if defaults.bool(forKey: "hardPaywallBlockQuotes"), !context.isPreview {
            let savedLanguage = defaults.string(forKey: "language")
            let languageCode = savedLanguage ?? "en"
            let isFrench = languageCode.lowercased().hasPrefix("fr")
            let quoteText = isFrench
                ? "Abonnez-vous dans l’app pour continuer."
                : "Subscribe in the app to continue."
            let safeIdx = max(0, min(themeIndex, allAppThemes.count - 1))
            let theme = allAppThemes[safeIdx]
            let now = Date()
            let entry = BusinessMindsetEntry(
                date: now,
                themeIndex: themeIndex,
                quoteText: quoteText,
                category: nil,
                signature: nil,
                bookTitle: nil,
                url: nil,
                languageCode: languageCode,
                isConfigured: isConfigured,
                isPreview: false,
                showShareButton: false,
                showLikeButton: false,
                isFavorite: false,
                isPremium: false,
                isSubscriptionStale: false,
                lockScreenFontSize: 12.0,
                widgetFontSize: CGFloat(theme.fontSize)
            )
            let next = now.addingTimeInterval(3600)
            let timeline = Timeline(entries: [entry], policy: .after(next))
            completion(timeline)
            return
        }

        if (premiumExpired || premiumStateStale) && isConfigured && !context.isPreview {
            let savedLanguage = defaults.string(forKey: "language")
            let languageCode = savedLanguage ?? "en"
            let isFrench = languageCode.lowercased().hasPrefix("fr")
            let quoteText = isFrench
                ? "Ouvrez l'application pour mettre à jour"
                : "Open the app to update"
            let safeIdx = max(0, min(themeIndex, allAppThemes.count - 1))
            let theme = allAppThemes[safeIdx]
            let now = Date()
            let entry = BusinessMindsetEntry(
                date: now,
                themeIndex: themeIndex,
                quoteText: quoteText,
                category: nil,
                signature: nil,
                bookTitle: nil,
                url: nil,
                languageCode: languageCode,
                isConfigured: isConfigured,
                isPreview: false,
                showShareButton: false,
                showLikeButton: false,
                isFavorite: false,
                isPremium: false,
                isSubscriptionStale: true,
                lockScreenFontSize: 12.0,
                widgetFontSize: CGFloat(theme.fontSize)
            )
            let next = now.addingTimeInterval(3600)
            let timeline = Timeline(entries: [entry], policy: .after(next))
            completion(timeline)
            return
        }
        
        // DEBUG: Vérifier si c'est un thème custom
        let isCustomTheme = defaults.bool(forKey: "widgetIsCustomTheme")
        print("[widget] 🔍 DEBUG getTimeline - isCustomTheme=\(isCustomTheme), themeIndex=\(themeIndex), isConfigured=\(isConfigured)")
        if isCustomTheme {
            if let customThemes = defaults.array(forKey: "themeCustomDatasMap") as? [[String: Any]] {
                print("[widget] 🔍 DEBUG getTimeline - customThemes count=\(customThemes.count)")
                if themeIndex < customThemes.count {
                    let theme = customThemes[themeIndex]
                    print("[widget] 🔍 DEBUG getTimeline - theme name=\(theme["name"] ?? "nil"), widgetImageName=\(theme["widgetImageName"] ?? "nil")")
                }
            } else {
                print("[widget] ⚠️ DEBUG getTimeline - themeCustomDatasMap is nil!")
            }
        }
        
        var topics = defaults.stringArray(forKey: "widgetTopicsSelected") ?? ["general"]
        
        // Valider et corriger les topics selon le statut premium
        topics = validateWidgetTopics(topics: topics, premium: premium, defaults: defaults)
        
        let favoritesList = defaults.array(forKey: "widgetFavorites") as? [[String: Any]] ?? []
        // Lire la langue depuis SharedPreferences (clé "language") au lieu de la langue système
        // Si pas sauvegardée, forcer "en" pour être cohérent avec Flutter (qui force aussi "en")
        let savedLanguage = defaults.string(forKey: "language")
        let systemLanguage = Locale.current.languageCode ?? "en"
        // Forcer "en" par défaut si pas sauvegardé (cohérent avec Flutter qui force "en")
        let appLanguage = savedLanguage ?? "en"
        let languageCode = appLanguage
        print("[widget] Language detection -> savedLanguage: \(savedLanguage ?? "nil"), systemLanguage: \(systemLanguage), final: \(languageCode)")
        
        // Lire toutes les préférences nécessaires pour la génération
        let gender = defaults.string(forKey: "gender")
        let affirmationPercentage = defaults.integer(forKey: "tone_value_AFFIRMATION")
        let noMercyPercentage = defaults.integer(forKey: "tone_value_NO MERCY")
        
        // Lire les pourcentages des plans pour personalized_feed
        var planPercentages: [String: Double] = [:]
        planPercentages["growth"] = defaults.double(forKey: "plan_growth_percentage")
        planPercentages["discipline"] = defaults.double(forKey: "plan_discipline_percentage")
        planPercentages["confidence"] = defaults.double(forKey: "plan_confidence_percentage")
        planPercentages["strategy"] = defaults.double(forKey: "plan_strategy_percentage")
        let savedQuote = defaults.string(forKey: "widgetQuote")
        let lastTimestamp = defaults.double(forKey: "widgetQuoteTimestamp")
        let forceNewQuote = defaults.bool(forKey: "widgetForceNewQuote")
        let forceLockScreenOnly = defaults.bool(forKey: "widgetForceLockScreenQuoteOnly")
        let frequencyId = defaults.string(forKey: "widgetUpdateFrequency") ?? defaultUpdateFrequencyId
        let buttonSelection = defaults.stringArray(forKey: "widgetButtonsSelection") ?? defaultButtonsSelection
        let frequency = WidgetUpdateFrequency.from(frequencyId)
        let lastDate = lastTimestamp > 0 ? Date(timeIntervalSince1970: lastTimestamp) : nil
        let now = Date()
        let calendar = Calendar.current
        let schedule = QuoteLibrary.schedule(for: frequency, at: now, calendar: calendar)
        // Les icônes sont visibles par défaut
        // Si buttonSelection est vide, toutes les icônes sont visibles
        // Si "none" est sélectionné, aucune icône n'est visible
        // Sinon, afficher seulement les icônes sélectionnées
        let hasNone = buttonSelection.contains("none")
        var showShareButton = !hasNone && (buttonSelection.isEmpty || buttonSelection.contains("share"))
        var showLikeButton = !hasNone && (buttonSelection.isEmpty || buttonSelection.contains("like"))

        let dateFormatter = ISO8601DateFormatter()
        let frequencyLabel: String
        switch frequency {
        case .oncePerDay: frequencyLabel = "once_per_day"
        case .twicePerDay: frequencyLabel = "twice_per_day"
        case .everySixHours: frequencyLabel = "every_6_hours"
        case .everyThreeHours: frequencyLabel = "every_3_hours"
        case .everyHour: frequencyLabel = "every_hour"
        case .twicePerHour: frequencyLabel = "twice_per_hour"
        }
        let lastDateString = lastDate.map { dateFormatter.string(from: $0) } ?? "nil"
        let currentSlotString = dateFormatter.string(from: schedule.currentSlotStart)
        let nextTriggerString = dateFormatter.string(from: schedule.nextTrigger)

        print("[widget] getTimeline frequency=\(frequencyLabel) buttons=\(buttonSelection) lastDate=\(lastDateString) slotStart=\(currentSlotString) nextTrigger=\(nextTriggerString)")

        var quoteText: String = ""
        var quoteCategory: String?
        var quoteSignature: String?
        var quoteBookTitle: String?
        var quoteURL: String?
        var quoteLanguage = languageCode
        var currentMetadataDict: [String: Any] = [:]
        let favoriteQuotes = Set(favoritesList.compactMap { $0["quote"] as? String })
        
        if !isConfigured {
            // Widget jamais configuré depuis l’app : afficher un message d’invite
            let isFrench = languageCode.lowercased().hasPrefix("fr")
            quoteText = isFrench
                ? "Touchez pour configurer ce widget"
                : "Tap to configure"
            quoteCategory = nil
            quoteSignature = nil
            quoteBookTitle = nil
            quoteURL = nil
            // Pas d'icônes tant que le widget n'est pas configuré
            showShareButton = false
            showLikeButton = false
            print("[widget] Widget not configured; showing 'Tap to configure' prompt")
        } else {
            let shouldGenerate: Bool
            if let lastDate {
                shouldGenerate = lastDate < schedule.currentSlotStart
            } else {
                shouldGenerate = savedQuote?.isEmpty ?? true
            }

            // Vérifier si la langue a changé
            let savedQuoteLanguage = defaults.string(forKey: widgetQuoteLanguageKey)
            let languageChanged = savedQuoteLanguage != nil && savedQuoteLanguage != languageCode
            
            print("[widget] shouldGenerate=\(shouldGenerate) savedQuoteExists=\(!(savedQuote?.isEmpty ?? true)) topics=\(topics) favoritesCount=\(favoritesList.count)")
            print("[widget] Language check -> savedQuoteLanguage: \(savedQuoteLanguage ?? "nil"), currentLanguageCode: \(languageCode), languageChanged: \(languageChanged)")
            print("[widget] Force flag -> widgetForceNewQuote=\(forceNewQuote), forceLockScreenOnly=\(forceLockScreenOnly)")

            // Si on force seulement le lock screen, on ne régénère JAMAIS la citation principale
            // Sinon, on applique la logique normale (shouldGenerate, languageChanged, ou forceNewQuote)
            let shouldRegenerateMainQuote = !forceLockScreenOnly && (shouldGenerate || languageChanged || forceNewQuote)
            
            // Bloc "régénération" : main et/ou lock screen. Se ferme avant "else if saved".
            if shouldRegenerateMainQuote || forceLockScreenOnly {
                if forceLockScreenOnly && !shouldRegenerateMainQuote {
                    // On ne régénère que le lock screen : garder la citation principale existante
                    quoteText = savedQuote ?? ""
                    quoteLanguage = defaults.string(forKey: widgetQuoteLanguageKey) ?? languageCode
                    if let storedMetadata = defaults.dictionary(forKey: widgetQuoteDetailsKey) as? [String: Any] {
                        currentMetadataDict = storedMetadata
                        quoteCategory = storedMetadata["category"] as? String
                        quoteSignature = storedMetadata["signature"] as? String
                        quoteBookTitle = storedMetadata["bookTitle"] as? String
                        quoteURL = storedMetadata["url"] as? String
                    }
                }
                if shouldRegenerateMainQuote {
                var newQuote: QuoteResult
                
                // Si forceNewQuote est true, vérifier si une citation a été sauvegardée par navigation
                // Vérifier aussi si c'est une citation choisie par l'utilisateur (via flag)
                let wasChosenQuote = defaults.bool(forKey: "widgetQuoteWasChosen")
                if forceNewQuote && !forceLockScreenOnly, let navigatedQuote = defaults.string(forKey: "widgetQuote"), !navigatedQuote.isEmpty {
                    print("[widget] 🔄 Using chosen quote from settings (one-time use): \(navigatedQuote.prefix(50))...")
                    quoteText = navigatedQuote
                    
                    // 🔧 FIX: D'abord récupérer la catégorie depuis les métadonnées sauvegardées
                    var quoteCategoryFromMetadata: String? = nil
                    if let storedMetadata = defaults.dictionary(forKey: widgetQuoteDetailsKey) as? [String: Any] {
                        quoteCategoryFromMetadata = storedMetadata["category"] as? String
                        quoteSignature = storedMetadata["signature"] as? String
                        quoteBookTitle = storedMetadata["bookTitle"] as? String
                        quoteURL = storedMetadata["url"] as? String
                    }
                    
                    // Utiliser la catégorie des métadonnées, ou le topic actuel, ou "general" par défaut
                    let topicToSearch = quoteCategoryFromMetadata ?? defaults.string(forKey: "widgetCurrentTopic") ?? "general"
                    // 🔧 Force premium=true pour trouver la citation choisie même si elle n'est pas gratuite
                    let quotes = QuoteGenerator.getQuotesForTopicSortedByLength(
                        topicId: topicToSearch,
                        languageCode: languageCode,
                        premium: true, // Force premium pour les citations choisies depuis l'app
                        gender: gender
                    )
                    
                    if let quote = quotes.first(where: { $0.text == navigatedQuote }) {
                        quoteCategory = quote.category
                        quoteSignature = quote.signature
                        quoteBookTitle = quote.bookTitle
                        quoteURL = quote.url
                        newQuote = quote
                        // Mettre à jour le topic et l'index pour la navigation
                        if let category = quoteCategory, let index = quotes.firstIndex(where: { $0.text == navigatedQuote }) {
                            defaults.set(category, forKey: "widgetCurrentTopic")
                            defaults.set(index, forKey: "widgetCurrentQuoteIndex")
                            print("[widget] ✅ Found metadata for navigated quote in topic \(category), updated index to \(index)")
                        } else {
                            print("[widget] ✅ Found metadata for navigated quote in topic \(topicToSearch)")
                        }
                    } else {
                        // Fallback : utiliser les métadonnées sauvegardées
                        if let storedMetadata = defaults.dictionary(forKey: widgetQuoteDetailsKey) as? [String: Any] {
                            quoteCategory = storedMetadata["category"] as? String
                            quoteSignature = storedMetadata["signature"] as? String
                            quoteBookTitle = storedMetadata["bookTitle"] as? String
                            quoteURL = storedMetadata["url"] as? String
                            
                            // 🔧 FIX: Mettre à jour widgetCurrentTopic avec la catégorie des métadonnées
                            if let category = quoteCategory {
                                defaults.set(category, forKey: "widgetCurrentTopic")
                                // 🔧 Force premium=true pour trouver la citation même si elle n'est pas gratuite
                                let quotesInCategory = QuoteGenerator.getQuotesForTopicSortedByLength(
                                    topicId: category,
                                    languageCode: languageCode,
                                    premium: true, // Force premium pour les citations choisies
                                    gender: gender
                                )
                                if let index = quotesInCategory.firstIndex(where: { $0.text == navigatedQuote }) {
                                    defaults.set(index, forKey: "widgetCurrentQuoteIndex")
                                    print("[widget] 💾 Updated topic to \(category) and index to \(index) from metadata (premium forced)")
                                } else {
                                    print("[widget] ⚠️ Navigated quote '\(navigatedQuote.prefix(30))...' not found in topic \(category) even with premium=true")
                                }
                            }
                        }
                        newQuote = QuoteResult(
                            text: navigatedQuote,
                            category: quoteCategory,
                            signature: quoteSignature,
                            bookTitle: quoteBookTitle,
                            url: quoteURL
                        )
                        print("[widget] ⚠️ Quote not found in topic, using stored metadata")
                    }
                } else {
                // Générer une citation normalement (sans filtrage pour le widget normal)
                    let generatedQuote = QuoteGenerator.getRandomQuoteFromTopics(
                    topics: topics,
                    languageCode: languageCode,
                    premium: premium,
                    gender: gender,
                    affirmationPercentage: affirmationPercentage,
                    noMercyPercentage: noMercyPercentage,
                    favorites: favoritesList,
                    planPercentages: planPercentages
                )
                
                // S'assurer que la citation n'est jamais vide
                    if generatedQuote.text.isEmpty {
                    print("[widget] ⚠️ Generated quote is empty, using default quote")
                    let defaultQuote = QuoteLibrary.defaultQuoteResult(languageCode: languageCode)
                    quoteText = defaultQuote.text
                    quoteCategory = defaultQuote.category
                    quoteSignature = defaultQuote.signature
                    quoteBookTitle = defaultQuote.bookTitle
                    quoteURL = defaultQuote.url
                        newQuote = defaultQuote
                } else {
                        quoteText = generatedQuote.text
                        quoteCategory = generatedQuote.category
                        quoteSignature = generatedQuote.signature
                        quoteBookTitle = generatedQuote.bookTitle
                        quoteURL = generatedQuote.url
                        newQuote = generatedQuote
                    }
                    
                    // Sauvegarder l'index et le topic pour la navigation
                    if let category = quoteCategory {
                        let quotes = QuoteGenerator.getQuotesForTopicSortedByLength(
                            topicId: category,
                            languageCode: languageCode,
                            premium: premium,
                            gender: gender
                        )
                        if let index = quotes.firstIndex(where: { $0.text == quoteText }) {
                            defaults.set(index, forKey: "widgetCurrentQuoteIndex")
                            defaults.set(category, forKey: "widgetCurrentTopic")
                            print("[widget] 💾 Saved index \(index) for topic \(category)")
                        }
                    }
                }
                
                // Pour le widget principal : trouver une citation qui tient dans 4 lignes
                print("[widget] [FontSize] 🎯 Starting widget quote size calculation for navigated/generated quote")
                let widgetResult = findWidgetQuote(
                    initialQuote: newQuote,
                    themeIndex: themeIndex,
                    effectiveWidth: effectiveWidth,
                    effectiveMaxHeight: effectiveMaxHeight,
                    userName: userName,
                            topics: topics,
                            languageCode: languageCode,
                            premium: premium,
                            gender: gender,
                            affirmationPercentage: affirmationPercentage,
                            noMercyPercentage: noMercyPercentage,
                    favoritesList: favoritesList,
                    planPercentages: planPercentages,
                    useThemeFontFamily: true
                )
                print("[widget] [FontSize] ✅ Widget quote size calculation completed: fontSize=\(widgetResult.fontSize)pt")
                let widgetQuote = widgetResult.quote
                let widgetFontSize = widgetResult.fontSize
                        
                        // Si on a dû utiliser une citation différente, mettre à jour les métadonnées
                if widgetQuote.text != quoteText {
                            quoteText = widgetQuote.text
                            quoteCategory = widgetQuote.category
                            quoteSignature = widgetQuote.signature
                            quoteBookTitle = widgetQuote.bookTitle
                            quoteURL = widgetQuote.url
                }
                
                let metadata = QuoteMetadataPayload(
                    quote: quoteText,
                    category: quoteCategory,
                    signature: quoteSignature,
                    bookTitle: quoteBookTitle,
                    url: quoteURL,
                    languageCode: languageCode,
                    date: now
                )
                currentMetadataDict = metadata.toDayQuoteDictionary()
                defaults.set(quoteText, forKey: "widgetQuote")
                let cleanedMetadata = cleanDictionaryForUserDefaults(currentMetadataDict)
                defaults.set(cleanedMetadata, forKey: widgetQuoteDetailsKey)
                defaults.set(languageCode, forKey: widgetQuoteLanguageKey)
                defaults.set(quoteSignature, forKey: "widgetQuoteSignature")
                defaults.set(quoteBookTitle, forKey: "widgetQuoteBook")
                defaults.set(quoteURL, forKey: "widgetQuoteURL")
                defaults.set(now.timeIntervalSince1970, forKey: "widgetQuoteTimestamp")
                
                // ⚠️ IMPORTANT : Si c'était une citation choisie par l'utilisateur, la supprimer après utilisation
                // pour qu'elle ne soit plus utilisée lors des prochains rafraîchissements automatiques
                if wasChosenQuote {
                    defaults.removeObject(forKey: "widgetQuote")
                    defaults.removeObject(forKey: "widgetQuoteTimestamp")
                    defaults.removeObject(forKey: widgetQuoteDetailsKey)
                    defaults.set(false, forKey: "widgetQuoteWasChosen")
                    print("[widget] 📱 Chosen quote removed after one-time use")
                }
                
                // Sauvegarder la taille de police pour le widget principal
                defaults.set(widgetFontSize, forKey: "widgetMainFontSize")
            }
            
            // Pour le lock screen : régénérer seulement si nécessaire
            let savedLockScreenQuote = defaults.string(forKey: "widgetLockScreenQuote")
            
            // Vérifier s'il existe une citation forcée pour le lockscreen (depuis Flutter)
            let forcedLockScreenQuote = defaults.string(forKey: "lockscreenForcedQuote")
            
            // Régénérer le lock screen UNIQUEMENT si :
            // - Il n'existe pas de citation sauvegardée
            // - On force explicitement le lock screen (forceLockScreenOnly = true)
            // - OU si une citation forcée existe et est différente de la sauvegardée
            // ⚠️ NE PLUS régénérer automatiquement quand le widget principal se régénère
            let shouldRegenerateLockScreen = savedLockScreenQuote == nil || savedLockScreenQuote?.isEmpty == true || forceLockScreenOnly || (forcedLockScreenQuote != nil && forcedLockScreenQuote != savedLockScreenQuote)
            
            if shouldRegenerateLockScreen {
                // Déclarer la variable pour la citation de base du lockscreen
                let baseQuoteForLockScreen: QuoteResult
                
                // ⚠️ IMPORTANT : Si forceLockScreenOnly est true (clic utilisateur), 
                // ignorer la citation forcée et générer une nouvelle citation aléatoire
                // La citation forcée ne doit être utilisée que lors des rafraîchissements automatiques
                if forceLockScreenOnly {
                    // Clic sur le lockscreen → toujours générer une nouvelle citation aléatoire
                    // même si une citation est forcée (l'utilisateur veut une nouvelle citation)
                    print("[widget] 🔒 Forcing new random quote for lock screen (user clicked) - ignoring forced quote")
                    baseQuoteForLockScreen = QuoteGenerator.getRandomQuoteFromTopics(
                        topics: topics,
                        languageCode: languageCode,
                        premium: premium,
                        gender: gender,
                        affirmationPercentage: affirmationPercentage,
                        noMercyPercentage: noMercyPercentage,
                        favorites: favoritesList,
                        planPercentages: planPercentages
                    )
                } else if let forcedQuote = forcedLockScreenQuote, !forcedQuote.isEmpty {
                    // Citation forcée depuis Flutter (settings) → utiliser cette citation UNE SEULE FOIS
                    // puis la supprimer pour qu'elle ne soit plus utilisée lors des rafraîchissements automatiques
                    print("[widget] 🔒 Using forced lockscreen quote from Flutter (one-time use): \(forcedQuote.prefix(50))...")
                    
                    // Chercher les métadonnées de cette citation dans quotesTot
                    var foundQuote: QuoteResult? = nil
                    for topicId in topics {
                        let quotes = QuoteGenerator.getQuotesForTopicSortedByLength(
                            topicId: topicId,
                            languageCode: languageCode,
                            premium: true, // Force premium pour trouver la citation forcée
                            gender: gender
                        )
                        if let quote = quotes.first(where: { $0.text == forcedQuote }) {
                            foundQuote = quote
                            break
                        }
                    }
                    
                    // Si la citation forcée est trouvée, l'utiliser directement
                    // Sinon, créer un QuoteResult basique avec le texte forcé
                    baseQuoteForLockScreen = foundQuote ?? QuoteResult(
                        text: forcedQuote,
                        category: quoteCategory,
                        signature: quoteSignature,
                        bookTitle: quoteBookTitle,
                        url: quoteURL
                    )
                    
                    // ⚠️ IMPORTANT : Supprimer la citation forcée après l'avoir utilisée
                    // pour qu'elle ne soit plus utilisée lors des prochains rafraîchissements automatiques
                    defaults.removeObject(forKey: "lockscreenForcedQuote")
                    print("[widget] 🔒 Forced lockscreen quote removed after one-time use")
                } else if let savedMainQuote = defaults.string(forKey: "widgetQuote"), !savedMainQuote.isEmpty {
                    // Première création ou régénération normale → utiliser la citation principale comme base
                    print("[widget] 🔒 Using main quote as base for lock screen")
                    if let storedMetadata = defaults.dictionary(forKey: widgetQuoteDetailsKey) as? [String: Any] {
                        baseQuoteForLockScreen = QuoteResult(
                            text: savedMainQuote,
                            category: storedMetadata["category"] as? String,
                            signature: storedMetadata["signature"] as? String,
                            bookTitle: storedMetadata["bookTitle"] as? String,
                            url: storedMetadata["url"] as? String
                        )
                    } else {
                        baseQuoteForLockScreen = QuoteResult(
                            text: savedMainQuote,
                            category: nil,
                            signature: nil,
                            bookTitle: nil,
                            url: nil
                        )
                    }
                } else {
                    // Pas de citation principale → générer une nouvelle
                    print("[widget] 🔒 No main quote, generating new for lock screen")
                    baseQuoteForLockScreen = QuoteGenerator.getRandomQuoteFromTopics(
                        topics: topics,
                        languageCode: languageCode,
                        premium: premium,
                        gender: gender,
                        affirmationPercentage: affirmationPercentage,
                        noMercyPercentage: noMercyPercentage,
                        favorites: favoritesList,
                        planPercentages: planPercentages
                    )
                }
                
                // Pour le lock screen : trouver une citation qui tient dans 3 lignes
                let lockScreenResult = findLockScreenQuote(
                    initialQuote: baseQuoteForLockScreen,
                    topics: topics,
                    languageCode: languageCode,
                    premium: premium,
                    gender: gender,
                    affirmationPercentage: affirmationPercentage,
                    noMercyPercentage: noMercyPercentage,
                    favoritesList: favoritesList,
                    planPercentages: planPercentages
                )
                let lockScreenQuote = lockScreenResult.quote
                let lockScreenFontSize = lockScreenResult.fontSize
                
                // Sauvegarder la citation et la taille de police pour le lock screen
                defaults.set(lockScreenQuote.text, forKey: "widgetLockScreenQuote")
                defaults.set(lockScreenFontSize, forKey: "widgetLockScreenFontSize")
                
                // Sauvegarder aussi les métadonnées de la citation du lock screen
                let lockScreenMetadata = QuoteMetadataPayload(
                    quote: lockScreenQuote.text,
                    category: lockScreenQuote.category,
                    signature: lockScreenQuote.signature,
                    bookTitle: lockScreenQuote.bookTitle,
                    url: lockScreenQuote.url,
                    languageCode: languageCode,
                    date: now
                )
                let cleanedLockScreenMetadata = cleanDictionaryForUserDefaults(lockScreenMetadata.toDayQuoteDictionary())
                defaults.set(cleanedLockScreenMetadata, forKey: "widgetLockScreenQuoteDetails")
                defaults.set(lockScreenQuote.signature, forKey: "widgetLockScreenQuoteSignature")
                defaults.set(lockScreenQuote.bookTitle, forKey: "widgetLockScreenQuoteBook")
                defaults.set(lockScreenQuote.url, forKey: "widgetLockScreenQuoteURL")
                
                print("[widget] 🔒 Lock screen quote regenerated - fontSize=\(lockScreenFontSize)")
            }
            
            if forceNewQuote {
                defaults.set(false, forKey: "widgetForceNewQuote")
                defaults.set(false, forKey: "widgetForceLockScreenQuoteOnly")
            }
            defaults.synchronize()
            print("[widget] Generated quote - category=\(quoteCategory ?? "nil") languageCode=\(languageCode)")
            } else if let saved = savedQuote, !saved.isEmpty {
                quoteText = saved
                quoteLanguage = defaults.string(forKey: widgetQuoteLanguageKey) ?? languageCode
                if let storedMetadata = defaults.dictionary(forKey: widgetQuoteDetailsKey) as? [String: Any] {
                    currentMetadataDict = storedMetadata
                    quoteCategory = storedMetadata["category"] as? String
                    quoteSignature = storedMetadata["signature"] as? String
                    quoteBookTitle = storedMetadata["bookTitle"] as? String
                    quoteURL = storedMetadata["url"] as? String
                    
                    // 🔧 FIX: Mettre à jour widgetCurrentTopic avec la catégorie de la citation choisie depuis l'app
                    if let category = quoteCategory {
                        defaults.set(category, forKey: "widgetCurrentTopic")
                        // 🔧 Force premium=true pour trouver la citation choisie même si elle n'est pas gratuite
                        let quotes = QuoteGenerator.getQuotesForTopicSortedByLength(
                            topicId: category,
                            languageCode: languageCode,
                            premium: true, // Force premium pour les citations choisies
                            gender: gender
                        )
                        if let index = quotes.firstIndex(where: { $0.text == quoteText }) {
                            defaults.set(index, forKey: "widgetCurrentQuoteIndex")
                            print("[widget] 💾 Updated topic to \(category) and index to \(index) for chosen quote (premium forced)")
                        } else {
                            print("[widget] ⚠️ Quote '\(quoteText.prefix(30))...' not found in topic \(category) even with premium=true")
                        }
                    } else {
                        print("[widget] ⚠️ No category found in metadata for chosen quote")
                    }
                } else if let favoriteDict = favoritesList.first(where: { ($0["quote"] as? String) == saved }) {
                    currentMetadataDict = favoriteDict
                    quoteCategory = favoriteDict["category"] as? String
                    quoteSignature = favoriteDict["signature"] as? String
                    quoteBookTitle = favoriteDict["bookTitle"] as? String
                    quoteURL = favoriteDict["url"] as? String
                    let cleanedFavoriteDict = cleanDictionaryForUserDefaults(favoriteDict)
                    defaults.set(cleanedFavoriteDict, forKey: widgetQuoteDetailsKey)
                    defaults.set(quoteSignature, forKey: "widgetQuoteSignature")
                    defaults.set(quoteBookTitle, forKey: "widgetQuoteBook")
                    defaults.set(quoteURL, forKey: "widgetQuoteURL")
                    
                    // 🔧 FIX: Mettre à jour widgetCurrentTopic avec la catégorie du favori
                    if let category = quoteCategory {
                        defaults.set(category, forKey: "widgetCurrentTopic")
                        // 🔧 Force premium=true pour trouver la citation favorite même si elle n'est pas gratuite
                        let quotes = QuoteGenerator.getQuotesForTopicSortedByLength(
                            topicId: category,
                            languageCode: languageCode,
                            premium: true, // Force premium pour les favoris
                            gender: gender
                        )
                        if let index = quotes.firstIndex(where: { $0.text == quoteText }) {
                            defaults.set(index, forKey: "widgetCurrentQuoteIndex")
                            print("[widget] 💾 Updated topic to \(category) and index to \(index) for favorite quote (premium forced)")
                        } else {
                            print("[widget] ⚠️ Favorite quote '\(quoteText.prefix(30))...' not found in topic \(category) even with premium=true")
                        }
                    }
                }

                // Recalculer la taille pour le widget principal. Si la citation sauvegardée ne tient pas à 15pt,
                // générer de nouvelles citations jusqu'à en trouver une qui tient, sinon utiliser la quote courte par défaut.
                let safeThemeIndexWidget = max(0, min(themeIndex, allAppThemes.count - 1))
                let themeWidget = allAppThemes[safeThemeIndexWidget]
                // Utiliser widgetBaseFontSize comme taille de base et maximale
                let computeWidgetFontSize: (String) -> CGFloat? = { text in
                    bestWidgetFontSize(
                        text: text,
                        baseSize: CGFloat(widgetBaseFontSize),
                        minSize: 15.0,
                        maxSize: CGFloat(widgetBaseFontSize),
                        width: effectiveWidth,
                        maxLines: 5,
                        fontFamily: nil,
                        maxHeight: effectiveMaxHeight
                    )
                }
                
                var widgetFontSize: CGFloat = CGFloat(widgetBaseFontSize)
                var savedFits = false
                print("[widget] Testing saved quote: \(quoteText.count) chars - baseSize=\(widgetBaseFontSize)pt, effectiveWidth=\(effectiveWidth)pt")
                let quoteTextWithName = replaceNamePlaceholder(quoteText, userName: userName)
                if let fittingSize = computeWidgetFontSize(quoteTextWithName) {
                    widgetFontSize = fittingSize
                    savedFits = true
                    print("[widget] ✓ Saved quote ACCEPTED at fontSize=\(fittingSize)pt")
                } else {
                    print("[widget] ⚠️ Saved quote REFUSED: doesn't fit even at minSize=15pt, searching for alternative...")
                    var widgetAttempts = 0
                    let maxWidgetAttempts = 50
                    var widgetQuote = QuoteGenerator.getRandomQuoteFromTopics(
                        topics: topics,
                        languageCode: languageCode,
                        premium: premium,
                        gender: gender,
                        affirmationPercentage: affirmationPercentage,
                        noMercyPercentage: noMercyPercentage,
                        favorites: favoritesList,
                        planPercentages: planPercentages
                    )
                    while widgetAttempts < maxWidgetAttempts {
                        let widgetQuoteTextWithName = replaceNamePlaceholder(widgetQuote.text, userName: userName)
                        if let fittingSize = computeWidgetFontSize(widgetQuoteTextWithName) {
                            widgetFontSize = fittingSize
                            quoteText = widgetQuote.text
                            quoteCategory = widgetQuote.category
                            quoteSignature = widgetQuote.signature
                            quoteBookTitle = widgetQuote.bookTitle
                            quoteURL = widgetQuote.url
                            savedFits = true
                            print("[widget] Found alternative quote that fits at fontSize=\(widgetFontSize) (attempt \(widgetAttempts + 1))")
                            break
                        }
                        widgetQuote = QuoteGenerator.getRandomQuoteFromTopics(
                            topics: topics,
                            languageCode: languageCode,
                            premium: premium,
                            gender: gender,
                            affirmationPercentage: affirmationPercentage,
                            noMercyPercentage: noMercyPercentage,
                            favorites: favoritesList,
                            planPercentages: planPercentages
                        )
                        widgetAttempts += 1
                    }
                    
                    if !savedFits {
                        // Fallback ultra-court pour garantir le fit
                        let fallbackShort = QuoteLibrary.defaultQuoteResult(languageCode: languageCode)
                        let fallbackTextWithName = replaceNamePlaceholder(fallbackShort.text, userName: userName)
                        if let fittingSize = computeWidgetFontSize(fallbackTextWithName) {
                            widgetFontSize = fittingSize
                        } else {
                            widgetFontSize = 14.0
                        }
                        quoteText = fallbackShort.text
                        quoteCategory = fallbackShort.category
                        quoteSignature = fallbackShort.signature
                        quoteBookTitle = fallbackShort.bookTitle
                        quoteURL = fallbackShort.url
                        print("[widget] ⚠️ Using default short quote after saved quote failed to fit; fontSize=\(widgetFontSize)")
                    }
                }
                defaults.set(widgetFontSize, forKey: "widgetMainFontSize")
                
                // Vérifier si la citation du lock screen existe, sinon la régénérer si nécessaire
                let savedLockScreenQuote = defaults.string(forKey: "widgetLockScreenQuote")
                if savedLockScreenQuote == nil || savedLockScreenQuote?.isEmpty == true {
                    // Régénérer une citation pour le lock screen si elle n'existe pas
                    let savedQuoteResult = QuoteResult(
                        text: saved,
                        category: quoteCategory,
                        signature: quoteSignature,
                        bookTitle: quoteBookTitle,
                        url: quoteURL
                    )
                    let lockScreenResult = findLockScreenQuote(
                        initialQuote: savedQuoteResult,
                                topics: topics,
                                languageCode: languageCode,
                                premium: premium,
                                gender: gender,
                                affirmationPercentage: affirmationPercentage,
                                noMercyPercentage: noMercyPercentage,
                        favoritesList: favoritesList,
                                planPercentages: planPercentages
                            )
                    let lockScreenQuote = lockScreenResult.quote
                    let lockScreenFontSize = lockScreenResult.fontSize
                    
                    defaults.set(lockScreenQuote.text, forKey: "widgetLockScreenQuote")
                    defaults.set(lockScreenFontSize, forKey: "widgetLockScreenFontSize")
                    
                    // Sauvegarder aussi les métadonnées de la citation du lock screen
                    let lockScreenMetadata = QuoteMetadataPayload(
                        quote: lockScreenQuote.text,
                        category: lockScreenQuote.category,
                        signature: lockScreenQuote.signature,
                        bookTitle: lockScreenQuote.bookTitle,
                        url: lockScreenQuote.url,
                        languageCode: languageCode,
                        date: now
                    )
                    let cleanedLockScreenMetadata = cleanDictionaryForUserDefaults(lockScreenMetadata.toDayQuoteDictionary())
                    defaults.set(cleanedLockScreenMetadata, forKey: "widgetLockScreenQuoteDetails")
                    defaults.set(lockScreenQuote.signature, forKey: "widgetLockScreenQuoteSignature")
                    defaults.set(lockScreenQuote.bookTitle, forKey: "widgetLockScreenQuoteBook")
                    defaults.set(lockScreenQuote.url, forKey: "widgetLockScreenQuoteURL")
                }
                
                // Note: metadata lookup removed - using stored metadata or favorites only
                print("[widget] Reusing saved quote - savedLanguage=\(quoteLanguage) currentLanguage=\(languageCode)")
            } else {
                // Fallback : générer une citation normalement
                let fallback = QuoteGenerator.getRandomQuoteFromTopics(
                    topics: topics,
                    languageCode: languageCode,
                    premium: premium,
                    gender: gender,
                    affirmationPercentage: affirmationPercentage,
                    noMercyPercentage: noMercyPercentage,
                    favorites: favoritesList,
                    planPercentages: planPercentages
                )
                quoteText = fallback.text
                quoteCategory = fallback.category
                quoteSignature = fallback.signature
                quoteBookTitle = fallback.bookTitle
                quoteURL = fallback.url
                
                // Pour le lock screen : trouver une citation qui tient dans 3 lignes
                let lockScreenResult = findLockScreenQuote(
                    initialQuote: fallback,
                            topics: topics,
                            languageCode: languageCode,
                            premium: premium,
                            gender: gender,
                            affirmationPercentage: affirmationPercentage,
                            noMercyPercentage: noMercyPercentage,
                    favoritesList: favoritesList,
                            planPercentages: planPercentages
                        )
                let lockScreenQuote = lockScreenResult.quote
                let lockScreenFontSize = lockScreenResult.fontSize
                
                // Pour le widget principal (4 lignes) : calculer la taille réelle qui tient, sinon générer une autre citation
                let widgetResult = findWidgetQuote(
                    initialQuote: fallback,
                    themeIndex: themeIndex,
                    effectiveWidth: effectiveWidth,
                    effectiveMaxHeight: effectiveMaxHeight,
                    userName: userName,
                            topics: topics,
                            languageCode: languageCode,
                            premium: premium,
                            gender: gender,
                            affirmationPercentage: affirmationPercentage,
                            noMercyPercentage: noMercyPercentage,
                    favoritesList: favoritesList,
                    planPercentages: planPercentages,
                    useThemeFontFamily: false
                        )
                let widgetQuote = widgetResult.quote
                let widgetFontSize = widgetResult.fontSize
                
                // Si on a dû utiliser une citation différente, mettre à jour les métadonnées
                if widgetQuote.text != quoteText {
                    quoteText = widgetQuote.text
                    quoteCategory = widgetQuote.category
                    quoteSignature = widgetQuote.signature
                    quoteBookTitle = widgetQuote.bookTitle
                    quoteURL = widgetQuote.url
                }
                
                let metadata = QuoteMetadataPayload(
                    quote: quoteText,
                    category: quoteCategory,
                    signature: quoteSignature,
                    bookTitle: quoteBookTitle,
                    url: quoteURL,
                    languageCode: languageCode,
                    date: now
                )
                currentMetadataDict = metadata.toDayQuoteDictionary()
                defaults.set(quoteText, forKey: "widgetQuote")
                let cleanedMetadata = cleanDictionaryForUserDefaults(currentMetadataDict)
                defaults.set(cleanedMetadata, forKey: widgetQuoteDetailsKey)
                defaults.set(languageCode, forKey: widgetQuoteLanguageKey)
                defaults.set(quoteSignature, forKey: "widgetQuoteSignature")
                defaults.set(quoteBookTitle, forKey: "widgetQuoteBook")
                defaults.set(quoteURL, forKey: "widgetQuoteURL")
                defaults.set(now.timeIntervalSince1970, forKey: "widgetQuoteTimestamp")
                
                // Sauvegarder la citation et la taille de police pour le lock screen
                defaults.set(lockScreenQuote.text, forKey: "widgetLockScreenQuote")
                defaults.set(lockScreenFontSize, forKey: "widgetLockScreenFontSize")
                
                // Sauvegarder aussi les métadonnées de la citation du lock screen
                let lockScreenMetadata = QuoteMetadataPayload(
                    quote: lockScreenQuote.text,
                    category: lockScreenQuote.category,
                    signature: lockScreenQuote.signature,
                    bookTitle: lockScreenQuote.bookTitle,
                    url: lockScreenQuote.url,
                    languageCode: languageCode,
                    date: now
                )
                let cleanedLockScreenMetadata = cleanDictionaryForUserDefaults(lockScreenMetadata.toDayQuoteDictionary())
                defaults.set(cleanedLockScreenMetadata, forKey: "widgetLockScreenQuoteDetails")
                defaults.set(lockScreenQuote.signature, forKey: "widgetLockScreenQuoteSignature")
                defaults.set(lockScreenQuote.bookTitle, forKey: "widgetLockScreenQuoteBook")
                defaults.set(lockScreenQuote.url, forKey: "widgetLockScreenQuoteURL")
                
                // Sauvegarder la taille de police calculée pour le widget principal
                defaults.set(widgetFontSize, forKey: "widgetMainFontSize")
                
                if forceNewQuote {
                    defaults.set(false, forKey: "widgetForceNewQuote")
                }
                defaults.synchronize()
                print("[widget] Fallback quote used")
                print("[widget] Lock screen quote fontSize=\(lockScreenFontSize)")
            }
        }

        if quoteCategory == nil, let category = currentMetadataDict["category"] as? String {
            quoteCategory = category
        }
        if quoteSignature == nil, let signature = currentMetadataDict["signature"] as? String {
            quoteSignature = signature
        }
        if quoteBookTitle == nil, let bookTitle = currentMetadataDict["bookTitle"] as? String {
            quoteBookTitle = bookTitle
        }
        if quoteURL == nil, let urlString = currentMetadataDict["url"] as? String {
            quoteURL = urlString
        }

        // S'assurer que quoteText n'est jamais vide
        let finalQuoteText: String = {
            if quoteText.isEmpty {
                print("[widget] ⚠️ quoteText is empty, using default quote")
                return QuoteLibrary.defaultQuoteResult(languageCode: quoteLanguage).text
            }
            return quoteText
        }()
        
        let isFavorite = favoriteQuotes.contains(finalQuoteText)
        
        // Les icônes sont visibles par défaut
        let finalShowShareButton = showShareButton
        let finalShowLikeButton = showLikeButton
        
        // Générer une seule entrée (animation supprimée)
        var entries: [BusinessMindsetEntry] = []
        
        // Récupérer la taille de police pour le lock screen (sauvegardée ou par défaut)
        let savedLockScreenFontSize = defaults.double(forKey: "widgetLockScreenFontSize")
        let lockScreenFontSize: CGFloat = savedLockScreenFontSize > 0 ? savedLockScreenFontSize : 12.0
        
        // Récupérer la taille de police pour le widget principal (sauvegardée ou calculer depuis le thème)
        let savedWidgetFontSize = defaults.double(forKey: "widgetMainFontSize")
        
        // Déterminer le thème à utiliser (app ou custom)
        let actualThemeIndex: Int
        let selectedTheme: ThemeData
        
        if isCustomTheme {
            // Utiliser un thème custom
            if let customThemes = defaults.array(forKey: "themeCustomDatasMap") as? [[String: Any]],
               themeIndex >= 0 && themeIndex < customThemes.count {
                print("[widget] 📦 Using custom theme at index \(themeIndex)")
                let customThemeData = customThemes[themeIndex]
                
                // Convertir le dictionnaire en ThemeData
                let color1 = customThemeData["color1"] as? UInt32 ?? 0xFF1f1f1f
                let fontFamily = customThemeData["fontfamily"] as? String ?? "InterTight"
                let fontColor = customThemeData["fontcolor"] as? UInt32 ?? 0xFFFFFFFF
                let fontSize = (customThemeData["fontsize"] as? Double).map { Int($0) } ?? 18
                let name = customThemeData["name"] as? String ?? "Custom"
                let isImageTheme = customThemeData["isImage"] as? Bool ?? false
                let imageName = customThemeData["imageName"] as? String
                
                selectedTheme = ThemeData(
                    color1: color1,
                    fontFamily: fontFamily,
                    fontColor: fontColor,
                    fontSize: fontSize,
                    name: name,
                    isImage: isImageTheme,
                    imageName: imageName
                )
                actualThemeIndex = themeIndex
                print("[widget] 🎨 Custom theme loaded: name='\(name)', isImage=\(isImageTheme), widgetImageName=\(customThemeData["widgetImageName"] ?? "nil")")
            } else {
                print("[widget] ⚠️ Custom theme requested but not found, fallback to app theme 0")
                let safeThemeIndex = max(0, min(themeIndex, allAppThemes.count - 1))
                selectedTheme = allAppThemes[safeThemeIndex]
                actualThemeIndex = safeThemeIndex
            }
        } else {
            // Utiliser un thème de l'app
            let safeThemeIndex = max(0, min(themeIndex, allAppThemes.count - 1))
            selectedTheme = allAppThemes[safeThemeIndex]
            actualThemeIndex = safeThemeIndex
            print("[widget] 📦 Using app theme at index \(safeThemeIndex)")
        }
        
        let widgetFontSize: CGFloat
        if savedWidgetFontSize > 0 {
            widgetFontSize = savedWidgetFontSize
        } else {
            // Si pas sauvegardée, utiliser la taille du thème ou calculer si nécessaire
            widgetFontSize = CGFloat(selectedTheme.fontSize)
        }
        
        print("[widget] 🎨 Theme selected: index=\(actualThemeIndex), name='\(selectedTheme.name)', fontFamily='\(selectedTheme.fontFamily)', fontSize=\(selectedTheme.fontSize)")
        print("[widget] Widget fontSize=\(widgetFontSize)")
        
        let entry = BusinessMindsetEntry(
            date: now,
            themeIndex: actualThemeIndex,
            quoteText: finalQuoteText,
            category: quoteCategory,
            signature: quoteSignature,
            bookTitle: quoteBookTitle,
            url: quoteURL,
            languageCode: quoteLanguage,
            isConfigured: isConfigured,
            isPreview: false,
            showShareButton: finalShowShareButton,
            showLikeButton: finalShowLikeButton,
            isFavorite: isFavorite,
            isPremium: premium,
            isSubscriptionStale: false,
            lockScreenFontSize: lockScreenFontSize,
            widgetFontSize: widgetFontSize
        )
        entries.append(entry)
        
        print("[widget] Entry summary -> themeIndex: \(entries.first?.themeIndex ?? 0), showShare: \(entries.first?.showShareButton ?? false), showLike: \(entries.first?.showLikeButton ?? false), entries count: \(entries.count)")
        
        let timeline = Timeline(entries: entries, policy: .after(schedule.nextTrigger))
        print("[widget] Timeline created with \(entries.count) entries; next policy trigger at \(nextTriggerString)")
        
        completion(timeline)
    }
}

// MARK: - Widget View
struct BusinessMindsetWidgetView: View {
    var entry: BusinessMindsetEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        let _ = print("[widget] 🎯 View body called - widgetFamily=\(String(describing: widgetFamily)), themeIndex=\(entry.themeIndex)")
        return Group {
            switch widgetFamily {
            case .accessoryRectangular:
                accessoryRectangularView
            case .accessoryInline:
                accessoryInlineView
            default:
                systemMediumView
            }
        }
    }
    
    // MARK: - System Medium View (Home Screen)
    private var systemMediumView: some View {
        GeometryReader { geometry in
            let theme = BusinessMindsetWidgetViewModel.themeData(for: entry.themeIndex)
            let _ = print("[widget] 📱 systemMediumView - themeIndex=\(entry.themeIndex), name='\(theme.name)', fontFamily='\(theme.fontFamily)', fontSize=\(theme.fontSize)")
            
            // LISTER TOUTES LES POLICES DISPONIBLES (DEBUG)
            let allFontFamilies = UIFont.familyNames.sorted()
            let _ = print("[widget] 📚 Font families available (\(allFontFamilies.count)): \(allFontFamilies.prefix(10).joined(separator: ", "))...")
            
            // DIAGNOSTIC: Vérifier les polices chargées par le bundle
            if let bundlePath = Bundle.main.path(forResource: "BebasNeue-Regular", ofType: "ttf") {
                let _ = print("[widget] ✅ Font file BebasNeue-Regular.ttf found in bundle: \(bundlePath)")
            } else {
                let _ = print("[widget] ❌ Font file BebasNeue-Regular.ttf NOT found in bundle")
            }
            
            // Lister tous les fichiers .ttf dans le bundle
            if let resourcePath = Bundle.main.resourcePath {
                let _ = print("[widget] 📂 Resources path: \(resourcePath)")
                let fileManager = FileManager.default
                if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                    let ttfFiles = files.filter { $0.hasSuffix(".ttf") }
                    let _ = print("[widget] 📄 TTF files found in bundle (\(ttfFiles.count)): \(ttfFiles.prefix(5).joined(separator: ", "))...")
                }
            }
            
            let iconDimension = max(8, min(geometry.size.width, geometry.size.height) * 0.120) // Un cran plus grand
            // Couleur du texte & des icônes :
            // - en prévisualisation iOS (page de choix des tailles) : blanc cassé fixe 0xFFfff9ee
            // - en usage normal : couleur du thème
            let baseFontColor = Color(hex: theme.fontColor)
            let textAndIconColor = entry.isPreview ? Color(hex: 0xFFfff9ee) : baseFontColor
            let iconColor = textAndIconColor
            
            // Récupérer le nom d'utilisateur pour remplacer %NAME%
            let defaults = widgetUserDefaults()
            let userName = defaults.string(forKey: "userName") ?? defaults.string(forKey: "name")
            let displayQuoteText = replaceNamePlaceholder(entry.quoteText, userName: userName)
            
            // Utiliser la taille de police calculée pour le widget (sauvegardée ou celle de l'entrée)
            let savedWidgetFontSize = defaults.double(forKey: "widgetMainFontSize")
            let finalWidgetFontSize: CGFloat = savedWidgetFontSize > 0 ? savedWidgetFontSize : entry.widgetFontSize
            
            // Créer la police AVANT le Text pour pouvoir logger
            let quoteFont = customFont(family: theme.fontFamily, size: finalWidgetFontSize)
            let _ = print("[widget] 🎯 Font created for quote - fontFamily='\(theme.fontFamily)', fontSize=\(finalWidgetFontSize)")
            
            // Contenu uniquement (fond géré par containerBackground)
            ZStack {
                // Contenu principal : comportement différent selon l'état de configuration / premium
                if entry.isConfigured && (entry.isPremium || entry.isPreview) {
                    // Widget configuré et premium : tap → ouvre la home
                    Link(destination: URL(string: "businessmindset://home")!) {
                        HStack {
                            Spacer(minLength: 0)
                            Text(displayQuoteText)
                                .font(quoteFont)
                                .foregroundColor(textAndIconColor)
                                .onAppear {
                                    print("[widget] 🎨 Text displayed - fontFamily='\(theme.fontFamily)', fontSize=\(finalWidgetFontSize)")
                                }
                                .multilineTextAlignment(.center)
                                .frame(
                                    maxWidth: geometry.size.width * 0.85,
                                    alignment: .center
                                )
                                .lineLimit(5)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: false)
                            Spacer(minLength: 0)
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: geometry.size.height * 0.95,
                            alignment: .center
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else if entry.isConfigured && entry.isSubscriptionStale {
                    let stalePrompt = entry.languageCode.lowercased().hasPrefix("fr")
                        ? "Ouvrez l'application pour mettre à jour"
                        : "Open the app to update"
                    Link(destination: URL(string: "businessmindset://home")!) {
                        HStack {
                            Spacer(minLength: 0)
                            Text(stalePrompt)
                                .font(.system(size: min(16, geometry.size.height * 0.16), weight: .medium))
                                .foregroundColor(textAndIconColor)
                                .multilineTextAlignment(.center)
                                .frame(
                                    maxWidth: geometry.size.width * 0.85,
                                    alignment: .center
                                )
                                .lineLimit(3)
                                .lineSpacing(2)
                            Spacer(minLength: 0)
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: geometry.size.height * 0.65,
                            alignment: .center
                        )
                        .padding(.vertical, max(8, geometry.size.height * 0.05))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else if entry.isConfigured && !entry.isPremium {
                    // Widget configuré mais pas premium : message "abonnez-vous"
                    let premiumPrompt = NSLocalizedString("widget_premium_required", comment: "")
                    
                    Link(destination: URL(string: "businessmindset://home")!) {
                        HStack {
                            Spacer(minLength: 0)
                            Text(premiumPrompt)
                                .font(.system(size: min(16, geometry.size.height * 0.16), weight: .medium))
                                .foregroundColor(textAndIconColor)
                                .multilineTextAlignment(.center)
                                .frame(
                                    maxWidth: geometry.size.width * 0.85,
                                    alignment: .center
                                )
                                .lineLimit(3)
                                .lineSpacing(2)
                            Spacer(minLength: 0)
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: geometry.size.height * 0.65,
                            alignment: .center
                        )
                        .padding(.vertical, max(8, geometry.size.height * 0.05))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    // Widget jamais configuré : message "Tap to configure" qui ouvre la page Widget
                    let isFrench = entry.languageCode.lowercased().hasPrefix("fr")
                    let prompt = isFrench
                        ? "Touchez pour configurer ce widget"
                        : "Tap to configure"
                    
                    Link(destination: URL(string: "businessmindset://widget")!) {
                        HStack {
                            Spacer(minLength: 0)
                            Text(prompt)
                                .font(.system(size: min(18, geometry.size.height * 0.18), weight: .medium))
                                .foregroundColor(textAndIconColor)
                                .multilineTextAlignment(.center)
                                .frame(
                                    maxWidth: geometry.size.width * 0.85,
                                    alignment: .center
                                )
                                .minimumScaleFactor(1.2)
                                .lineLimit(2)
                                .lineSpacing(2)
                            Spacer(minLength: 0)
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: geometry.size.height * 0.65,
                            alignment: .center
                        )
                        .padding(.vertical, max(8, geometry.size.height * 0.05))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            
                // Icônes uniquement affichées si premium (ou preview)
                if entry.isPremium || entry.isPreview {
                VStack {
                    Spacer()
                    
                    // Icônes en bas (share à gauche, like à droite)
                    HStack {
                        // Icône share à gauche
                        if entry.showShareButton {
                            shareButton(iconDimension: iconDimension, iconColor: iconColor)
                        } else {
                            // Espaceur si pas de bouton share pour garder le layout
                            Spacer()
                        }
                        
                        // COMMENTÉ: Flèches de navigation gauche/droite
                        // Flèche gauche (citation précédente)
                        /*
                        if #available(iOSApplicationExtension 17.0, *) {
                            Button(intent: NavigateQuotePreviousIntent()) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: iconDimension * 0.8))
                                    .foregroundStyle(iconColor)
                                    .padding(iconDimension * 0.2)
                            }
                            .buttonStyle(.plain)
                        }
                        */
                        
                        Spacer()
                        
                        // COMMENTÉ: Flèches de navigation gauche/droite
                        // Flèche droite (citation suivante)
                        /*
                        if #available(iOSApplicationExtension 17.0, *) {
                            Button(intent: NavigateQuoteNextIntent()) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: iconDimension * 0.8))
                                    .foregroundStyle(iconColor)
                                    .padding(iconDimension * 0.2)
                            }
                            .buttonStyle(.plain)
                        }
                        */
                        
                        // Icône favorite à droite
                        if entry.showLikeButton {
                            favoriteButton(iconDimension: iconDimension, iconColor: iconColor)
                        } else {
                            // Espaceur si pas de bouton like pour garder le layout
                            Spacer()
                        }
                    }
                        .padding(.horizontal, 0)
                        .padding(.bottom, 0)
                }
                } // end if isPremium || isPreview
            }
            .onAppear {
                // Mémoriser les dimensions exactes utilisées dans la vue
                // measureWidth DOIT correspondre au maxWidth du Text (0.85)
                let measureWidth = geometry.size.width * 0.85
                defaults.set(measureWidth, forKey: "widgetMeasuredWidth")
                // measureMaxHeight DOIT correspondre au maxHeight du HStack (0.95)
                let measureMaxHeight = geometry.size.height * 0.95
                defaults.set(measureMaxHeight, forKey: "widgetMeasuredMaxHeight")
                print("[widget] 📏 Measured widget dimensions: width=\(geometry.size.width) → \(measureWidth) (85%), height=\(geometry.size.height) → \(measureMaxHeight) (95%)")
            }
            .modifier(
                WidgetBackgroundModifier(
                    theme: theme,
                    useTransparentBackground: false,
                    useFixedPreviewBackground: entry.isPreview
                )
            )
        }
    }
    
    // MARK: - Accessory Rectangular View (Lock Screen)
    private var accessoryRectangularView: some View {
        let theme = allAppThemes[entry.themeIndex]
        let defaults = widgetUserDefaults()
        
        // Si le widget n'est pas configuré, afficher le message "Tap to configure"
        var lockScreenQuoteText: String
        var destinationURL: URL
        var fontSize: CGFloat
        
        if !entry.isConfigured {
            // Widget non configuré : afficher le message d'invite
            let isFrench = entry.languageCode.lowercased().hasPrefix("fr")
            lockScreenQuoteText = isFrench
                ? "Touchez pour configurer ce widget"
                : "Tap to configure"
            // Ouvrir la page de configuration du widget
            destinationURL = URL(string: "businessmindset://widget")!
            fontSize = 12.0
            print("[widget] 🔒 Lock screen: Widget not configured, showing 'Tap to configure'")
        } else if entry.isSubscriptionStale && !entry.isPreview {
            lockScreenQuoteText = entry.languageCode.lowercased().hasPrefix("fr")
                ? "Ouvrez l'application pour mettre à jour"
                : "Open the app to update"
            destinationURL = URL(string: "businessmindset://home")!
            fontSize = 12.0
            print("[widget] 🔒 Lock screen: Subscription state stale, showing refresh prompt")
        } else if !entry.isPremium && !entry.isPreview {
            // Widget configuré mais pas premium : message d'abonnement
            lockScreenQuoteText = NSLocalizedString("widget_premium_required_short", comment: "")
            destinationURL = URL(string: "businessmindset://home")!
            fontSize = 12.0
            print("[widget] 🔒 Lock screen: Not premium, showing subscribe prompt")
        } else {
            // Widget configuré : afficher la citation normale
            // Récupérer la citation spécifique pour le lock screen (ou utiliser celle de l'entry si non trouvée)
            let savedLockScreenQuote = defaults.string(forKey: "widgetLockScreenQuote")
            lockScreenQuoteText = {
                // Priorité 1: Citation sauvegardée pour le lock screen
                if let saved = savedLockScreenQuote, !saved.isEmpty {
                    print("[widget] 🔒 Lock screen: Using saved quote: '\(saved.prefix(60))...'")
                    return saved
                }
                // Priorité 2: Citation de l'entry
                if !entry.quoteText.isEmpty {
                    print("[widget] 🔒 Lock screen: Using entry quote: '\(entry.quoteText.prefix(60))...'")
                    return entry.quoteText
                }
                // Priorité 3: Citation par défaut
                let languageCode = defaults.string(forKey: "widgetQuoteLanguage") ?? "en"
                let defaultQuote = QuoteLibrary.defaultQuoteResult(languageCode: languageCode).text
                print("[widget] ⚠️ Lock screen: Using default quote")
                return defaultQuote
            }()
            // Ouvrir la home
            destinationURL = URL(string: "businessmindset://home?source=lockscreen")!
            
            let savedLockScreenFontSize = defaults.double(forKey: "widgetLockScreenFontSize")
            fontSize = savedLockScreenFontSize > 0 ? savedLockScreenFontSize : 12.0
        }
        
        // Récupérer le nom d'utilisateur pour remplacer %NAME%
        let userName = defaults.string(forKey: "userName") ?? defaults.string(forKey: "name")
        let displayLockScreenQuoteText = replaceNamePlaceholder(lockScreenQuoteText, userName: userName)
        
        print("[widget] 🔒 Lock screen rendering - quote: '\(displayLockScreenQuoteText.prefix(60))...', fontSize: \(fontSize), themeIndex: \(entry.themeIndex), isConfigured: \(entry.isConfigured)")
        
        let content = Link(destination: destinationURL) {
            VStack(alignment: .center, spacing: 2) {
                // Afficher la citation du lock screen (filtrée pour tenir dans 3 lignes)
                // Utiliser foregroundStyle(.primary) pour une meilleure lisibilité sur lock screen
                Text(displayLockScreenQuoteText)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(8)
        }
        .widgetURL(destinationURL)
        
        // Utiliser containerBackground pour iOS 17+, sinon pas de background (iOS 16)
        // Utiliser .fill.tertiary au lieu de .clear pour améliorer la lisibilité
        return Group {
            if #available(iOSApplicationExtension 17.0, *) {
                content.containerBackground(.fill.tertiary, for: .widget)
            } else {
                content
            }
        }
    }
    
    // MARK: - Accessory Inline View (Lock Screen)
    private var accessoryInlineView: some View {
        // Déterminer le texte et l'URL de destination selon l'état de configuration / premium
        var displayText: String
        var destinationURL: URL
        
        if !entry.isConfigured {
            // Widget non configuré : afficher le message d'invite
            let isFrench = entry.languageCode.lowercased().hasPrefix("fr")
            displayText = isFrench
                ? "Touchez pour configurer"
                : "Tap to configure"
            // Ouvrir la page de configuration du widget
            destinationURL = URL(string: "businessmindset://widget")!
            print("[widget] 🔒 Inline lock screen: Widget not configured, showing 'Tap to configure'")
        } else if entry.isSubscriptionStale && !entry.isPreview {
            displayText = entry.languageCode.lowercased().hasPrefix("fr")
                ? "Ouvrez l'application pour mettre à jour"
                : "Open app to update"
            destinationURL = URL(string: "businessmindset://home")!
            print("[widget] 🔒 Inline lock screen: Subscription state stale, showing refresh prompt")
        } else if !entry.isPremium && !entry.isPreview {
            // Widget configuré mais pas premium : message d'abonnement court
            displayText = NSLocalizedString("widget_premium_required_inline", comment: "")
            destinationURL = URL(string: "businessmindset://home")!
            print("[widget] 🔒 Inline lock screen: Not premium, showing subscribe prompt")
        } else {
            // Widget configuré et premium : afficher la citation normale
            let defaults = widgetUserDefaults()
            let userName = defaults.string(forKey: "userName") ?? defaults.string(forKey: "name")
            displayText = replaceNamePlaceholder(entry.quoteText, userName: userName)
            // Ouvrir la home
            destinationURL = URL(string: "businessmindset://home?source=lockscreen")!
        }
        
        let content = Link(destination: destinationURL) {
            HStack(spacing: 4) {
                // Utiliser foregroundStyle(.primary) pour une meilleure lisibilité sur lock screen
                Text(displayText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .widgetURL(destinationURL)
        
        // Utiliser containerBackground pour iOS 17+, sinon pas de background (iOS 16)
        // Utiliser .fill.tertiary au lieu de .clear pour améliorer la lisibilité
        return Group {
            if #available(iOSApplicationExtension 17.0, *) {
                content.containerBackground(.fill.tertiary, for: .widget)
            } else {
                content
            }
        }
    }

    @ViewBuilder
    private func shareButton(iconDimension: CGFloat, iconColor: Color) -> some View {
        if let url = URL(string: "businessmindset://widget/share") {
            Link(destination: url) {
                iconImageView(
                    assetName: "share2",
                    fallbackSystemName: "square.and.arrow.up",
                    iconDimension: iconDimension,
                    iconColor: iconColor
                )
            }
            .buttonStyle(.plain)
        } else {
            iconImageView(
                assetName: "share2",
                fallbackSystemName: "square.and.arrow.up",
                iconDimension: iconDimension,
                iconColor: iconColor
            )
            .opacity(0.5)
        }
    }

    private func shareSubject() -> String {
        if let signature = entry.signature, !signature.isEmpty {
            return signature
        }
        return "Business Mindset"
    }

    @ViewBuilder
    private func favoriteButton(iconDimension: CGFloat, iconColor: Color) -> some View {
        let assetName = entry.isFavorite ? "favoriteplain" : "favorite"
        let fallbackSystemName = entry.isFavorite ? "heart.fill" : "heart"

        if #available(iOSApplicationExtension 17.0, *) {
            Button(intent: ToggleFavoriteIntent(
                quote: entry.quoteText,
                category: entry.category,
                signature: entry.signature,
                bookTitle: entry.bookTitle,
                url: entry.url,
                languageCode: entry.languageCode
            )) {
                iconImageView(
                    assetName: assetName,
                    fallbackSystemName: fallbackSystemName,
                    iconDimension: iconDimension,
                    iconColor: iconColor
                )
            }
            .buttonStyle(.plain)
        } else {
            iconImageView(
                assetName: assetName,
                fallbackSystemName: fallbackSystemName,
                iconDimension: iconDimension,
                iconColor: iconColor
            )
            .opacity(0.5)
        }
    }

    @ViewBuilder
    private func iconImageView(
        assetName: String,
        fallbackSystemName: String,
        iconDimension: CGFloat,
        iconColor: Color
    ) -> some View {
        if let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage.withRenderingMode(.alwaysTemplate))
                .resizable()
                .scaledToFit()
                .frame(width: iconDimension, height: iconDimension)
                .padding(iconDimension * 0.2) // Réduit le padding des icônes
                .foregroundStyle(iconColor)
        } else {
            Image(systemName: fallbackSystemName)
                .font(.system(size: iconDimension))
                .foregroundStyle(iconColor)
                .padding(iconDimension * 0.2) // Réduit le padding des icônes
        }
    }
}

// MARK: - Theme Background View
struct ThemeBackgroundView: View {
    let theme: ThemeData
    let widgetSize: CGSize
    
    var body: some View {
        if theme.isImage, let imageName = theme.imageName, !imageName.isEmpty {
            // Image: affichée avec BoxFit.cover équivalent et centrée
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: widgetSize.width, height: widgetSize.height)
            } else {
                // Fallback si image introuvable
                Color(hex: theme.color1)
            }
        } else {
            // Fond couleur (dégradé ou uni)
            if theme.nbrColor == 1 {
                Color(hex: theme.color1)
            } else if theme.nbrColor == 2 {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: theme.color1),
                        Color(hex: theme.color2 ?? theme.color1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if theme.nbrColor == 3 {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: theme.color1),
                        Color(hex: theme.color2 ?? theme.color1),
                        Color(hex: theme.color3 ?? theme.color1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color(hex: theme.color1)
            }
        }
    }
}

// MARK: - Widget Configuration
struct BusinessMindsetWidget: Widget {
    let kind: String = "BusinessMindsetWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BusinessMindsetWidgetProvider()) { entry in
            let _ = print("[widget] 🔥 BusinessMindsetWidgetView created with entry.themeIndex=\(entry.themeIndex)")
            return BusinessMindsetWidgetView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("widget_display_name", comment: "Widget configuration title"))
        .description(NSLocalizedString("widget_description", comment: "Widget configuration subtitle"))
        .supportedFamilies([.systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Background Helpers
struct WidgetBackgroundModifier: ViewModifier {
    let theme: ThemeData
    let useTransparentBackground: Bool
    let useFixedPreviewBackground: Bool
    
    init(
        theme: ThemeData,
        useTransparentBackground: Bool = false,
        useFixedPreviewBackground: Bool = false
    ) {
        self.theme = theme
        self.useTransparentBackground = useTransparentBackground
        self.useFixedPreviewBackground = useFixedPreviewBackground
    }
    
    @ViewBuilder
    private func widgetBackgroundView() -> some View {
        if useTransparentBackground {
            // Fond transparent avec contenu vide
            EmptyView()
        } else if useFixedPreviewBackground {
            // Fond fixe pour la prévisualisation iOS (page de choix des tailles)
            Color(
                red: 31.0 / 255.0,
                green: 31.0 / 255.0,
                blue: 31.0 / 255.0
            )
        } else {
            // Utilise la même logique que ThemeBackgroundView pour les couleurs et images
            if theme.isImage, let imageName = theme.imageName, !imageName.isEmpty {
                // Charger widgetImageName depuis SharedPreferences pour les thèmes custom
                let defaults = widgetUserDefaults()
                let isCustomTheme = defaults.bool(forKey: "widgetIsCustomTheme")
                let themeIndex = defaults.integer(forKey: "widgetThemeIndex")
                let widgetImageName = getWidgetImageName(defaults: defaults, themeIndex: themeIndex)
                
                // Image: affichée avec BoxFit.cover équivalent et centrée
                if let uiImage = loadThemeImage(imageName, isCustomTheme: isCustomTheme, widgetImageName: widgetImageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } else {
                    // Fallback si image introuvable
                    Color(hex: theme.color1)
                }
            } else {
                // Fond couleur (dégradé ou uni)
                if theme.nbrColor == 1 {
                    Color(hex: theme.color1)
                } else if theme.nbrColor == 2 {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: theme.color1),
                            Color(hex: theme.color2 ?? theme.color1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else if theme.nbrColor == 3 {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: theme.color1),
                            Color(hex: theme.color2 ?? theme.color1),
                            Color(hex: theme.color3 ?? theme.color1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    Color(hex: theme.color1)
                }
            }
        }
    }
    
    func body(content: Content) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            if useTransparentBackground {
                // Fond transparent avec contenu vide (selon https://swiftsenpai.com/development/widget-container-background/)
                content.containerBackground(for: .widget) {
                    // Contenu vide pour fond transparent
                }
            } else {
                content.containerBackground(for: .widget) {
                    widgetBackgroundView() // Utilise les couleurs du thème (dégradé si applicable)
                }
            }
        } else {
            // iOS 16 : pas de containerBackground, on utilise background
            if useTransparentBackground {
                content // Pas de fond pour iOS 16
            } else {
                content.background(widgetBackgroundView())
            }
        }
    }
}

extension View {
    @ViewBuilder
    func widgetContainerBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) {
                Color(red: 18/255, green: 18/255, blue: 20/255, opacity: 0.2)
            }
        } else {
            self.background(Color(red: 18/255, green: 18/255, blue: 20/255))
        }
    }
}

// MARK: - Preview
struct BusinessMindsetWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview non configuré
            BusinessMindsetWidgetView(entry: BusinessMindsetEntry(
                date: Date(),
                themeIndex: 0,
                quoteText: "Success is not final, failure is not fatal: it is the courage to continue that counts.",
                category: "general",
                signature: "Business Mindset",
                bookTitle: nil,
                url: nil,
                languageCode: "en",
                isConfigured: false,
                isPreview: false,
                showShareButton: true,
                showLikeButton: true,
                isFavorite: false,
                isPremium: false,
                isSubscriptionStale: false,
                lockScreenFontSize: 12.0,
                widgetFontSize: CGFloat(allAppThemes[0].fontSize)
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Non configuré")
            
            // Preview configuré - Thème Black
            BusinessMindsetWidgetView(entry: BusinessMindsetEntry(
                date: Date(),
                themeIndex: 0,
                quoteText: "La vue seule de ce widget suffit à combler de joie quiconque en son for intérieur",
                category: "confmind",
                signature: "Business Mindset",
                bookTitle: nil,
                url: nil,
                languageCode: "fr",
                isConfigured: true,
                isPreview: false,
                showShareButton: true,
                showLikeButton: true,
                isFavorite: true,
                isPremium: true,
                isSubscriptionStale: false,
                lockScreenFontSize: 12.0,
                widgetFontSize: CGFloat(allAppThemes[0].fontSize)
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Configuré - Black")
            
            // Preview configuré - Thème avec image
            BusinessMindsetWidgetView(entry: BusinessMindsetEntry(
                date: Date(),
                themeIndex: 25, // skylineTheme
                quoteText: "La vue seule de ce widget suffit à combler de joie quiconque en son for intérieur",
                category: "vispurp",
                signature: "Business Mindset",
                bookTitle: nil,
                url: nil,
                languageCode: "fr",
                isConfigured: true,
                isPreview: false,
                showShareButton: true,
                showLikeButton: true,
                isFavorite: false,
                isPremium: true,
                isSubscriptionStale: false,
                lockScreenFontSize: 12.0,
                widgetFontSize: CGFloat(allAppThemes[25].fontSize)
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Configuré - Skyline")
        }
    }
}


