// created on 9/29/24 by robinsr

import Defaults
import Percentage
import SwiftUI



struct SheetControlsPresentedEnvKey : EnvironmentKey {
  static let defaultValue: SheetPresentation.SheetControl = .noControls
}

extension EnvironmentValues {
  
  /**
    Returns a `SheetPresentation.Controls` value representing the visibility of the sheet controls.
   */
  var sheetControls: SheetPresentation.SheetControl {
    get { self[SheetControlsPresentedEnvKey.self] }
    set { self[SheetControlsPresentedEnvKey.self] = newValue }
  }
}



struct SheetPaddingEnvKey : EnvironmentKey {
  static let defaultValue: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension EnvironmentValues {

  /**
   Returns a `EdgeInsets` value representing the padding of the containing sheet view. Returns zero
   values if the view is not contained within a sheet.
   */
  var sheetPadding: EdgeInsets {
    get { self[SheetPaddingEnvKey.self] }
    set { self[SheetPaddingEnvKey.self] = newValue }
  }
}


struct SheetPresentationEnvKey : EnvironmentKey {
  static let defaultValue: SheetPresentation = .modalSticky(controls: .close)
}

extension EnvironmentValues {
  
  /**
    Returns a `SheetPresentation` value representing the current presentation style of the sheet.
   */
  var sheetPresentation: SheetPresentation {
    get { self[SheetPresentationEnvKey.self] }
    set { self[SheetPresentationEnvKey.self] = newValue }
  }
}
