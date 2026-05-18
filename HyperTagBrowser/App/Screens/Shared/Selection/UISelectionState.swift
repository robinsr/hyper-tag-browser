// created on 1/11/26 by robinsr

import SwiftUI


/**
 * Defines different states applicable to a selectable item.
 *
 * While `UISelectionState` is modeled as an enum and not an `OptionSet`, it is not meant to imply that a UI element
 * is limited to only one `UISelectionState` state. For instance, `active` and `hover` are not mutually exclusive
 * states.
 *
 * The presence of the `none` state, however, would imply no other states are cooccurring.
 *
 */
enum UISelectionState: String, CaseIterable {

  /// Item is currently selected and focused
  case active
  
  /// Item is selected as part of a multi-selection; not primary focus item
  case included
  
  /// Item may be selected, but is currently hovered over
  case hover
  
  /// Item is not currently selected or hovered over
  case none
  
  /**
   * Color values to apply to a view based on current UI state
   */
  var colors: StateColor {
    switch self {
    case .active:
      return StateColor(.blue).dimmed(by: 0.5)
    case .included:
      return StateColor(.blue.lighten(by: 0.25)).dimmed(by: 0.4)
    case .hover:
      return StateColor(.green).dimmed(by: 0.5)
    case .none:
      return StateColor(.clear)
    }
  }
  
  
  struct StateColor {
    let stroke: Color
    let fill: Color
    
    init(_ strokeColor: Color, _ fillColor: Color? = nil) {
      self.stroke = strokeColor
      self.fill = fillColor ?? strokeColor
    }
    
    func dimmed(by val: Double) -> Self {
      StateColor(self.stroke, self.fill.opacity(val))
    }
  }
  
  enum Intent: String, CaseIterable {
    /// Indicates itent to select an item.
    case willSelect
    /// Indicates intent to deselect an item.
    case willDeselect
    /// Indicates intent to toggle the selection state of an item.
    case willToggle
  }
}
