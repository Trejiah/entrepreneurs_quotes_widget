import UIKit

// MARK: - ShareImageWithMetadataProvider

class ShareImageWithMetadataProvider: UIActivityItemProvider {
  private let fileURL: URL

  init(image: UIImage) {
    let tempDir = FileManager.default.temporaryDirectory
    let fileName = "BusinessMindset_Quote.jpg"
    let url = tempDir.appendingPathComponent(fileName)

    try? FileManager.default.removeItem(at: url)

    if let jpegData = image.jpegData(compressionQuality: 0.9) {
      try? jpegData.write(to: url)
      print("[ShareImage] 💾 Fichier créé: \(fileName), taille: \(Double(jpegData.count) / (1024 * 1024)) MB")
    }

    self.fileURL = url

    super.init(placeholderItem: url)
  }

  override var item: Any {
    return fileURL
  }

  override func activityViewController(
    _ activityViewController: UIActivityViewController,
    dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
  ) -> String {
    return "public.jpeg"
  }

  override func activityViewController(
    _ activityViewController: UIActivityViewController,
    subjectForActivityType activityType: UIActivity.ActivityType?
  ) -> String {
    return "Business Mindset Quote"
  }
}

// MARK: - ShareImageItemProvider

class ShareImageItemProvider: UIActivityItemProvider {
  private let image: UIImage
  private var tempFileURL: URL?

  init(image: UIImage, quote _: String) {
    self.image = image
    super.init(placeholderItem: image)
  }

  override var item: Any {
    return image
  }

  override func activityViewController(
    _ activityViewController: UIActivityViewController,
    itemForActivityType activityType: UIActivity.ActivityType?
  ) -> Any? {
    let tempDir = FileManager.default.temporaryDirectory
    let fileName = "BusinessMindset_Quote.jpg"
    let fileURL = tempDir.appendingPathComponent(fileName)

    try? FileManager.default.removeItem(at: fileURL)

    guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
      return image
    }

    do {
      try jpegData.write(to: fileURL)
      tempFileURL = fileURL
      print("[ShareImage] 💾 Fichier créé pour partage: \(fileName)")
      return fileURL
    } catch {
      print("[ShareImage] ❌ Erreur création fichier: \(error)")
      return image
    }
  }

  override func activityViewController(
    _ activityViewController: UIActivityViewController,
    dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
  ) -> String {
    return "public.jpeg"
  }

  override func activityViewController(
    _ activityViewController: UIActivityViewController,
    subjectForActivityType activityType: UIActivity.ActivityType?
  ) -> String {
    return "Business Mindset Quote"
  }
}
