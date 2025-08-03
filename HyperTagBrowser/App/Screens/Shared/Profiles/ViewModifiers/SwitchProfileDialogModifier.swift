// created on 5/2/25 by robinsr

import Factory
import SwiftUI


struct SwitchProfileDialogModifier: ViewModifier {
  @Environment(\.dispatcher) var dispatch
  
  @Injected(\PreferencesContainer.externalProfiles) var externProfiles
  
  @Binding var profileId: ExternalUserProfile.ID?

  var switchToProfile: ExternalUserProfile {
    if let id = profileId {
      return ExternalUserProfile(id: id)
    } else {
      return DefaultUserProfile.external
    }
  }
  
  var profileName: String { switchToProfile.name }
  var isSwitching: Bool { profileId != nil }
  
  func cancelProfileSwitch() {
    profileId = nil
  }
  
  func acceptProfileSwitch() {
    if let id = profileId {
      profileId = nil
      dispatch(.showSheet(.none))
      dispatch(.setActiveProfile(to: id))
    }
  }
  
  
  func body(content: Content) -> some View {
    content
      .confirmationDialog(
        Text("Switch to \(profileName) profile?"),
        isPresented: .notNil($profileId)
      ) {
        DialogActions
      }
  }
  
  @ViewBuilder
  var DialogActions: some View {
    Button("No", role: .cancel) {
      cancelProfileSwitch()
    }
    .keyboardShortcut(.cancelAction)
    
    Button("Yes") {
      acceptProfileSwitch()
    }
    .keyboardShortcut(.defaultAction)
  }
}

extension View {
  func switchProfileConfirmationDialog(selection profileId: Binding<ExternalUserProfile.ID?>) -> some View {
    modifier(SwitchProfileDialogModifier(profileId: profileId))
  }
}
