import Foundation

let widgetSuiteName = "group.com.bakemono.businessmindset"

func widgetUserDefaults() -> UserDefaults {
  if let suite = UserDefaults(suiteName: widgetSuiteName) {
    print("[widget] Using shared UserDefaults suite \(widgetSuiteName)")
    return suite
  } else {
    print("[widget] ⚠️ Falling back to standard UserDefaults (suite unavailable)")
    return .standard
  }
}
