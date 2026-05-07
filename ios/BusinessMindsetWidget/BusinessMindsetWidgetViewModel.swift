import Foundation

/// État et règles de présentation pour les vues du widget (MVVM — sans logique de timeline).
enum BusinessMindsetWidgetViewModel {

  /// Résout le `ThemeData` affiché pour un index de thème (app ou custom depuis l’App Group).
  static func themeData(for themeIndex: Int, defaults: UserDefaults = widgetUserDefaults()) -> ThemeData {
    let isCustomTheme = defaults.bool(forKey: "widgetIsCustomTheme")

    if isCustomTheme,
       let customThemes = defaults.array(forKey: "themeCustomDatasMap") as? [[String: Any]],
       themeIndex >= 0 && themeIndex < customThemes.count {
      let customData = customThemes[themeIndex]
      let color1 = customData["color1"] as? UInt32 ?? 0xFF1f1f1f
      let fontFamily = customData["fontfamily"] as? String ?? "InterTight"
      let fontColor = customData["fontcolor"] as? UInt32 ?? 0xFFFFFFFF
      let fontSize = (customData["fontsize"] as? Double).map { Int($0) } ?? 18
      let name = customData["name"] as? String ?? "Custom"
      let isImageTheme = customData["isImage"] as? Bool ?? false
      let imageName = customData["imageName"] as? String

      let customTheme = ThemeData(
        color1: color1,
        fontFamily: fontFamily,
        fontColor: fontColor,
        fontSize: fontSize,
        name: name,
        isImage: isImageTheme,
        imageName: imageName
      )
      print("[widget] 📦 Using CUSTOM theme '\(name)' for systemMediumView")
      return customTheme
    } else {
      let safeIndex = max(0, min(themeIndex, allAppThemes.count - 1))
      let appTheme = allAppThemes[safeIndex]
      print("[widget] 📦 Using APP theme '\(appTheme.name)' for systemMediumView")
      return appTheme
    }
  }
}
