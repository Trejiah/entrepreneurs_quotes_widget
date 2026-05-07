import SwiftUI
import UIKit

/// Présentation et logique d’affichage pour l’image de partage (couche ViewModel MVVM).
struct ShareImageViewModel {
  let quote: String
  let signature: String?
  let bookTitle: String?
  let userName: String
  let themeIsImage: Bool
  let themeImageName: String?
  let themeColor1: UInt32
  let themeColor2: UInt32?
  let themeColor3: UInt32?
  let themeNbrColor: Int
  let themeFontFamily: String
  let themeFontSize: Int
  let themeFontColor: UInt32
  let imageSize: CGSize

  var displayQuote: String {
    quote.replacingOccurrences(of: "%NAME%", with: userName)
  }

  var appDisplayName: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Business Mindset"
  }

  func quoteFontSize() -> CGFloat {
    CGFloat(themeFontSize) * 1.1 * (imageSize.width / 375.0)
  }

  func signatureFontSize() -> CGFloat {
    CGFloat(themeFontSize) * 0.75 * (imageSize.width / 375.0)
  }

  func bookTitleFontSize() -> CGFloat {
    CGFloat(themeFontSize) * 0.6 * (imageSize.width / 375.0)
  }

  func signatureTopPadding() -> CGFloat {
    20 * (imageSize.height / 812.0)
  }

  func bookTitleTopPadding() -> CGFloat {
    10 * (imageSize.height / 812.0)
  }

  func horizontalPadding() -> CGFloat {
    17 * (imageSize.width / 375.0)
  }

  func brandingTopPadding() -> CGFloat {
    30 * (imageSize.height / 812.0)
  }

  func brandingIconSize() -> CGFloat {
    33 * (imageSize.width / 375.0)
  }

  func brandingCornerRadius() -> CGFloat {
    10 * (imageSize.width / 375.0)
  }

  func brandingNameFontSize() -> CGFloat {
    11 * (imageSize.width / 375.0)
  }

  func brandingHorizontalPadding() -> CGFloat {
    5 * (imageSize.width / 375.0)
  }

  func brandingVerticalPadding() -> CGFloat {
    5 * (imageSize.height / 812.0)
  }

  func brandingFrameWidthFraction() -> CGFloat {
    imageSize.width * 0.37
  }

  func brandingBackgroundCornerRadius() -> CGFloat {
    12 * (imageSize.width / 375.0)
  }

  func swiftUIColor(_ value: UInt32) -> Color {
    let r = Double((value >> 16) & 0xFF) / 255.0
    let g = Double((value >> 8) & 0xFF) / 255.0
    let b = Double(value & 0xFF) / 255.0
    return Color(red: r, green: g, blue: b)
  }

  func customFont(size: CGFloat) -> Font {
    let postScriptName = Self.fontPostScriptMapping[themeFontFamily] ?? themeFontFamily
    if let font = UIFont(name: postScriptName, size: size) {
      return Font(font)
    }
    return .system(size: size)
  }

  func loadBackgroundImage(name: String) -> UIImage? {
    if let flutterBundle = Bundle.main.path(forResource: "Frameworks", ofType: nil) {
      let assetPath = "\(flutterBundle)/App.framework/flutter_assets/assets/images/backgrounds/\(name)"
      if FileManager.default.fileExists(atPath: assetPath) {
        return UIImage(contentsOfFile: assetPath)
      }
    }

    if let image = UIImage(named: name) {
      return image
    }

    let nameWithoutExt = (name as NSString).deletingPathExtension
    if let image = UIImage(named: nameWithoutExt) {
      return image
    }

    return nil
  }

  func appIcon() -> UIImage? {
    if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
       let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
       let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String] {
      for iconName in iconFiles.reversed() {
        if let icon = UIImage(named: iconName) {
          return icon
        }
      }
    }

    if let icon = UIImage(named: "AppIcon") {
      return icon
    }

    return nil
  }

  private static let fontPostScriptMapping: [String: String] = [
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
}
