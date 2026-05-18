// created on 5/14/25 by robinsr

import SwiftUI
import System


struct NavigateToFolderButton: View {
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  
  var location: FilePath
  var relativeTo: FilePath = UserLocation.homePath
  var onTap: (() -> ())? = nil
  
  private func defaultTapHandler() {
    navigate(.folder(location))
  }
  
  private var isUbiquitousItem: Bool {
    location.fileURL.isUbiquitousItem
  }
  
  var relativePath: String {
    location.relative(to: relativeTo).string
  }
  
  var labelText: String {
    if isUbiquitousItem {
      return "\(homeURL: location.fileURL)"
    }
    
    else if relativePath.notEmpty {
      return relativePath
    }
    
    return location.baseName
  }
  
  var body: some View {
    Button {
      if let tapHandler = onTap {
        tapHandler()
      } else {
        defaultTapHandler()
      }
    } label: {
      Text(verbatim: labelText)
        .prefixWithFileIcon(.folder, size: 16)
    }
  }
}
