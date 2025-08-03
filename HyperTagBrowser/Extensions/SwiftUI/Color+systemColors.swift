  // created on 9/21/24 by robinsr

import Foundation
import SwiftUI


extension Color {
  static let darkModeBackgroundColor = Color(red: 0.1176, green: 0.1176, blue: 0.1176)
  static let lightModeBackgroundColor = Color(red: 0.89, green: 0.89, blue: 0.89)
  
  var asDarkModeBackground: Color {
    mix(with: Constants.darkModeBackgroundMixColor, by: Constants.darkModeBackgroundMixAmount)
  }
  
  
  // Control Colors
  static let controlColor             = NSColor.controlColor.asColor
  static let controlTextColor         = NSColor.controlTextColor.asColor
  static let controlBackgroundColor   = NSColor.controlBackgroundColor.asColor
  static let disabledControlTextColor = NSColor.disabledControlTextColor.asColor
  
  // Text Colors
  static let headerTextColor      = NSColor.headerTextColor.asColor
  static let textBackgroundColor  = NSColor.textBackgroundColor.asColor
  static let textColor            = NSColor.textColor.asColor
  static let linkColor            = NSColor.linkColor.asColor
  static let placeholderTextColor = NSColor.placeholderTextColor.asColor
  
    // "Primary"
  static let labelColor          = NSColor.labelColor.asColor
  static let systemFill          = NSColor.systemFill.asColor
  
  // Secondary
  static let secondaryLabelColor = NSColor.secondaryLabelColor.asColor
  static let secondarySystemFill = NSColor.secondarySystemFill.asColor
  
    // Tertiary
  static let tertiaryLabelColor = NSColor.tertiaryLabelColor.asColor
  static let tertiarySystemFill = NSColor.tertiarySystemFill.asColor
  
  // Quaternary
  static let quaternaryLabelColor = NSColor.quaternaryLabelColor.asColor
  static let quaternarySystemFill = NSColor.quaternarySystemFill.asColor
  
  // Quinary
  static let quinaryLabelColor = NSColor.quinaryLabel.asColor
  static let quinarySystemFill = NSColor.quinarySystemFill.asColor
  
  // Selected Items
  static let selectedContentBackgroundColor = NSColor.selectedContentBackgroundColor.asColor
  static let selectedControlColor           = NSColor.selectedControlColor.asColor
  static let selectedControlTextColor       = NSColor.selectedControlTextColor.asColor
  static let selectedMenuItemTextColor      = NSColor.selectedMenuItemTextColor.asColor
  static let selectedTextBackgroundColor    = NSColor.selectedTextBackgroundColor.asColor
  static let selectedTextColor              = NSColor.selectedTextColor.asColor
  
  static let findHighlightColor          = NSColor.findHighlightColor.asColor
  static let gridColor                   = NSColor.gridColor.asColor
  static let keyboardFocusIndicatorColor = NSColor.keyboardFocusIndicatorColor.asColor
  static let separatorColor              = NSColor.separatorColor.asColor
  static let scrubberTexturedBackground  = NSColor.scrubberTexturedBackground.asColor
  static let textInsertionPointColor     = NSColor.textInsertionPointColor.asColor
  static let underPageBackgroundColor    = NSColor.underPageBackgroundColor.asColor
  
  static let alternateSelectedControlTextColor   = NSColor.alternateSelectedControlTextColor.asColor
  static let alternatingContentBackgroundColors  = NSColor.alternatingContentBackgroundColors.map(\.asColor)
  
  static let unemphasizedSelectedContentBackgroundColor = NSColor.unemphasizedSelectedContentBackgroundColor.asColor
  static let unemphasizedSelectedTextBackgroundColor    = NSColor.unemphasizedSelectedTextBackgroundColor.asColor
  static let unemphasizedSelectedTextColor              = NSColor.unemphasizedSelectedTextColor.asColor
  
  static let windowBackgroundColor = NSColor.windowBackgroundColor.asColor
  static let windowFrameTextColor  = NSColor.windowFrameTextColor.asColor
}
