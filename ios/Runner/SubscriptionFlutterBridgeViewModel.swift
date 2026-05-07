import Flutter
import StoreKit
import UIKit

/// ViewModel du pont Flutter pour les flux natifs liés aux abonnements (StoreKit).
final class SubscriptionFlutterBridgeViewModel {

  var windowSceneProvider: () -> UIWindowScene?

  init(windowSceneProvider: @escaping () -> UIWindowScene? = { nil }) {
    self.windowSceneProvider = windowSceneProvider
  }

  func handleShowManageSubscriptions(result: @escaping FlutterResult) {
    print("[MANAGE SUBSCRIPTIONS] Called handleShowManageSubscriptions")

    if #available(iOS 17.0, *) {
      print("[MANAGE SUBSCRIPTIONS] iOS 17.0+ detected, using AppStore.showManageSubscriptions")

      guard let windowScene = windowSceneProvider() else {
        print("[MANAGE SUBSCRIPTIONS] ERROR: Window scene not available")
        result(FlutterError(
          code: "UNAVAILABLE",
          message: "Window scene not available",
          details: nil
        ))
        return
      }

      print("[MANAGE SUBSCRIPTIONS] Window scene found, showing manage subscriptions")

      Task { @MainActor in
        do {
          try await AppStore.showManageSubscriptions(in: windowScene)
          print("[MANAGE SUBSCRIPTIONS] Successfully showed manage subscriptions")
          await MainActor.run {
            result(nil)
          }
        } catch {
          print("[MANAGE SUBSCRIPTIONS] ERROR: \(error.localizedDescription)")
          await MainActor.run {
            result(FlutterError(
              code: "ERROR",
              message: "Failed to show manage subscriptions: \(error.localizedDescription)",
              details: nil
            ))
          }
        }
      }
    } else {
      print("[MANAGE SUBSCRIPTIONS] iOS < 17.0, opening settings")
      if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settingsUrl) { success in
          if success {
            print("[MANAGE SUBSCRIPTIONS] Settings opened successfully")
            result(nil)
          } else {
            print("[MANAGE SUBSCRIPTIONS] ERROR: Failed to open settings")
            result(FlutterError(
              code: "ERROR",
              message: "Failed to open settings",
              details: nil
            ))
          }
        }
      } else {
        print("[MANAGE SUBSCRIPTIONS] ERROR: Settings URL not available")
        result(FlutterError(
          code: "UNAVAILABLE",
          message: "Settings not available",
          details: nil
        ))
      }
    }
  }
}
