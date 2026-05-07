import Foundation

// Constante pour personalized_feed
private let personalizedFeedTopicId = "personalized_feed"

// Structure pour représenter une citation avec métadonnées
struct QuoteWithMetadata {
    let quote: QuoteData
    let category: String
    let topicSource: String
    let tone: String?
    let planCategory: String?
    
    func toQuoteResult(languageCode: String) -> QuoteResult {
        let text = languageCode.lowercased().hasPrefix("fr") 
            ? (quote.fr ?? quote.en ?? "")
            : (quote.en ?? quote.fr ?? "")
        
        let signature = quote.signature
        let bookTitle = languageCode.lowercased().hasPrefix("fr")
            ? (quote.bookTitle?.fr ?? quote.bookTitle?.en)
            : (quote.bookTitle?.en ?? quote.bookTitle?.fr)
        
        return QuoteResult(
            text: text,
            category: category,
            signature: signature,
            bookTitle: bookTitle,
            url: quote.url
        )
    }
}

enum QuoteGenerator {
    
    // MARK: - Navigation Helpers
    /// Obtient toutes les citations d'un topic triées par longueur (pour navigation)
    static func getQuotesForTopicSortedByLength(
        topicId: String,
        languageCode: String,
        premium: Bool,
        gender: String?
    ) -> [QuoteResult] {
        guard let quotes = quotesTot[topicId] else {
            return []
        }
        
        let isFemale = gender == "Female"
        var results: [QuoteResult] = []
        
        for quote in quotes {
            // Filtrer par isFree si nécessaire
            if !premium && quote.isFree != true {
                continue
            }
            
            // Exclure womenemp si gender != "Female"
            if topicId == "womenemp" && !isFemale {
                continue
            }
            
            let text = languageCode.lowercased().hasPrefix("fr")
                ? (quote.fr ?? quote.en ?? "")
                : (quote.en ?? quote.fr ?? "")
            
            if !text.isEmpty {
                let signature = quote.signature
                let bookTitle = languageCode.lowercased().hasPrefix("fr")
                    ? (quote.bookTitle?.fr ?? quote.bookTitle?.en)
                    : (quote.bookTitle?.en ?? quote.bookTitle?.fr)
                
                results.append(QuoteResult(
                    text: text,
                    category: topicId,
                    signature: signature,
                    bookTitle: bookTitle,
                    url: quote.url
                ))
            }
        }
        
        // Trier par longueur du texte (plus court d'abord)
        return results.sorted { $0.text.count < $1.text.count }
    }
    
    // Fonction principale pour obtenir une citation aléatoire
    static func getRandomQuoteFromTopics(
        topics: [String],
        languageCode: String,
        premium: Bool,
        gender: String?,
        affirmationPercentage: Int,
        noMercyPercentage: Int,
        favorites: [[String: Any]],
        planPercentages: [String: Double]
    ) -> QuoteResult {
        
        var selectedTopics = topics
        if selectedTopics.isEmpty {
            selectedTopics = ["general"]
        }
        
        // Étape 1 : Choisir un topic aléatoire
        let randomTopicIndex = Int.random(in: 0..<selectedTopics.count)
        let selectedTopicId = selectedTopics[randomTopicIndex]
        
        // Étape 2 : Obtenir les citations disponibles
        let availableQuotes = getAvailableQuotesForTopic(
            topicId: selectedTopicId,
            lang: languageCode,
            premium: premium,
            gender: gender,
            favorites: favorites,
            planPercentages: planPercentages
        )
        
        if availableQuotes.isEmpty {
            // Fallback : toutes les citations
            let allTopics = Array(quotesTot.keys)
            guard let randomCat = allTopics.randomElement(),
                  let quotes = quotesTot[randomCat],
                  let randomQuote = quotes.randomElement() else {
                return QuoteLibrary.defaultQuoteResult(languageCode: languageCode)
            }
            
            let text = languageCode.lowercased().hasPrefix("fr")
                ? (randomQuote.fr ?? randomQuote.en ?? "")
                : (randomQuote.en ?? randomQuote.fr ?? "")
            
            let signature = randomQuote.signature
            let bookTitle = languageCode.lowercased().hasPrefix("fr")
                ? (randomQuote.bookTitle?.fr ?? randomQuote.bookTitle?.en)
                : (randomQuote.bookTitle?.en ?? randomQuote.bookTitle?.fr)
            
            return QuoteResult(
                text: text,
                category: randomCat,
                signature: signature,
                bookTitle: bookTitle,
                url: randomQuote.url
            )
        }
        
        // Étape 3 : Appliquer la pondération par tone
        let weights = availableQuotes.map { quoteWithMeta in
            let tone = quoteWithMeta.tone
            var weight = 1.0 // Poids de base pour tone null
            
            if tone == "affirmative" {
                weight = max(0.01, 1.0 + Double(affirmationPercentage) / 100.0)
            } else if tone == "no mercy" {
                weight = max(0.01, 1.0 + Double(noMercyPercentage) / 100.0)
            }
            
            return weight
        }
        
        let totalWeight = weights.reduce(0.0, +)
        let randomValue = Double.random(in: 0..<totalWeight)
        var cumulative = 0.0
        var selectedIndex = 0
        
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if randomValue <= cumulative {
                selectedIndex = index
                break
            }
        }
        
        return availableQuotes[selectedIndex].toQuoteResult(languageCode: languageCode)
    }
    
    // Fonction pour obtenir les citations disponibles pour un topic
    static func getAvailableQuotesForTopic(
        topicId: String,
        lang: String,
        premium: Bool,
        gender: String?,
        favorites: [[String: Any]],
        planPercentages: [String: Double]
    ) -> [QuoteWithMetadata] {
        
        var availableQuotes: [QuoteWithMetadata] = []
        let isFemale = gender == "Female"
        
        if topicId == personalizedFeedTopicId {
            // My personalized feed
            let planCategories = ["growth", "discipline", "confidence", "strategy"]
            var planPercentagesDict: [String: Double] = [:]
            var totalPercentage = 0.0
            
            for cat in planCategories {
                if let percentage = planPercentages[cat], percentage > 0.0 {
                    planPercentagesDict[cat] = percentage
                    totalPercentage += percentage
                }
            }
            
            // Étape 1 : Tirer au sort un plan selon les pourcentages
            var selectedPlanCategory: String
            if planPercentagesDict.isEmpty || totalPercentage == 0.0 {
                selectedPlanCategory = planCategories.randomElement() ?? planCategories[0]
            } else {
                let randomValue = Double.random(in: 0..<totalPercentage)
                var cumulative = 0.0
                selectedPlanCategory = planCategories.first!
                
                for (key, value) in planPercentagesDict.sorted(by: { $0.key < $1.key }) {
                    cumulative += value
                    if randomValue <= cumulative {
                        selectedPlanCategory = key
                        break
                    }
                }
            }
            
            // Étape 2 : Définir les topics pour chaque plan
            let planToTopics: [String: [String]] = [
                "growth": ["growsucces", "leadership", "entrepreneurship"],
                "discipline": ["focdic", "vispurp"],
                "confidence": ["confmind", "resilience", "womenemp"],
                "strategy": ["salebranding", "wealthmoney"]
            ]
            
            var topicsForPlan = planToTopics[selectedPlanCategory] ?? []
            
            // Filtrer womenemp si gender != "Female"
            topicsForPlan = topicsForPlan.filter { topic in
                if topic == "womenemp" && !isFemale {
                    return false
                }
                return true
            }
            
            if topicsForPlan.isEmpty {
                return availableQuotes
            }
            
            // Étape 3 : Tirer au sort un topic parmi ceux disponibles
            let selectedTopic = topicsForPlan.randomElement() ?? topicsForPlan[0]
            
            // Étape 4 : Parcourir les citations du topic sélectionné
            if let quotes = quotesTot[selectedTopic] {
                for quote in quotes {
                    // Une fois le topic choisi via le plan, on accepte toutes les citations
                    // de ce topic (on ne re-filtre pas par personalizedPlan).
                    
                    // Filtrer par isFree si nécessaire
                    if !premium && quote.isFree != true {
                        continue
                    }
                    
                    let text = lang.lowercased().hasPrefix("fr") 
                        ? (quote.fr ?? quote.en ?? "")
                        : (quote.en ?? quote.fr ?? "")
                    
                    if !text.isEmpty {
                        availableQuotes.append(QuoteWithMetadata(
                            quote: quote,
                            category: selectedTopic,
                            topicSource: "personalized_feed",
                            tone: quote.tone,
                            planCategory: quote.personalizedPlan
                        ))
                    }
                }
            }
            
        } else if topicId == "favoritesquotes" {
            // My favorites
            for fav in favorites {
                guard let quoteText = fav["quote"] as? String, !quoteText.isEmpty else {
                    continue
                }
                
                // Gérer bookTitle : peut être une String dans les favoris
                var bookTitleStruct: BookTitle? = nil
                if let bookTitleString = fav["bookTitle"] as? String, !bookTitleString.isEmpty {
                    // Si bookTitle est une String, créer une structure BookTitle
                    bookTitleStruct = BookTitle(en: bookTitleString, fr: bookTitleString)
                } else if let bookTitleDict = fav["bookTitle"] as? [String: Any] {
                    // Si bookTitle est un dictionnaire
                    bookTitleStruct = BookTitle(
                        en: bookTitleDict["en"] as? String,
                        fr: bookTitleDict["fr"] as? String
                    )
                }
                
                // Créer une QuoteData à partir du favori
                let quote = QuoteData(
                    en: quoteText,
                    fr: quoteText,
                    signature: fav["signature"] as? String,
                    bookTitle: bookTitleStruct,
                    url: fav["url"] as? String,
                    personalizedPlan: nil,
                    isFree: nil,
                    businessic: nil,
                    frombook: nil,
                    tone: nil
                )
                
                availableQuotes.append(QuoteWithMetadata(
                    quote: quote,
                    category: fav["category"] as? String ?? "",
                    topicSource: "favoritesquotes",
                    tone: nil,
                    planCategory: nil
                ))
            }
            
        } else if topicId == "general" {
            // General : toutes les citations
            for (category, quotes) in quotesTot {
                // Exclure womenemp si gender != "Female"
                if category == "womenemp" && !isFemale {
                    continue
                }
                
                for quote in quotes {
                    // Filtrer par isFree si nécessaire
                    if !premium && quote.isFree != true {
                        continue
                    }
                    
                    let text = lang.lowercased().hasPrefix("fr")
                        ? (quote.fr ?? quote.en ?? "")
                        : (quote.en ?? quote.fr ?? "")
                    
                    if !text.isEmpty {
                        availableQuotes.append(QuoteWithMetadata(
                            quote: quote,
                            category: category,
                            topicSource: "general",
                            tone: quote.tone,
                            planCategory: quote.personalizedPlan
                        ))
                    }
                }
            }
            
        } else if topicId == "businessic" {
            // Business Icons : filtrer par businessic == true
            for (category, quotes) in quotesTot {
                for quote in quotes {
                    if quote.businessic != true {
                        continue
                    }
                    
                    if !premium && quote.isFree != true {
                        continue
                    }
                    
                    let text = lang.lowercased().hasPrefix("fr")
                        ? (quote.fr ?? quote.en ?? "")
                        : (quote.en ?? quote.fr ?? "")
                    
                    if !text.isEmpty {
                        availableQuotes.append(QuoteWithMetadata(
                            quote: quote,
                            category: category,
                            topicSource: "businessic",
                            tone: quote.tone,
                            planCategory: quote.personalizedPlan
                        ))
                    }
                }
            }
            
        } else if topicId == "frombook" {
            // From books : filtrer par frombook == true
            for (category, quotes) in quotesTot {
                for quote in quotes {
                    if quote.frombook != true {
                        continue
                    }
                    
                    if !premium && quote.isFree != true {
                        continue
                    }
                    
                    let text = lang.lowercased().hasPrefix("fr")
                        ? (quote.fr ?? quote.en ?? "")
                        : (quote.en ?? quote.fr ?? "")
                    
                    if !text.isEmpty {
                        availableQuotes.append(QuoteWithMetadata(
                            quote: quote,
                            category: category,
                            topicSource: "frombook",
                            tone: quote.tone,
                            planCategory: quote.personalizedPlan
                        ))
                    }
                }
            }
            
        } else if topicId == "no_mercy" {
            // No Mercy : filtrer par tone == "no mercy"
            for (category, quotes) in quotesTot {
                // Exclure womenemp si gender != "Female"
                if category == "womenemp" && !isFemale {
                    continue
                }
                
                for quote in quotes {
                    if quote.tone != "no mercy" {
                        continue
                    }
                    
                    if !premium && quote.isFree != true {
                        continue
                    }
                    
                    let text = lang.lowercased().hasPrefix("fr")
                        ? (quote.fr ?? quote.en ?? "")
                        : (quote.en ?? quote.fr ?? "")
                    
                    if !text.isEmpty {
                        availableQuotes.append(QuoteWithMetadata(
                            quote: quote,
                            category: category,
                            topicSource: "no_mercy",
                            tone: quote.tone,
                            planCategory: quote.personalizedPlan
                        ))
                    }
                }
            }
            
        } else if topicId == "affirmative" {
            // Affirmative : filtrer par tone == "affirmative"
            for (category, quotes) in quotesTot {
                // Exclure womenemp si gender != "Female"
                if category == "womenemp" && !isFemale {
                    continue
                }
                
                for quote in quotes {
                    if quote.tone != "affirmative" {
                        continue
                    }
                    
                    if !premium && quote.isFree != true {
                        continue
                    }
                    
                    let text = lang.lowercased().hasPrefix("fr")
                        ? (quote.fr ?? quote.en ?? "")
                        : (quote.en ?? quote.fr ?? "")
                    
                    if !text.isEmpty {
                        availableQuotes.append(QuoteWithMetadata(
                            quote: quote,
                            category: category,
                            topicSource: "affirmative",
                            tone: quote.tone,
                            planCategory: quote.personalizedPlan
                        ))
                    }
                }
            }
            
        } else {
            // Topic spécifique
            if let quotes = quotesTot[topicId] {
                for quote in quotes {
                    // Filtrer par isFree si nécessaire
                    if !premium && quote.isFree != true {
                        continue
                    }
                    
                    let text = lang.lowercased().hasPrefix("fr")
                        ? (quote.fr ?? quote.en ?? "")
                        : (quote.en ?? quote.fr ?? "")
                    
                    if !text.isEmpty {
                        availableQuotes.append(QuoteWithMetadata(
                            quote: quote,
                            category: topicId,
                            topicSource: topicId,
                            tone: quote.tone,
                            planCategory: quote.personalizedPlan
                        ))
                    }
                }
            }
        }
        
        return availableQuotes
    }
}

