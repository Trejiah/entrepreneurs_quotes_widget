import AppTrackingTransparency
import Flutter
import StoreKit

/// ViewModel du pont Flutter pour Storefront et App Tracking Transparency.
final class StoreFlutterBridgeViewModel {

  func handleMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getStorefrontCountryCode":
      if #available(iOS 13.0, *) {
        let countryCode = SKPaymentQueue.default().storefront?.countryCode
        print("[AppDelegate] 🏪 Storefront countryCode: \(countryCode ?? "nil")")
        result(countryCode as Any?)
      } else {
        result(nil as Any?)
      }
    case "requestATT":
      if #available(iOS 14, *) {
        ATTrackingManager.requestTrackingAuthorization { status in
          let statusString: String
          switch status {
          case .authorized:     statusString = "authorized"
          case .denied:         statusString = "denied"
          case .restricted:     statusString = "restricted"
          case .notDetermined:  statusString = "not_determined"
          @unknown default:     statusString = "unknown"
          }
          print("[AppDelegate] 📱 ATT request result: \(statusString)")
          DispatchQueue.main.async {
            result(statusString)
          }
        }
      } else {
        result("not_applicable")
      }
    case "getATTStatus":
      if #available(iOS 14, *) {
        let status = ATTrackingManager.trackingAuthorizationStatus
        let statusString: String
        switch status {
        case .authorized:     statusString = "authorized"
        case .denied:         statusString = "denied"
        case .restricted:     statusString = "restricted"
        case .notDetermined:  statusString = "not_determined"
        @unknown default:     statusString = "unknown"
        }
        print("[AppDelegate] 📱 ATT status: \(statusString)")
        result(statusString)
      } else {
        result("not_applicable")
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
