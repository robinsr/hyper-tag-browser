// created on 5/14/25 by robinsr

import SwiftUI
import System


struct NavigateToFolderButton: View {
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  
  var location: FilePath
  var relativeTo: FilePath = UserLocation.homePath
  
  var relativepath: String {
    location.path(relativeTo: relativeTo).string
  }
  
  var labelText: String {
    relativepath.isEmpty ? location.baseName : relativepath
  }
  
  var body: some View {
    Button {
      dispatch(.showSheet(.none))
      navigate(.folder(location))
    } label: {
      Text(verbatim: labelText)
        .prefixWithFileIcon(.folder, size: 16)
    }
  }
}
