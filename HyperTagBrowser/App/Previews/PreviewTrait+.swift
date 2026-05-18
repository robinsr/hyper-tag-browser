// created on 1/12/26 by robinsr

import SwiftUI

extension PreviewTrait where T == Preview.ViewTraits {
  
  @MainActor
  static func fixed(_ w: Double, _ h: Double) -> Self {
    .fixedLayout(width: w, height: h)
  }
}
