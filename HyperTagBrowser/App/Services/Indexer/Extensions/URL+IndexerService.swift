// created on 3/3/25 by robinsr

import Foundation
import GRDB


extension URL {
  
  /**
   Returns a boolean indicating whether files of the current file URL are able to be added to the index
   */
  var isIndexable: Bool {
    self.isDirectory && self.volumeIsBrowsable
  }
}

