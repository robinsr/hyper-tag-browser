// created on 1/3/25 by robinsr

import SwiftUI
import Factory


struct ProfileInfoButton: View {
  @Environment(\.dispatcher) var dispatch
  
  @Injected(\PreferencesContainer.userProfile) var current
  
  var body: some View {
    StatusBarButton {
      dispatch(.showSheet(.userProfiles))
    } label: {
      Label(current.name, .person)
    }
    .contextMenu {
      Button(current.dbFile, using: .finder) {
        Text("Reveal DB in finder")
      }
    }
  }
}
