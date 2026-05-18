// created on 11/24/25 by robinsr

import OSLog
import SwiftUI


extension View {

  /**
   * Experimental: Create a new logger for the view.
   *
   */
  // TODO: This is experimental, and may not work as expected. Determine if this is worth keeping.
  public static func newLogger(_ viewName: String = #filePath) -> CustomLogger {
    return os.Logger.newLog(label: viewName)
  }
}
