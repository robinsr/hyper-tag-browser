// created on 1/7/25 by robinsr

import AppKit
import SwiftUI
import UniformTypeIdentifiers


/**
 * A view modifier that adds a file icon to a view based on the file type of the URL.
 *
 * - Parameters:
 *   - url: The URL of the file.
 *   - type: Optionally override the `UTType` of the file, defaults to the content type of the URL.
 *   - iconVisible: Optionally hide the icon, defaults to `true`.
 */
struct FileItemLabelModifier : ViewModifier {
  var url: URL? = nil
  var type: UTType? = nil
  var size: CGFloat? = NSFont.systemFontSize(for: .regular)
  var visibility: Visibility = .automatic
  var presentation: IconPresentation = .symbol
  
  @ScaledMetric var iconFontSize = NSFont.systemFontSize(for: .regular) * 1.5
  
  var iconSize: CGFloat {
    size ?? NSFont.preferredFont(forTextStyle: .body).pointSize * 1.33
  }
  
  var isVisible: Bool {
    visibility.oneOf(.visible, .automatic)
  }
  
  var uttype: UTType {
    type ?? url?.contentType ?? .item
  }
  
  var icon: FileTypeIcon {
    FileTypeIcon(uttype: uttype)
  }
  
  
  func body(content: Content) -> some View {
    HStack(spacing: iconSize /  1.95) {
      Group {
        switch presentation {
        case .symbol: SymbolIcon
        case .image: ImageIcon
        }
      }
      .visible(isVisible)
      
      content
        .lineLimit(1)
        .truncationMode(.tail)
    }
  }
  
  var SymbolIcon: some View {
    Image(systemName: icon.systemName)
      .symbolRenderingMode(.palette)
      .foregroundStyle(.blue, .green, .red)
  }
  
  var ImageIcon: some View {
    Image(fileType: icon, size: iconSize)
      .font(.system(size: iconSize))
  }
  
  enum IconPresentation {
    case symbol, image
  }
}


extension View {
  typealias IconType = FileItemLabelModifier.IconPresentation
  
  func prefixWithFileIcon(
    _ url: URL,
    size: CGFloat? = nil,
    visibility: Visibility = .automatic,
    presentation: IconType = .image
  ) -> some View {
    modifier(FileItemLabelModifier(url: url, size: size, visibility: visibility, presentation: presentation))
  }
  
  func prefixWithFileIcon(
    _ type: UTType,
    size: CGFloat? = nil,
    visibility: Visibility = .automatic,
    presentation: IconType = .image
  ) -> some View {
    modifier(FileItemLabelModifier(type: type, size: size, visibility: visibility, presentation: presentation))
  }
}
