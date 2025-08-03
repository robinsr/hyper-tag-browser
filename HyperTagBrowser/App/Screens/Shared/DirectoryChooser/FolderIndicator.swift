// created on 4/27/25 by robinsr

import SwiftUI

struct FolderIndicator: View {
  var name: String = ""
  
  var body: some View {
    Text(name)
      .font(.body)
      .prefixWithFileIcon(.folder, size: 16, presentation: .image)
  }
}
