// created on 4/23/25 by robinsr

import Foundation
import UniformTypeIdentifiers

struct URLPathSegment: Identifiable, Equatable {
  let id = UUID()
  let url: URL
  
  var name: String { url.lastPathComponent }
  var icon: SymbolIcon { url == UserLocation.home ? .home : .triangleRight }
  var hasDescendants: Bool { url.isDirectory }
}
