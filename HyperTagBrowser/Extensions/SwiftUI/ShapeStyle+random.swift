// created on 1/4/25 by robinsr

import SwiftUI

extension ShapeStyle where Self == Color {
  
  /**
   Returns a random color. Useful for determining if a View is being updated.
   */
  static var random: Color {
    Color(
      red: .random(in: 0...1),
      green: .random(in: 0...1),
      blue: .random(in: 0...1)
    )
  }
  
//  static var labelColor: Color {
//    Color.labelColor
//  }

//  static var secondaryLabelColor: Color {
//    Color.secondaryLabelColor
//  }

//  static var tertiaryLabelColor: Color {
//    Color.tertiaryLabelColor
//  }

//  static var quaternaryLabelColor: Color {
//    Color.quaternaryLabelColor
//  }

//  /// Used for large scale images or subtle decorative elements; not for general foreground content.
//  static var linkColor: Color {
//    Color.linkColor
//  }

//  static var placeholderTextColor: Color {
//    Color.placeholderTextColor
//  }

//  static var windowFrameTextColor: Color {
//    Color.windowFrameTextColor
//  }

//  static var selectedMenuItemTextColor: Color {
//    Color.selectedMenuItemTextColor
//  }

//  static var alternateSelectedControlTextColor: Color {
//    Color.alternateSelectedControlTextColor
//  }

//  static var headerTextColor: Color {
//    Color.headerTextColor
//  }

//  static var separatorColor: Color {
//    Color.separatorColor
//  }

//  static var gridColor: Color {
//    Color.gridColor
//  }

//  static var windowBackgroundColor: Color {
//    Color.windowBackgroundColor
//  }

//  static var underPageBackgroundColor: Color {
//    Color.underPageBackgroundColor
//  }

//  static var controlBackgroundColor: Color {
//    Color.controlBackgroundColor
//  }

//  static var selectedContentBackgroundColor: Color {
//    Color.selectedContentBackgroundColor
//  }

//  static var unemphasizedSelectedContentBackgroundColor: Color {
//    Color.unemphasizedSelectedContentBackgroundColor
//  }

//  static var alternatingContentBackgroundColors: [Color] {
//    Color.alternatingContentBackgroundColors
//  }

//  static var findHighlightColor: Color {
//    Color.findHighlightColor
//  }

//  static var textColor: Color {
//    Color.textColor
//  }

//  static var textBackgroundColor: Color {
//    Color.textBackgroundColor
//  }

//  static var textInsertionPointColor: Color {
//    Color.textInsertionPointColor
//  }

//  static var selectedTextColor: Color {
//    Color.selectedTextColor
//  }

//  static var selectedTextBackgroundColor: Color {
//    Color.selectedTextBackgroundColor
//  }

//  static var unemphasizedSelectedTextBackgroundColor: Color {
//    Color.unemphasizedSelectedTextBackgroundColor
//  }

//  static var unemphasizedSelectedTextColor: Color {
//    Color.unemphasizedSelectedTextColor
//  }

//  static var controlColor: Color {
//    Color.controlColor
//  }

//  static var controlTextColor: Color {
//    Color.controlTextColor
//  }

//  static var selectedControlColor: Color {
//    Color.selectedControlColor
//  }

//  static var selectedControlTextColor: Color {
//    Color.selectedControlTextColor
//  }

  static var disabledControlTextColor: Color {
    Color.disabledControlTextColor
  }
//
//  static var keyboardFocusIndicatorColor: Color {
//    Color.keyboardFocusIndicatorColor
//  }

//  static var scrubberTexturedBackground: Color {
//    Color.scrubberTexturedBackground
//  }
}
