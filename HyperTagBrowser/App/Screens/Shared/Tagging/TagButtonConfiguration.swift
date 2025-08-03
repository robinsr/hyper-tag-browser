// created on 5/6/25 by robinsr

import SwiftUI

/**
 * A configuration object for the ``TagButton`` view
 *
 * - Parameters:
 *   - size: The ``PillButtonSize`` size of the button, default is ``PillButtonSize/small``
 *   - variant: The ``PillButtonVariant`` variant of the button, default is ``PillButtonVariant/primary``
 *   - keyConfig: The configuration for the keyboard shortcut, either a supplied ``KeyBinding``, `KeyboardShortcut`, or an indexed shortcut
 *   - label: Optionally override the default label. The default uses the ``FilteringTag/description`` value
 *   - labelCount: Optionally add a integer-based "usage count" to the label
 *   - contextMenuConfig: The configuration for the context menu, either a set of predefined sections, or a set of custom buttons
 *   - contextMenuDispatch: The function to call when an action is selected from the context menu
 *   - onTap: The function to call when the button is tapped
 */
struct TagButtonConfiguration {
  typealias Variant = PillButtonVariant
  typealias Size = PillButtonSize

  var size: Size = .small
  var variant: Variant = .primary
  var label: String? = nil
  var labelCount: Int? = nil
  var keyConfig: KeyConfig = .none
  var contextMenuConfig: TagMenuConfig = .sections(.empty)
  var contextMenuDispatch: DispatchFn = { _ in }
  var onTap: (FilteringTag) -> Void = { _ in }
  // var onLongPress: (FilteringTag) -> Void = { _ in }
  var longPressAction: TagMenuAction = .renameAll

  /**
   * Returns a View that can be used as a label for the button.
   *
   * - Parameters:
   *   - tag: The ``FilteringTag`` to use for the label, from which the label's text and icon are derived.
   */
  func label(forTag tag: FilteringTag) -> some View {
    Label {
      if let explicitLabel = self.label {
        Text(explicitLabel)
          .lineLimit(1)
          .truncationMode(.tail)
      } else {
        Text(tag.description)
          .lineLimit(1)
          .truncationMode(.tail)

        if let usageCount = self.labelCount {
          Text("(\(usageCount))")
            .textScale(.secondary)
        }

        if let keyBinding = self.keyConfig.keyShortcut {
          KeyBindingHintView(binding: keyBinding)
            .lineLimit(1)
            .textScale(.secondary)
            .fontWeight(.regular)
            .scaleEffect(0.9)
        }
      }
    } icon: {
      Image(tag.icon)
        .symbolVariant(self.variant.symbolVariant)
    }
  }

  /**
   * Returns the appropriate ``PillButtonSize`` size variant for the button
   * based on the supplied window size.
   */
  func sizeVariant(forWindowSize windowSize: CGSize = .largeWindow) -> PillButtonSize {
    windowSize.width.isWithinBreakpoint(.small) ? .small : self.size
  }

  
  /**
   * Returns a `PillButtonStyle` to use as a button style
   */
  func buttonStyle(forWindowSize windowSize: CGSize = .largeWindow) -> some ButtonStyle {
    PillButtonStyle(size: sizeVariant(forWindowSize: windowSize), variant: variant)
  }
  
  /**
   * Returns a `PillButtonStyle` to use as a button style
   */
  func labelStyle(forWindowSize windowSize: CGSize = .largeWindow) -> some LabelStyle {
    PillLabelStyle(size: sizeVariant(forWindowSize: windowSize), variant: variant)
  }
  
  
  
  enum KeyConfig {
    case none
    case binding(KeyBinding)
    case shortcut(KeyboardShortcut)
    case indexed(Int, EventModifiers)

    var isPresent: Bool {
      switch self {
        case .binding(_), .shortcut(_):
          return true
        case .indexed(let index, _):
          return index >= 0 && index < 10
        case .none: return false
      }
    }

    var keyShortcut: KeyBinding? {
      switch self {
        case .binding(let binding):
          return binding
        case .shortcut(let shortcut):
          return KeyBinding.init(shortcut.key, shortcut.modifiers)
        case .indexed(let index, let mods):
          guard 0...10 ~= index else { return nil }
          return KeyBinding.indexed(index, mods)
        case .none: return nil
      }
    }
  }

  static let noopButton = TagButtonConfiguration(
    size: .small,
    variant: .primary,
    contextMenuConfig: .noMenu,
    contextMenuDispatch: { _ in },
    onTap: { _ in }
  )

  static func noopButton(
    size: Size = .small,
    variant: Variant = Variant.primary(.inclusive)
  ) -> TagButtonConfiguration {
    .init(
      size: size,
      variant: variant,
      contextMenuConfig: .noMenu,
      contextMenuDispatch: { _ in },
      onTap: { _ in }
    )
  }
}
