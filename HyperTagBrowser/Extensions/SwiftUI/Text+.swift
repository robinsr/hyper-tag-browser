// created on 5/11/25 by robinsr

import SwiftUI


extension Text {
  
  /**
   * Initializes a Text view from a ``KeyBinding`` value.
   */
  init(_ binding: KeyBinding) {
    self.init(binding.description)
  }
  
  
  /**
    * Initializes a Text view from a ``KeyEquivalent`` value.
   */
  init(_ key: KeyEquivalent) {
    self.init(key.asCharacter)
  }
}
