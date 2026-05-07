import Flutter
import Foundation
import WidgetKit

/// ViewModel du pont Flutter pour synchroniser widgets et App Group (pas de UIKit direct sauf reload timelines).
final class WidgetFlutterBridgeViewModel {

  private let widgetSuiteName: String
  private let widgetPremiumExpirationKey: String

  init(
    widgetSuiteName: String = FlutterBridgeConstants.widgetSuiteName,
    widgetPremiumExpirationKey: String = FlutterBridgeConstants.widgetPremiumExpirationKey
  ) {
    self.widgetSuiteName = widgetSuiteName
    self.widgetPremiumExpirationKey = widgetPremiumExpirationKey
  }

  func handleGetWidgetFavorites(result: FlutterResult) {
    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      print("[WidgetBridge] Unable to access suite \(widgetSuiteName) for getWidgetFavorites")
      result(FlutterError(code: "SUITE_UNAVAILABLE", message: "Unable to access app group defaults", details: nil))
      return
    }

    let favorites = defaults.array(forKey: "widgetFavorites") ?? []
    print("[WidgetBridge] Returning \(favorites.count) favorites to Flutter")
    result(favorites)
  }

  func handleSetOpenedFromLockScreen(result: FlutterResult) {
    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      result(FlutterError(code: "SUITE_UNAVAILABLE", message: "Unable to access app group defaults", details: nil))
      return
    }

    defaults.set(true, forKey: "openedFromLockScreen")
    defaults.synchronize()
    print("[WidgetBridge] 🔒 Flag openedFromLockScreen activé")
    result(nil)
  }

  func handleGetOpenedFromLockScreen(result: FlutterResult) {
    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      result(FlutterError(code: "SUITE_UNAVAILABLE", message: "Unable to access app group defaults", details: nil))
      return
    }

    let openedFromLockScreen = defaults.bool(forKey: "openedFromLockScreen")
    print("[WidgetBridge] 🔒 Getting openedFromLockScreen flag: \(openedFromLockScreen)")
    result(openedFromLockScreen)
  }

  func handleResetOpenedFromLockScreen(result: FlutterResult) {
    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      result(FlutterError(code: "SUITE_UNAVAILABLE", message: "Unable to access app group defaults", details: nil))
      return
    }

    defaults.set(false, forKey: "openedFromLockScreen")
    defaults.synchronize()
    print("[WidgetBridge] 🔒 Flag openedFromLockScreen réinitialisé")
    result(nil)
  }

  func handleGetWidgetStoredQuote(result: FlutterResult) {
    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      result(FlutterError(code: "SUITE_UNAVAILABLE", message: "Unable to access app group defaults", details: nil))
      return
    }

    let openedFromLockScreen = defaults.bool(forKey: "openedFromLockScreen")

    print("[WidgetBridge] getWidgetStoredQuote called - openedFromLockScreen: \(openedFromLockScreen)")

    let quote: String?
    let signature: String?
    let book: String?
    let url: String?

    if openedFromLockScreen {
      quote = defaults.string(forKey: "widgetLockScreenQuote")
      signature = defaults.string(forKey: "widgetLockScreenQuoteSignature")
      book = defaults.string(forKey: "widgetLockScreenQuoteBook")
      url = defaults.string(forKey: "widgetLockScreenQuoteURL")

      print("[WidgetBridge] 🔒 Lock screen quote found: \(quote ?? "nil")")
      print("[WidgetBridge] 🔒 Lock screen signature: \(signature ?? "nil")")
      print("[WidgetBridge] 🔒 Lock screen book: \(book ?? "nil")")

      let mainQuote = defaults.string(forKey: "widgetQuote")
      print("[WidgetBridge] 📱 Main widget quote (for comparison): \(mainQuote ?? "nil")")
    } else {
      quote = defaults.string(forKey: "widgetQuote")
      signature = defaults.string(forKey: "widgetQuoteSignature")
      book = defaults.string(forKey: "widgetQuoteBook")
      url = defaults.string(forKey: "widgetQuoteURL")
      print("[WidgetBridge] Loading main widget quote: \(quote ?? "nil")")
    }

    let payload: [String: Any?] = [
      "quote": quote,
      "signature": signature,
      "book": book,
      "url": url,
      "timestamp": defaults.double(forKey: "widgetQuoteTimestamp")
    ]
    result(payload)
  }

  func handleForceWidgetNewQuote(result: FlutterResult) {
    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      result(FlutterError(code: "SUITE_UNAVAILABLE", message: "Unable to access app group defaults", details: nil))
      return
    }

    let openedFromLockScreen = defaults.bool(forKey: "openedFromLockScreen")

    if openedFromLockScreen {
      print("[WidgetBridge] 🔒 Forcing new quote for LOCK SCREEN widget only")
      defaults.removeObject(forKey: "widgetLockScreenQuote")
      defaults.removeObject(forKey: "widgetLockScreenFontSize")
      defaults.set(true, forKey: "widgetForceNewQuote")
      defaults.set(true, forKey: "widgetForceLockScreenQuoteOnly")

      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadTimelines(ofKind: "BusinessMindsetWidget")
      }
    } else {
      print("[WidgetBridge] 📱 Forcing new quote for HOME SCREEN widget only")
      defaults.removeObject(forKey: "widgetQuote")
      defaults.removeObject(forKey: "widgetQuoteTimestamp")
      defaults.set(true, forKey: "widgetForceNewQuote")
      defaults.set(false, forKey: "widgetForceLockScreenQuoteOnly")

      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadTimelines(ofKind: "BusinessMindsetWidget")
      }
    }

    result(nil)
  }

  func handleForceLockScreenWidgetNewQuote(result: FlutterResult) {
    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      result(FlutterError(code: "SUITE_UNAVAILABLE", message: "Unable to access app group defaults", details: nil))
      return
    }

    defaults.removeObject(forKey: "widgetLockScreenQuote")
    defaults.removeObject(forKey: "widgetLockScreenFontSize")

    defaults.set(true, forKey: "widgetForceNewQuote")

    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: "BusinessMindsetWidget")
    }
    result(nil)
  }

  func handleSetLockscreenForcedQuote(arguments: Any?, result: FlutterResult) {
    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      result(FlutterError(code: "SUITE_UNAVAILABLE", message: "Unable to access app group defaults", details: nil))
      return
    }

    guard let args = arguments as? [String: Any],
          let quote = args["quote"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected quote parameter", details: nil))
      return
    }

    defaults.set(quote, forKey: "lockscreenForcedQuote")
    defaults.synchronize()

    print("[WidgetBridge] 🔒 Citation forcée pour lockscreen sauvegardée: \(quote.prefix(50))...")
    result(nil)
  }

  func handleGetLockscreenForcedQuote(result: FlutterResult) {
    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      result(FlutterError(code: "SUITE_UNAVAILABLE", message: "Unable to access app group defaults", details: nil))
      return
    }

    let forcedQuote = defaults.string(forKey: "lockscreenForcedQuote")
    print("[WidgetBridge] 🔒 Lecture citation forcée lockscreen: \(forcedQuote?.prefix(50) ?? "nil")")
    result(forcedQuote)
  }

  func handleClearLockscreenForcedQuote(result: FlutterResult) {
    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      result(FlutterError(code: "SUITE_UNAVAILABLE", message: "Unable to access app group defaults", details: nil))
      return
    }

    defaults.removeObject(forKey: "lockscreenForcedQuote")
    defaults.synchronize()

    print("[WidgetBridge] 🔒 Citation forcée pour lockscreen supprimée")
    result(nil)
  }

  /// Paywall Remote Config : bloquer citations tant que non abonné.
  func setHardPaywallQuotesBlocked(arguments: Any?) {
    let blocked = (arguments as? [String: Any])?["blocked"] as? Bool ?? false
    if let suite = UserDefaults(suiteName: widgetSuiteName) {
      suite.set(blocked, forKey: "hardPaywallBlockQuotes")
    }
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  func handleUpdateWidgetData(arguments: Any?, result: FlutterResult) {
    print("[WidgetBridge] handleUpdateWidgetData called")
    guard let payload = arguments as? [String: Any] else {
      print("[WidgetBridge] Invalid arguments: \(String(describing: arguments))")
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected dictionary for updateWidgetData", details: nil))
      return
    }

    guard let defaults = UserDefaults(suiteName: widgetSuiteName) else {
      print("[WidgetBridge] Unable to access suite \(widgetSuiteName)")
      result(FlutterError(code: "SUITE_UNAVAILABLE", message: "Unable to access app group defaults", details: nil))
      return
    }

    print("[WidgetBridge] Payload received: \(payload)")

    if let configured = payload["configured"] as? Bool {
      defaults.set(configured, forKey: "widgetConfigured")
    }

    let widgetAlreadyConfigured = defaults.bool(forKey: "widgetConfigured")
    let isWidgetConfigCall = (payload["configured"] as? Bool) == true

    if let themeIndex = payload["themeIndex"] as? Int {
      if !widgetAlreadyConfigured || isWidgetConfigCall {
        defaults.set(themeIndex, forKey: "widgetThemeIndex")
      }

      if payload["isCustomTheme"] != nil {
        defaults.set(themeIndex, forKey: "themeIndex")
      }
    }
    if let isCustomTheme = payload["isCustomTheme"] as? Bool {
      defaults.set(isCustomTheme, forKey: "widgetIsCustomTheme")
      defaults.set(isCustomTheme, forKey: "isCustomTheme")
    }

    if let customThemes = payload["customThemes"] as? [[String: Any]] {
      print("[WidgetBridge] Synchronisation de \(customThemes.count) thèmes custom")
      let cleanedThemes = customThemes.map { Self.cleanDictionaryForUserDefaults($0) }
      defaults.set(cleanedThemes, forKey: "themeCustomDatasMap")
    }

    if let language = payload["language"] as? String {
      defaults.set(language, forKey: "language")
    }
    if let quote = payload["quote"] as? String {
      defaults.set(quote, forKey: "widgetQuote")
      defaults.set(Date().timeIntervalSince1970, forKey: "widgetQuoteTimestamp")
      defaults.set(true, forKey: "widgetQuoteWasChosen")
      print("[WidgetBridge] 📱 Quote chosen by user - will be used once then removed")
    }
    if let widgetQuoteDetails = payload["widgetQuoteDetails"] as? [String: Any] {
      let cleanedDict = Self.cleanDictionaryForUserDefaults(widgetQuoteDetails)
      defaults.set(cleanedDict, forKey: "widgetQuoteDetails")
      if let signature = widgetQuoteDetails["signature"] as? String {
        defaults.set(signature, forKey: "widgetQuoteSignature")
      }
      if let bookTitle = widgetQuoteDetails["bookTitle"] as? String {
        defaults.set(bookTitle, forKey: "widgetQuoteBook")
      }
      if let url = widgetQuoteDetails["url"] as? String {
        defaults.set(url, forKey: "widgetQuoteURL")
      }
      if let languageCode = widgetQuoteDetails["languageCode"] as? String {
        defaults.set(languageCode, forKey: "widgetQuoteLanguageCode")
      }
    }
    if let topics = payload["topics"] as? [String] {
      defaults.set(topics, forKey: "widgetTopicsSelected")
    }
    if let favorites = payload["favorites"] as? [[String: Any]] {
      defaults.set(favorites, forKey: "widgetFavorites")
    }
    if let frequency = payload["frequency"] as? String {
      defaults.set(frequency, forKey: "widgetUpdateFrequency")
    }
    if let buttons = payload["buttons"] as? [String] {
      defaults.set(buttons, forKey: "widgetButtonsSelection")
    }
    if let isPremium = payload["isPremium"] as? Bool {
      defaults.set(isPremium, forKey: "isPremium")
    }
    let payloadExpiration = (payload["premiumExpirationEpochMs"] as? NSNumber)?.doubleValue
    if let expirationMs = payloadExpiration, expirationMs > 0 {
      defaults.set(expirationMs, forKey: widgetPremiumExpirationKey)
    } else {
      defaults.removeObject(forKey: widgetPremiumExpirationKey)
    }
    if let planGrowthPercentage = payload["planGrowthPercentage"] as? Double {
      defaults.set(planGrowthPercentage, forKey: "plan_growth_percentage")
    }
    if let planDisciplinePercentage = payload["planDisciplinePercentage"] as? Double {
      defaults.set(planDisciplinePercentage, forKey: "plan_discipline_percentage")
    }
    if let planConfidencePercentage = payload["planConfidencePercentage"] as? Double {
      defaults.set(planConfidencePercentage, forKey: "plan_confidence_percentage")
    }
    if let planStrategyPercentage = payload["planStrategyPercentage"] as? Double {
      defaults.set(planStrategyPercentage, forKey: "plan_strategy_percentage")
    }
    if let userName = payload["userName"] as? String {
      defaults.set(userName, forKey: "userName")
      defaults.set(userName, forKey: "name")
    }

    print("""
[WidgetBridge] Stored values ->
  configured: \(defaults.bool(forKey: "widgetConfigured")),
  themeIndex: \(defaults.integer(forKey: "widgetThemeIndex")),
  frequency: \(defaults.string(forKey: "widgetUpdateFrequency") ?? "nil"),
  buttons: \(defaults.stringArray(forKey: "widgetButtonsSelection") ?? []),
  timestamp: \(defaults.double(forKey: "widgetQuoteTimestamp"))
""")

    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
      print("[WidgetBridge] Requested reloadAllTimelines")
    }
    result(nil)
  }

  private static func cleanDictionaryForUserDefaults(_ dict: [String: Any]) -> [String: Any] {
    var cleaned: [String: Any] = [:]
    for (key, value) in dict {
      if value is NSNull {
        continue
      }
      if value is String || value is NSNumber || value is Date || value is Data {
        cleaned[key] = value
      } else if let array = value as? [Any] {
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
        let cleanedNested = cleanDictionaryForUserDefaults(nestedDict)
        if !cleanedNested.isEmpty {
          cleaned[key] = cleanedNested
        }
      }
    }
    return cleaned
  }
}
