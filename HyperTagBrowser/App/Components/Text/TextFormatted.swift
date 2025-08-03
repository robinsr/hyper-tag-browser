// created on 9/21/24 by robinsr

import SwiftUI


public struct StyleClass: Equatable, Hashable {
  
  var font: Font = .body
  var opacity: CGFloat = 1.0

  
  static let mega             = StyleClass(font: .title.weight(.medium))
  static let body             = StyleClass(font: .body)
  static let emphasis         = StyleClass(font: .body.weight(.bold))
  static let code             = StyleClass(font: .callout.monospaced())
  static let contentTitle     = StyleClass(font: .title2.weight(.ultraLight))
  //static let dialogTitle      = StyleClass(font: .title.weight(.bold))
  static let dialogTitle      = StyleClass(font: .title3.weight(.regular).smallCaps())
  static let identifier       = StyleClass(font: .caption.weight(.medium).monospaced())
  static let label            = StyleClass(font: .caption.monospaced())
  static let sectionLabel     = StyleClass(font: .body.weight(.medium))
  static let listItem         = StyleClass(font: .body.weight(.light))
  static let listItemSubtitle = StyleClass(font: .caption)
  static let listEditorInput  = StyleClass(font: .title.weight(.thin), opacity: 0.9)
  static let listEditorItem   = StyleClass(font: .title2.weight(.light))
  static let toolbar          = StyleClass(font: .body)
  static let statusbar        = StyleClass(font: .system(size: 12).weight(.medium), opacity: 0.5)
  static let controlLabel     = StyleClass(font: .body.weight(.light))
  static let primaryButton    = StyleClass(font: .body)
  static let errorDetails     = StyleClass(font: .body.monospaced())
  static let hint             = StyleClass(font: .subheadline.weight(.thin).italic())
  static let unset            = StyleClass(font: .body)
  
  static func link(_ fontWeight: Font.Weight = .regular) -> StyleClass {
    StyleClass(font: .body.weight(fontWeight))
  }
}

// TODO: Use these as style config for semantic items, eg "folderLink", "itemTitle", "thumbnailLabel", etc
extension Text {
  public func styleClass(_ style: StyleClass) -> some View {
    if style == .primaryButton {
      self.font(style.font).kerning(1.0)
    } else {
      self.font(style.font).foregroundStyle(.primary)
    }
  }
}


struct TextStyleClassViewModifier: ViewModifier {
  var style: StyleClass
  
  func body(content: Content) -> some View {
    content
      .font(style.font)
      .opacity(style.opacity)
  }
}

extension View {
  public func styleClass(_ style: StyleClass) -> some View {
    self.modifier(TextStyleClassViewModifier(style: style))
  }
}
