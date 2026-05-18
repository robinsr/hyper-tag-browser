// created on 5/6/25 by robinsr

import SwiftUI
import Factory

/**
 * A configuration object for the ``TagButton`` view
 *
 * - Parameters:
 *   - size: The `PillButtonSize` size of the button, default is `.small`
 *   - variant: The `PillButtonVariant` variant of the button, default is `.primary`
 *   - label: Override the default label
 *   - counts: Show usage count of tag always, never, or use users's preference setting
 *   - draggable: Allow dragging
 *   - menu: A `TagMenuConfig` defining the context menu
 *   - onMenuItem: Called when an action is selected from the context menu
 *   - shortcut: A `KeyConfig` defining a keyboard shortcut
 *   - press: Action to perform on long press
 *   - onTap: Called when the button is tapped
 */
@MainActor
struct TagButtonConfiguration: Sendable {
  typealias Variant = PillButtonVariant
  typealias Size = PillButtonSize
  
  typealias Handler = (FilteringTag, EventModifiers) -> Void
  
  static var `default`: TagButtonConfiguration {
    TagButtonConfiguration()
  }
  
  enum ShowUsageCount {
    case always
    case never
    case preference
  }
  
  var size: Size = .small
  var variant: Variant = .primary(.inclusive)
  var label: String? = nil
  var counts: ShowUsageCount = .never
  var draggable: Bool = false
  var menu: TagMenuConfig = .noMenu
  var onMenuItem: DispatchFn = { _ in }
  var shortcut: KeyConfig = .none
  var onLongPress: ((FilteringTag) -> Void)? = nil
  var onTap: (FilteringTag) -> Void = { _ in }
  
  
  private var preferCountShowing: Bool {
    PreferencesContainer.shared.prefs().forKey(.showTagUsageCount)
  }
  
  var style: PillButtonVariantStyleConfiguration {
    variant.style
  }
  
  var symbol: SymbolVariants {
    variant.symbolVariant
  }
  
  var showCount: Bool {
    if (preferCountShowing) {
      return counts != .never
    } else {
      return counts != .always
    }
  }
  
  var canFocus: Bool {
    draggable == false
  }
  
  var hasMenu: Bool {
    menu != .noMenu
  }
  
  var hasTap: Bool {
    true // placeholder for future untappable use case
  }
  
  var buttons: [TagMenuAction] {
    menu.buttons
  }
  
  var hasLongPress: Bool {
    onLongPress != nil
  }
  
  var hasKeyBinding: Bool {
    shortcut.isPresent
  }
  
  var binding: KeyBinding? {
    shortcut.binding
  }
}
