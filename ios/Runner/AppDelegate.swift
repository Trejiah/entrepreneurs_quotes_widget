import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var deepLinkChannel: FlutterMethodChannel?
  private var revenueCatChannel: FlutterMethodChannel?
  private var storeChannel: FlutterMethodChannel?
  private var pendingDeepLink: String?

  private var widgetFlutterBridgeViewModel: WidgetFlutterBridgeViewModel!
  private var shareFlutterBridgeViewModel: ShareFlutterBridgeViewModel!
  private var subscriptionFlutterBridgeViewModel: SubscriptionFlutterBridgeViewModel!
  private var storeFlutterBridgeViewModel: StoreFlutterBridgeViewModel!

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🚀 [AppDelegate] didFinishLaunchingWithOptions")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    print("✅ [AppDelegate] Flutter initialisé par super.application()")

    GeneratedPluginRegistrant.register(with: self)
    print("✅ [AppDelegate] Plugins enregistrés")

    if let pluginClass = NSClassFromString("FlutterLocalNotificationsPlugin") as? NSObject.Type {
      let selector = NSSelectorFromString("setPluginRegistrantCallback:")
      if pluginClass.responds(to: selector) {
        let callback: @convention(block) (Any) -> Void = { registry in
          GeneratedPluginRegistrant.register(with: registry as! FlutterPluginRegistry)
        }

        _ = pluginClass.perform(selector, with: unsafeBitCast(callback as @convention(block) (Any) -> Void, to: AnyObject.self))
        print("✅ [AppDelegate] Callback notifications configuré via réflexion")
      } else {
        print("⚠️ [AppDelegate] setPluginRegistrantCallback non disponible")
      }
    } else {
      print("⚠️ [AppDelegate] FlutterLocalNotificationsPlugin introuvable")
    }

    UNUserNotificationCenter.current().delegate = self
    print("✅ [AppDelegate] NotificationCenter delegate configuré")

    if let initialURL = launchOptions?[.url] as? URL {
      pendingDeepLink = initialURL.absoluteString
      print("🔗 [AppDelegate] Deep link initial détecté: \(initialURL.absoluteString)")
    }

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if let flutterVC = self.window?.rootViewController as? FlutterViewController {
        self.setupFlutterChannels(with: flutterVC)
      } else {
        print("❌ [AppDelegate] FlutterViewController introuvable après lancement")
      }
    }

    return result
  }

  private func setupFlutterChannels(with controller: FlutterViewController) {
    if deepLinkChannel != nil { return }

    widgetFlutterBridgeViewModel = WidgetFlutterBridgeViewModel()
    shareFlutterBridgeViewModel = ShareFlutterBridgeViewModel { [weak self] in
      guard let root = self?.window?.rootViewController else { return nil }
      var top = root
      while let presented = top.presentedViewController {
        top = presented
      }
      return top
    }
    subscriptionFlutterBridgeViewModel = SubscriptionFlutterBridgeViewModel { [weak self] in
      self?.window?.windowScene
    }
    storeFlutterBridgeViewModel = StoreFlutterBridgeViewModel()

    print("🔧 [AppDelegate] Initialisation des channels Flutter...")

    let channel = FlutterMethodChannel(
      name: FlutterBridgeConstants.deepLinkChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    deepLinkChannel = channel
    print("✅ [AppDelegate] Channel deep link/widget initialisé: \(FlutterBridgeConstants.deepLinkChannelName)")

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "DEALLOCATED", message: "AppDelegate deallocated", details: nil))
        return
      }

      switch call.method {
      case "reloadWidgets":
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
          result(nil)
        } else {
          result(FlutterError(code: "UNAVAILABLE", message: "WidgetCenter requires iOS 14+", details: nil))
        }
      case "updateWidgetData":
        self.widgetFlutterBridgeViewModel.handleUpdateWidgetData(arguments: call.arguments, result: result)
      case "getWidgetFavorites":
        self.widgetFlutterBridgeViewModel.handleGetWidgetFavorites(result: result)
      case "getWidgetStoredQuote":
        self.widgetFlutterBridgeViewModel.handleGetWidgetStoredQuote(result: result)
      case "setOpenedFromLockScreen":
        self.widgetFlutterBridgeViewModel.handleSetOpenedFromLockScreen(result: result)
      case "getOpenedFromLockScreen":
        self.widgetFlutterBridgeViewModel.handleGetOpenedFromLockScreen(result: result)
      case "resetOpenedFromLockScreen":
        self.widgetFlutterBridgeViewModel.handleResetOpenedFromLockScreen(result: result)
      case "forceWidgetNewQuote":
        self.widgetFlutterBridgeViewModel.handleForceWidgetNewQuote(result: result)
      case "forceLockScreenWidgetNewQuote":
        self.widgetFlutterBridgeViewModel.handleForceLockScreenWidgetNewQuote(result: result)
      case "setLockscreenForcedQuote":
        self.widgetFlutterBridgeViewModel.handleSetLockscreenForcedQuote(arguments: call.arguments, result: result)
      case "getLockscreenForcedQuote":
        self.widgetFlutterBridgeViewModel.handleGetLockscreenForcedQuote(result: result)
      case "clearLockscreenForcedQuote":
        self.widgetFlutterBridgeViewModel.handleClearLockscreenForcedQuote(result: result)
      case "generateShareImage":
        self.shareFlutterBridgeViewModel.handleGenerateShareImage(arguments: call.arguments, result: result)
      case "generateShareImageBytes":
        self.shareFlutterBridgeViewModel.handleGenerateShareImageBytes(arguments: call.arguments, result: result)
      case "shareImageDirect":
        self.shareFlutterBridgeViewModel.handleShareImageDirect(arguments: call.arguments, result: result)
      case "saveImageToGallery":
        self.shareFlutterBridgeViewModel.handleSaveImageToGallery(arguments: call.arguments, result: result)
      case "getAppGroupPath":
        self.shareFlutterBridgeViewModel.handleGetAppGroupPath(result: result)
      case "cancelAllIosPendingNotifications":
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        result(nil)
      case "setHardPaywallQuotesBlocked":
        self.widgetFlutterBridgeViewModel.setHardPaywallQuotesBlocked(arguments: call.arguments)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    if let pendingDeepLink = pendingDeepLink {
      print("🔗 [AppDelegate] Envoi du deep link en attente: \(pendingDeepLink)")
      channel.invokeMethod("deepLink", arguments: pendingDeepLink)
      self.pendingDeepLink = nil
    }

    let revenueCatChannel = FlutterMethodChannel(
      name: FlutterBridgeConstants.revenueCatChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    self.revenueCatChannel = revenueCatChannel
    print("✅ [AppDelegate] Channel RevenueCat initialisé")

    revenueCatChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "DEALLOCATED", message: "AppDelegate deallocated", details: nil))
        return
      }
      switch call.method {
      case "showManageSubscriptions":
        self.subscriptionFlutterBridgeViewModel.handleShowManageSubscriptions(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let storeChannel = FlutterMethodChannel(
      name: FlutterBridgeConstants.storeChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    self.storeChannel = storeChannel
    print("✅ [AppDelegate] Channel Store initialisé")

    storeChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "DEALLOCATED", message: "AppDelegate deallocated", details: nil))
        return
      }
      self.storeFlutterBridgeViewModel.handleMethod(call: call, result: result)
    }

    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✅ [AppDelegate] Tous les channels Flutter sont initialisés")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🔗 [AppDelegate] application(_:open:options:) - URL: \(url.absoluteString)")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    if url.scheme?.lowercased() == "businessmindset" {
      if let channel = deepLinkChannel {
        print("✅ [AppDelegate] Channel disponible, envoi immédiat du deep link")
        channel.invokeMethod("deepLink", arguments: url.absoluteString)
      } else {
        print("⏳ [AppDelegate] Channel non encore initialisé, mise en attente du deep link")
        pendingDeepLink = url.absoluteString
      }
      return true
    }

    return super.application(app, open: url, options: options)
  }
}
