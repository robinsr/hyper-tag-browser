// created on 1/12/26 by robinsr

import SwiftUI


extension View {
  func frame(preset: PreviewSize) -> some View {
    self.frame(width: preset.width, height: preset.height)
  }
}

