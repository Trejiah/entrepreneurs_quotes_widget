//
//  WidgetQuoteLayoutEngine.swift
//  BusinessMindsetWidget
//
//  Moteur de calcul et layout pour les citations du widget
//

import UIKit
import SwiftUI
import Foundation

// MARK: - Constants
let widgetTextWidthEstimate: CGFloat = 310.0
let widgetMaxHeightEstimate: CGFloat = 150.0
let widgetHeightSafetyMargin: CGFloat = 1.05
let widgetBaseFontSize: Int = 26
let widgetBaseFontOffset: Int = 4
let widgetSizeBoost: Int = 2

// MARK: - Lock Screen Quote Validation
/// Estime si une citation tient dans 3 lignes avec une taille de police donnée
/// Prend en compte les mots longs qui peuvent forcer des retours à la ligne
/// Retourne true si la citation devrait tenir, false sinon
func quoteFitsInLockScreen(_ quote: String, fontSize: CGFloat) -> Bool {
    // Largeur estimée pour le lockscreen (similaire au widget)
    let lockScreenWidth: CGFloat = 310.0
    
    // Plus la police est petite, plus on peut mettre de caractères par ligne
    // Formule de base : maxCharsPerLine = 29 - fontSize
    // Cela donne : 16pt=13, 15pt=14, 14pt=15, 13pt=16, 12pt=17, 11pt=18, 10pt=19
    let baseMaxCharsPerLine = Int(29 - fontSize)
    
    // Détecter les mots larges (> 8 lettres) qui peuvent forcer des retours à la ligne
    let words = quote.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    let longWordsCount = words.filter { $0.count > 8 }.count
    
    // Réduire la largeur effective selon le nombre de mots longs
    // Réduction similaire à celle utilisée dans lineCountForWidget
    // Réduire de 3% par mot large, avec un maximum de 20% de réduction totale
    let reductionFactor = min(Double(longWordsCount) * 0.03, 0.20)
    let effectiveWidth = lockScreenWidth * (1.0 - reductionFactor)
    
    // Ajuster le nombre de caractères par ligne selon la réduction de largeur
    let widthAdjustment = effectiveWidth / lockScreenWidth
    let adjustedMaxCharsPerLine = Int(Double(baseMaxCharsPerLine) * widthAdjustment)
    let maxChars = adjustedMaxCharsPerLine * 3 // Maximum pour 3 lignes
    
    // Si la citation est plus courte que le maximum ajusté, elle devrait tenir
    let fits = quote.count <= maxChars
    
    if !fits {
        print("[widget] [LockScreen] Quote doesn't fit: \(quote.count) chars (max=\(maxChars)), longWords=\(longWordsCount), reduction=\(Int(reductionFactor * 100))%, fontSize=\(fontSize)pt")
    }
    
    return fits
}

/// Trouve une citation qui tient dans 3 lignes en testant différentes tailles de police
/// Retourne (quote, fontSize) ou nil si aucune citation ne convient après plusieurs tentatives
/// Teste d'abord les plus grandes tailles (16pt) puis descend jusqu'à 10pt
func findQuoteThatFits(
    availableQuotes: [QuoteResult],
    maxAttempts: Int = 20
) -> (quote: QuoteResult, fontSize: CGFloat)? {
    let fontSizes: [CGFloat] = [16.0, 15.0, 14.0, 13.0, 12.0, 11.0, 10.0]
    
    // Mélanger les citations pour avoir de la variété
    let shuffledQuotes = availableQuotes.shuffled()
    
    // Pour chaque citation, trouver la plus grande taille de police qui fonctionne
    for quote in shuffledQuotes.prefix(maxAttempts) {
        // Tester de la plus grande à la plus petite taille
        for fontSize in fontSizes {
            if quoteFitsInLockScreen(quote.text, fontSize: fontSize) {
                // Trouvé ! Retourner cette citation avec cette taille
                return (quote, fontSize)
            }
        }
    }
    
    // Si aucune citation ne convient avec aucune taille, prendre la première avec la plus petite taille
    if let firstQuote = availableQuotes.first {
        return (firstQuote, 10.0)
    }
    
    return nil
}

// MARK: - Widget Topics Validation
/// Valide et corrige les topics du widget selon le statut premium
/// Topics accessibles en free : general, favoritesquotes, resilience, vispurp
/// Si des topics verrouillés sont détectés en free, les remplace par "general"
func validateWidgetTopics(topics: [String], premium: Bool, defaults: UserDefaults) -> [String] {
    // Si premium, tous les topics sont valides
    if premium {
        return topics.isEmpty ? ["general"] : topics
    }
    
    // Topics accessibles en free
    let freeTopics: Set<String> = ["general", "favoritesquotes", "resilience", "vispurp"]
    
    // Vérifier si des topics verrouillés sont présents
    let hasLockedTopics = topics.contains { !freeTopics.contains($0) }
    
    if hasLockedTopics {
        // Corriger : utiliser "general" si des topics verrouillés sont présents
        let correctedTopics = ["general"]
        defaults.set(correctedTopics, forKey: "widgetTopicsSelected")
        
        print("[widget] ⚠️ Topics verrouillés détectés - Correction automatique")
        print("   - premium: \(premium)")
        print("   - topics avant: \(topics)")
        print("   - topics après: \(correctedTopics)")
        
        return correctedTopics
    }
    
    // Topics valides, les utiliser (ou "general" par défaut si vide)
    return topics.isEmpty ? ["general"] : topics
}

// MARK: - Widget Quote Validation (4 lignes)
/// Estime si une citation tient dans 4 lignes avec une taille de police donnée
/// Retourne true si la citation devrait tenir, false sinon
func quoteFitsInWidget(_ quote: String, fontSize: CGFloat) -> Bool {
    let baseFontSize: CGFloat = fontSize
    let minFontSize: CGFloat = 14.0
    let charsPerStep = 10   // 🔑 TON curseur de lissage

    let penalty = quote.count / charsPerStep
    let requiredFontSize = max(minFontSize, baseFontSize - CGFloat(penalty))

    return fontSize >= requiredFontSize
}

/// Trouve la taille de police appropriée pour une citation dans le widget (4 lignes)
/// Teste de themeFontSize jusqu'à 12pt minimum
/// Retourne la taille trouvée ou nil si aucune taille ne fonctionne
func findWidgetFontSize(quote: String, themeFontSize: Int) -> CGFloat? {
    let baseSize = CGFloat(themeFontSize)
    let minSize: CGFloat = 15.0
    
    // Tester de la taille du thème jusqu'à 12pt (réduire de 1pt à chaque fois)
    var currentSize = baseSize
    while currentSize >= minSize {
        if quoteFitsInWidget(quote, fontSize: currentSize) {
            return currentSize
        }
        currentSize -= 1.0
    }
    
    // Aucune taille ne fonctionne (même à 12pt)
    return nil
}

// MARK: - Layout Calculations
/// Calcule le nombre de lignes nécessaires et la hauteur réelle avec lineSpacing.
/// Retourne (lineCount, realHeight).
func lineCountForWidget(text: String, fontSize: CGFloat, width: CGFloat, fontFamily: String? = nil) -> (lineCount: Int, realHeight: CGFloat) {
    // Ajouter +2 caractères pour éviter la troncature iOS si on est à la limite
    let textWithMargin = text + "  "
    
    // Utiliser la MÊME police que celle utilisée dans customFont() pour avoir des métriques exactes
    let font: UIFont
    if let fontFamily = fontFamily {
        // Mapping IDENTIQUE à customFont() pour obtenir le nom PostScript exact
        let fontPostScriptMapping: [String: String] = [
            "InterTight": "InterTight-Regular",
            "JosefinSlab": "JosefinSlab-Regular",
            "DidactGothic": "DidactGothic-Regular",
            "Raleway": "Raleway-Regular",
            "YesevaOne": "YesevaOne-Regular",
            "EBGaramond": "EBGaramond-Regular",
            "PlayfairDisplay": "PlayfairDisplay-Regular",
            "MontSerrat": "Montserrat-Regular",
            "Montserrat": "Montserrat-Regular",
            "Lato": "Lato-Regular",
            "SourceSansPro": "SourceSansPro-Regular",
            "Oswald": "Oswald-Regular",
            "Quicksand": "Quicksand-Regular",
            "Quicksans": "Quicksand-Regular",
            "BebasNeue": "BebasNeue-Regular",
            "Ovo": "Ovo",
            "Lustria": "Lustria-Regular",
            "JosefinSans": "JosefinSans-Regular",
            "CormorantGaramond": "CormorantGaramond-Regular",
            "Sanchez": "Sanchez-Regular",
            "Oranlenbaum": "Oranienbaum-Regular",
            "Oranienbaum": "Oranienbaum-Regular",
            "BodoniModa": "BodoniModa18pt-Regular",
            "BodoniModa_18pt": "BodoniModa18pt-Regular",
            "Volkorn": "Volkhov-Regular",
            "AbhayaLibre": "AbhayaLibre-Regular",
            "Allerta": "Allerta-Regular",
            "LibreBaskerville": "LibreBaskerville-Regular"
        ]
        let postScriptName = fontPostScriptMapping[fontFamily] ?? fontFamily
        if let customFont = UIFont(name: postScriptName, size: fontSize) {
            font = customFont
        } else {
            font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        }
    } else {
        font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
    }

    let lineSpacing: CGFloat = 4.0  // Correspond au .lineSpacing(4) du widget
    
    // Détecter les mots larges (> 7 lettres) et ajuster la largeur
    let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    let longWordsCount = words.filter { $0.count > 8 }.count
    // Réduire de 6% par mot large, avec un maximum de 20% de réduction totale
    let reductionFactor = min(Double(longWordsCount) * 0.03, 0.20)
    let effectiveWidth = width * (1.0 - reductionFactor)
    
    // boundingRect NE prend PAS en compte lineSpacing même avec NSParagraphStyle !
    let rect = (textWithMargin as NSString).boundingRect(
        with: CGSize(width: effectiveWidth, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: font],
        context: nil
    )
    
    // rect.height = n × lineHeight (SANS lineSpacing)
    let linesFloat = rect.height / font.lineHeight
    let lineCountMargin: CGFloat = 1.05
    let adjustedLinesFloat = linesFloat * lineCountMargin
    let lineCount = Int(ceil(adjustedLinesFloat))
    
    // Calculer la hauteur RÉELLE avec lineSpacing (ce qui sera affiché dans SwiftUI)
    // Ajouter une marge de sécurité pour les arrondis et différences de rendu
    let baseHeightWithSpacing = CGFloat(lineCount) * font.lineHeight + CGFloat(max(0, lineCount - 1)) * lineSpacing
    let realHeightWithSpacing = baseHeightWithSpacing * widgetHeightSafetyMargin
    
    let marginPercent = Int((widgetHeightSafetyMargin - 1.0) * 100)
    // Calculer le pourcentage de manière plus précise pour éviter les erreurs d'arrondi
    let lineCountMarginPercentValue = (lineCountMargin - 1.0) * 100
    let lineCountMarginPercent = Int(round(lineCountMarginPercentValue))
    print("[widget] [FontSize] lineCountForWidget: text=\(text.count) chars, longWords=\(longWordsCount), width=\(width)pt (effective=\(effectiveWidth)pt, reduction=\(Int(reductionFactor * 100))%), fontSize=\(fontSize)pt, fontFamily='\(fontFamily ?? "system")' → rect.height=\(rect.height)pt / font.lineHeight=\(font.lineHeight)pt = \(linesFloat) × marge lineCount \(lineCountMargin) (\(lineCountMarginPercent)%) = \(adjustedLinesFloat) → \(lineCount) lignes | Hauteur: \(baseHeightWithSpacing)pt + marge hauteur \(marginPercent)% = \(realHeightWithSpacing)pt")
    return (lineCount: lineCount, realHeight: realHeightWithSpacing)
}

/// Trouve la plus grande taille de police (>= minSize) qui tient dans maxLines lignes ET dans maxHeight.
/// Retourne nil si aucune taille ne passe.
func bestWidgetFontSize(
    text: String,
    baseSize: CGFloat,
    minSize: CGFloat = 15.0,
    maxSize: CGFloat? = nil,
    width: CGFloat,
    maxLines: Int = 5,
    fontFamily: String? = nil,
    maxHeight: CGFloat? = nil  // ← Nouveau paramètre pour la hauteur maximale disponible
) -> CGFloat? {
    let capSize = maxSize ?? baseSize
    var current = min(capSize, baseSize)
    print("[widget] [FontSize] bestWidgetFontSize: text length=\(text.count) chars, baseSize=\(baseSize)pt, minSize=\(minSize)pt, width=\(width)pt, maxLines=\(maxLines), maxHeight=\(maxHeight?.description ?? "nil")")
    print("[widget] [FontSize] Citation en test: \"\(text)\"")
    while current >= minSize {
        let result = lineCountForWidget(text: text, fontSize: current, width: width, fontFamily: fontFamily)
        print("[widget] [FontSize]   Test fontSize=\(current)pt → \(result.lineCount) lignes (max=\(maxLines)), hauteur réelle=\(result.realHeight)pt")
        if result.lineCount <= maxLines {
            // Vérifier que la hauteur réelle rentre dans maxHeight si fourni
            if let maxHeight = maxHeight {
                print("[widget] [FontSize]   Comparaison: hauteur réelle \(result.realHeight)pt vs maxHeight disponible \(maxHeight)pt")
                if result.realHeight > maxHeight {
                    print("[widget] [FontSize]   ✗ REFUSÉ: hauteur réelle \(result.realHeight)pt dépasse maxHeight \(maxHeight)pt, réduire la taille")
                    current -= 1.0
                    continue  // Tester une taille plus petite
                }
            }
            print("[widget] [FontSize]   ✓ ACCEPTÉ: fontSize=\(current)pt pour \(text.count) caractères (\(result.lineCount) lignes, \(result.realHeight)pt)")
            return current
        }
        current -= 1.0
    }
    
    print("[widget] [FontSize]   ✗ REFUSÉ: aucune taille entre \(baseSize)pt et \(minSize)pt ne tient (texte trop long: \(text.count) caractères)")
    return nil
}

// MARK: - Font Helper
func customFont(family: String, size: CGFloat) -> Font {
    print("[widget] 🚨 customFont() called - family='\(family)', size=\(size)")
    // Mapping direct des noms de famille utilisés dans les thèmes vers les noms PostScript réels
    // Ce mapping est basé sur les noms exacts des fichiers .ttf et leurs noms PostScript
    let fontPostScriptMapping: [String: String] = [
        // Polices principales
        "InterTight": "InterTight-Regular",
        "JosefinSlab": "JosefinSlab-Regular",
        "DidactGothic": "DidactGothic-Regular",
        "Raleway": "Raleway-Regular",
        "YesevaOne": "YesevaOne-Regular",
        "EBGaramond": "EBGaramond-Regular",
        "PlayfairDisplay": "PlayfairDisplay-Regular",
        "MontSerrat": "Montserrat-Regular",  // MontSerrat (avec S majuscule) utilisé dans thèmes
        "Montserrat": "Montserrat-Regular",  // Compatibilité
        "Lato": "Lato-Regular",
        "SourceSansPro": "SourceSansPro-Regular",
        "Oswald": "Oswald-Regular",
        "Quicksand": "Quicksand-Regular",
        "Quicksans": "Quicksand-Regular",  // Alias (au cas où)
        "BebasNeue": "BebasNeue-Regular",
        "Ovo": "Ovo",  // Pas de -Regular pour Ovo (nom PostScript exact)
        "Lustria": "Lustria-Regular",
        "JosefinSans": "JosefinSans-Regular",
        "CormorantGaramond": "CormorantGaramond-Regular",
        "Sanchez": "Sanchez-Regular",
        "Oranlenbaum": "Oranienbaum-Regular",  // Oranlenbaum utilisé dans thèmes → Oranienbaum PostScript
        "Oranienbaum": "Oranienbaum-Regular",  // Compatibilité
        "BodoniModa": "BodoniModa18pt-Regular",  // BodoniModa → BodoniModa18pt-Regular (sans underscore)
        "BodoniModa_18pt": "BodoniModa18pt-Regular",  // Compatibilité
        "Volkorn": "Volkhov-Regular",  // Volkorn utilisé dans thèmes → Volkhov-Regular (fichier physique)
        "AbhayaLibre": "AbhayaLibre-Regular",
        "Allerta": "Allerta-Regular",
        "LibreBaskerville": "LibreBaskerville-Regular"
    ]
    
    // Obtenir le nom PostScript depuis le mapping
    let postScriptName = fontPostScriptMapping[family] ?? family
    print("[widget] 🔤 Font mapping: family='\(family)' → PostScript='\(postScriptName)'")
    
    // LISTER TOUTES LES POLICES DE CETTE FAMILLE (DEBUG)
    let fontsInFamily = UIFont.fontNames(forFamilyName: family)
    print("[widget] 🔍 Fonts available in family '\(family)': \(fontsInFamily.joined(separator: ", "))")
    
    // Méthode améliorée : utiliser UIFont directement puis convertir en Font SwiftUI
    // Cela garantit que la police est bien chargée
    if let uiFont = UIFont(name: postScriptName, size: size) {
        print("[widget] ✅ SUCCESS via UIFont(name: '\(postScriptName)') - size=\(size)")
        return Font(uiFont)
    } else {
        print("[widget] ⚠️ FAILED UIFont(name: '\(postScriptName)') - font not found")
    }
    
    // Si UIFont ne trouve pas la police, chercher dans la famille
    if let firstAvailable = fontsInFamily.first {
        if let uiFont = UIFont(name: firstAvailable, size: size) {
            print("[widget] ✅ Font found via first available in family: '\(firstAvailable)'")
            return Font(uiFont)
        }
    }
    
    // En dernier recours, essayer Font.custom() directement
    print("[widget] ⚠️ LAST RESORT - Font.custom('\(postScriptName)', size: \(size))")
    return .custom(postScriptName, size: size)
}

// MARK: - Helper Functions
/// Remplace %NAME% dans le texte par le nom d'utilisateur
func replaceNamePlaceholder(_ text: String, userName: String?) -> String {
    guard let userName = userName, !userName.isEmpty else {
        return text
    }
    return text.replacingOccurrences(of: "%NAME%", with: userName)
}

/// Nettoie un dictionnaire pour ne garder que les valeurs property-list valides
/// Exclut les valeurs nil et les types non-property-list
func cleanDictionaryForUserDefaults(_ dict: [String: Any]) -> [String: Any] {
    var cleaned: [String: Any] = [:]
    for (key, value) in dict {
        // Exclure les valeurs nil (représentées par NSNull)
        if value is NSNull {
            continue
        }
        // Vérifier que la valeur est un type property-list valide
        if value is String || value is NSNumber || value is Date || value is Data {
            cleaned[key] = value
        } else if let array = value as? [Any] {
            // Pour les tableaux, vérifier récursivement
            let cleanedArray = array.compactMap { item -> Any? in
                if item is NSNull { return nil }
                if item is String || item is NSNumber || item is Date || item is Data {
                    return item
                }
                if let dictItem = item as? [String: Any] {
                    return cleanDictionaryForUserDefaults(dictItem)
                }
                return nil
            }
            if !cleanedArray.isEmpty {
                cleaned[key] = cleanedArray
            }
        } else if let nestedDict = value as? [String: Any] {
            // Pour les dictionnaires imbriqués, nettoyer récursivement
            let cleanedNested = cleanDictionaryForUserDefaults(nestedDict)
            if !cleanedNested.isEmpty {
                cleaned[key] = cleanedNested
            }
        }
    }
    return cleaned
}

// MARK: - Widget Theme Helper
/// Récupère l'index du thème depuis UserDefaults selon la logique du widget
/// - Si le widget est configuré, utilise widgetThemeIndex
/// - Sinon, utilise themeIndex s'il existe, sinon widgetThemeIndex, sinon 0
func getWidgetThemeIndex(defaults: UserDefaults, isConfigured: Bool) -> Int {
    if isConfigured {
        return defaults.integer(forKey: "widgetThemeIndex")
    } else {
        if defaults.object(forKey: "themeIndex") != nil {
            return defaults.integer(forKey: "themeIndex")
        } else if defaults.object(forKey: "widgetThemeIndex") != nil {
            return defaults.integer(forKey: "widgetThemeIndex")
        } else {
            return 0
        }
    }
}

/// Récupère le widgetImageName d'un thème custom depuis SharedPreferences
/// Retourne le nom du fichier de l'image recadrée pour le widget, ou nil si non trouvé
func getWidgetImageName(defaults: UserDefaults, themeIndex: Int) -> String? {
    // Vérifier que c'est un thème custom
    let isCustomTheme = defaults.bool(forKey: "widgetIsCustomTheme")
    guard isCustomTheme else {
        return nil
    }
    
    // Récupérer la liste des thèmes custom
    guard let themesData = defaults.array(forKey: "themeCustomDatasMap") as? [[String: Any]] else {
        print("[widget] ⚠️ Aucun thème custom trouvé dans SharedPreferences")
        return nil
    }
    
    // Vérifier que l'index est valide
    guard themeIndex >= 0 && themeIndex < themesData.count else {
        print("[widget] ⚠️ Index de thème custom invalide: \(themeIndex)")
        return nil
    }
    
    // Récupérer widgetImageName du thème
    let theme = themesData[themeIndex]
    let widgetImageName = theme["widgetImageName"] as? String
    
    if let imageName = widgetImageName, !imageName.isEmpty {
        print("[widget] ✅ widgetImageName trouvé: \(imageName)")
        return imageName
    } else {
        print("[widget] ℹ️ Pas de widgetImageName pour ce thème custom")
        return nil
    }
}

// MARK: - Lock Screen Quote Helper
/// Trouve une citation aléatoire qui tient dans 3 lignes pour le lock screen
/// - Génère toujours une citation aléatoire indépendante (pas basée sur la citation du widget app)
/// - Teste différentes tailles (16pt à 10pt) jusqu'à trouver une citation qui tient
/// - Retourne (QuoteResult, CGFloat) : la citation et la taille de police
func findLockScreenQuote(
    initialQuote: QuoteResult,
    topics: [String],
    languageCode: String,
    premium: Bool,
    gender: String?,
    affirmationPercentage: Int,
    noMercyPercentage: Int,
    favoritesList: [[String: Any]],
    planPercentages: [String: Double]
) -> (quote: QuoteResult, fontSize: CGFloat) {
    // Initialiser avec une citation par défaut comme fallback
    let defaultQuote = QuoteLibrary.defaultQuoteResult(languageCode: languageCode)
    var lockScreenQuote: QuoteResult = defaultQuote
    var lockScreenFontSize: CGFloat = 12.0
    
    // Toutes les tailles de police possibles (de la plus grande à la plus petite)
    let fontSizes: [CGFloat] = [16.0, 15.0, 14.0, 13.0, 12.0, 11.0, 10.0]
    
    // Tester d'abord la citation initiale
    var foundQuote = false
    print("[widget] Testing initial quote for lock screen: '\(initialQuote.text.prefix(50))...'")
    
    for fontSize in fontSizes {
        if quoteFitsInLockScreen(initialQuote.text, fontSize: fontSize) {
            lockScreenQuote = initialQuote
            lockScreenFontSize = fontSize
            foundQuote = true
            print("[widget] ✅ Initial quote fits in lock screen at fontSize=\(fontSize)pt")
            break
        }
    }
    
    // Si la citation initiale ne tient pas, générer des alternatives
    if !foundQuote {
        print("[widget] Initial quote doesn't fit, generating alternatives...")
        let maxAttempts = 50
        
        for attempt in 0..<maxAttempts {
            // Générer une citation aléatoire indépendante
            let candidate = QuoteGenerator.getRandomQuoteFromTopics(
                topics: topics,
                languageCode: languageCode,
                premium: premium,
                gender: gender,
                affirmationPercentage: affirmationPercentage,
                noMercyPercentage: noMercyPercentage,
                favorites: favoritesList,
                planPercentages: planPercentages
            )
            
            // Tester toutes les tailles pour cette citation candidate (de la plus grande à la plus petite)
            var foundFittingSize: CGFloat? = nil
            for fontSize in fontSizes {
                if quoteFitsInLockScreen(candidate.text, fontSize: fontSize) {
                    foundFittingSize = fontSize
                    break
                }
            }
            
            if let fittingSize = foundFittingSize {
                // Trouvé une citation qui tient !
                lockScreenQuote = candidate
                lockScreenFontSize = fittingSize
                foundQuote = true
                print("[widget] Found alternative lock screen quote (attempt \(attempt + 1)): fontSize=\(lockScreenFontSize)pt")
                break
            }
        }
        
        if !foundQuote {
            // Si après toutes les tentatives aucune citation ne tient, utiliser un fallback avec 10pt
            let fallbackCandidate = QuoteGenerator.getRandomQuoteFromTopics(
                topics: topics,
                languageCode: languageCode,
                premium: premium,
                gender: gender,
                affirmationPercentage: affirmationPercentage,
                noMercyPercentage: noMercyPercentage,
                favorites: favoritesList,
                planPercentages: planPercentages
            )
            lockScreenQuote = fallbackCandidate
            lockScreenFontSize = 10.0
            print("[widget] ⚠️ Using fallback random lock screen quote with 10pt after \(maxAttempts) attempts")
        }
    }
    
    return (lockScreenQuote, lockScreenFontSize)
}

// MARK: - Widget Quote Finder
/// Trouve une citation qui tient dans le widget principal (4-5 lignes)
/// - Teste d'abord la citation initiale
/// - Si elle ne tient pas, génère des alternatives jusqu'à en trouver une qui tient
/// - Retourne (QuoteResult, CGFloat) : la citation et la taille de police
func findWidgetQuote(
    initialQuote: QuoteResult,
    themeIndex: Int,
    effectiveWidth: CGFloat,
    effectiveMaxHeight: CGFloat,
    userName: String?,
    topics: [String],
    languageCode: String,
    premium: Bool,
    gender: String?,
    affirmationPercentage: Int,
    noMercyPercentage: Int,
    favoritesList: [[String: Any]],
    planPercentages: [String: Double],
    useThemeFontFamily: Bool = true
) -> (quote: QuoteResult, fontSize: CGFloat) {
    let safeThemeIndex = max(0, min(themeIndex, allAppThemes.count - 1))
    let theme = allAppThemes[safeThemeIndex]
    
    let computeWidgetFontSize: (String) -> CGFloat? = { text in
        bestWidgetFontSize(
            text: text,
            baseSize: CGFloat(widgetBaseFontSize),
            minSize: 15.0,
            maxSize: CGFloat(widgetBaseFontSize),
            width: effectiveWidth,
            maxLines: 5,
            fontFamily: useThemeFontFamily ? theme.fontFamily : nil,
            maxHeight: effectiveMaxHeight
        )
    }
    
    var widgetQuote: QuoteResult = initialQuote
    var widgetFontSize: CGFloat = CGFloat(widgetBaseFontSize)
    var foundWidgetQuote = false
    var widgetAttempts = 0
    let maxWidgetAttempts = 50
    
    // Boucle pour trouver une citation qui tient dans 4 lignes
    while !foundWidgetQuote && widgetAttempts < maxWidgetAttempts {
        let currentQuoteText = widgetAttempts == 0 ? initialQuote.text : widgetQuote.text
        let currentQuoteTextWithName = replaceNamePlaceholder(currentQuoteText, userName: userName)
        
        if let fittingSize = computeWidgetFontSize(currentQuoteTextWithName) {
            widgetFontSize = fittingSize
            foundWidgetQuote = true
            print("[widget] Widget quote fits with fontSize=\(widgetFontSize) (attempt \(widgetAttempts + 1))")
        } else {
            print("[widget] Widget quote doesn't fit at minSize, generating new quote (attempt \(widgetAttempts + 1))...")
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
    }
    
    if !foundWidgetQuote {
        // Fallback : utiliser une citation très courte par défaut pour garantir le fit
        let fallbackShort = QuoteLibrary.defaultQuoteResult(languageCode: languageCode)
        let fallbackTextWithName = replaceNamePlaceholder(fallbackShort.text, userName: userName)
        if let fittingSize = computeWidgetFontSize(fallbackTextWithName) {
            widgetFontSize = fittingSize
        } else {
            widgetFontSize = 15.0
        }
        widgetQuote = fallbackShort
        print("[widget] ⚠️ Using default short quote to ensure fit; fontSize=\(widgetFontSize)")
    }
    
    return (widgetQuote, widgetFontSize)
}

// MARK: - Color Extension pour hex
extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        let a = Double((hex >> 24) & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

