import Flutter
import Photos
import SwiftUI
import UIKit

/// ViewModel du pont Flutter pour images de partage, partage natif et App Group (chemins).
final class ShareFlutterBridgeViewModel {

  /// Contrôleur affiché au sommet de la pile (pour UIActivityViewController).
  var topViewControllerProvider: () -> UIViewController?

  init(topViewControllerProvider: @escaping () -> UIViewController? = { nil }) {
    self.topViewControllerProvider = topViewControllerProvider
  }

  func handleGenerateShareImage(arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected dictionary", details: nil))
      return
    }

    let quote = args["quote"] as? String ?? ""
    let signature = args["signature"] as? String
    let bookTitle = args["bookTitle"] as? String
    let userName = args["userName"] as? String ?? "Nobody"

    let themeIsImage = args["themeIsImage"] as? Bool ?? false
    let themeImageName = args["themeImageName"] as? String
    let themeColor1 = args["themeColor1"] as? Int ?? 0xFF1f1f1f
    let themeColor2 = args["themeColor2"] as? Int
    let themeColor3 = args["themeColor3"] as? Int
    let themeNbrColor = args["themeNbrColor"] as? Int ?? 1
    let themeFontFamily = args["themeFontFamily"] as? String ?? "InterTight"
    let themeFontSize = args["themeFontSize"] as? Int ?? 18
    let themeFontColor = args["themeFontColor"] as? Int ?? 0xFFFFFFFF

    if quote.isEmpty {
      result(FlutterError(code: "EMPTY_QUOTE", message: "Quote is empty", details: nil))
      return
    }

    let sharePreviewText = quote.replacingOccurrences(of: "%NAME%", with: userName)

    print("[ShareImage] 🔄 Début de la génération d'image...")

    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        result(FlutterError(code: "DEALLOCATED", message: "ShareFlutterBridgeViewModel deallocated", details: nil))
        return
      }

      if let image = Self.generateShareImageDirect(
        quote: quote,
        signature: signature,
        bookTitle: bookTitle,
        userName: userName,
        themeIsImage: themeIsImage,
        themeImageName: themeImageName,
        themeColor1: themeColor1,
        themeColor2: themeColor2,
        themeColor3: themeColor3,
        themeNbrColor: themeNbrColor,
        themeFontFamily: themeFontFamily,
        themeFontSize: themeFontSize,
        themeFontColor: themeFontColor
      ) {
        print("[ShareImage] ✅ Image générée avec succès, présentation du share sheet...")
        self.presentShareSheet(with: image, quote: sharePreviewText)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          result(nil)
        }
      } else {
        print("[ShareImage] ❌ Échec de la génération d'image")
        result(FlutterError(code: "GENERATION_FAILED", message: "Failed to generate image", details: nil))
      }
    }
  }

  func presentShareSheet(with image: UIImage, quote: String) {
    guard let presentingViewController = topViewControllerProvider() else {
      print("[ShareImage] ❌ Cannot find root view controller")
      return
    }

    print("[ShareImage] 📱 Présentation depuis: \(type(of: presentingViewController))")

    let itemProvider = ShareImageItemProvider(image: image, quote: quote)

    let activityViewController = UIActivityViewController(
      activityItems: [itemProvider],
      applicationActivities: nil
    )

    if let popoverController = activityViewController.popoverPresentationController {
      popoverController.sourceView = presentingViewController.view
      popoverController.sourceRect = CGRect(
        x: presentingViewController.view.bounds.midX,
        y: presentingViewController.view.bounds.midY,
        width: 0,
        height: 0
      )
      popoverController.permittedArrowDirections = []
    }

    presentingViewController.present(activityViewController, animated: true) {
      print("[ShareImage] ✅ Share sheet affiché avec succès")
    }

    print("[ShareImage] 🎨 Share sheet présenté avec image de \(image.size.width)x\(image.size.height), scale: \(image.scale)")
  }

  static func generateShareImageDirect(
    quote: String,
    signature: String?,
    bookTitle: String?,
    userName: String,
    themeIsImage: Bool,
    themeImageName: String?,
    themeColor1: Int,
    themeColor2: Int?,
    themeColor3: Int?,
    themeNbrColor: Int,
    themeFontFamily: String,
    themeFontSize: Int,
    themeFontColor: Int
  ) -> UIImage? {
    let imageWidth: CGFloat = 720
    let imageHeight: CGFloat = 1280
    let imageSize = CGSize(width: imageWidth, height: imageHeight)

    let vm = ShareImageViewModel(
      quote: quote,
      signature: signature,
      bookTitle: bookTitle,
      userName: userName,
      themeIsImage: themeIsImage,
      themeImageName: themeImageName,
      themeColor1: UInt32(themeColor1),
      themeColor2: themeColor2 != nil ? UInt32(themeColor2!) : nil,
      themeColor3: themeColor3 != nil ? UInt32(themeColor3!) : nil,
      themeNbrColor: themeNbrColor,
      themeFontFamily: themeFontFamily,
      themeFontSize: themeFontSize,
      themeFontColor: UInt32(themeFontColor),
      imageSize: imageSize
    )
    let shareView = ShareImageView(viewModel: vm)

    let semaphore = DispatchSemaphore(value: 0)
    var renderedImage: UIImage?

    DispatchQueue.main.async {
      let hostingController = UIHostingController(rootView: shareView)
      hostingController.view.frame = CGRect(origin: .zero, size: imageSize)
      hostingController.view.backgroundColor = UIColor.clear
      hostingController.view.layoutIfNeeded()

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        let image: UIImage
        if #available(iOS 16.0, *) {
          let format = UIGraphicsImageRendererFormat()
          format.scale = 2.0
          format.opaque = true

          let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
          image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
            hostingController.view.drawHierarchy(in: CGRect(origin: .zero, size: imageSize), afterScreenUpdates: true)
          }
        } else {
          UIGraphicsBeginImageContextWithOptions(imageSize, true, 2.0)
          defer { UIGraphicsEndImageContext() }

          UIColor.white.setFill()
          UIRectFill(CGRect(origin: .zero, size: imageSize))
          hostingController.view.drawHierarchy(in: CGRect(origin: .zero, size: imageSize), afterScreenUpdates: true)
          image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        }

        print("[ShareImage] Image générée directement - Taille: \(image.size.width)x\(image.size.height), Scale: \(image.scale)")
        renderedImage = image
        semaphore.signal()
      }
    }

    if semaphore.wait(timeout: .now() + 3.0) == .timedOut {
      print("[ShareImage] Timeout lors du rendu")
      return nil
    }

    return renderedImage
  }

  func handleGenerateShareImageBytes(arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected dictionary", details: nil))
      return
    }

    let quote = args["quote"] as? String ?? ""
    let signature = args["signature"] as? String
    let bookTitle = args["bookTitle"] as? String
    let userName = args["userName"] as? String ?? "Nobody"

    let themeIsImage = args["themeIsImage"] as? Bool ?? false
    let themeImageName = args["themeImageName"] as? String
    let themeColor1 = args["themeColor1"] as? Int ?? 0xFF1f1f1f
    let themeColor2 = args["themeColor2"] as? Int
    let themeColor3 = args["themeColor3"] as? Int
    let themeNbrColor = args["themeNbrColor"] as? Int ?? 1
    let themeFontFamily = args["themeFontFamily"] as? String ?? "InterTight"
    let themeFontSize = args["themeFontSize"] as? Int ?? 18
    let themeFontColor = args["themeFontColor"] as? Int ?? 0xFFFFFFFF

    if quote.isEmpty {
      result(FlutterError(code: "EMPTY_QUOTE", message: "Quote is empty", details: nil))
      return
    }

    print("[ShareImageBytes] 🔄 Génération de l'image pour Flutter...")

    DispatchQueue.global(qos: .userInitiated).async {
      if let image = Self.generateShareImageDirect(
        quote: quote,
        signature: signature,
        bookTitle: bookTitle,
        userName: userName,
        themeIsImage: themeIsImage,
        themeImageName: themeImageName,
        themeColor1: themeColor1,
        themeColor2: themeColor2,
        themeColor3: themeColor3,
        themeNbrColor: themeNbrColor,
        themeFontFamily: themeFontFamily,
        themeFontSize: themeFontSize,
        themeFontColor: themeFontColor
      ) {
        if let jpegData = image.jpegData(compressionQuality: 0.85) {
          print("[ShareImageBytes] ✅ Image générée: \(jpegData.count) bytes")
          result(FlutterStandardTypedData(bytes: jpegData))
        } else {
          print("[ShareImageBytes] ❌ Échec de la conversion en JPEG")
          result(FlutterError(code: "JPEG_CONVERSION_FAILED", message: "Failed to convert image to JPEG", details: nil))
        }
      } else {
        print("[ShareImageBytes] ❌ Échec de la génération d'image")
        result(FlutterError(code: "GENERATION_FAILED", message: "Failed to generate image", details: nil))
      }
    }
  }

  func handleShareImageDirect(arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
          let imageData = args["imageBytes"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected imageBytes", details: nil))
      return
    }

    print("[ShareImageDirect] 🔄 Partage de l'image...")

    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        result(FlutterError(code: "DEALLOCATED", message: "ShareFlutterBridgeViewModel deallocated", details: nil))
        return
      }

      guard let image = UIImage(data: imageData.data) else {
        print("[ShareImageDirect] ❌ Impossible de créer UIImage depuis les données")
        result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create image from data", details: nil))
        return
      }

      print("[ShareImageDirect] ✅ Image créée: \(image.size.width)x\(image.size.height)")

      guard let presentingViewController = self.topViewControllerProvider() else {
        print("[ShareImageDirect] ❌ Cannot find root view controller")
        result(FlutterError(code: "NO_ROOT_VC", message: "Cannot find root view controller", details: nil))
        return
      }

      print("[ShareImageDirect] 📱 Présentation depuis: \(type(of: presentingViewController))")

      let itemProvider = ShareImageWithMetadataProvider(image: image)

      let activityViewController = UIActivityViewController(
        activityItems: [itemProvider],
        applicationActivities: nil
      )

      if let popoverController = activityViewController.popoverPresentationController {
        popoverController.sourceView = presentingViewController.view
        popoverController.sourceRect = CGRect(
          x: presentingViewController.view.bounds.midX,
          y: presentingViewController.view.bounds.midY,
          width: 0,
          height: 0
        )
        popoverController.permittedArrowDirections = []
      }

      presentingViewController.present(activityViewController, animated: true) {
        print("[ShareImageDirect] ✅ Share sheet affiché avec succès")
      }

      result(nil)
    }
  }

  func handleSaveImageToGallery(arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
          let imageData = args["imageBytes"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected imageBytes", details: nil))
      return
    }

    print("[SaveImage] 🔄 Sauvegarde de l'image dans la galerie...")

    guard let image = UIImage(data: imageData.data) else {
      print("[SaveImage] ❌ Impossible de créer UIImage depuis les données")
      result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create image from data", details: nil))
      return
    }

    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        result(FlutterError(code: "DEALLOCATED", message: "ShareFlutterBridgeViewModel deallocated", details: nil))
        return
      }

      let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)

      if currentStatus == .authorized || currentStatus == .limited {
        self.saveImageToGallery(image: image, result: result)
      } else if currentStatus == .notDetermined {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
          DispatchQueue.main.async {
            if status == .authorized || status == .limited {
              self.saveImageToGallery(image: image, result: result)
            } else {
              print("[SaveImage] ❌ Autorisation refusée")
              result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access denied", details: nil))
            }
          }
        }
      } else {
        print("[SaveImage] ❌ Autorisation refusée (status: \(currentStatus.rawValue))")
        result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access denied", details: nil))
      }
    }
  }

  private func saveImageToGallery(image: UIImage, result: @escaping FlutterResult) {
    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.creationRequestForAsset(from: image)
    }, completionHandler: { success, error in
      DispatchQueue.main.async {
        if success {
          print("[SaveImage] ✅ Image sauvegardée avec succès")
          result(true)
        } else {
          print("[SaveImage] ❌ Erreur lors de la sauvegarde: \(error?.localizedDescription ?? "Unknown error")")
          result(FlutterError(code: "SAVE_FAILED", message: error?.localizedDescription ?? "Failed to save image", details: nil))
        }
      }
    })
  }

  func handleGetAppGroupPath(result: FlutterResult) {
    if let groupURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: FlutterBridgeConstants.widgetSuiteName
    ) {
      print("[AppGroup] ✅ Chemin App Group: \(groupURL.path)")
      result(groupURL.path)
    } else {
      print("[AppGroup] ❌ Impossible d'obtenir le chemin de l'App Group")
      result(FlutterError(
        code: "APP_GROUP_UNAVAILABLE",
        message: "Cannot access App Group container",
        details: nil
      ))
    }
  }
}
