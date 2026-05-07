//
//  WidgetModels.swift
//  BusinessMindsetWidget
//
//  Modèles de données partagés pour le widget
//

import Foundation

// MARK: - Quote Types

struct QuoteResult {
    let text: String
    let category: String?
    let signature: String?
    let bookTitle: String?
    let url: String?
}

struct QuoteMetadataPayload: Codable {
    let quote: String
    let category: String?
    let signature: String?
    let bookTitle: String?
    let url: String?
    let languageCode: String
    let day: Int
    let month: String
    let year: Int

    init(
        quote: String,
        category: String?,
        signature: String?,
        bookTitle: String?,
        url: String?,
        languageCode: String,
        date: Date
    ) {
        self.quote = quote
        self.category = category
        self.signature = signature
        self.bookTitle = bookTitle
        self.url = url
        self.languageCode = languageCode

        let calendar = Calendar.current
        self.day = calendar.component(.day, from: date)
        self.year = calendar.component(.year, from: date)
        self.month = QuoteMetadataPayload.monthName(for: date, languageCode: languageCode)
    }

    init?(favoriteDictionary: [String: Any], languageCode: String) {
        guard let quote = favoriteDictionary["quote"] as? String else {
            return nil
        }
        self.quote = quote
        self.category = favoriteDictionary["category"] as? String
        self.signature = favoriteDictionary["signature"] as? String
        self.bookTitle = favoriteDictionary["bookTitle"] as? String
        self.url = favoriteDictionary["url"] as? String
        self.languageCode = languageCode

        let calendar = Calendar.current
        if let day = favoriteDictionary["day"] as? Int {
            self.day = day
        } else {
            self.day = calendar.component(.day, from: Date())
        }
        if let year = favoriteDictionary["year"] as? Int {
            self.year = year
        } else {
            self.year = calendar.component(.year, from: Date())
        }
        if let monthName = favoriteDictionary["month"] as? String, !monthName.isEmpty {
            self.month = monthName
        } else {
            self.month = QuoteMetadataPayload.monthName(for: Date(), languageCode: languageCode)
        }
    }

    static func monthName(for date: Date, languageCode: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode.lowercased().hasPrefix("fr") ? "fr_FR" : "en_US")
        formatter.dateFormat = "LLLL"
        return formatter.string(from: date).capitalized
    }

    func toDayQuoteDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "quote": quote,
            "day": day,
            "month": month,
            "year": year
        ]
        if let category {
            dict["category"] = category
        }
        if let signature {
            dict["signature"] = signature
        }
        if let bookTitle {
            dict["bookTitle"] = bookTitle
        }
        if let url {
            dict["url"] = url
        }
        return dict
    }

    func jsonString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Widget Update Frequency

enum WidgetUpdateFrequency: String {
    case oncePerDay = "once_per_day"
    case twicePerDay = "twice_per_day"
    case everySixHours = "every_6_hours"
    case everyThreeHours = "every_3_hours"
    case everyHour = "every_hour"
    case twicePerHour = "twice_per_hour"

    static func from(_ value: String?) -> WidgetUpdateFrequency {
        guard let value else { return .everyThreeHours }
        return WidgetUpdateFrequency(rawValue: value) ?? .everyThreeHours
    }
}

struct FrequencySchedule {
    let currentSlotStart: Date
    let nextTrigger: Date
}

// MARK: - Quote Library

enum QuoteLibrary {
    static func defaultQuoteResult(languageCode: String) -> QuoteResult {
        if languageCode.lowercased().hasPrefix("fr") {
            return QuoteResult(
                text: "La vue seule de ce widget suffit à combler de joie quiconque en son for intérieur",
                category: nil,
                signature: nil,
                bookTitle: nil,
                url: nil
            )
        } else {
            return QuoteResult(
                text: "Tap to configure your widget",
                category: nil,
                signature: nil,
                bookTitle: nil,
                url: nil
            )
        }
    }

    static func schedule(for frequency: WidgetUpdateFrequency, at date: Date, calendar: Calendar) -> FrequencySchedule {
        let startOfDay = calendar.startOfDay(for: date)
        let secondsSinceStart = date.timeIntervalSince(startOfDay)

        func slotSchedule(slotSeconds: Int) -> FrequencySchedule {
            let currentIndex = max(0, Int(secondsSinceStart / Double(slotSeconds)))
            let currentStart = calendar.date(byAdding: .second, value: currentIndex * slotSeconds, to: startOfDay)!
            let nextIndex = currentIndex + 1
            if nextIndex * slotSeconds >= 24 * 3600 {
                let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                return FrequencySchedule(currentSlotStart: currentStart, nextTrigger: nextDay)
            }
            let next = calendar.date(byAdding: .second, value: nextIndex * slotSeconds, to: startOfDay)!
            return FrequencySchedule(currentSlotStart: currentStart, nextTrigger: next)
        }

        switch frequency {
        case .oncePerDay:
            let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return FrequencySchedule(currentSlotStart: startOfDay, nextTrigger: nextDay)
        case .twicePerDay:
            let midday = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!
            if secondsSinceStart < 12 * 3600 {
                return FrequencySchedule(currentSlotStart: startOfDay, nextTrigger: midday)
            } else {
                let nextMidnight = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                return FrequencySchedule(currentSlotStart: midday, nextTrigger: nextMidnight)
            }
        case .everySixHours:
            return slotSchedule(slotSeconds: 6 * 3600)
        case .everyThreeHours:
            return slotSchedule(slotSeconds: 3 * 3600)
        case .everyHour:
            return slotSchedule(slotSeconds: 3600)
        case .twicePerHour:
            return slotSchedule(slotSeconds: 30 * 60)
        }
    }
}

