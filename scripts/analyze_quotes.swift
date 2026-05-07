#!/usr/bin/env swift

// Script temporaire pour analyser les citations et trouver des exemples par taille de police
// Usage: swift analyze_quotes.swift

import Foundation
import UIKit

// Copie des fonctions de calcul depuis BusinessMindsetWidget.swift
func lineCountForWidget(text: String, fontSize: CGFloat, width: CGFloat) -> Int {
    let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
    let rect = (text as NSString).boundingRect(
        with: CGSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: font],
        context: nil
    )
    let lines = rect.height / font.lineHeight
    return Int(ceil(lines))
}

func bestWidgetFontSize(
    text: String,
    baseSize: CGFloat,
    minSize: CGFloat = 14.0,
    maxSize: CGFloat? = nil,
    width: CGFloat,
    maxLines: Int = 4
) -> CGFloat? {
    let capSize = maxSize ?? baseSize
    var current = min(capSize, baseSize)
    while current >= minSize {
        if lineCountForWidget(text: text, fontSize: current, width: width) <= maxLines {
            return current
        }
        current -= 1.0
    }
    return nil
}

// Paramètres utilisés dans le widget
let widgetBaseFontOffset = 4
let widgetSizeBoost = 2
let widgetTextWidthEstimate: CGFloat = 300.0
let minSize: CGFloat = 14.0
let maxLines = 4

// Supposons un thème avec fontSize = 20 (exemple)
let themeFontSize = 20
let baseThemeFontSize = themeFontSize + widgetBaseFontOffset + widgetSizeBoost // = 26

// Charger QuotesModel.swift - on va lire directement le fichier
let quotesModelPath = "/Users/gabriellejarmuzek/StudioProjects/businessmindset/ios/BusinessMindsetWidget/QuotesModel.swift"

// Pour simplifier, on va chercher des citations manuellement dans le fichier
// ou utiliser une approche différente

print("Analyse des citations pour trouver des exemples par taille de police...")
print("Paramètres:")
print("  - baseThemeFontSize: \(baseThemeFontSize)")
print("  - minSize: \(minSize)")
print("  - width: \(widgetTextWidthEstimate)")
print("  - maxLines: \(maxLines)")
print("")

// Citations de test pour chaque taille
let testQuotes: [(String, String)] = [
    // Courtes (26pt)
    ("confmind", "I am not a product of my circumstances. I am a product of my decisions."),
    ("confmind", "If you want more, become more."),
    ("confmind", "High expectations are the key to everything."),
    
    // Moyennes
    ("confmind", "Do one thing every day that scares you."),
    ("confmind", "Don't wish it were easier; wish you were better."),
    
    // Longues
    ("confmind", "Until you become completely obsessed with your mission, no one will take you seriously. Until the world understands that you're not going away—that you are 100 percent committed and have complete and utter conviction and will persist in pursuing your project—you will not get the attention you need and the support you want."),
]

var foundExamples: [Int: (String, String)] = [:]
var rejectedQuote: (String, String)? = nil

for (category, quote) in testQuotes {
    if let fontSize = bestWidgetFontSize(
        text: quote,
        baseSize: CGFloat(baseThemeFontSize),
        minSize: minSize,
        maxSize: CGFloat(baseThemeFontSize),
        width: widgetTextWidthEstimate,
        maxLines: maxLines
    ) {
        let fontSizeInt = Int(fontSize)
        if foundExamples[fontSizeInt] == nil {
            foundExamples[fontSizeInt] = (category, quote)
            print("✅ Taille \(fontSizeInt)pt trouvée:")
            print("   Catégorie: \(category)")
            print("   Citation: \(quote)")
            print("")
        }
    } else {
        if rejectedQuote == nil {
            rejectedQuote = (category, quote)
            print("❌ Citation rejetée (trop longue même à 14pt):")
            print("   Catégorie: \(category)")
            print("   Citation: \(quote)")
            print("")
        }
    }
}

print("\n=== Résumé ===")
for size in stride(from: 26, through: 14, by: -1) {
    if let (cat, quote) = foundExamples[size] {
        print("\(size)pt: [\(cat)] \(quote.prefix(60))...")
    } else {
        print("\(size)pt: (non trouvé)")
    }
}

if let (cat, quote) = rejectedQuote {
    print("\nRejetée: [\(cat)] \(quote.prefix(60))...")
}


