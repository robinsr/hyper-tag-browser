// created on 11/27/25 by robinsr

import SwiftUI

extension EnvironmentValues {
  @Entry var showContextMenuSymbols = true
}

extension View {
  func contextMenuSymbols(enabled showSymbols: Bool = true) -> some View {
    environment(\.showContextMenuSymbols, showSymbols)
  }
}
