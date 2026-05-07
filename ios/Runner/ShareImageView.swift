import SwiftUI
import UIKit

struct ShareImageView: View {
  let viewModel: ShareImageViewModel

  var body: some View {
    let vm = viewModel
    ZStack {
      backgroundView(vm: vm)

      VStack(spacing: 0) {
        Spacer()

        VStack(spacing: 0) {
          VStack(spacing: 0) {
            Text(vm.displayQuote)
              .font(vm.customFont(size: vm.quoteFontSize()))
              .foregroundColor(vm.swiftUIColor(vm.themeFontColor))
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)

            VStack(alignment: .trailing, spacing: 0) {
              if let signature = vm.signature, !signature.isEmpty {
                Text(signature)
                  .font(vm.customFont(size: vm.signatureFontSize()))
                  .foregroundColor(vm.swiftUIColor(vm.themeFontColor))
                  .multilineTextAlignment(.trailing)
                  .padding(.top, vm.signatureTopPadding())
              }

              if let bookTitle = vm.bookTitle, !bookTitle.isEmpty {
                Text(bookTitle)
                  .font(vm.customFont(size: vm.bookTitleFontSize()))
                  .foregroundColor(vm.swiftUIColor(vm.themeFontColor))
                  .multilineTextAlignment(.trailing)
                  .padding(.top, vm.bookTitleTopPadding())
              }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
          }
          .padding(.horizontal, vm.horizontalPadding())

          HStack {
            Spacer()
            appBrandingFrame(vm: vm)
            Spacer()
          }
          .padding(.top, vm.brandingTopPadding())
        }

        Spacer()
      }
    }
    .frame(width: vm.imageSize.width, height: vm.imageSize.height)
  }

  @ViewBuilder
  private func backgroundView(vm: ShareImageViewModel) -> some View {
    if vm.themeIsImage, let imageName = vm.themeImageName, !imageName.isEmpty {
      if let bgImage = vm.loadBackgroundImage(name: imageName) {
        Image(uiImage: bgImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: vm.imageSize.width, height: vm.imageSize.height)
          .clipped()
      } else {
        vm.swiftUIColor(vm.themeColor1)
      }
    } else {
      if vm.themeNbrColor == 1 {
        vm.swiftUIColor(vm.themeColor1)
      } else if vm.themeNbrColor == 2, let color2 = vm.themeColor2 {
        LinearGradient(
          colors: [
            vm.swiftUIColor(vm.themeColor1),
            vm.swiftUIColor(color2)
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      } else if vm.themeNbrColor >= 3, let color2 = vm.themeColor2, let color3 = vm.themeColor3 {
        LinearGradient(
          colors: [
            vm.swiftUIColor(vm.themeColor1),
            vm.swiftUIColor(color2),
            vm.swiftUIColor(color3)
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      } else {
        vm.swiftUIColor(vm.themeColor1)
      }
    }
  }

  private func appBrandingFrame(vm: ShareImageViewModel) -> some View {
    HStack(spacing: vm.brandingHorizontalPadding()) {
      if let appIcon = vm.appIcon() {
        Image(uiImage: appIcon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: vm.brandingIconSize(), height: vm.brandingIconSize())
          .clipShape(RoundedRectangle(cornerRadius: vm.brandingCornerRadius()))
      }

      Text(vm.appDisplayName)
        .font(.system(size: vm.brandingNameFontSize(), weight: .semibold))
        .foregroundColor(.white)
    }
    .padding(.horizontal, vm.brandingHorizontalPadding())
    .padding(.vertical, vm.brandingVerticalPadding())
    .frame(width: vm.brandingFrameWidthFraction(), alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: vm.brandingBackgroundCornerRadius())
        .fill(Color.black.opacity(0.40))
    )
  }
}

extension View {
  func snapshot() -> UIImage {
    let controller = UIHostingController(rootView: self)
    let view = controller.view

    let targetSize = controller.view.intrinsicContentSize
    view?.bounds = CGRect(origin: .zero, size: targetSize)
    view?.backgroundColor = .clear

    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
      view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
  }
}
